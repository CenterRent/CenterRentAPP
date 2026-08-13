import SwiftUI

struct ReviewView: View {
    let booking: Booking
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var rating = 0
    @State private var comment = ""
    @State private var isLoading = false
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CRSpacing.s8) {
                    if submitted {
                        successView
                    } else {
                        reviewForm
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.top, CRSpacing.s8)
                .padding(.bottom, CRSpacing.s10)
            }
            .navigationTitle("Avaliar experiência")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(CRColor.Icon.primary)
                    }
                }
            }
        }
    }

    private var reviewForm: some View {
        VStack(spacing: CRSpacing.s6) {
            // Prompt
            VStack(spacing: CRSpacing.s2) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 56)).foregroundColor(CRColor.Accent.default)
                Text("Como foi a experiência?")
                    .font(.crHeading3).foregroundColor(CRColor.Text.primary)
                Text("Sua avaliação ajuda outros profissionais a encontrar os melhores espaços.")
                    .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            }

            // Star Rating
            VStack(spacing: CRSpacing.s3) {
                Text(ratingLabel).font(.crHeading5).foregroundColor(CRColor.Text.primary)
                HStack(spacing: CRSpacing.s3) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: { withAnimation(CRAnimation.springFast) { rating = i }; HapticFeedback.selection() }) {
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 44))
                                .foregroundColor(i <= rating ? CRColor.Accent.default : CRColor.Neutral.n300)
                                .scaleEffect(i <= rating ? 1.1 : 1.0)
                                .animation(CRAnimation.springFast, value: rating)
                        }
                    }
                }
            }

            // Quick Tags
            if rating > 0 {
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("O que você mais valorizou?").font(.crLabelMD).foregroundColor(CRColor.Text.secondary)
                    FlowLayout(spacing: CRSpacing.s2) {
                        ForEach(quickTags, id: \.self) { tag in
                            Button(action: {
                                if comment.contains(tag) {
                                    comment = comment.replacingOccurrences(of: tag + " ", with: "")
                                } else {
                                    comment += tag + " "
                                }
                            }) {
                                Text(tag)
                                    .font(.crLabelSM)
                                    .foregroundColor(comment.contains(tag) ? .white : CRColor.Primary.default)
                                    .padding(.horizontal, CRSpacing.s3).padding(.vertical, CRSpacing.s2)
                                    .background(comment.contains(tag) ? CRColor.Primary.default : CRColor.Primary.lighter)
                                    .cornerRadius(CRRadius.full)
                            }
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Comment
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                HStack {
                    Text("Comentário").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    Spacer()
                    Text("\(comment.count)/500").font(.crCaptionSM)
                        .foregroundColor(comment.count > 450 ? CRColor.Feedback.error : CRColor.Text.tertiary)
                }
                TextEditor(text: $comment)
                    .font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                    .frame(minHeight: 100)
                    .padding(CRSpacing.s3)
                    .background(CRColor.Surface.primary)
                    .cornerRadius(CRRadius.input)
                    .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                        .stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
                    .onChange(of: comment) { _, newValue in if newValue.count > 500 { comment = String(newValue.prefix(500)) } }
            }

            CRButton("Publicar avaliação", variant: .primary, size: .lg,
                     icon: "checkmark", isLoading: isLoading, isFullWidth: true) {
                Task { await submitReview() }
            }
            .disabled(rating == 0)
            .opacity(rating == 0 ? 0.5 : 1.0)
        }
        .animation(CRAnimation.easeNormal, value: rating)
    }

    private var successView: some View {
        VStack(spacing: CRSpacing.s6) {
            ZStack {
                Circle().fill(CRColor.Feedback.successLight).frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundColor(CRColor.Feedback.success)
            }
            Text("Avaliação publicada!").font(.crHeading3).foregroundColor(CRColor.Text.primary)
            Text("Obrigado por contribuir com a comunidade de profissionais.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            CRButton("Fechar", variant: .primary, size: .lg, isFullWidth: true) { dismiss() }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Muito ruim"
        case 2: return "Ruim"
        case 3: return "Regular"
        case 4: return "Bom"
        case 5: return "Excelente!"
        default: return "Toque para avaliar"
        }
    }

    private var quickTags: [String] {
        switch rating {
        case 4, 5: return ["Espaço limpo", "Bem equipado", "Localização ótima", "Anunciante atencioso", "Fácil de agendar"]
        default:   return ["Espaço sujo", "Equipamento faltando", "Localização difícil", "Comunicação ruim"]
        }
    }

    private func submitReview() async {
        guard rating > 0 else { return }
        isLoading = true; defer { isLoading = false }
        let review = Review(
            id: UUID().uuidString,
            authorId: authService.currentUser?.id ?? "",
            targetId: booking.listingId,
            bookingId: booking.id,
            rating: rating,
            comment: comment,
            createdAt: Date(),
            isPublic: true
        )
        _ = try? await SupabaseClient.shared.createReview(review)
        HapticFeedback.success()
        withAnimation(CRAnimation.springNormal) { submitted = true }
    }
}

