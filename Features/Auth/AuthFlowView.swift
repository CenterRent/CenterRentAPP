import SwiftUI
import AuthenticationServices

// MARK: - Auth Flow (Login / Cadastro)
struct AuthFlowView: View {
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    @EnvironmentObject var authService: AuthService

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ScrollView {
            VStack(spacing: CRSpacing.s8) {
                // Header
                VStack(spacing: CRSpacing.s2) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(CRColor.Primary.default)
                    Text(mode == .signIn ? "Bem-vindo de volta" : "Criar conta")
                        .font(.crHeading2)
                        .foregroundColor(CRColor.Text.primary)
                    Text(mode == .signIn
                         ? "Entre para encontrar espaços odontológicos"
                         : "Comece a alugar ou anunciar em minutos")
                        .font(.crBodyBase)
                        .foregroundColor(CRColor.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CRSpacing.s8)
                }
                .padding(.top, CRSpacing.s12)

                // Social Auth
                VStack(spacing: CRSpacing.s3) {
                    SocialAuthButton(
                        icon: "globe",
                        label: mode == .signIn ? "Entrar com Google" : "Cadastrar com Google",
                        backgroundColor: CRColor.Surface.primary,
                        textColor: CRColor.Text.primary,
                        borderColor: CRColor.Border.default
                    ) { Task { await signInWithGoogle() } }

                    SignInWithAppleButton(
                        mode == .signIn ? .signIn : .signUp,
                        onRequest: { req in req.requestedScopes = [.fullName, .email] },
                        onCompletion: { result in Task { await handleAppleSignIn(result) } }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: CRSize.buttonLG)
                    .cornerRadius(CRRadius.button)
                }

                // Divider
                HStack {
                    Rectangle().fill(CRColor.Border.default).frame(height: 1)
                    Text("ou").font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
                        .padding(.horizontal, CRSpacing.s3)
                    Rectangle().fill(CRColor.Border.default).frame(height: 1)
                }

                // Email Form
                VStack(spacing: CRSpacing.s4) {
                    CRTextField("E-mail", text: $email,
                                placeholder: "seu@email.com",
                                isRequired: true,
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                leadingIcon: "envelope")

                    CRSecureTextField("Senha", text: $password,
                                     isRequired: true)

                    if mode == .signUp {
                        CRSecureTextField("Confirmar senha", text: $confirmPassword,
                                         isRequired: true)
                    }

                    if mode == .signIn {
                        HStack {
                            Spacer()
                            Button(action: { Task { await requestPasswordReset() } }) {
                                Text("Esqueci minha senha")
                                    .font(.crLabelSM)
                                    .foregroundColor(CRColor.Text.link)
                            }
                        }
                    }
                }

                // Error
                if let error = errorMessage {
                    HStack(spacing: CRSpacing.s2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(CRColor.Feedback.error)
                        Text(error)
                            .font(.crBodySM)
                            .foregroundColor(CRColor.Feedback.error)
                        Spacer()
                    }
                    .padding(CRSpacing.s3)
                    .background(CRColor.Feedback.errorLight)
                    .cornerRadius(CRRadius.sm)
                }

                // CTA
                CRButton(
                    mode == .signIn ? "Entrar" : "Criar conta",
                    variant: .primary,
                    size: .lg,
                    isLoading: isLoading,
                    isFullWidth: true
                ) { Task { await handleEmailAuth() } }

                // Mode switch
                HStack(spacing: CRSpacing.s1) {
                    Text(mode == .signIn ? "Não tem conta?" : "Já tem conta?")
                        .font(.crBodyBase)
                        .foregroundColor(CRColor.Text.secondary)
                    Button(action: {
                        withAnimation(CRAnimation.easeNormal) {
                            mode = mode == .signIn ? .signUp : .signIn
                            errorMessage = nil
                        }
                    }) {
                        Text(mode == .signIn ? "Criar conta" : "Entrar")
                            .font(.crLabelMD)
                            .foregroundColor(CRColor.Text.link)
                    }
                }

                // Terms
                if mode == .signUp {
                    Text("Ao criar sua conta você concorda com os Termos de Uso e Política de Privacidade do Center Rent.")
                        .font(.crCaptionMD)
                        .foregroundColor(CRColor.Text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, CRSpacing.s4)
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
            .padding(.bottom, CRSpacing.s10)
        }
        .background(CRColor.Background.primary.ignoresSafeArea())
    }

    // MARK: - Actions
    private func handleEmailAuth() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        if mode == .signUp && password != confirmPassword {
            errorMessage = "As senhas não coincidem."
            HapticFeedback.error()
            return
        }

        do {
            if mode == .signIn {
                _ = try await authService.signInWithEmail(email: email, password: password)
            } else {
                _ = try await authService.signUpWithEmail(email: email, password: password)
            }
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }

    private func signInWithGoogle() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await authService.signInWithGoogle()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success:
            isLoading = true
            defer { isLoading = false }
            do {
                _ = try await authService.signInWithApple()
                HapticFeedback.success()
            } catch { errorMessage = error.localizedDescription }
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }

    private func requestPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Informe seu e-mail para redefinir a senha."
            return
        }
        do {
            try await authService.resetPassword(email: email)
            errorMessage = nil
            // Show success alert
        } catch { errorMessage = error.localizedDescription }
    }
}

// MARK: - Social Auth Button
private struct SocialAuthButton: View {
    let icon: String
    let label: String
    let backgroundColor: Color
    let textColor: Color
    let borderColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.s3) {
                Image(systemName: icon)
                    .font(.system(size: CRSize.iconMD, weight: .medium))
                Text(label).font(.crButtonMD)
                Spacer()
            }
            .foregroundColor(textColor)
            .padding(.horizontal, CRSpacing.s6)
            .frame(height: CRSize.buttonLG)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(CRRadius.button)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.button).stroke(borderColor, lineWidth: CRBorder.thin))
        }
    }
}
