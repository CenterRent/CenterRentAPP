import SwiftUI

struct ChatListView: View {
    @State private var conversations: [ChatConversation] = ChatConversation.mocks
    @State private var searchText = ""
    @EnvironmentObject var router: AppRouter

    var filtered: [ChatConversation] {
        guard !searchText.isEmpty else { return conversations }
        return conversations.filter { $0.otherUserName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Mensagens")

            // Search
            HStack(spacing: CRSpacing.sm) {
                Image(systemName: "magnifyingglass").foregroundColor(.crTextTertiary)
                TextField("Buscar conversa...", text: $searchText)
                    .font(.crBody)
            }
            .padding(.horizontal, CRSpacing.base)
            .frame(height: 44)
            .background(Color.crBackground)
            .cornerRadius(CRRadius.pill)
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
            .background(Color.white)

            Divider()

            if filtered.isEmpty {
                VStack(spacing: CRSpacing.xl) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 64)).foregroundColor(.crDivider)
                    Text("Nenhuma conversa ainda")
                        .font(.crH4).foregroundColor(.crTextSecondary)
                    Text("Quando você entrar em contato com um anfitrião,\na conversa aparecerá aqui.")
                        .font(.crBody).foregroundColor(.crTextTertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(CRSpacing.xl)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { conv in
                            ConversationRow(conversation: conv) {
                                router.push(.chatDetail(conv))
                            }
                            Divider().padding(.leading, 76)
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

struct ConversationRow: View {
    let conversation: ChatConversation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: CRSpacing.md) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.crPrimary.opacity(0.2))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text(String(conversation.otherUserName.prefix(2)).uppercased())
                                .font(.crLabel).foregroundColor(.crPrimary)
                        )
                    if conversation.unreadCount > 0 {
                        Circle().fill(Color.crPrimary).frame(width: 14, height: 14)
                            .overlay(
                                Text("\(conversation.unreadCount)")
                                    .font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.otherUserName)
                            .font(conversation.unreadCount > 0 ? .crLabel : .crBody)
                            .foregroundColor(.crTextPrimary)
                        Spacer()
                        Text(conversation.lastMessageTime, style: .time)
                            .font(.crCaption)
                            .foregroundColor(conversation.unreadCount > 0 ? .crPrimary : .crTextTertiary)
                    }

                    if let listing = conversation.listingTitle {
                        Text(listing)
                            .font(.crCaption)
                            .foregroundColor(.crTextTertiary)
                            .lineLimit(1)
                    }

                    Text(conversation.lastMessage)
                        .font(.crBodySmall)
                        .foregroundColor(conversation.unreadCount > 0 ? .crTextPrimary : .crTextSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
        }
        .buttonStyle(.plain)
        .background(conversation.unreadCount > 0 ? Color.crPrimary.opacity(0.03) : Color.white)
    }
}

