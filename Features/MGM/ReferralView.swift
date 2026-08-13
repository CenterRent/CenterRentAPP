import SwiftUI

struct ReferralView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showCopied = false
    @State private var showCelebration = false
    @State private var invites: [ReferralInvite] = ReferralInvite.mocks

    private var referralLink: String {
        "https://app.com/centerrent\(authVM.currentUser?.id.prefix(6) ?? "27zxU")"
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: CRSpacing.xxl) {
                    // Header
                    CRNavigationHeader(title: "Indicar amigos", onBack: { router.goBack() })

                    // Hero illustration
                    VStack(spacing: CRSpacing.xl) {
                        ZStack {
                            Circle().fill(Color.crPrimary.opacity(0.1)).frame(width: 160, height: 160)
                            Image(systemName: "gift.fill")
                                .font(.system(size: 72)).foregroundColor(.crPrimary)
                        }

                        VStack(spacing: CRSpacing.sm) {
                            Text("Ganhe recompensas\npor indicação")
                                .font(.crH2).foregroundColor(.crPrimary)
                                .multilineTextAlignment(.center)
                            Text("A cada amigo que se cadastrar e fizer a primeira reserva usando seu link, você ganha 25 pontos.")
                                .font(.crBody).foregroundColor(.crTextSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Steps
                        HStack(spacing: CRSpacing.md) {
                            ReferralStepCard(number: "1", text: "Compartilhe seu link", color: .crPrimary)
                            ReferralStepCard(number: "2", text: "Amigo se cadastra", color: .crAccentOrange)
                            ReferralStepCard(number: "3", text: "Você ganha pontos!", color: .crSuccess)
                        }
                    }
                    .padding(.horizontal, CRSpacing.base)

                    // Your code
                    VStack(alignment: .leading, spacing: CRSpacing.sm) {
                        Text("Seu código").font(.crH4).foregroundColor(.crTextPrimary)

                        HStack {
                            Text(referralLink)
                                .font(.crBody).foregroundColor(.crPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = referralLink
                                withAnimation { showCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showCopied = false }
                                }
                            } label: {
                                Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 20))
                                    .foregroundColor(showCopied ? .crSuccess : .crPrimary)
                            }
                        }
                        .padding(CRSpacing.base)
                        .background(Color.crPrimary.opacity(0.06))
                        .cornerRadius(CRRadius.md)
                        .overlay(RoundedRectangle(cornerRadius: CRRadius.md).stroke(Color.crPrimary.opacity(0.2), lineWidth: 1))

                        CRButton(title: "Compartilhar link", icon: "square.and.arrow.up") {
                            shareLink()
                        }
                    }
                    .padding(.horizontal, CRSpacing.base)

                    // Invite list
                    VStack(alignment: .leading, spacing: CRSpacing.md) {
                        HStack {
                            Text("Convide um amigo")
                                .font(.crH4).foregroundColor(.crTextPrimary)
                            Spacer()
                            Button { } label: {
                                Image(systemName: "magnifyingglass").foregroundColor(.crPrimary)
                            }
                        }

                        ForEach(invites) { invite in
                            ReferralInviteRow(invite: invite) {
                                withAnimation { showCelebration = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { showCelebration = false }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CRSpacing.base)
                    .padding(.bottom, CRSpacing.xxxl)
                }
            }
            .background(Color.crBackground)
            .navigationBarHidden(true)

            // Celebration overlay
            if showCelebration {
                CelebrationOverlay { showCelebration = false }
            }
        }
    }

    private func shareLink() {
        let av = UIActivityViewController(activityItems: [referralLink], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let vc = scene.windows.first?.rootViewController {
            vc.present(av, animated: true)
        }
    }
}

struct ReferralStepCard: View {
    let number: String
    let text: String
    let color: Color

    var body: some View {
        VStack(spacing: CRSpacing.sm) {
            Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                .overlay(Text(number).font(.crH3).foregroundColor(color))
            Text(text)
                .font(.crCaption).foregroundColor(.crTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(CRSpacing.sm)
        .background(Color.white)
        .cornerRadius(CRRadius.md)
        .crShadowSoft()
    }
}

struct ReferralInviteRow: View {
    let invite: ReferralInvite
    let onInvite: () -> Void

    var body: some View {
        HStack(spacing: CRSpacing.md) {
            Circle().fill(Color.crPrimary.opacity(0.15)).frame(width: 44, height: 44)
                .overlay(Text(String(invite.name.prefix(2))).font(.crLabel).foregroundColor(.crPrimary))

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.name).font(.crLabel).foregroundColor(.crTextPrimary)
                Text(invite.source).font(.crCaption).foregroundColor(.crTextTertiary)
            }
            Spacer()

            if invite.status == .accepted {
                HStack(spacing: 4) {
                    Text("+25").font(.crLabel).foregroundColor(.crSuccess)
                    Text("Aceito").font(.crCaption).foregroundColor(.crTextTertiary)
                }
            } else {
                Button(action: onInvite) {
                    Text("Convidar")
                        .font(.crLabel).foregroundColor(.crPrimary)
                        .padding(.horizontal, CRSpacing.md).padding(.vertical, CRSpacing.xs)
                        .background(Color.crPrimary.opacity(0.1)).cornerRadius(CRRadius.pill)
                }
            }
        }
    }
}

struct CelebrationOverlay: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        Color.black.opacity(0.4).ignoresSafeArea()
            .overlay(
                VStack(spacing: CRSpacing.xl) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 64)).foregroundColor(.crWarning)
                        .scaleEffect(appeared ? 1.0 : 0.5)
                    VStack(spacing: CRSpacing.sm) {
                        Text("Parabéns! Você\nganhou 25 pontos")
                            .font(.crH2).foregroundColor(.white).multilineTextAlignment(.center)
                    }
                    CRButton(title: "Convide outro amigo") { onDismiss() }
                        .padding(.horizontal, CRSpacing.xl)
                }
                .padding(CRSpacing.xxl)
                .background(Color.crPrimary).cornerRadius(CRRadius.xl2)
                .padding(.horizontal, CRSpacing.xl)
                .scaleEffect(appeared ? 1.0 : 0.8)
            )
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appeared = true }
            }
    }
}

// MARK: - Models
struct ReferralInvite: Identifiable {
    let id: String
    let name: String
    let source: String
    var status: ReferralStatus

    enum ReferralStatus { case pending, accepted }

    static let mocks: [ReferralInvite] = [
        ReferralInvite(id: "1", name: "Maria Silva", source: "Facebook", status: .pending),
        ReferralInvite(id: "2", name: "João Costa", source: "Facebook", status: .pending),
        ReferralInvite(id: "3", name: "Ana Rocha", source: "Facebook", status: .accepted),
        ReferralInvite(id: "4", name: "Pedro Alves", source: "Facebook", status: .accepted),
        ReferralInvite(id: "5", name: "Carla Lima", source: "WhatsApp", status: .accepted),
    ]
}
