import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: CRTab = .home
    @State private var chatBadge = 2
    @State private var notifBadge = 1

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                        .environmentObject(router)
                case .reservations:
                    MyBookingsView()
                        .environmentObject(router)
                        .environmentObject(authVM)
                case .chat:
                    ChatListView()
                        .environmentObject(router)
                case .notifications:
                    NotificationsView()
                        .environmentObject(router)
                case .profile:
                    ProfileView()
                        .environmentObject(router)
                        .environmentObject(authVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Glass Tab Bar (VISUAL 10)
            CRMainTabBar(
                selected: $selectedTab,
                badgeCounts: [
                    .chat: chatBadge,
                    .notifications: notifBadge
                ]
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
