import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var showSignOutAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero header
                ProfileHeaderView(profile: vm.profile)

                // Stats bar
                if let profile = vm.profile {
                    ProfileStatsBar(profile: profile)
                        .padding(.horizontal, CRSpacing.base)
                        .padding(.top, CRSpacing.base)
                }

                // Action buttons
                HStack(spacing: CRSpacing.md) {
                    if vm.isOwnerOrBoth {
                        CRButton(title: "Anunciar", icon: "plus", size: .medium) {
                            router.push(.createListing)
                        }
                    }
                    CRButton(title: "Editar perfil", variant: .outline, size: .medium) {
                        router.push(.editProfile)
                    }
                }
                .padding(.horizontal, CRSpacing.base)
                .padding(.top, CRSpacing.md)

                // Menu sections
                VStack(spacing: CRSpacing.xl) {
                    ProfileSection(title: "Minha conta") {
                        ProfileRow(icon: "person.fill", label: "Dados pessoais", subtitle: "Nome, CPF, Telefone") { router.push(.editProfile) }
                        ProfileRow(icon: "doc.fill", label: "Documentos", subtitle: "CRO/CRM, Comprovante") {}
                        ProfileRow(icon: "mappin.circle.fill", label: "Endereços", subtitle: "Locais de entrega e retirada") {}
                        ProfileRow(icon: "creditcard.fill", label: "Pagamentos", subtitle: "Cartões e chaves PIX", isLast: true) {}
                    }

                    if vm.isOwnerOrBoth {
                        ProfileSection(title: "Anúncios") {
                            ProfileRow(icon: "list.bullet.rectangle.fill", label: "Meus Anúncios", subtitle: "CRO/CRM, Comprovante") { router.push(.myListings) }
                            ProfileRow(icon: "doc.text.fill", label: "Resumo", subtitle: "Nome, CPF, Telefone", isLast: true) {}
                        }
                    }

                    ProfileSection(title: "Configurações") {
                        ProfileRow(icon: "bell.fill", label: "Notificações", subtitle: "Nome, CPF, Telefone") {}
                        ProfileRow(icon: "slider.horizontal.3", label: "Preferências", subtitle: "CRO/CRM, Comprovante", isLast: true) {}
                    }

                    ProfileSection(title: "Suporte") {
                        ProfileRow(icon: "questionmark.circle.fill", label: "Ajuda e FAQ", subtitle: "Nome, CPF, Telefone") {}
                        ProfileRow(icon: "shield.checkered", label: "Termos de uso", subtitle: "CRO/CRM, Comprovante", isLast: true) {}
                    }

                    // Referral card
                    ReferralBannerCard { router.push(.referral) }
                        .padding(.horizontal, CRSpacing.base)

                    // Sign out
                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack(spacing: CRSpacing.sm) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.crError)
                            Text("SAIR DA CONTA")
                                .font(.crLabel).foregroundColor(.crError)
                        }
                        .padding(.vertical, CRSpacing.md)
                    }
                    .buttonStyle(.plain)

                    Text("Versão 1.0.0 · Build 2026")
                        .font(.crCaption).foregroundColor(.crTextTertiary)
                        .padding(.bottom, CRSpacing.xxxl)
                }
                .padding(.top, CRSpacing.xl)
            }
        }
        .background(Color.crBackground)
        .alert("Sair da conta", isPresented: $showSignOutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Sair", role: .destructive) {
                Task { await authVM.signOut() }
            }
        } message: {
            Text("Tem certeza que deseja sair?")
        }
        .task {
            if let userId = authVM.currentUser?.id {
                await vm.loadProfile(userId: userId)
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let profile: UserProfile?
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color.crPrimary.opacity(0.15), Color.crSecondary.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .ignoresSafeArea(edges: .top)

            // Avatar
            VStack(spacing: CRSpacing.sm) {
                ZStack(alignment: .bottomTrailing) {
                    if let url = profile?.avatarURL, let imgUrl = URL(string: url) {
                        AsyncImage(url: imgUrl) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            avatarPlaceholder
                        }
                        .frame(width: 90, height: 90).clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    } else {
                        avatarPlaceholder
                    }

                    if profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22)).foregroundColor(.crPrimary)
                            .background(Color.white.clipShape(Circle()))
                    }
                }

                VStack(spacing: 4) {
                    Text(profile?.fullName ?? "Profissional")
                        .font(.crH3).foregroundColor(.crTextPrimary)
                    HStack(spacing: 6) {
                        if profile?.isVerified == true {
                            Text("Profissional verificado")
                                .font(.crLabelSmall).foregroundColor(.crPrimary)
                            Circle().fill(Color.crTextTertiary).frame(width: 4, height: 4)
                        }
                        if let pid = profile?.professionalId {
                            Text(pid).font(.crLabelSmall).foregroundColor(.crTextTertiary)
                        }
                    }
                }
                .padding(.bottom, CRSpacing.base)
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Color.crPrimary.opacity(0.2))
            .frame(width: 90, height: 90)
            .overlay(
                Text(String(profile?.fullName.prefix(1) ?? "P"))
                    .font(.crDisplay2).foregroundColor(.crPrimary)
            )
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
    }
}

