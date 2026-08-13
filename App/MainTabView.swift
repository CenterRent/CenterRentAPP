import SwiftUI

// MARK: - MainTabView
// Built on the native iOS 26 Tab API per Apple HIG:
// https://developer.apple.com/design/human-interface-guidelines/tab-bars
//
// Key native behaviours used:
//  • Tab(role: .search) — automatically places the search tab as a separate
//    pill/circle outside the main bar (matches Figma node 3039-3896 exactly).
//  • .tabBarMinimizeBehavior(.onScrollDown) — tab bar collapses to a minimal
//    form while the user scrolls, revealing more content.
//  • Liquid Glass material — applied automatically by iOS 26 to the floating
//    tab bar; no UIBlurEffect or custom background code needed.
//  • Content flows beneath the floating bar via native safe-area insets.

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── 1. Home ───────────────────────────────────────────────
            Tab("Home", systemImage: "house", value: 0) {
                NavigationStack(path: $router.navigationPath) {
                    HomeView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            destinationView(for: destination)
                        }
                }
            }

            // ── 2. Chat ───────────────────────────────────────────────
            Tab("Chat", systemImage: "message", value: 1) {
                NavigationStack {
                    ConversationListView()
                }
            }

            // ── 3. Perfil ─────────────────────────────────────────────
            Tab("Perfil", systemImage: "person.crop.circle", value: 2) {
                NavigationStack(path: $router.profilePath) {
                    ProfileView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            profileDestinationView(for: destination)
                        }
                }
            }

            // ── 4. Carrinho ───────────────────────────────────────────
            Tab("Carrinho", systemImage: "bag", value: 3) {
                NavigationStack {
                    DashboardView()
                }
            }

            // ── 5. Search — role: .search places this tab as a separate
            //    pill on the trailing side of the bar automatically ──────
            Tab("Buscar", systemImage: "magnifyingglass", value: 4, role: .search) {
                NavigationStack {
                    SearchView()
                }
            }
        }
        // Tab bar collapses when user scrolls content down (HIG recommendation)
        .tabBarMinimizeBehavior(.onScrollDown)
        // Active-tab accent — matches Figma design token #C02D5B
        .tint(Color(hex: "#C02D5B"))
        // Sync router.selectedTab ↔ local state (supports deep links)
        .onChange(of: selectedTab) { _, newTab in
            router.selectedTab = newTab
        }
        .onChange(of: router.selectedTab) { _, newIndex in
            if newIndex != selectedTab {
                selectedTab = newIndex
            }
        }
        // Sheets
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    // MARK: - Push Destinations
    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .listingDetail(let id):  ListingDetailView(listingId: id)
        case .createListing:          CreateListingView()
        case .chat(let id):           ConversationChatView(conversationId: id)
        case .chatDetail(let id):     ConversationChatView(conversationId: id)
        case .profile(let id):        PublicProfileView(userId: id)
        case .bookingDetail(let id):  BookingRequestDetailView(bookingId: id)
        case .phoneVerification:      PhoneVerificationView(isOnboarding: false)
        case .dashboard:              DashboardView()
        case .mgm:                    MGMView()
        case .notifications:          NotificationsView()
        case .settings:               SettingsView()
        case .search:                 SearchView()
        default:                      EmptyView()
        }
    }

    // MARK: - Profile Tab Destinations
    @ViewBuilder
    private func profileDestinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .myListings:             MyListingsView()
        case .dashboard:              DashboardView()
        case .mgm:                    MGMView()
        case .notifications:          NotificationsView()
        case .settings:               SettingsView()
        case .editProfile:            EditProfileView()
        case .listingDetail(let id):  ListingDetailView(listingId: id)
        default:                      EmptyView()
        }
    }

    // MARK: - Sheet Views
    @ViewBuilder
    private func sheetView(for sheet: SheetDestination) -> some View {
        switch sheet {
        case .filters(let filter):
            FilterView(filter: filter)
        case .booking(let listing):
            BookingRequestView(listing: listing)
        case .review(let booking):
            ReviewView(booking: booking)
        case .imageViewer(let urls, let index):
            ImageViewerView(imageURLs: urls, startIndex: index)
        case .reportListing(let id):
            ReportListingView(listingId: id)
        default:
            EmptyView()
        }
    }
}
