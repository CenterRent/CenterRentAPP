import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var showTerms = false

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CRSpacing.xl) {
                    // Header
                    HStack {
                        Button {
                            HapticFeedback.impact(.light)
                            withAnimation(.easeInOut(duration: 0.32)) {
                                router.authScreen = .login
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

                    VStack(alignment: .leading, spacing: CRSpacing.xs) {
                        Text("Criar Conta")
                            .font(.crH1).foregroundColor(.crPrimary)
                        Text("Preencha seus dados para começar")
                            .font(.crBody).foregroundColor(.crTextSecondary)
                    }

                    // Form Fields
                    VStack(spacing: CRSpacing.base) {
                        CRTextField(label: "Nome completo", placeholder: "Seu nome", text: $authVM.registrationName, icon: "person")
                        CRTextField(label: "Email", placeholder: "Seu@email.com", text: $authVM.registrationEmail, icon: "envelope", keyboardType: .emailAddress)
                        CRTextField(label: "Telefone", placeholder: "(11) 99999-9999", text: $authVM.registrationPhone, icon: "phone", keyboardType: .phonePad)

                        VStack(alignment: .leading, spacing: CRSpacing.xs) {
                            CRTextField(
                                label: "Número de registro profissional",
                                placeholder: "2038475",
                                text: $authVM.registrationProfessionalId,
                                icon: "doc.badge.checkmark"
                            )
                            Text("CRO, CRM, COREN, CREFITO, CRBM…")
                                .font(.crCaption)
                                .foregroundColor(.crTextTertiary)
                        }

                        CRTextField(label: "Senha", placeholder: "••••••••••", text: $authVM.registrationPassword, icon: "lock", isSecure: true)
                        CRTextField(label: "Confirmar Senha", placeholder: "••••••••••", text: $authVM.registrationConfirmPassword, icon: "lock", isSecure: true)
                    }

                    // Terms checkbox
                    HStack(alignment: .top, spacing: CRSpacing.sm) {
                        Button {
                            withAnimation { authVM.acceptedTerms.toggle() }
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(authVM.acceptedTerms ? Color.crPrimary : Color.crDivider, lineWidth: 2)
                                .frame(width: 22, height: 22)
                                .background(authVM.acceptedTerms ? Color.crPrimary.cornerRadius(4) : Color.clear.cornerRadius(4))
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(authVM.acceptedTerms ? 1 : 0)
                                )
                        }

                        HStack(spacing: 4) {
                            Text("Aceito os").font(.crBody).foregroundColor(.crTextSecondary)
                            Button("termos de uso") { showTerms = true }
                                .font(.crLabel).foregroundColor(.crPrimary)
                            Text("e").font(.crBody).foregroundColor(.crTextSecondary)
                            Button("política de privacidade") { showTerms = true }
                                .font(.crLabel).foregroundColor(.crPrimary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    // Error
                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.crBodySmall)
                            .foregroundColor(.crError)
                            .padding(CRSpacing.md)
                            .background(Color.crError.opacity(0.1))
                            .cornerRadius(CRRadius.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    CRButton(title: "Criar conta", isLoading: authVM.isLoading) {
                        Task { await handleRegister() }
                    }

                    Spacer().frame(height: CRSpacing.xxl)
                }
                .padding(.horizontal, CRSpacing.xl)
                .padding(.top, CRSpacing.lg)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTerms) {
            TermsView()
        }
    }

    private func handleRegister() async {
        await authVM.register()
        if authVM.isAuthenticated {
            HapticFeedback.success()
            // RootView automatically transitions to OnboardingView / MainTabView
        } else if authVM.errorMessage != nil {
            HapticFeedback.error()
        }
    }
}

struct TermsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Termos de Uso\n\nAo usar o Center Rent, você concorda com nossos termos de serviço e política de privacidade. Os dados são coletados para melhorar sua experiência e processar reservas com segurança.")
                    .font(.crBody)
                    .foregroundColor(.crTextSecondary)
                    .padding()
            }
            .navigationTitle("Termos de Uso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fechar") { dismiss() }
            }}
        }
    }
}