// MARK: - Stats Bar
struct ProfileStatsBar: View {
    let profile: UserProfile
    var body: some View {
        HStack {
            StatCard(value: "\(profile.totalRentals)", label: "Aluguéis", icon: "house.fill")
            Divider().frame(height: 40)
            StatCard(value: String(format: "%.1f", profile.rating), label: "Avaliação", icon: "star.fill")
            Divider().frame(height: 40)
            StatCard(value: "R$\(String(format: "%.1f", profile.totalEarnings / 1000))k", label: "Ganhos", icon: "brazilianrealsign")
        }
        .padding(CRSpacing.md)
        .background(Color.white)
        .cornerRadius(CRRadius.lg)
        .crShadowSoft()
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(.crPrimary)
                Text(value).font(.crH3).foregroundColor(.crTextPrimary)
            }
            Text(label).font(.crCaption).foregroundColor(.crTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Section
struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Text(title)
                .font(.crLabelSmall).foregroundColor(.crTextTertiary)
                .padding(.horizontal, CRSpacing.base)
                .padding(.horizontal, CRSpacing.base)

            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(CRRadius.lg)
            .crShadowSoft()
            .padding(.horizontal, CRSpacing.base)
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let subtitle: String
    var isLast: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.crPrimary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.crBody).foregroundColor(.crTextPrimary)
                    Text(subtitle).font(.crCaption).foregroundColor(.crTextTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13)).foregroundColor(.crTextTertiary)
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
            .overlay(
                isLast ? nil : Divider().padding(.leading, 60),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Referral Banner
struct ReferralBannerCard: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.md) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.crPrimary)
                    .frame(width: 60, height: 60)
                    .background(Color.crPrimary.opacity(0.1))
                    .cornerRadius(CRRadius.md)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ganhe recompensas!")
                        .font(.crLabel).foregroundColor(.crTextPrimary)
                    Text("Indique amigos e ganhe pontos\na cada reserva feita.")
                        .font(.crBodySmall).foregroundColor(.crTextSecondary)
                        .lineSpacing(3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.crTextTertiary)
            }
            .padding(CRSpacing.md)
            .background(Color.white)
            .cornerRadius(CRRadius.lg)
            .crShadowSoft()
        }
        .buttonStyle(CRPressStyle())
    }
}

// MARK: - Navigation Header Reusable
struct CRNavigationHeader: View {
    let title: String
    var onBack: (() -> Void)? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            if let back = onBack {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.crTextPrimary)
                }
            }
            Spacer()
            Text(title).font(.crH4).foregroundColor(.crTextPrimary)
            Spacer()
            if let trailing = trailing {
                trailing
            } else if onBack != nil {
                Image(systemName: "chevron.left").opacity(0)
            }
        }
        .padding(.horizontal, CRSpacing.base)
        .padding(.vertical, CRSpacing.md)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}
