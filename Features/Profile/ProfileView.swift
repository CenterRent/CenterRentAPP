import SwiftUI
import PhotosUI

// MARK: - My Profile View
struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var showEditProfile = false
    @State private var showPhoneVerification = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false

    var user: UserProfile? { authService.currentUser }

    var body: some View {
        ScrollView {
            VStack(spacing: CRSpacing.s6) {
                // Profile Header
                profileHeader

                // Verification Status
                verificationSection

                // Stats
                statsSection

                Divider().overlay(CRColor.Border.default).padding(.horizontal, CRSpacing.screenHorizontal)

                // Menu Items
                menuSection

                Divider().overlay(CRColor.Border.default).padding(.horizontal, CRSpacing.screenHorizontal)

                // Danger Zone
                dangerSection
            }
            .padding(.bottom, CRSpacing.s10)
        }
        .background(CRColor.Background.secondary.ignoresSafeArea())
        .navigationTitle("Meu Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditProfile = true }) {
                    Image(systemName: "pencil.circle").foregroundColor(CRColor.Primary.default)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showPhoneVerification) {
            PhoneVerificationView(isOnboarding: false)
        }
        .alert("Sair da conta?", isPresented: $showSignOutAlert) {
            // authVM (não authService direto) -- é authVM.isAuthenticated que
            // controla o gate de RootView; chamar só authService.signOut()
            // limpava o usuário aqui mas deixava o app "logado" mesmo assim.
            Button("Sair", role: .destructive) { Task { await authVM.signOut() } }
            Button("Cancelar", role: .cancel) {}
        }
        .alert("Excluir conta?", isPresented: $showDeleteAlert) {
            Button("Excluir definitivamente", role: .destructive) {
                Task { await authVM.deleteAccount() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação é permanente e irreversível. Todos os seus dados, anúncios e histórico serão apagados.")
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: CRSpacing.s4) {
            ZStack(alignment: .bottomTrailing) {
                CRAvatar(
                    imageURL: user?.profileImageURL,
                    name: user?.fullName ?? "?",
                    size: CRSize.avatar2XL
                )
                Button(action: { showEditProfile = true }) {
                    Circle()
                        .fill(CRColor.Primary.default)
                        .frame(width: 32, height: 32)
                        .overlay(Image(systemName: "camera.fill").font(.system(size: 13)).foregroundColor(.white))
                }
            }
            .padding(.top, CRSpacing.s3)

            VStack(spacing: CRSpacing.s2) {
                Text(user?.fullName ?? "").font(.crHeading3).foregroundColor(CRColor.Text.primary)
                Text(user?.specialty ?? "Profissional de Odontologia")
                    .font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio).font(.crBodySM).foregroundColor(CRColor.Text.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, CRSpacing.s8)
                }

                // Badges
                HStack(spacing: CRSpacing.s2) {
                    if user?.verificationStatus == .verified {
                        CRBadge("CRO Verificado", style: .verified)
                    } else if user?.verificationStatus == .pendingVerification {
                        CRBadge("Verificação pendente", style: .pending)
                    }
                    if user?.phoneVerified == true {
                        CRBadge("Tel. Verificado", style: .phoneVerified)
                    }
                }
            }
        }
    }

    // MARK: - Verification Section
    private var verificationSection: some View {
        VStack(spacing: CRSpacing.s3) {
            if user?.phoneVerified == false {
                VerificationCard(
                    icon: "phone.badge.plus",
                    title: "Verifique seu telefone",
                    description: "Necessário para fazer reservas e conversar com anunciantes",
                    buttonLabel: "Verificar agora",
                    style: .warning,
                    action: { showPhoneVerification = true }
                )
            }
            if user?.verificationStatus == .notSubmitted {
                VerificationCard(
                    icon: "person.badge.key",
                    title: "Envie seu CRO",
                    description: "Obtenha o badge de profissional verificado",
                    buttonLabel: "Enviar documentos",
                    style: .info,
                    action: { showEditProfile = true }
                )
            }
            if user?.verificationStatus == .rejected {
                VerificationCard(
                    icon: "xmark.seal",
                    title: "Verificação rejeitada",
                    description: "Seus documentos não foram aceitos. Tente novamente.",
                    buttonLabel: "Reenviar",
                    style: .error,
                    action: { showEditProfile = true }
                )
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    // MARK: - Stats
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatBox(value: "0", label: "Anúncios", icon: "building.2")
            Divider().frame(height: 40).overlay(CRColor.Border.default)
            StatBox(value: "0", label: "Reservas", icon: "calendar.badge.checkmark")
            Divider().frame(height: 40).overlay(CRColor.Border.default)
            StatBox(value: "0.0", label: "Avaliação", icon: "star.fill", iconColor: CRColor.Accent.default)
        }
        .padding(.vertical, CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.card)
        .crShadow(CRShadow.xs)
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    // MARK: - Menu
    private var menuSection: some View {
        VStack(spacing: CRSpacing.s2) {
            ProfileMenuItem(icon: "building.2", label: "Meus anúncios", badge: 0) {
                router.profilePath.append(AppDestination.myListings)
            }
            ProfileMenuItem(icon: "calendar", label: "Minhas reservas") {
                router.profilePath.append(AppDestination.myBookings)
            }
            ProfileMenuItem(icon: "dollarsign.circle", label: "Financeiro") {
                router.profilePath.append(AppDestination.dashboard)
            }
            ProfileMenuItem(icon: "person.2.wave.2", label: "Indique e ganhe") {
                router.profilePath.append(AppDestination.mgm)
            }
            ProfileMenuItem(icon: "bell", label: "Notificações") {
                router.profilePath.append(AppDestination.notifications)
            }
            ProfileMenuItem(icon: "gearshape", label: "Configurações") {
                router.profilePath.append(AppDestination.settings)
            }
            ProfileMenuItem(icon: "questionmark.circle", label: "Ajuda e suporte") {
                // Open support
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    // MARK: - Danger
    private var dangerSection: some View {
        VStack(spacing: CRSpacing.s2) {
            Button(action: { showSignOutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sair da conta")
                    Spacer()
                }
                .font(.crLabelMD)
                .foregroundColor(CRColor.Feedback.error)
                .padding(CRSpacing.s4)
                .background(CRColor.Surface.primary)
                .cornerRadius(CRRadius.md)
            }
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Excluir conta")
                    Spacer()
                }
                .font(.crLabelSM)
                .foregroundColor(CRColor.Text.tertiary)
                .padding(CRSpacing.s4)
                .background(CRColor.Surface.primary)
                .cornerRadius(CRRadius.md)
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }
}

// MARK: - Stat Box
private struct StatBox: View {
    let value: String; let label: String; let icon: String
    var iconColor: Color = CRColor.Primary.default

    var body: some View {
        VStack(spacing: CRSpacing.s1) {
            Image(systemName: icon).foregroundColor(iconColor).font(.system(size: CRSize.iconMD))
            Text(value).font(.crHeading4).foregroundColor(CRColor.Text.primary)
            Text(label).font(.crCaptionMD).foregroundColor(CRColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Menu Item
private struct ProfileMenuItem: View {
    let icon: String; let label: String; var badge: Int = 0; let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.s3) {
                Image(systemName: icon)
                    .font(.system(size: CRSize.iconMD))
                    .foregroundColor(CRColor.Icon.accent)
                    .frame(width: 24)
                Text(label).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                Spacer()
                if badge > 0 { CRNotificationDot(badge) }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(CRColor.Icon.secondary)
            }
            .padding(CRSpacing.s4)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.md)
        }
    }
}

// MARK: - Verification Card
private struct VerificationCard: View {
    enum CardStyle { case warning, info, error }
    let icon: String; let title: String; let description: String
    let buttonLabel: String; let style: CardStyle; let action: () -> Void

    private var colors: (bg: Color, fg: Color) {
        switch style {
        case .warning: return (CRColor.Feedback.warningLight, CRColor.Feedback.warning)
        case .info:    return (CRColor.Feedback.infoLight, CRColor.Feedback.info)
        case .error:   return (CRColor.Feedback.errorLight, CRColor.Feedback.error)
        }
    }

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            Image(systemName: icon).font(.system(size: CRSize.iconLG)).foregroundColor(colors.fg)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                Text(description).font(.crCaptionMD).foregroundColor(CRColor.Text.secondary)
            }
            Spacer()
            CRButton(buttonLabel, variant: .primary, size: .sm, action: action)
        }
        .padding(CRSpacing.s4)
        .background(colors.bg)
        .cornerRadius(CRRadius.card)
    }
}

// MARK: - Public Profile View
struct PublicProfileView: View {
    let userId: String
    @State private var profile: UserProfile? = nil
    @State private var listings: [Listing] = []
    @State private var reviews: [Review] = []
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ScrollView {
            if let profile {
                VStack(spacing: CRSpacing.s6) {
                    // Header
                    VStack(spacing: CRSpacing.s3) {
                        CRAvatar(imageURL: profile.profileImageURL, name: profile.fullName, size: CRSize.avatar2XL)
                        Text(profile.fullName).font(.crHeading3).foregroundColor(CRColor.Text.primary)
                        Text(profile.specialty).font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                        HStack(spacing: CRSpacing.s2) {
                            if profile.verificationStatus == .verified { CRBadge("CRO Verificado", style: .verified) }
                            if profile.phoneVerified { CRBadge("Tel. verificado", style: .phoneVerified) }
                        }
                    }
                    .padding(.top, CRSpacing.s6)

                    // Listings
                    if !listings.isEmpty {
                        VStack(alignment: .leading, spacing: CRSpacing.s4) {
                            CRSectionHeader("Espaços anunciados") {}
                                .padding(.horizontal, CRSpacing.screenHorizontal)
                            ForEach(listings) { listing in
                                CRListingCard(listing: listing,
                                              onTap: { router.profilePath.append(AppDestination.listingDetail(listingId: listing.id)) },
                                              onFavorite: {})
                                    .padding(.horizontal, CRSpacing.screenHorizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, CRSpacing.s10)
            } else {
                ProgressView().padding(.top, CRSpacing.s10)
            }
        }
        .background(CRColor.Background.secondary.ignoresSafeArea())
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// EditProfileView is defined in Views/Profile/EditProfileView.swift
