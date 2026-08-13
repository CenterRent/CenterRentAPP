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
            // Background
            Color.crBackground.ignoresSafeArea()

            // Decorative blobs
            GeometryReader { geo in
                Circle()
                    .fill(Color.crPrimary.opacity(0.10))
                    .frame(width: 240)
                    .offset(x: geo.size.width - 80, y: -60)
                    .blur(radius: 55)
                Circle()
                    .fill(Color(hex: "#A78BFA").opacity(0.12))
                    .frame(width: 180)
                    .offset(x: -40, y: geo.size.height * 0.45)
                    .blur(radius: 45)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Back button ────────────────────────────────────
                HStack {
                    Button {
                        HapticFeedback.impact(.light)
                        withAnimation(.easeInOut(duration: 0.32)) {
                            router.authScreen = .splash
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Voltar")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.crPrimary)
                        .padding(8)
                        .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: CRSpacing.xl) {
                        Spacer().frame(height: CRSpacing.lg)

                        // ── Header ─────────────────────────────────
                        VStack(spacing: CRSpacing.sm) {
                            // Mini logo
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.crPrimary.opacity(0.10))
                                    .frame(width: 60, height: 60)
                                Text("CR")
                                    .font(.system(size: 26, weight: .black, design: .rounded))
                                    .foregroundColor(.crPrimary)
                            }
                            .padding(.bottom, 4)

                            Text("Acesse sua conta")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.crPrimary)
                            Text("Bem-vindo de volta!")
                                .font(.crBody)
                                .foregroundColor(.crTextSecondary)
                        }

                        Spacer().frame(height: 4)

                        // ── Form ───────────────────────────────────
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

                        // ── Auth error banner ──────────────────────
                        if let error = authVM.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.crError)
                                Text(error)
                                    .font(.crBodySmall)
                                    .foregroundColor(.crError)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(CRSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.crError.opacity(0.08))
                            .cornerRadius(CRRadius.sm)
                        }

                        // ── Login button ───────────────────────────
                        CRButton(title: "Entrar", isLoading: authVM.isLoading) {
                            Task { await handleLogin() }
                        }

                        // ── Forgot password ────────────────────────
                        Button("Esqueceu a senha?") {
                            HapticFeedback.impact(.light)
                        }
                        .font(.crLabel)
                        .foregroundColor(.crPrimary)

                        // ── Divider ────────────────────────────────
                        HStack {
                            Rectangle().fill(Color.crDivider).frame(height: 1)
                            Text("OU").font(.crCaption).foregroundColor(.crTextTertiary).fixedSize()
                            Rectangle().fill(Color.crDivider).frame(height: 1)
                        }

                        // ── Social buttons ─────────────────────────
                        HStack(spacing: CRSpacing.xl) {
                            SocialCircleButton(
                                icon: "g.circle.fill",
                                bgColor: Color(hex: "#4285F4")
                            ) { HapticFeedback.impact(.light) }

                            SocialCircleButton(
                                icon: "apple.logo",
                                bgColor: .black
                            ) { HapticFeedback.impact(.light) }
                        }

                        Spacer().frame(height: CRSpacing.xl)

                        // ── Register link ──────────────────────────
                        HStack(spacing: 4) {
                            Text("Não tem uma conta?")
                                .font(.crBody)
                                .foregroundColor(.crTextSecondary)
                            Button("Cadastre-se") {
                                HapticFeedback.impact(.light)
                                withAnimation(.easeInOut(duration: 0.32)) {
                                    router.authScreen = .register
                                }
                            }
                            .font(.crLabel)
                            .foregroundColor(.crPrimary)
                        }

                        Spacer().frame(height: CRSpacing.xxxl)
                    }
                    .padding(.horizontal, CRSpacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { authVM.errorMessage = nil }
    }

    // MARK: - Login Handler
    private func handleLogin() async {
        emailError = nil
        passwordError = nil

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            emailError = "Informe seu email"
            HapticFeedback.error()
            return
        }
        guard !password.isEmpty else {
            passwordError = "Informe sua senha"
            HapticFeedback.error()
            return
        }

        await authVM.signIn(email: email.trimmingCharacters(in: .whitespaces),
                            password: password)

        if authVM.isAuthenticated {
            HapticFeedback.success()
            // RootView automatically transitions to MainTabView / OnboardingView
        } else if authVM.errorMessage != nil {
            HapticFeedback.error()
        }
    }
}
