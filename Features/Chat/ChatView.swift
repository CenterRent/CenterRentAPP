import SwiftUI
import Combine

// MARK: - Conversation List
struct ConversationListView: View {
    @StateObject private var vm = ConversationListViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.currentUser?.phoneVerified == false {
                phoneVerificationRequired
            } else if vm.isLoading {
                loadingView
            } else if vm.conversations.isEmpty {
                emptyState
            } else {
                conversationList
            }
        }
        .navigationTitle("Mensagens")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await vm.load(userId: authService.currentUser?.id ?? "") } }
    }

    private var conversationList: some View {
        List {
            ForEach(vm.conversations) { conversation in
                CRConversationRow(conversation: conversation)
                    .onTapGesture { router.navigate(to: .chat(conversationId: conversation.id)) }
                    .listRowInsets(EdgeInsets(top: 0, leading: CRSpacing.screenHorizontal,
                                             bottom: 0, trailing: CRSpacing.screenHorizontal))
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await vm.load(userId: authService.currentUser?.id ?? "") }
    }

    private var phoneVerificationRequired: some View {
        VStack(spacing: CRSpacing.s4) {
            Image(systemName: "phone.badge.plus").font(.system(size: 56))
                .foregroundColor(CRColor.Feedback.warning)
            Text("Verificação necessária").font(.crHeading4).foregroundColor(CRColor.Text.primary)
            Text("Verifique seu telefone para enviar e receber mensagens com outros profissionais.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            CRButton("Verificar telefone", variant: .primary, size: .lg) {
                router.navigate(to: .profile(userId: authService.currentUser?.id ?? ""))
            }
        }
        .padding(CRSpacing.s8)
    }

    private var emptyState: some View {
        VStack(spacing: CRSpacing.s4) {
            Image(systemName: "message.badge").font(.system(size: 56))
                .foregroundColor(CRColor.Neutral.n300)
            Text("Nenhuma conversa ainda").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            Text("Quando você entrar em contato com um anunciante, a conversa aparecerá aqui.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            CRButton("Explorar espaços", variant: .outline, size: .md) { router.switchTab(to: .home) }
        }
        .padding(CRSpacing.s8)
    }

    private var loadingView: some View {
        LazyVStack(spacing: CRSpacing.s3) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: CRSpacing.s3) {
                    Circle().fill(CRColor.Neutral.n200).frame(width: CRSize.avatarMD, height: CRSize.avatarMD)
                    VStack(alignment: .leading, spacing: CRSpacing.s2) {
                        RoundedRectangle(cornerRadius: 4).fill(CRColor.Neutral.n200).frame(width: 120, height: 14)
                        RoundedRectangle(cornerRadius: 4).fill(CRColor.Neutral.n200).frame(height: 12)
                    }
                }
                .shimmer()
                .padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
        .padding(.top, CRSpacing.s4)
    }
}

// MARK: - Conversation Row
private struct CRConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            ZStack(alignment: .bottomTrailing) {
                CRAvatar(
                    imageURL: conversation.otherUser?.profileImageURL,
                    name: conversation.otherUser?.fullName ?? "?",
                    size: CRSize.avatarMD
                )
                if conversation.unreadCount > 0 {
                    CRNotificationDot(conversation.unreadCount)
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: CRSpacing.s1) {
                HStack {
                    Text(conversation.otherUser?.fullName ?? "Usuário")
                        .font(conversation.unreadCount > 0 ? .crLabelLG : .crBodyMD)
                        .foregroundColor(CRColor.Text.primary)
                    Spacer()
                    Text(conversation.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.crCaptionSM).foregroundColor(CRColor.Text.tertiary)
                }
                if let listing = conversation.listing {
                    Text(listing.title).font(.crCaptionMD).foregroundColor(CRColor.Text.link).lineLimit(1)
                }
                Text(conversation.lastMessage?.content ?? "Sem mensagens")
                    .font(conversation.unreadCount > 0 ? .crLabelSM : .crCaptionMD)
                    .foregroundColor(conversation.unreadCount > 0 ? CRColor.Text.primary : CRColor.Text.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, CRSpacing.s3)
    }
}

