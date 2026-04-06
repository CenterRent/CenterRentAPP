import SwiftUI

struct OnboardingPage {
    let gradient: LinearGradient
    let image: String         // SF Symbol or asset name
    let headline: String
    let highlightWord: String
    let highlightColor: Color
    let body: String
}

let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        gradient: .crOnboarding2,
        image: "stethoscope",
        headline: "Acesse sem precisar",
        highlightWord: "INVESTIR.",
        highlightColor: .crSecondary,
        body: "Alugue equipamentos de saúde, estética e fisio por hora ou dia. Pague só quando usar."
    ),
    OnboardingPage(
        gradient: LinearGradient(colors: [Color(hex: "#F4874B"), Color(hex: "#E07020")], startPoint: .top, endPoint: .bottom),
        image: "eye.circle.fill",
        headline: "Seu ativo parado\ngera",
        highlightWord: "ZERO",
        highlightColor: Color(hex: "#DCF289"),
        body: "Transforme equipamentos ociosos em renda. Alugue para outros profissionais."
    ),
    OnboardingPage(
        gradient: .crOnboarding3,
        image: "lock.shield.fill",
        headline: "Contrato digital\ne pagamento",
        highlightWord: "SEGURO.",
        highlightColor: Color(hex: "#D94F7E"),
        body: "Contratos digitais, pagamento via cartão, PIX ou Apple Pay. Segurança para ambas as partes."
    ),
]

struct OnboardingView: View {
    @EnvironmentObject var router: AppRouter
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(onboardingPages.indices, id: \.self) { i in
                    OnboardingPageView(page: onboardingPages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Bottom Controls
            VStack(spacing: CRSpacing.xl) {
                // Page Dots
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.crPrimary : Color.white.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                HStack {
                    if currentPage < onboardingPages.count - 1 {
                        Button("Pular") { router.push(.login) }
                            .font(.crLabel)
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()

                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Circle()
                                .fill(Color.crPrimary)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .crShadowFloat()
                        }
                    } else {
                        CRButton(title: "Começar agora") {
                            router.push(.login)
                        }
                    }
                }
            }
            .padding(.horizontal, CRSpacing.xl)
            .padding(.bottom, CRSpacing.xxxl)
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        ZStack {
            page.gradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Image area (top 55%)
                ZStack {
                    Image(systemName: page.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundColor(.white.opacity(0.9))
                        .scaleEffect(appeared ? 1.0 : 0.8)
                        .opacity(appeared ? 1.0 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.48)

                // Text area
                VStack(alignment: .leading, spacing: CRSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(page.headline)
                            .font(.crH1)
                            .foregroundColor(.white)
                        Text(page.highlightWord)
                            .font(.crDisplay2)
                            .foregroundColor(page.highlightColor)
                    }

                    Text(page.body)
                        .font(.crBodyLarge)
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, CRSpacing.xl)
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}
