import SwiftUI

// Alias para compatibilidade
typealias OnboardingView = OnboardingFlowView

// MARK: - Onboarding Flow
// Slides de apresentação mostrados apenas na PRIMEIRA abertura do app.
// Quando concluído, chama `onComplete` — o RootView persiste a flag
// e transiciona para o fluxo de auth (SplashView).
// NÃO contém login/cadastro: isso evita o loop login→onboarding→login.
struct OnboardingFlowView: View {
    /// Chamado quando o usuário termina ou pula o onboarding.
    var onComplete: () -> Void = {}

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "building.2.crop.circle.fill",
            color: CRColor.Primary.default,
            title: "Alugue salas odontológicas",
            description: "Encontre espaços equipados perto de você por hora, dia ou mês. Sem burocracia."
        ),
        OnboardingPage(
            icon: "person.2.fill",
            color: CRColor.Secondary.default,
            title: "Conecte-se P2P",
            description: "Direto entre profissionais. Sem intermediários, com total transparência e segurança."
        ),
        OnboardingPage(
            icon: "checkmark.seal.fill",
            color: CRColor.Feedback.success,
            title: "100% verificado",
            description: "Todos os profissionais são verificados pelo CRO. Confie com tranquilidade."
        ),
        OnboardingPage(
            icon: "calendar.badge.checkmark",
            color: CRColor.Accent.default,
            title: "Agende em segundos",
            description: "Reserve, pague e comece a atender. Agenda em tempo real, sem conflitos."
        )
    ]

    var body: some View {
        ZStack {
            CRColor.Background.primary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Pular
                HStack {
                    Spacer()
                    Button(action: { onComplete() }) {
                        Text("Pular")
                            .font(.crLabelMD)
                            .foregroundColor(CRColor.Text.secondary)
                            .padding(CRSpacing.s4)
                    }
                }

                // Slides
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(CRAnimation.springNormal, value: currentPage)

                // Indicador de página
                HStack(spacing: CRSpacing.s2) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? CRColor.Primary.default : CRColor.Neutral.n300)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(CRAnimation.springFast, value: currentPage)
                    }
                }
                .padding(.bottom, CRSpacing.s8)

                // CTA
                VStack(spacing: CRSpacing.s3) {
                    if currentPage < pages.count - 1 {
                        CRButton("Próximo", variant: .primary, size: .lg, icon: "arrow.right",
                                 iconPosition: .trailing, isFullWidth: true) {
                            withAnimation(CRAnimation.springNormal) { currentPage += 1 }
                        }
                    } else {
                        CRButton("Criar conta grátis", variant: .primary, size: .lg,
                                 isFullWidth: true) {
                            onComplete()
                        }
                        CRButton("Já tenho conta", variant: .ghost, size: .md, isFullWidth: true) {
                            onComplete()
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.bottom, CRSpacing.s10)
            }
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

// MARK: - Onboarding Page View
private struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: CRSpacing.s6) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                Image(systemName: page.icon)
                    .font(.system(size: 72))
                    .foregroundColor(page.color)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: CRSpacing.s3) {
                Text(page.title)
                    .font(.crHeading2)
                    .foregroundColor(CRColor.Text.primary)
                    .multilineTextAlignment(.center)
                Text(page.description)
                    .font(.crBodyLG)
                    .foregroundColor(CRColor.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, CRSpacing.s8)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(CRAnimation.springNormal.delay(0.1)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}
