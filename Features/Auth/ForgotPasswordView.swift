import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var isSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Recuperar senha", onBack: { router.authScreen = .login })

            VStack(spacing: CRSpacing.xxl) {
                Spacer()
                Image(systemName: isSent ? "envelope.badge.checkmark" : "lock.rotation")
                    .font(.system(size: 72)).foregroundColor(.crPrimary)

                VStack(spacing: CRSpacing.sm) {
                    Text(isSent ? "Email enviado!" : "Esqueceu a senha?")
                        .font(.crH2).foregroundColor(.crPrimary)
                    Text(isSent
                         ? "Verifique sua caixa de entrada em \(email) e siga as instruções."
                         : "Digite seu email e enviaremos um link para redefinir sua senha.")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                        .multilineTextAlignment(.center)
                }

                if !isSent {
                    CRTextField(label: "Email", placeholder: "seu@email.com", text: $email, icon: "envelope", keyboardType: .emailAddress)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.crCaptionSM).foregroundColor(.crError)
                            .multilineTextAlignment(.center)
                    }

                    CRButton(title: "Enviar link de recuperação", isLoading: isLoading) {
                        Task { await sendResetLink() }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity(email.isEmpty ? 0.5 : 1)
                } else {
                    CRButton(title: "Voltar para o login") { router.authScreen = .login }
                }
                Spacer()
            }
            .padding(.horizontal, CRSpacing.xl)
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }

    private func sendResetLink() async {
        guard !email.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.resetPassword(email: email)
            HapticFeedback.success()
            withAnimation { isSent = true }
        } catch {
            // Supabase não confirma se o e-mail existe (evita enumeração de contas),
            // então na prática esse catch é sobretudo erro de rede/rate limit.
            errorMessage = "Não foi possível enviar o link agora. Tente novamente em instantes."
            HapticFeedback.error()
        }
    }
}