// MARK: - Image Viewer
struct ImageViewerView: View {
    let imageURLs: [String]
    let startIndex: Int
    @State private var currentIndex: Int
    @Environment(\.dismiss) var dismiss

    init(imageURLs: [String], startIndex: Int) {
        self.imageURLs = imageURLs
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $currentIndex) {
                ForEach(imageURLs.indices, id: \.self) { i in
                    CRRemoteImage(urlString: imageURLs[i], scaledToFill: false)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text("\(currentIndex + 1) / \(imageURLs.count)")
                        .font(.crLabelMD).foregroundColor(.white)
                }
                .padding(CRSpacing.s4)
                Spacer()
                HStack(spacing: CRSpacing.s2) {
                    ForEach(imageURLs.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, CRSpacing.s8)
            }
        }
    }
}

// MARK: - Report Listing View
struct ReportListingView: View {
    let listingId: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: ReportReason? = nil
    @State private var details = ""
    @State private var submitted = false

    enum ReportReason: String, CaseIterable {
        case fraudulent      = "Anúncio fraudulento"
        case inappropriate   = "Conteúdo inapropriado"
        case wrongInfo       = "Informações incorretas"
        case unavailable     = "Espaço não disponível conforme anunciado"
        case other           = "Outro"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CRSpacing.s6) {
                    if submitted {
                        VStack(spacing: CRSpacing.s4) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 56)).foregroundColor(CRColor.Feedback.success)
                            Text("Denúncia enviada").font(.crHeading4).foregroundColor(CRColor.Text.primary)
                            Text("Nossa equipe irá revisar em até 48 horas. Obrigado por manter a comunidade segura.")
                                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
                            CRButton("Fechar", variant: .primary, size: .lg, isFullWidth: true) { dismiss() }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: CRSpacing.s3) {
                            Text("Motivo da denúncia").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button(action: { selectedReason = reason }) {
                                    HStack {
                                        Text(reason.rawValue).font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                                        Spacer()
                                        Image(systemName: selectedReason == reason ? "circle.fill" : "circle")
                                            .foregroundColor(selectedReason == reason ? CRColor.Primary.default : CRColor.Neutral.n400)
                                    }
                                    .padding(CRSpacing.s3)
                                    .background(selectedReason == reason ? CRColor.Primary.lighter : CRColor.Surface.primary)
                                    .cornerRadius(CRRadius.sm)
                                }
                            }
                            CRTextField("Detalhes adicionais (opcional)", text: $details,
                                        placeholder: "Descreva o problema com mais detalhes...")
                            CRButton("Enviar denúncia", variant: .primary, size: .lg, isFullWidth: true) {
                                HapticFeedback.success()
                                withAnimation { submitted = true }
                            }
                            .disabled(selectedReason == nil)
                            .opacity(selectedReason == nil ? 0.5 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.top, CRSpacing.s6)
                .padding(.bottom, CRSpacing.s10)
            }
            .navigationTitle("Denunciar anúncio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
