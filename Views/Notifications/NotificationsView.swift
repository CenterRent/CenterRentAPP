import SwiftUI

struct CRNotification: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
    let time: Date
    var isRead: Bool
}

struct NotificationsView: View {
    @State private var notifications: [CRNotification] = [
        CRNotification(id: "1", icon: "calendar.badge.checkmark", iconColor: .crSuccess, title: "Reserva confirmada!", body: "Sua reserva na Sala Odontológica Premium foi confirmada para 15/04.", time: Date().addingTimeInterval(-300), isRead: false),
        CRNotification(id: "2", icon: "star.fill", iconColor: .crWarning, title: "Nova avaliação!", body: "Dr. Gabriel Silva avaliou sua reserva com 5 estrelas.", time: Date().addingTimeInterval(-3600), isRead: false),
        CRNotification(id: "3", icon: "bubble.left.fill", iconColor: .crPrimary, title: "Nova mensagem", body: "Balanced Body: 'O Reformer estará disponível no horário solicitado.'", time: Date().addingTimeInterval(-7200), isRead: true),
        CRNotification(id: "4", icon: "gift.fill", iconColor: .crAccentOrange, title: "Ganhou 25 pontos!", body: "Maria Silva aceitou seu convite e fez a primeira reserva.", time: Date().addingTimeInterval(-86400), isRead: true),
        CRNotification(id: "5", icon: "tag.fill", iconColor: .crAccentPink, title: "Promoção especial", body: "Use WELCOME20 e ganhe 20% de desconto na sua próxima reserva.", time: Date().addingTimeInterval(-172800), isRead: true),
    ]

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(
                title: "Notificações",
                trailing: AnyView(
                    Button("Marcar lidas") {
                        withAnimation { notifications = notifications.map { var n = $0; n.isRead = true; return n } }
                    }
                    .font(.crLabelSmall).foregroundColor(.crPrimary)
                )
            )

            if notifications.isEmpty {
                Spacer()
                Image(systemName: "bell.slash").font(.system(size: 64)).foregroundColor(.crDivider)
                Text("Sem notificações").font(.crH4).foregroundColor(.crTextSecondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifications) { notif in
                            NotificationRow(notification: notif) {
                                if let i = notifications.firstIndex(where: { $0.id == notif.id }) {
                                    withAnimation { notifications[i].isRead = true }
                                }
                            }
                            Divider().padding(.leading, 72)
                        }
                    }
                    .background(Color.white)
                    .padding(.bottom, CRSpacing.xxxl)
                }
            }
        }
        .background(Color.crBackground)
    }
}

struct NotificationRow: View {
    let notification: CRNotification
    let onRead: () -> Void

    var body: some View {
        Button(action: onRead) {
            HStack(alignment: .top, spacing: CRSpacing.md) {
                ZStack {
                    Circle().fill(notification.iconColor.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: notification.icon)
                        .font(.system(size: 20)).foregroundColor(notification.iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(notification.isRead ? .crBody : .crLabel)
                            .foregroundColor(.crTextPrimary)
                        Spacer()
                        if !notification.isRead {
                            Circle().fill(Color.crPrimary).frame(width: 8, height: 8)
                        }
                    }
                    Text(notification.body)
                        .font(.crBodySmall).foregroundColor(.crTextSecondary).lineLimit(2)
                    Text(notification.time, style: .relative)
                        .font(.crCaption).foregroundColor(.crTextTertiary)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
        }
        .buttonStyle(.plain)
        .background(notification.isRead ? Color.white : Color.crPrimary.opacity(0.03))
    }
}