// MARK: - Chat View (messages)
struct ConversationChatView: View {
    let conversationId: String
    @StateObject private var vm = ChatViewModel()
    @EnvironmentObject var authService: AuthService
    @FocusState private var inputFocused: Bool
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: CRSpacing.s2) {
                        ForEach(vm.messages) { message in
                            CRMessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == authService.currentUser?.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, CRSpacing.screenHorizontal)
                    .padding(.top, CRSpacing.s4)
                    .padding(.bottom, CRSpacing.s4)
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: vm.messages.count) { _, _ in
                    if let lastId = vm.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            // Booking Quick Action
            if let listing = vm.listing {
                HStack(spacing: CRSpacing.s2) {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(CRColor.Primary.default)
                    Text("Reservar \(listing.title)")
                        .font(.crLabelSM).foregroundColor(CRColor.Text.primary).lineLimit(1)
                    Spacer()
                    CRButton("Reservar", variant: .primary, size: .sm) {
                        // router.present(.booking(listing: listing))
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.vertical, CRSpacing.s3)
                .background(CRColor.Primary.lighter)
            }

            // Input Bar
            VStack(spacing: 0) {
                Divider().overlay(CRColor.Border.default)
                HStack(spacing: CRSpacing.s3) {
                    TextField("Mensagem...", text: $messageText, axis: .vertical)
                        .font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                        .padding(.horizontal, CRSpacing.s3)
                        .padding(.vertical, CRSpacing.s2)
                        .background(CRColor.Surface.secondary)
                        .cornerRadius(CRRadius.full)
                        .focused($inputFocused)
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        Image(systemName: messageText.trimmingCharacters(in: .whitespaces).isEmpty
                              ? "mic" : "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? CRColor.Icon.secondary : CRColor.Primary.default)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty && vm.isLoading)
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.vertical, CRSpacing.s3)
                .background(CRColor.Background.primary)
                .padding(.bottom, CRSpacing.s2)
            }
        }
        .navigationTitle(vm.otherUser?.fullName ?? "Conversa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let user = vm.otherUser {
                    Button(action: { /* router.navigate(.profile(userId: user.id)) */ }) {
                        CRAvatar(imageURL: user.profileImageURL, name: user.fullName, size: 32)
                    }
                }
            }
        }
        .onAppear { Task { await vm.load(conversationId: conversationId) } }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        HapticFeedback.impact(.light)
        Task { await vm.send(text: text, senderId: authService.currentUser?.id ?? "") }
    }
}

// MARK: - Message Bubble
private struct CRMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .font(.crBodyBase)
                    .foregroundColor(isFromCurrentUser ? .white : CRColor.Text.primary)
                    .padding(.horizontal, CRSpacing.s3)
                    .padding(.vertical, CRSpacing.s2)
                    .background(isFromCurrentUser ? CRColor.Primary.default : CRColor.Surface.primary)
                    .cornerRadius(CRRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: CRRadius.lg)
                            .stroke(isFromCurrentUser ? Color.clear : CRColor.Border.default, lineWidth: CRBorder.thin)
                    )

                HStack(spacing: CRSpacing.s1) {
                    Text(message.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.crCaptionSM).foregroundColor(CRColor.Text.tertiary)
                    if isFromCurrentUser {
                        Image(systemName: statusIcon).font(.system(size: 10))
                            .foregroundColor(message.status == .read ? CRColor.Feedback.info : CRColor.Text.tertiary)
                    }
                }
            }
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }

    private var statusIcon: String {
        switch message.status {
        case .sent:      return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read:      return "checkmark.circle.fill"
        case .sending:   return "clock"
        default:         return "checkmark"
        }
    }
}

// MARK: - ConversationListViewModel
@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false

    func load(userId: String) async {
        isLoading = true; defer { isLoading = false }
        conversations = (try? await SupabaseManager.shared.fetchConversations(userId: userId)) ?? []
    }
}

// MARK: - ChatViewModel
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var otherUser: UserProfile? = nil
    @Published var listing: Listing? = nil
    @Published var isLoading = false

    private var conversationId: String = ""

    func load(conversationId: String) async {
        self.conversationId = conversationId
        isLoading = true; defer { isLoading = false }
        messages = (try? await SupabaseManager.shared.fetchMessages(conversationId: conversationId)) ?? []
        SupabaseManager.shared.subscribeToConversation(id: conversationId) { [weak self] newMessages in
            Task { @MainActor in
                guard let self else { return }
                // Evita duplicar mensagens que o próprio envio já otimisticamente adicionou.
                let newOnes = newMessages.filter { new in !self.messages.contains { $0.id == new.id } }
                self.messages.append(contentsOf: newOnes)
            }
        }
    }

    func send(text: String, senderId: String) async {
        guard !conversationId.isEmpty else { return }
        let msg = ChatMessage(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            content: text,
            type: .text,
            status: .sending,
            createdAt: Date()
        )
        messages.append(msg)
        if let sent = try? await SupabaseManager.shared.sendMessage(msg) {
            if let i = messages.firstIndex(where: { $0.id == msg.id }) { messages[i] = sent }
        } else if let i = messages.firstIndex(where: { $0.id == msg.id }) {
            messages[i].status = .failed
        }
    }
}
