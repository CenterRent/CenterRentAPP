import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background with hero image effect
            LinearGradient(
                colors: [Color(hex: "#1A1A2E"), Color(hex: "#2D1B6E")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // Decorative blobs
            GeometryReader { geo in
                Circle().fill(Color.crPrimary.opacity(0.4))
                    .frame(width: 300, height: 300)
                    .offset(x: -80, y: -60)
                    .blur(radius: 60)
                Circle().fill(Color.crSecondary.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .offset(x: geo.size.width - 120, y: 40)
                    .blur(radius: 50)
            }.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: CRSpacing.md) {
                    HStack(spacing: 0) {
                        Text("C")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundColor(.crPrimary)
                        Text("R")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundColor(.crSecondary)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Text("Center Rent")
                        .font(.crDisplay2)
                        .foregroundColor(.white)
                        .opacity(logoOpacity)

                    Text("Alugue espaços e equipamentos\npara profissionais de saúde")
                        .font(.crBody)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(contentOpacity)
                }

                Spacer()

                // Auth Options
                VStack(spacing: CRSpacing.xl) {
                    Text("Entrar com")
                        .font(.crLabel)
                        .foregroundColor(.white.opacity(0.7))

                    HStack(spacing: CRSpacing.xl) {
                        // Email
                        Button {
                            router.push(.login)
                        } label: {
                            Circle()
                                .fill(Color.crSecondary)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.crTextPrimary)
                                )
                        }

                        // Google
                        SocialCircleButton(
                            icon: "g.circle.fill",
                            bgColor: Color(hex: "#4285F4")
                        ) { /* Google Sign In */ }

                        // Apple
                        SocialCircleButton(
                            icon: "apple.logo",
                            bgColor: .white
                        ) { /* Apple Sign In */ }

                        // Facebook
                        SocialCircleButton(
                            icon: "f.circle.fill",
                            bgColor: Color(hex: "#1877F2")
                        ) { /* Facebook Sign In */ }
                    }

                    HStack(spacing: 4) {
                        Text("Não tem uma conta?")
                            .font(.crBody)
                            .foregroundColor(.white.opacity(0.7))
                        Button("Cadastre-se") {
                            router.push(.register)
                        }
                        .font(.crLabel)
                        .foregroundColor(.crSecondary)
                    }
                }
                .opacity(contentOpacity)
                .padding(.bottom, CRSpacing.xxxl)
            }
            .padding(.horizontal, CRSpacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
                contentOpacity = 1.0
            }
        }
    }
}

struct SocialCircleButton: View {
    let icon: String
    let bgColor: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(bgColor)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(bgColor == .white ? .black : .white)
                )
                .crShadowSoft()
        }.buttonStyle(CRPressStyle())
    }
}
