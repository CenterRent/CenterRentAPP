import SwiftUI
import Combine

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var pushNotifications = true
    @State private var emailNotifications = true
    @State private var marketingEmails = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            // Account
            Section("Conta") {
                NavigationLink(destination: EditProfileView()) {
                    SettingsRow(icon: "person.circle", label: "Editar perfil")
                }
                NavigationLink(destination: PhoneVerificationView(isOnboarding: false)) {
                    SettingsRow(
                        icon: "phone.badge.checkmark",
                        label: "Verificação de telefone",
                        badge: authService.currentUser?.phoneVerified == true ? nil : "Pendente"
                    )
                }
                SettingsRow(icon: "lock.circle", label: "Segurança e senha")
                SettingsRow(icon: "creditcard", label: "Pagamentos")
            }

            // Notifications
            Section("Notificações") {
                HStack {
                    SettingsRow(icon: "bell", label: "Notificações push")
                    Spacer()
                    Toggle("", isOn: $pushNotifications).tint(CRColor.Primary.default).labelsHidden()
                }
                HStack {
                    SettingsRow(icon: "envelope", label: "E-mails transacionais")
                    Spacer()
                    Toggle("", isOn: $emailNotifications).tint(CRColor.Primary.default).labelsHidden()
                }
                HStack {
                    SettingsRow(icon: "megaphone", label: "Novidades e promoções")
                    Spacer()
                    Toggle("", isOn: $marketingEmails).tint(CRColor.Primary.default).labelsHidden()
                }
            }

            // About
            Section("Sobre") {
                Button(action: {}) {
                    SettingsRow(icon: "doc.text", label: "Termos de Uso")
                }
                Button(action: {}) {
                    SettingsRow(icon: "hand.raised", label: "Política de Privacidade")
                }
                Button(action: {}) {
                    SettingsRow(icon: "questionmark.circle", label: "Central de Ajuda")
                }
                HStack {
                    SettingsRow(icon: "info.circle", label: "Versão do app")
                    Spacer()
                    Text("1.0.0 (MVP)").font(.crBodySM).foregroundColor(CRColor.Text.tertiary)
                }
            }

            // Danger
            Section {
                Button(action: { showDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash").foregroundColor(CRColor.Feedback.error)
                        Text("Excluir minha conta").foregroundColor(CRColor.Feedback.error)
                    }
                    .font(.crLabelMD)
                }
            }
        }
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.large)
        .alert("Excluir conta?", isPresented: $showDeleteAlert) {
            Button("Excluir", role: .destructive) {
                Task { try? await authService.deleteAccount() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Todos os seus dados serão removidos permanentemente. Esta ação não pode ser desfeita.")
        }
    }
}

private struct SettingsRow: View {
    let icon: String; let label: String; var badge: String? = nil

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: CRSize.iconMD))
                .foregroundColor(CRColor.Icon.accent)
                .frame(width: 24)
            Text(label).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
            Spacer()
            if let badge {
                Text(badge).font(.crCaptionSM).foregroundColor(CRColor.Feedback.warning)
                    .padding(.horizontal, CRSpacing.s2).padding(.vertical, 2)
                    .background(CRColor.Feedback.warningLight).cornerRadius(CRRadius.xs)
            }
        }
    }
}
