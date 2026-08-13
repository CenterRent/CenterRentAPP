import SwiftUI
import Combine

// MARK: - HomeView
struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @State private var searchText = ""
    @State private var showFilters = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {

                // ── Search Header ─────────────────────────────────────
                headerSearchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                // ── Categories ────────────────────────────────────────
                categoriesSection
                    .padding(.bottom, 28)

                // ── Próximos a você (horizontal scroll) ───────────────
                nearbySection
                    .padding(.bottom, 28)

                // ── Main feed (vertical) ──────────────────────────────
                feedSection
                    .padding(.bottom, 100) // space above tab bar
            }
        }
        .background(Color(hex: "#F5F5F7").ignoresSafeArea())
        .navigationBarHidden(true)
        .refreshable { await vm.refresh() }
        .onAppear { Task { await vm.loadInitial() } }
        .sheet(isPresented: $showFilters) {
            FilterView(filter: vm.filter)
        }
    }

    // MARK: - Header / Search Bar
    private var headerSearchBar: some View {
        HStack(spacing: 12) {
            // Greeting
            VStack(alignment: .leading, spacing: 2) {
                Text("Olá, \(authService.currentUser?.displayName ?? "Profissional") 👋")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7280"))
                Text("O que você busca hoje?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A2E"))
            }
            Spacer()
            // Notification bell
            Button {
                router.navigate(to: .notifications)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1A2E"))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    // Badge de notificação não lidas (mocado — substituir por vm.unreadCount)
                    Circle()
                        .fill(Color(hex: "#C02D5B"))
                        .frame(width: 10, height: 10)
                        .offset(x: 1, y: -1)
                }
            }
        }
    }

    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Categorias")
                .padding(.horizontal, 20)

            // 2-column color-block grid
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(vm.categories) { cat in
                    CategoryCard(category: cat) {
                        vm.filterByCategory(cat)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Nearby Section (horizontal scroll)
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Próximos a você")
                    .padding(.leading, 20)
                Spacer()
                Button("Ver todos") { router.navigate(to: .search) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(CRColor.Primary.default)
                    .padding(.trailing, 20)
            }

            if vm.isLoading {
                horizontalShimmer
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(vm.nearbyListings) { listing in
                            CRListingCard(
                                listing: listing,
                                onTap: { router.navigate(to: .listingDetail(listingId: listing.id)) },
                                onFavorite: { vm.toggleFavorite(listing.id) },
                                onRent: { router.navigate(to: .listingDetail(listingId: listing.id)) },
                                isCompact: true
                            )
                            .frame(width: 240)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Main Feed (vertical list)
    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle(vm.filter.isActive ? "Resultados" : "Todos os espaços")
                    .padding(.leading, 20)
                Spacer()
                if vm.filter.isActive {
                    Button("Limpar") { vm.clearFilters() }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(CRColor.Primary.default)
                        .padding(.trailing, 20)
                }
            }

            if vm.isLoading {
                verticalShimmer
            } else if vm.listings.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(Array(vm.listings.enumerated()), id: \.element.id) { index, listing in
                        // Partner banner after 4th card
                        if index == 4 {
                            PartnerBannerCard { router.navigate(to: .mgm) }
                                .padding(.horizontal, 20)
                        }

                        CRListingCard(
                            listing: listing,
                            onTap: { router.navigate(to: .listingDetail(listingId: listing.id)) },
                            onFavorite: { vm.toggleFavorite(listing.id) },
                            onRent: { router.navigate(to: .listingDetail(listingId: listing.id)) }
                        )
                        .padding(.horizontal, 20)
                        .onAppear {
                            if listing.id == vm.listings.last?.id {
                                Task { await vm.loadMore() }
                            }
                        }
                    }

                    if vm.isLoadingMore {
                        ProgressView()
                            .tint(CRColor.Primary.default)
                            .padding()
                    }
                }
            }
        }
    }

    // MARK: - Section Title
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "#1A1A2E"))
    }

    // MARK: - Shimmer placeholders
    private var horizontalShimmer: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(width: 240, height: 230)
                        .shimmer()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var verticalShimmer: some View {
        LazyVStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(height: 280)
                    .shimmer()
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 52))
                .foregroundColor(CRColor.Primary.default.opacity(0.4))
            Text("Nenhum espaço encontrado")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#1A1A2E"))
            Text("Tente ajustar seus filtros ou buscar em outra cidade.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#6B7280"))
                .multilineTextAlignment(.center)
            Button(action: { vm.clearFilters() }) {
                Text("Limpar filtros")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CRColor.Primary.default)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }
}

