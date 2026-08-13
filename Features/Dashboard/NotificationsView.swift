import SwiftUI
import Combine

struct NotificationsView: View {
    @StateObject private var vm = NotificationsViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if vm.isLoading {
                loadingView
            } else if vm.notifications.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .navigationTitle("Notificações")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !vm.notifications.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Marcar tudo") { vm.markAllRead() }
                        .font(.crLabelSM).foregroundColor(CRColor.Primary.default)
                }
            }
        }
        .onAppear { Task { await vm.load(userId: authService.currentUser?.id ?? "") } }
    }

    private var notificationList: some View {
        List {
            ForEach(vm.groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(date).font(.crLabelSM).foregroundColor(CRColor.Text.tertiary)) {
                    ForEach(vm.groupedNotifications[date] ?? []) { notif in
                        NotificationRow(notification: notif)
                            .listRowInsets(EdgeInsets(top: CRSpacing.s2, leading: CRSpacing.screenHorizontal,
                                                      bottom: CRSpacing.s2, trailing: CRSpacing.screenHorizontal))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture { vm.markRead(notif.id) }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: CRSpacing.s4) {
            Image(systemName: "bell.slash").font(.system(size: 56)).foregroundColor(CRColor.Neutral.n300)
            Text("Sem notificações").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            Text("Você verá aqui atualizações sobre reservas, mensagens e avaliações.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
        }
        .padding(CRSpacing.s8)
    }

    private var loadingView: some View {
        LazyVStack(spacing: CRSpacing.s3) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: CRSpacing.s3) {
                    Circle().fill(CRColor.Neutral.n200).frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: CRSpacing.s2) {
                        RoundedRectangle(cornerRadius: 4).fill(CRColor.Neutral.n200).frame(height: 14)
                        RoundedRectangle(cornerRadius: 4).fill(CRColor.Neutral.n200).frame(width: 200, height: 12)
                    }
                }
                .shimmer().padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
        .padding(.top, CRSpacing.s4)
    }
}

private struct NotificationRow: View {
    let notification: AppNotification

    private var icon: (name: String, color: Color) {
        switch notification.type {
        case .bookingRequest:   return ("calendar.badge.plus", CRColor.Primary.default)
        case .bookingAccepted:  return ("checkmark.circle.fill", CRColor.Feedback.success)
        case .bookingDeclined:  return ("xmark.circle.fill", CRColor.Feedback.error)
        case .newMessage:       return ("message.fill", CRColor.Secondary.default)
        case .reviewReceived:   return ("star.fill", CRColor.Accent.default)
        case .verificationDone: return ("checkmark.seal.fill", CRColor.Feedback.success)
        case .referralReward:   return ("gift.fill", CRColor.Accent.default)
        case .system:           return ("bell.fill", CRColor.Neutral.n500)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: CRSpacing.s3) {
            ZStack {
                Circle()
                    .fill(icon.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon.name)
                    .font(.system(size: CRSize.iconMD))
                    .foregroundColor(icon.color)
            }
            VStack(alignment: .leading, spacing: CRSpacing.s1) {
                HStack {
                    Text(notification.title)
                        .font(notification.isRead ? .crBodyBase : .crLabelMD)
                        .foregroundColor(CRColor.Text.primary)
                    Spacer()
                    Text(notification.createdAt.formatted(.relative(presentation: .named)))
                        .font(.crCaptionSM).foregroundColor(CRColor.Text.tertiary)
                }
                Text(notification.body)
                    .font(.crBodySM).foregroundColor(CRColor.Text.secondary).lineSpacing(3)
            }
            if !notification.isRead {
                Circle().fill(CRColor.Primary.default).frame(width: 8, height: 8).padding(.top, 4)
            }
        }
        .padding(CRSpacing.s3)
        .background(notification.isRead ? CRColor.Surface.primary : CRColor.Primary.lighter.opacity(0.5))
        .cornerRadius(CRRadius.md)
    }
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false

    var groupedNotifications: [String: [AppNotification]] {
        Dictionary(grouping: notifications) { notif in
            let cal = Calendar.current
            if cal.isDateInToday(notif.createdAt) { return "Hoje" }
            if cal.isDateInYesterday(notif.createdAt) { return "Ontem" }
            return notif.createdAt.formatted(.dateTime.day().month(.wide))
        }
    }

    func load(userId: String) async {
        isLoading = true; defer { isLoading = false }
        // notifications = try? await supabase.fetchNotifications(userId)
        // Seed data for development
        notifications = []
    }

    func markRead(_ id: String) {
        if let i = notifications.firstIndex(where: { $0.id == id }) {
            notifications[i].isRead = true
        }
    }

    func markAllRead() {
        notifications = notifications.map {
            var n = $0; n.isRead = true; return n
        }
    }
}
