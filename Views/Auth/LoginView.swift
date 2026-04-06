import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter

    @State private var email = ""
    @State private var password = ""
    @State private var emailError: String?
    @State private var passwordError: String?

    var body: some View {
        ZStack {
            // Background limpo — sem faixa verde (BUG 3)
            Color.crBackground.ignoresSafeArea()

            // Formas decorativas sutis (sem as faixas coloridas)
            GeometryReader { geo in
                Circle().fill(Color.crPrimary.opacity(0.18))
                    .frame(width: 220).offset(x: geo.size.width - 70, y: -60).blur(radius: 50)
                Circle().fill(Color.crAccentOrange.opacity(0.25))
                    .frame(width: 160).offset(x: -50, y: 80).blur(radius: 40)
                Circle().fill(Color.crSecondary.opacity(0.15))
                    .frame(width: 180).offset(x: geo.size.width * 0.3, y: -30).blur(radius: 45)
            }.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header com botão voltar (BUG 2)
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Voltar")
                                .font(.crBody)
                        }
                        .foregroundColor(.crPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal, CRSpacing.xl)
                .padding(.top, CRSpacing.lg)

                ScrollView {
                    VStack(spacing: CRSpacing.xl) {
                        Spacer().frame(height: CRSpacing.lg)

                        // Header
                        VStack(spacing: CRSpacing.sm) {
                            Text("Acesse sua conta")
                                .font(.crH1)
                                .foregroundColor(.crPrimary)
                            Text("Faça login agora mesmo")
                                .font(.crBody)
                                .foregroundColor(.crTextSecondary)
                        }

                        Spacer().frame(height: CRSpacing.lg)

                        // Form
                        VStack(spacing: CRSpacing.base) {
                            CRTextField(
                                label: "Email",
                                placeholder: "seu@email.com",
                                text: $email,
                                icon: "envelope",
                                keyboardType: .emailAddress,
                                errorMessage: emailError
                            )
                            CRTextField(
                                label: "Senha",
                                placeholder: "••••••••",
                                text: $password,
                                icon: "lock",
                                isSecure: true,
                                errorMessage: passwordError
                            )
                        }

                        // Error
                        if let error = authVM.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error)
                            }
                            .font(.crBodySmall)
                            .foregroundColor(.crError)
                            .padding(CRSpacing.md)
                            .background(Color.crError.opacity(0.1))
                            .cornerRadius(CRRadius.sm)
                        }

                        // Login button
                        CRButton(title: "Entrar", isLoading: authVM.isLoading) {
                            Task { await handleLogin() }
                        }

                        // Divider
                        HStack {
                            Rectangle().fill(Color.crDivider).frame(height: 1)
                            Text("OU CONTINUE COM")
                                .font(.crCaption).foregroundColor(.crTextTertiary)
                                .fixedSize()
                            Rectangle().fill(Color.crDivider).frame(height: 1)
                        }

                        // Social
                        HStack(spacing: CRSpacing.xl) {
                            SocialCircleButton(icon: "g.circle.fill", bgColor: Color(hex: "#4285F4")) {}
                            SocialCircleButton(icon: "apple.logo", bgColor: .black) {}
                            SocialCircleButton(icon: "f.circle.fill", bgColor: Color(hex: "#1877F2")) {}
                        }

                        Button("Esqueceu a senha?") { router.push(.forgotPassword) }
                            .font(.crLabel)
                            .foregroundColor(.crPrimary)

                        Spacer().frame(height: CRSpacing.xxl)

                        HStack(spacing: 4) {
                            Text("Não tem uma conta?").font(.crBody).foregroundColor(.crTextSecondary)
                            Button("Cadastre-se") { router.push(.register) }
                                .font(.crLabel).foregroundColor(.crPrimary)
                        }
                    }
                    .padding(.horizontal, CRSpacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func handleLogin() async {
        emailError = nil; passwordError = nil
        guard !email.isEmpty else { emailError = "Informe seu email"; return }
        guard !password.isEmpty else { passwordError = "Informe sua senha"; return }
        await authVM.signIn(email: email, password: password)
        if authVM.isAuthenticated {
            if authVM.onboardingComplete || authVM.userTypeDone {
                // Onboarding já feito — vai direto para o app (sessão persistida)
                router.setRoot(.main)
            } else {
                // Primeira vez — pergunta tipo de uso
                router.push(.userType)
            }
        }
    }
}
