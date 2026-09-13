import SwiftUI

// MARK: - Root View
// ┌─────────────────────────────────────────────────────────────┐
// │  FLUXO CORRETO:                                             │
// │                                                             │
// │  1ª vez no app                                              │
// │    OnboardingFlowView (slides marketing) → SplashView       │
// │                                            → Login/Cadastro │
// │                                                             │
// │  Já autenticado                                             │
// │    → MainTabView  (direto, sem onboarding de volta)         │
// │                                                             │
// │  Visitante (guest)                                          │
// │    → MainTabView  (acesso limitado)                         │
// └─────────────────────────────────────────────────────────────┘
struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter

    /// Persiste se o usuário já viu os slides de onboarding.
    /// true = já viu → pula direto para auth/app na próxima abertura.
    @AppStorage("cr_has_seen_onboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            if router.isPasswordRecovery {
                // Prioridade máxima: usuário veio do link de "esqueci minha senha".
                // A sessão de recuperação pode deixar authVM.isAuthenticated=true,
                // mas ele precisa definir a nova senha antes de entrar no app.
                NewPasswordView()
                    .transition(.opacity)

            } else if authVM.isAuthenticated || router.isGuest {
                // ── Autenticado ou visitante → app direto ──────────
                MainTabView()
                    .transition(.opacity)

            } else if !hasSeenOnboarding {
                // ── Primeira abertura → slides de apresentação ─────
                OnboardingFlowView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)

            } else {
                // ── Auth flow (splash → login / cadastro) ──────────
                authFlowView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.35), value: router.isGuest)
    }

    // MARK: - Auth flow (state machine)
    @ViewBuilder
    private var authFlowView: some View {
        ZStack {
            switch router.authScreen {
            case .splash:
                SplashView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            case .login:
                LoginView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .register:
                RegisterView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            case .forgotPassword:
                ForgotPasswordView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.32), value: router.authScreen)
    }
}

@main
struct CenterRentApp: App {
    @StateObject private var authVM  = AuthViewModel()
    @StateObject private var router  = AppRouter()
    private let authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(authService)
                .environmentObject(router)
                .preferredColorScheme(.light)
                .onAppear {
                    setupAppearance()
                    authVM.checkSession()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func setupAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .white
        navAppearance.shadowColor = nil
        navAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor(Color.crTextPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab bar — rendered natively by iOS 26 Tab API with Liquid Glass.
        // Do NOT hide it; the system manages the floating glass appearance.
    }

    // MARK: - Deep Links
    // centerrent://reset-password#access_token=...&type=recovery&refresh_token=...
    //   → link do e-mail de "esqueci minha senha" (Supabase Auth)
    // centerrent://listing/ID, centerrent://booking/ID, etc.
    //   → repassados pra AppRouter.handleDeepLink (busca/reserva/chat/indicação)
    private func handleIncomingURL(_ url: URL) {
        let isRecovery = url.host == "reset-password"
            || (url.fragment ?? "").contains("type=recovery")

        if isRecovery {
            Task {
                do {
                    try await authService.establishRecoverySession(from: url)
                    await MainActor.run { router.isPasswordRecovery = true }
                } catch {
                    // Link expirado/inválido — manda pro login normal em vez de travar.
                    await MainActor.run { router.authScreen = .login }
                }
            }
            return
        }

        router.handleDeepLink(url)
    }
}
