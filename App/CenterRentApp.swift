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
            if authVM.isAuthenticated || router.isGuest {
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
}
