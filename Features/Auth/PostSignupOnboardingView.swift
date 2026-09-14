import SwiftUI

// MARK: - Post-Signup Onboarding
// Exibido uma única vez logo após o cadastro, antes de liberar o app:
// escolher tipo de usuário (persiste em UserProfile.userType no Supabase,
// ver AuthViewModel.saveUserType) e interesses. Usuários que já vinham
// usando o app (login normal, sessão restaurada) nunca veem essa tela —
// AuthViewModel já marca onboardingComplete/userTypeDone como concluídos
// nesses dois casos (ver checkSession()/signIn()).
//
// Não usa AppRouter.navigate — é um mini state machine local, igual ao
// authFlowView de RootView, porque essas telas nunca são alcançadas de
// mais nenhum outro lugar do app.
struct PostSignupOnboardingView: View {
    private enum Step { case userType, interests, profileSetup, loading }
    @State private var step: Step = .userType

    var body: some View {
        Group {
            switch step {
            case .userType:
                UserTypeView(onSelected: { withAnimation { step = .interests } })
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            case .interests:
                InterestSelectionView(onFinished: { withAnimation { step = .profileSetup } })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .profileSetup:
                ProfileSetupView(onFinished: { withAnimation { step = .loading } })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .loading:
                SetupLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: step)
    }
}