// MARK: - Chat Detail
struct ChatDetailView: View {
    let conversation: ChatConversation
    @EnvironmentObject var router: AppRouter
    @State private var messages: [ChatMessage] = ChatMessage.mocks
    @State private var newMessage = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with user info
            HStack(spacing: CRSpacing.md) {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.crTextPrimary)
                }

                Circle().fill(Color.crPrimary.opacity(0.2)).frame(width: 36, height: 36)
                    .overlay(Text(String(conversation.otherUserName.prefix(2))).font(.crLabelSmall).foregroundColor(.crPrimary))

                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.otherUserName).font(.crLabel)
                    Text("Online agora").font(.crCaption).foregroundColor(.crSuccess)
                }
                Spacer()
                Button { } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.crTextPrimary)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Listing context banner
            if let listing = conversation.listingTitle {
                HStack(spacing: CRSpacing.sm) {
                    Image(systemName: "building.2.fill").foregroundColor(.crPrimary).font(.system(size: 14))
                    Text(listing).font(.crBodySmall).foregroundColor(.crTextSecondary)
                    Spacer()
                    Button("Ver anúncio") {}.font(.crLabelSmall).foregroundColor(.crPrimary)
                }
                .padding(.horizontal, CRSpacing.base)
                .padding(.vertical, CRSpacing.sm)
                .background(Color.crPrimary.opacity(0.05))
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: CRSpacing.sm) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, isFromMe: msg.senderId == "me")
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, CRSpacing.base)
                    .padding(.vertical, CRSpacing.md)
                }
                .onAppear {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            // Input bar
            HStack(spacing: CRSpacing.md) {
                Button { } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26)).foregroundColor(.crPrimary)
                }

                TextField("Escreva uma mensagem...", text: $newMessage, axis: .vertical)
                    .font(.crBody)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, CRSpacing.md)
                    .padding(.vertical, CRSpacing.sm)
                    .background(Color.crBackground)
                    .cornerRadius(CRRadius.xl)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(newMessage.isEmpty ? .crTextTertiary : .crPrimary)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.sm)
            .background(Color.white)
            .overlay(Divider(), alignment: .top)
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }

    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let msg = ChatMessage(id: UUID().uuidString, senderId: "me", content: newMessage, createdAt: Date(), isRead: false)
        withAnimation { messages.append(msg) }
        newMessage = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 60) }
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.crBody)
                    .foregroundColor(isFromMe ? .white : .crTextPrimary)
                    .padding(.horizontal, CRSpacing.md)
                    .padding(.vertical, CRSpacing.sm)
                    .background(isFromMe ? Color.crPrimary : Color.white)
                    .cornerRadius(CRRadius.lg, corners: isFromMe
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight]
                    )
                    .crShadowSoft()

                Text(message.createdAt, style: .time)
                    .font(.crCaption).foregroundColor(.crTextTertiary)
            }
            if !isFromMe { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Mock data
extension ChatConversation {
    static let mocks: [ChatConversation] = [
        ChatConversation(id: "1", otherUserId: "u1", otherUserName: "Dr. Gabriel Silva", otherUserAvatarURL: nil,
                         lastMessage: "Perfeito! Confirmo a reserva para sexta.", lastMessageTime: Date().addingTimeInterval(-600),
                         unreadCount: 2, listingTitle: "Sala Odontológica Premium"),
        ChatConversation(id: "2", otherUserId: "u2", otherUserName: "Balanced Body", otherUserAvatarURL: nil,
                         lastMessage: "O Reformer estará disponível no horário.", lastMessageTime: Date().addingTimeInterval(-3600),
                         unreadCount: 0, listingTitle: "Reformer de Pilates"),
        ChatConversation(id: "3", otherUserId: "u3", otherUserName: "Espaço Bem-Estar", otherUserAvatarURL: nil,
                         lastMessage: "Obrigado pela avaliação! 😊", lastMessageTime: Date().addingTimeInterval(-86400),
                         unreadCount: 0, listingTitle: "Sala de massoterapia"),
    ]
}

extension ChatMessage {
    static let mocks: [ChatMessage] = [
        ChatMessage(id: "m1", senderId: "u1", content: "Olá! Vi que você se interessou pela minha sala odontológica.", createdAt: Date().addingTimeInterval(-3600), isRead: true),
        ChatMessage(id: "m2", senderId: "me", content: "Sim! Queria saber se está disponível para o dia 15.", createdAt: Date().addingTimeInterval(-3500), isRead: true),
        ChatMessage(id: "m3", senderId: "u1", content: "Está sim! Qual horário você precisa?", createdAt: Date().addingTimeInterval(-3400), isRead: true),
        ChatMessage(id: "m4", senderId: "me", content: "Das 9h às 17h, o dia todo.", createdAt: Date().addingTimeInterval(-3300), isRead: true),
        ChatMessage(id: "m5", senderId: "u1", content: "Perfeito! Confirmo a reserva para sexta.", createdAt: Date().addingTimeInterval(-600), isRead: false),
    ]
}
