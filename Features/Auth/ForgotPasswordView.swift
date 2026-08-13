import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var router: AppRouter
    @State private var email = ""
    @State private var isSent = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(title: "Recuperar senha", onBack: { router.goBack() })

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
                    CRButton(title: "Enviar link de recuperação", isLoading: isLoading) {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isLoading = false; isSent = true
                        }
                    }
                } else {
                    CRButton(title: "Voltar para o login") { router.popToRoot() }
                }
                Spacer()
            }
            .padding(.horizontal, CRSpacing.xl)
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }
}