// MARK: - CategoryCard
private struct CategoryCard: View {
    let category: SpaceCategory
    let action: () -> Void

    // Palette of gradient pairs for visual richness
    private var gradient: LinearGradient {
        let base = category.color
        return LinearGradient(
            colors: [base, base.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradient)
                    .frame(height: 72)

                // Decorative circle
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .offset(x: -10, y: 18)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .offset(x: 20, y: -10)

                Text(category.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Partner Banner Card
private struct PartnerBannerCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Seja um Parceiro")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Alugue seus equipamentos e espaços e aumente sua renda.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                    Text("Saiba mais →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#DCF289"))
                        .padding(.top, 2)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#DCF289"))
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [CRColor.Primary.default, CRColor.Primary.dark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: CRColor.Primary.default.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Filter
enum QuickFilter: String, CaseIterable {
    case available = "Disponível agora"
    case verified  = "Verificados"
    case hourly    = "Por hora"
    case daily     = "Por dia"
    case cheap     = "Menor preço"

    var label: String { rawValue }
    var icon: String {
        switch self {
        case .available: return "circle.fill"
        case .verified:  return "checkmark.seal"
        case .hourly:    return "clock"
        case .daily:     return "calendar"
        case .cheap:     return "tag"
        }
    }
}

// MARK: - HomeViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var listings: [Listing]         = []
    @Published var nearbyListings: [Listing]   = []
    @Published var categories: [SpaceCategory] = SpaceCategory.mock
    @Published var filter                      = ListingFilter()
    @Published var activeQuickFilter: QuickFilter? = nil
    @Published var isLoading                   = false
    @Published var isLoadingMore               = false
    @Published var hasMore                     = true
    // Used by SearchResultsView
    @Published var showFilters                 = false
    @Published var isSearching                 = false
    @Published var searchResults: [Listing]    = []

    private let manager  = SupabaseManager.shared
    private var page     = 0
    private let pageSize = 10

    func loadInitial() async {
        isLoading = true
        defer { isLoading = false }
        page = 0

        async let listingsTask   = manager.searchListings(query: filter.query, filter: filter, limit: pageSize, offset: 0)
        async let categoriesTask = manager.fetchCategories()

        let fetched = (try? await listingsTask) ?? []
        let cats    = (try? await categoriesTask) ?? SpaceCategory.mock

        listings       = fetched
        nearbyListings = Array(fetched.prefix(6))
        if !cats.isEmpty { categories = cats }
    }

    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        page += 1
        let more = (try? await manager.searchListings(
            query: filter.query, filter: filter,
            limit: pageSize, offset: page * pageSize
        )) ?? []
        if more.isEmpty { hasMore = false } else { listings.append(contentsOf: more) }
    }

    func refresh() async { await loadInitial() }

    func filterByCategory(_ cat: SpaceCategory) {
        filter.specialties = [cat.name]
        Task { await loadInitial() }
    }

    func clearFilters() {
        filter = ListingFilter()
        activeQuickFilter = nil
        Task { await loadInitial() }
    }

    func toggleFavorite(_ id: String) { HapticFeedback.impact(.light) }
    func toggleFavorite(_ listing: Listing) { toggleFavorite(listing.id) }

    func loadCategoryListings(_ category: SpaceCategory) async -> [Listing] {
        var f = ListingFilter()
        f.specialties = [category.name]
        return (try? await manager.searchListings(query: "", filter: f, limit: pageSize, offset: 0)) ?? []
    }

    func search(query: String) {
        filter.query = query
        isSearching = !query.isEmpty
        Task {
            await loadInitial()
            searchResults = listings
            isSearching = false
        }
    }
}
