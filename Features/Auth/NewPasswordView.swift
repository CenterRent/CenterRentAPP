import SwiftUI

// MARK: - New Password View
// Mostrada quando o usuário toca no link de "esqueci minha senha" recebido
// por e-mail (App/CenterRentApp.swift converte o deep link numa sessão de
// recuperação e liga router.isPasswordRecovery). Depois de trocar a senha,
// a gente desloga de propósito e manda pro login — evita ambiguidade sobre
// se a sessão de recuperação conta como login "de verdade".
struct NewPasswordView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    private var canSubmit: Bool {
        password.count >= 8 && password == confirmPassword
    }

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Nova senha", onBack: nil)

            VStack(spacing: CRSpacing.xxl) {
                Spacer()

                Image(systemName: didSucceed ? "checkmark.circle.fill" : "lock.rotation")
                    .font(.system(size: 72))
                    .foregroundColor(didSucceed ? .crSuccess : .crPrimary)

                VStack(spacing: CRSpacing.sm) {
                    Text(didSucceed ? "Senha alterada!" : "Defina sua nova senha")
                        .font(.crH2).foregroundColor(.crPrimary)
                    Text(didSucceed
                         ? "Faça login novamente com sua nova senha."
                         : "Escolha uma senha com pelo menos 8 caracteres.")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                        .multilineTextAlignment(.center)
                }

                if didSucceed {
                    CRButton(title: "Ir para o login") {
                        router.isPasswordRecovery = false
                        router.authScreen = .login
                    }
                } else {
                    VStack(spacing: CRSpacing.md) {
                        CRTextField(label: "Nova senha", placeholder: "••••••••",
                                    text: $password, icon: "lock", isSecure: true)
                        CRTextField(label: "Confirmar senha", placeholder: "••••••••",
                                    text: $confirmPassword, icon: "lock", isSecure: true)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.crCaptionSM).foregroundColor(.crError)
                                .multilineTextAlignment(.center)
                        } else if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("As senhas não coincidem.")
                                .font(.crCaptionSM).foregroundColor(.crError)
                        }
                    }

                    CRButton(title: "Salvar nova senha", isLoading: isLoading) {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit || isLoading)
                    .opacity(canSubmit ? 1 : 0.5)
                }

                Spacer()
            }
            .padding(.horizontal, CRSpacing.xl)
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }

    private func submit() async {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.updatePassword(password)
            try? await authService.signOut()
            HapticFeedback.success()
            withAnimation { didSucceed = true }
        } catch {
            errorMessage = "Não foi possível salvar a nova senha. O link pode ter expirado — solicite um novo."
            HapticFeedback.error()
        }
    }
}
