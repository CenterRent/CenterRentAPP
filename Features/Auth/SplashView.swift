import SwiftUI

// MARK: - Splash View
// Entry point of the app. Drives navigation exclusively via user interaction.
// Background: Cloudinary image (async loaded, gradient shown while loading).
// Logo: scale zoom-in animation. Buttons appear after logo animation settles.
struct SplashView: View {
    @EnvironmentObject var router: AppRouter

    // MARK: - Animation States
    @State private var logoScale: CGFloat    = 0.28
    @State private var logoOpacity: Double   = 0.0
    @State private var buttonsVisible: Bool  = false
    @State private var bgImageLoaded: Bool   = false

    // MARK: - Background image URL
    private let bgURL = URL(string:
        "https://res.cloudinary.com/dcmwfymws/image/upload/v1775521751/BG_tela_4_ztmvnc.png"
    )

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // ── Background ───────────────────────────────────────
                backgroundLayer(geo: geo)

                // ── Dark overlay so content stays legible ────────────
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.15),
                        .black.opacity(0.55),
                        .black.opacity(0.80)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                // ── Center logo ──────────────────────────────────────
                logoSection
                    .position(x: geo.size.width / 2,
                               y: geo.size.height * 0.40)

                // ── Bottom auth buttons ──────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    if buttonsVisible {
                        authButtons
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                            )
                    }
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .onAppear(perform: startAnimations)
    }

    // MARK: - Background Layer
    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
        // Gradient fallback — always visible immediately
        LinearGradient(
            colors: [Color(hex: "#0D0F1A"), Color(hex: "#1A1040"), Color(hex: "#2D1B6E")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        // Cloudinary hero image — loaded async, fades in when ready
        AsyncImage(url: bgURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .opacity(bgImageLoaded ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.45)) {
                            bgImageLoaded = true
                        }
                    }
            case .failure:
                // Fallback to decorative blobs
                ZStack {
                    Circle()
                        .fill(Color(hex: "#7C3AED").opacity(0.45))
                        .frame(width: 320).offset(x: -60, y: -80).blur(radius: 70)
                    Circle()
                        .fill(Color(hex: "#A78BFA").opacity(0.30))
                        .frame(width: 260).offset(x: 140, y: 60).blur(radius: 55)
                }
            case .empty:
                Color.clear
            @unknown default:
                Color.clear
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Logo mark — frosted pill
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .frame(width: 108, height: 108)
                    .shadow(color: .black.opacity(0.30), radius: 20, y: 8)

                Text("CR")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#C4B5FD"), .white],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            // App name
            VStack(spacing: 6) {
                Text("Center Rent")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                Text("Espaços para profissionais de saúde")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            }
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }

    // MARK: - Auth Buttons
    private var authButtons: some View {
        VStack(spacing: 12) {

            // ── 1. E-mail button — pixel-fiel ao Design System ────
            // Pill shape, #7F68C1, h=40, Inter Medium 16, icon envelope
            Button {
                HapticFeedback.impact(.medium)
                withAnimation(.easeInOut(duration: 0.32)) {
                    router.authScreen = .login
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope")
                        .font(.system(size: 16, weight: .regular))
                    Text("Entrar com o e-mail")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(-0.43)
                }
                .foregroundColor(Color(hex: "#F5F5F5"))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color(hex: "#7F68C1"))
                .clipShape(Capsule())
            }
            .buttonStyle(CRPressStyle())

            // ── 2. Social row ────────────────────────────────────
            HStack(spacing: 12) {
                SocialAuthRow(
                    icon: "g.circle.fill",
                    label: "Google",
                    iconColor: Color(hex: "#4285F4"),
                    action: { HapticFeedback.impact(.light) }
                )
                SocialAuthRow(
                    icon: "apple.logo",
                    label: "Apple",
                    iconColor: .white,
                    action: { HapticFeedback.impact(.light) }
                )
            }

            // ── 3. Register link ──────────────────────────────────
            Button {
                HapticFeedback.impact(.light)
                withAnimation(.easeInOut(duration: 0.32)) {
                    router.authScreen = .register
                }
            } label: {
                HStack(spacing: 5) {
                    Text("Não tem conta?")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.75))
                    Text("Cadastre-se grátis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .underline()
                }
            }

            // ── Thin divider ──────────────────────────────────────
            HStack(spacing: 8) {
                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 0.5)
                Text("ou")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.50))
                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 8)

            // ── 4. Guest login ─────────────────────────────────────
            Button {
                HapticFeedback.impact(.light)
                // Navigate directly to main app without authentication
                withAnimation(.easeInOut(duration: 0.35)) {
                    router.navigateAsGuest()
                }
            } label: {
                Text("Entrar sem logar")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .underline(color: .white.opacity(0.40))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 52)
    }

    // MARK: - Animation Sequence
    private func startAnimations() {
        // Step 1 — Logo zooms in with spring (response: 0.75, damping: 0.62)
        withAnimation(
            .spring(response: 0.75, dampingFraction: 0.62, blendDuration: 0)
            .delay(0.15)
        ) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }

        // Step 2 — Buttons slide up after logo settles (~0.85s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                buttonsVisible = true
            }
        }
    }
}

// MARK: - Social Auth Row Button
private struct SocialAuthRow: View {
    let icon: String
    let label: String
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.white.opacity(0.14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(CRPressStyle())
    }
}

// MARK: - SocialCircleButton (kept for LoginView / RegisterView compatibility)
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
        }
        .buttonStyle(CRPressStyle())
    }
}
