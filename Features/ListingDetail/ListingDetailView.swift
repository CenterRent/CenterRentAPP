import SwiftUI
import MapKit
import UIKit

// ============================================================
// MARK: - ListingDetailView  (Figma: "Página sala" — node 3243-5284)
// ============================================================
struct ListingDetailView: View {
    let listingId: String
    @StateObject private var vm = ListingDetailViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var currentImageIndex = 0
    @State private var showAllAmenities  = false
    @State private var expandDescription = false
    @State private var isFavorited       = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if vm.isLoading {
                loadingView
            } else if let listing = vm.listing {
                mainContent(listing: listing)
                stickyBar(listing: listing)
            } else {
                errorView
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        // ✅ Esconde a tab bar nativa do iOS 26
        .toolbar(.hidden, for: .tabBar)
        .onAppear { Task { await vm.load(listingId: listingId) } }
    }

    // ================================================================
    // MARK: - Main scroll
    // ================================================================
    @ViewBuilder
    private func mainContent(listing: Listing) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroCarousel(listing: listing)

                VStack(alignment: .leading, spacing: 0) {
                    titleSection(listing: listing)
                    highlightsSection(listing: listing)
                    amenitiesSection(listing: listing)
                    roomsSection(listing: listing)
                    reviewsSection(listing: listing)
                    locationSection(listing: listing)
                    ownerSection(listing: listing)
                    professionalInfoSection()
                    thinDivider
                    policyRows(listing: listing)
                    denunciarRow
                }
                .background(CRColor.Background.primary)
                .clipShape(RoundedTopCornersShape(radius: 24))
                .offset(y: -24)

                // bottom padding for sticky bar
                Color.clear.frame(height: 100)
            }
        }
        .background(CRColor.Neutral.n100)
    }

    // ================================================================
    // MARK: - 1. Hero Carousel
    // ================================================================

    /// Altura do container de imagem
    private let heroHeight: CGFloat = 420

    private func heroCarousel(listing: Listing) -> some View {
        ZStack(alignment: .bottom) {

            // ── Imagens ───────────────────────────────────────────────
            if listing.imageURLs.isEmpty {
                Rectangle()
                    .fill(CRColor.Neutral.n200)
                    .frame(height: heroHeight)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(CRColor.Neutral.n400)
                    )
            } else {
                TabView(selection: $currentImageIndex) {
                    ForEach(listing.imageURLs.indices, id: \.self) { idx in
                        heroImage(url: listing.imageURLs[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: heroHeight)
            }

            // ── Gradiente inferior ────────────────────────────────────
            LinearGradient(
                colors: [.black.opacity(0.30), .clear],
                startPoint: .bottom, endPoint: .center
            )
            .frame(height: 120)
            .allowsHitTesting(false)

            // ── Page dots ─────────────────────────────────────────────
            if listing.imageURLs.count > 1 {
                HStack(spacing: 5) {
                    ForEach(listing.imageURLs.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentImageIndex
                                  ? Color.white
                                  : Color.white.opacity(0.45))
                            .frame(
                                width:  i == currentImageIndex ? 7 : 5,
                                height: i == currentImageIndex ? 7 : 5
                            )
                            .animation(.easeInOut(duration: 0.2), value: currentImageIndex)
                    }
                }
                .padding(.bottom, 44)
            }

            // ── Counter badge (bottom-right) ──────────────────────────
            if listing.imageURLs.count > 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(currentImageIndex + 1)/\(listing.imageURLs.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(CRColor.Text.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.regularMaterial, in: Capsule())
                            .padding(.trailing, 16)
                            .padding(.bottom, 48)
                    }
                }
            }

            // ── Nav buttons — círculo branco com sombra (= NotificationsView) ──
            VStack {
                HStack {
                    // Back
                    Button { dismiss() } label: {
                        navCircleButton(icon: "chevron.left", iconSize: 16)
                    }
                    .buttonStyle(CRPressStyle())

                    Spacer()

                    HStack(spacing: 10) {
                        // Share
                        Button { } label: {
                            navCircleButton(icon: "square.and.arrow.up", iconSize: 15)
                        }
                        .buttonStyle(CRPressStyle())

                        // Favorite
                        Button {
                            isFavorited.toggle()
                            HapticFeedback.impact(.light)
                        } label: {
                            navCircleButton(
                                icon: isFavorited ? "heart.fill" : "heart",
                                iconSize: 15,
                                iconColor: isFavorited ? CRColor.Feedback.error : CRColor.Text.primary
                            )
                        }
                        .buttonStyle(CRPressStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }
        }
        .frame(height: heroHeight)
    }

    /// Círculo branco com sombra suave — mesmo padrão do resto do app
    private func navCircleButton(
        icon: String,
        iconSize: CGFloat,
        iconColor: Color = CRColor.Text.primary
    ) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(iconColor)
        }
    }

    /// Hero image — usa CRRemoteImage com auth fallback para bucket privado
    @ViewBuilder
    private func heroImage(url: String) -> some View {
        CRRemoteImage(urlString: url, scaledToFill: true)
            .frame(maxWidth: .infinity, maxHeight: heroHeight)
            .clipped()
    }

    // ================================================================
    // MARK: - 2. Title Section
    // ================================================================
    private func titleSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 14) {

            // Título
            Text(listing.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(CRColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Rating · localização
            HStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 13))
                    .foregroundColor(CRColor.Orange.c500)
                Text(String(format: "%.1f", listing.rating))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CRColor.Text.primary)
                Text("\(listing.reviewCount) avaliações")
                    .font(.system(size: 14))
                    .foregroundColor(CRColor.Text.secondary)
                Text("·").foregroundColor(CRColor.Text.tertiary)
                Text(listing.address.shortAddress)
                    .font(.system(size: 14))
                    .foregroundColor(CRColor.Text.secondary)
                    .lineLimit(1)
            }

            // Chips de especialidade + Disponível hoje
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(listing.specialties.prefix(3), id: \.self) { spec in
                        Text(spec)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(CRColor.Primary.default)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(CRColor.Primary.lighter)
                            .clipShape(Capsule())
                    }
                    Text("Disponível hoje")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(CRColor.Lemon.c900)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CRColor.Lemon.c100)
                        .clipShape(Capsule())
                }
            }

            // List navigation row — profissional do anúncio
            if let owner = vm.owner {
                ownerListNavigationRow(owner: owner)
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    // ================================================================
    // MARK: - List Navigation Row (owner)
    // ================================================================
    private func ownerListNavigationRow(owner: UserProfile) -> some View {
        Button {
            // navigate to owner profile if needed
        } label: {
            HStack(spacing: 12) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    ownerAvatar(url: owner.profileImageURL, size: 48)
                    if owner.verificationStatus == .verified {
                        ZStack {
                            Circle().fill(.white).frame(width: 16, height: 16)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(CRColor.Primary.default)
                        }
                        .offset(x: 2, y: 2)
                    }
                }

                // Name + subtitle
                VStack(alignment: .leading, spacing: 3) {
                    Text(owner.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(CRColor.Text.primary)
                    HStack(spacing: 4) {
                        if owner.verificationStatus == .verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(CRColor.Primary.default)
                        }
                        Text("Profissional Autorizado · \(ownerSince(owner))")
                            .font(.system(size: 12))
                            .foregroundColor(CRColor.Text.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(CRColor.Icon.secondary)
            }
            .padding(14)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CRRadius.md)
                    .stroke(CRColor.Border.default, lineWidth: 1)
            )
        }
        .buttonStyle(CRPressStyle())
    }

    // ================================================================
    // MARK: - 3. Highlights ("DESTAQUES DO PRODUTO")
    // ================================================================
    // Cores do card de destaques
    private let highlightCardBG    = Color(hex: "#D5DFFF")
    private let highlightCardInk   = Color(hex: "#012B5C")
    private let highlightIconBG    = Color(hex: "#012B5C").opacity(0.12)

    private func highlightsSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("DESTAQUES DO PRODUTO")
                .padding(.horizontal, CRSpacing.screenHorizontal)

            // ── Card: só os destaques ─────────────────────────────────
            let items = buildHighlights(listing: listing)
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(items, id: \.label) { h in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(highlightIconBG)
                                .frame(width: 34, height: 34)
                            Image(systemName: h.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(highlightCardInk)
                        }
                        Text(h.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(highlightCardInk)
                            .lineLimit(2)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(highlightCardBG)
            .cornerRadius(CRRadius.lg)
            .padding(.horizontal, CRSpacing.screenHorizontal)

            // ── Descrição fora do card ────────────────────────────────
            VStack(alignment: .leading, spacing: 14) {
                Text(listing.description)
                    .font(.system(size: 15))
                    .foregroundColor(CRColor.Text.secondary)
                    .lineLimit(expandDescription ? nil : 4)
                    .animation(.easeInOut(duration: 0.25), value: expandDescription)

                if listing.description.count > 180 {
                    HStack {
                        Spacer()
                        CRButton(
                            expandDescription ? "Mostrar menos" : "Mostrar mais",
                            variant: .outline,
                            size: .small,
                            icon: expandDescription ? "chevron.up" : "chevron.down",
                            iconPosition: .trailing,
                            isFullWidth: false
                        ) {
                            expandDescription.toggle()
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // Cores do componente de amenidade
    private let amenityIconColor   = Color(hex: "#503888")
    private let amenityIconBG      = Color(hex: "#E5E0F4")
    private let amenityInkColor    = Color(hex: "#191919")

    // ================================================================
    // MARK: - 4. Amenidades ("O QUE O LUGAR OFERECE")
    // ================================================================
    private func amenitiesSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("O QUE O LUGAR OFERECE")
                .padding(.horizontal, CRSpacing.screenHorizontal)

            let visible = showAllAmenities
                ? listing.amenities
                : Array(listing.amenities.prefix(6))

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(visible.indices, id: \.self) { i in
                    amenityCard(name: visible[i])
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)

            if listing.amenities.count > 6 {
                HStack {
                    Spacer()
                    CRButton(
                        showAllAmenities
                            ? "Mostrar menos"
                            : "Ver todas as \(listing.amenities.count) comodidades",
                        variant: .outline,
                        size: .small,
                        icon: showAllAmenities ? "chevron.up" : "chevron.down",
                        iconPosition: .trailing,
                        isFullWidth: false
                    ) {
                        withAnimation { showAllAmenities.toggle() }
                    }
                    Spacer()
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
        .padding(.vertical, 20)
    }

    private func amenityCard(name: String) -> some View {
        HStack(spacing: 12) {
            // Ícone com container arredondado
            ZStack {
                Circle()
                    .fill(amenityIconBG)
                    .frame(width: 44, height: 44)
                Image(systemName: amenityIcon(name))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(amenityIconColor)
            }

            // Textos
            VStack(alignment: .leading, spacing: 3) {
                Text("Incluso")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(amenityInkColor.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.4)
                Text(name)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(amenityInkColor)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(CRRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CRRadius.md)
                .stroke(CRColor.Border.default, lineWidth: 1)
        )
    }

    // ================================================================
    // MARK: - 5. Salas ("ONDE VOCÊ IRÁ ATENDER")
    // ================================================================
    private func roomsSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("ONDE VOCÊ IRÁ ATENDER")
                .padding(.horizontal, CRSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(buildRooms(listing: listing), id: \.name) { room in
                        VStack(alignment: .leading, spacing: 8) {
                            CRRemoteImage(urlString: room.imageURL, scaledToFill: true)
                                .frame(width: 156, height: 117)
                                .clipped()
                                .cornerRadius(12)

                            Text(room.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(CRColor.Text.primary)
                            Text(room.description)
                                .font(.system(size: 12))
                                .foregroundColor(CRColor.Text.secondary)
                                .lineLimit(2)
                        }
                        .frame(width: 156)
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
        .padding(.vertical, 20)
    }

    // ================================================================
    // MARK: - 6. Avaliações ("AVALIAÇÕES")
    // ================================================================
    private func reviewsSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack {
                sectionLabel("AVALIAÇÕES")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(CRColor.Accent.default)
                    Text(String(format: "%.1f", listing.rating))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(CRColor.Text.primary)
                    Text("(\(listing.reviewCount))")
                        .font(.system(size: 13))
                        .foregroundColor(CRColor.Text.secondary)
                }
            }

            // Filter chips
            let chips = buildReviewChips(listing: listing)
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(CRColor.Text.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .overlay(Capsule().stroke(CRColor.Border.default, lineWidth: 1))
                        }
                    }
                }
            }

            // Review cards
            if vm.reviews.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "star.slash").foregroundColor(CRColor.Neutral.n300)
                    Text("Sem avaliações ainda")
                        .font(.system(size: 14))
                        .foregroundColor(CRColor.Text.tertiary)
                }
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 20) {
                    ForEach(vm.reviews.prefix(3)) { review in
                        ReviewCard(review: review)
                    }
                }

                if listing.reviewCount > 3 {
                    Button { } label: {
                        Text("Ver todas as \(listing.reviewCount) avaliações")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(CRColor.Text.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: CRRadius.md)
                                    .stroke(CRColor.Border.default, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, 20)
    }

    // ================================================================
    // MARK: - 7. Localização
    // ================================================================
    private func locationSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("LOCALIZAÇÃO")

            let coord = CLLocationCoordinate2D(
                latitude:  listing.address.latitude  ?? -23.561,
                longitude: listing.address.longitude ?? -46.655
            )

            // Mapa + botão overlay
            ZStack(alignment: .bottomTrailing) {
                Map(initialPosition: .region(
                    MKCoordinateRegion(
                        center: coord,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    )
                )) {
                    Marker("", coordinate: coord).tint(CRColor.Primary.default)
                }
                .frame(height: 180)
                .cornerRadius(16)
                .disabled(true)

                Button { openMaps(listing: listing) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "map.fill").font(.system(size: 12, weight: .semibold))
                        Text("Ver no mapa").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(CRColor.Primary.default)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                }
                .padding(12)
            }

            // Endereço
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.address.neighborhood.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(CRColor.Text.primary)
                Text("Localização exata fornecida após a reserva. Perto do Shopping.")
                    .font(.system(size: 13))
                    .foregroundColor(CRColor.Text.secondary)
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, 20)
    }

    // ================================================================
    // MARK: - 8. Anunciante ("CONHEÇA O ANUNCIANTE")
    // ================================================================
    private func ownerSection(listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("CONHEÇA O ANUNCIANTE")

            if let owner = vm.owner {
                VStack(spacing: 16) {

                    // Avatar + nome + verificado
                    HStack(spacing: 14) {
                        ZStack(alignment: .bottomTrailing) {
                            ownerAvatar(url: owner.profileImageURL, size: 72)
                            if owner.verificationStatus == .verified {
                                ZStack {
                                    Circle().fill(.white).frame(width: 22, height: 22)
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(CRColor.Primary.default)
                                }
                                .offset(x: 2, y: 2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(owner.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(CRColor.Text.primary)
                            if owner.verificationStatus == .verified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(CRColor.Primary.default)
                                    Text("Anunciante verificado")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(CRColor.Primary.default)
                                }
                            }
                        }
                        Spacer()
                    }

                    // Stats: Nota | Avaliações | Anos
                    HStack(spacing: 0) {
                        statCell(value: String(format: "%.1f", listing.rating), label: "Nota")
                        Rectangle().fill(CRColor.Border.default).frame(width: 1, height: 36)
                        statCell(value: "\(listing.reviewCount)", label: "Avaliações")
                        Rectangle().fill(CRColor.Border.default).frame(width: 1, height: 36)
                        statCell(value: ownerYears(owner), label: "Anos")
                    }
                    .padding(.vertical, 12)
                    .background(CRColor.Surface.primary)
                    .cornerRadius(CRRadius.md)
                    .overlay(RoundedRectangle(cornerRadius: CRRadius.md)
                        .stroke(CRColor.Border.default, lineWidth: 1))

                    // Identidade verificada
                    if owner.verificationStatus == .verified {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 15))
                                .foregroundColor(CRColor.Feedback.success)
                            Text("Identidade verificada")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(CRColor.Text.primary)
                        }
                    }

                    // Bio
                    if let bio = owner.bio, !bio.isEmpty {
                        Text("\"\(bio)\"")
                            .font(.system(size: 14))
                            .foregroundColor(CRColor.Text.secondary)
                    }

                    // Info rows (2x)
                    VStack(spacing: 0) {
                        ownerInfoRow(owner: owner)
                        Rectangle().fill(CRColor.Border.default).frame(height: 1)
                        ownerInfoRow(owner: owner)
                    }
                }
                .padding(16)
                .background(CRColor.Surface.primary)
                .cornerRadius(CRRadius.lg)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.lg)
                    .stroke(CRColor.Border.default, lineWidth: 1))

            } else {
                RoundedRectangle(cornerRadius: CRRadius.lg)
                    .fill(CRColor.Neutral.n200)
                    .frame(height: 140)
                    .shimmer()
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, 20)
    }

    // ================================================================
    // MARK: - 9. Info Profissional + Enviar Mensagem
    // ================================================================
    private func professionalInfoSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                        .foregroundColor(CRColor.Icon.secondary)
                    Text("Taxa de resposta: 100%")
                        .font(.system(size: 14))
                        .foregroundColor(CRColor.Text.primary)
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(CRColor.Icon.secondary)
                    Text("Responde em até 1 hora")
                        .font(.system(size: 14))
                        .foregroundColor(CRColor.Text.secondary)
                }
            }

            // ✅ CRButton outline — mesmo padrão do restante do app
            if let owner = vm.owner {
                CRButton(
                    "Enviar mensagem ao profissional",
                    variant: .outline,
                    size: .large,
                    isFullWidth: true
                ) {
                    router.navigate(to: .chat(conversationId: owner.id))
                }
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, 20)
    }

    // ================================================================
    // MARK: - 10. Políticas
    // ================================================================
    private func policyRows(listing: Listing) -> some View {
        VStack(spacing: 0) {
            policyRow(
                icon: "arrow.counterclockwise.circle",
                title: "Política de cancelamento",
                subtitle: "Adicione as datas da reserva para obter as informações de cancelamento."
            )
            innerDivider
            policyRow(
                icon: "list.bullet.clipboard",
                title: "Regras do consultório",
                subtitle: "Adicione as datas da reserva para obter as informações das regras."
            )
            innerDivider
            policyRow(
                icon: "lock.shield",
                title: "Segurança e propriedade",
                subtitle: "Câmera de segurança na parte interna do consultório."
            )
        }
    }

    private func policyRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(CRColor.Icon.secondary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(CRColor.Text.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(CRColor.Text.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CRColor.Icon.secondary)
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, 18)
    }

    // "Denunciar anúncio"
    private var denunciarRow: some View {
        Button { } label: {
            HStack(spacing: 6) {
                Image(systemName: "flag")
                    .font(.system(size: 14))
                    .foregroundColor(CRColor.Feedback.error)
                Text("Denunciar anúncio")
                    .font(.system(size: 14))
                    .foregroundColor(CRColor.Feedback.error)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    // ================================================================
    // MARK: - Sticky Bottom Bar
    // ================================================================
    private func stickyBar(listing: Listing) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(CRColor.Border.default).frame(height: 1)
            HStack(spacing: 16) {
                // Preço
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("R$ \(Int(listing.pricePerHour))")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(CRColor.Text.primary)
                        Text("/ hora")
                            .font(.system(size: 14))
                            .foregroundColor(CRColor.Text.secondary)
                    }
                    if let daily = listing.pricePerDay {
                        Text("R$ \(Int(daily)) / dia")
                            .font(.system(size: 12))
                            .foregroundColor(CRColor.Text.tertiary)
                    }
                }

                Spacer()

                // ✅ CRButton — usa cornerRadius: 28 (pill) como restante do app
                CRButton(
                    "Reservar",
                    variant: .primary,
                    size: .large,
                    isFullWidth: false
                ) {
                    router.navigate(to: .booking(listingId: listing.id))
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
            .padding(.vertical, 14)
            .background(CRColor.Background.primary)
        }
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: -4)
    }

    // ================================================================
    // MARK: - Loading / Error
    // ================================================================
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(CRColor.Neutral.n200)
                    .frame(height: 420)
                    .shimmer()
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CRColor.Neutral.n200)
                            .frame(height: 18)
                            .shimmer()
                    }
                }
                .padding(CRSpacing.screenHorizontal)
                .padding(.top, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(CRColor.Neutral.n300)
            Text("Espaço não encontrado")
                .font(.crHeading5)
                .foregroundColor(CRColor.Text.primary)
            Text("Não foi possível carregar as informações deste anúncio.")
                .font(.crBodyBase)
                .foregroundColor(CRColor.Text.secondary)
                .multilineTextAlignment(.center)
            CRButton("Voltar", variant: .ghost, size: .medium, isFullWidth: false) { dismiss() }
        }
        .padding(32)
    }

    // ================================================================
    // MARK: - Shared UI helpers
    // ================================================================

    /// 8pt thick grey separator (entre seções principais)
    private var sectionDivider: some View {
        Rectangle().fill(CRColor.Neutral.n100).frame(height: 8)
    }

    /// 1pt divider fino
    private var thinDivider: some View {
        Rectangle().fill(CRColor.Border.default).frame(height: 1)
    }

    /// Divider dentro de seção (inset)
    private var innerDivider: some View {
        Rectangle().fill(CRColor.Border.default).frame(height: 1)
            .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(CRColor.Text.tertiary)
            .tracking(1.0)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(CRColor.Text.primary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(CRColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func ownerAvatar(url: String?, size: CGFloat) -> some View {
        if let urlStr = url, !urlStr.isEmpty {
            CRRemoteImage(urlString: urlStr, scaledToFill: true)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(CRColor.Primary.lighter)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(CRColor.Primary.default)
                )
        }
    }

    private func ownerInfoRow(owner: UserProfile) -> some View {
        HStack(spacing: 12) {
            ownerAvatar(url: owner.profileImageURL, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Anunciante: \(owner.displayName)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(CRColor.Text.primary)
                    .lineLimit(1)
                Text("\(ownerYears(owner)) anos oferecendo seu espaço")
                    .font(.system(size: 12))
                    .foregroundColor(CRColor.Text.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }

    // ================================================================
    // MARK: - Data helpers
    // ================================================================

    private func ownerSince(_ owner: UserProfile) -> String {
        "Desde \(Calendar.current.component(.year, from: owner.createdAt))"
    }

    private func ownerYears(_ owner: UserProfile) -> String {
        let joined  = Calendar.current.component(.year, from: owner.createdAt)
        let current = Calendar.current.component(.year, from: Date())
        return "\(max(1, current - joined))"
    }

    private func openMaps(listing: Listing) {
        let q = listing.address.fullAddress
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        UIApplication.shared.open(URL(string: "https://maps.apple.com/?q=\(q)")!)
    }

    private func buildHighlights(listing: Listing) -> [(icon: String, label: String)] {
        var r: [(String, String)] = []
        if listing.area > 0            { r.append(("ruler",          "Área de \(Int(listing.area)) m²")) }
        if listing.isVerifiedOwner     { r.append(("checkmark.seal", "Anunciante verificado")) }
        if listing.capacity > 1        { r.append(("person.2",       "Até \(listing.capacity) pessoas")) }
        if let s = listing.specialties.first { r.append(("stethoscope", s)) }
        if r.count < 4 { r.append(("star.fill",  "Ambiente de luxo")) }
        if r.count < 4 { r.append(("sofa",        "Mobiliário Ergonômico")) }
        return Array(r.prefix(4))
    }

    private func amenityIcon(_ name: String) -> String {
        let l = name.lowercased()
        if l.contains("wifi") || l.contains("internet") { return "wifi" }
        if l.contains("ar") || l.contains("condicion") { return "air.conditioner.horizontal" }
        if l.contains("estacion") { return "car" }
        if l.contains("copa") || l.contains("cozinha") || l.contains("café") { return "cup.and.saucer" }
        if l.contains("cadeira") { return "chair" }
        if l.contains("tomada") { return "powerplug" }
        if l.contains("autoclave") { return "cross.vial" }
        if l.contains("recepc") { return "person.badge.shield.checkmark" }
        if l.contains("banheiro") { return "shower" }
        if l.contains("compressor") { return "fan" }
        return "checkmark.circle"
    }

    private func buildRooms(listing: Listing) -> [(name: String, description: String, imageURL: String?)] {
        let names = ["Recepção", "Refeitório", "Consultório", "Sala de espera"]
        let descs = [
            "Recepcionista, banheiros, refeitório e espaço comum",
            "3 anos oferecendo seu espaço",
            "Sala climatizada e totalmente equipada",
            "Confortável e bem iluminada"
        ]
        return names.enumerated().map { i, n in
            (n, descs[i % descs.count], listing.imageURLs.indices.contains(i) ? listing.imageURLs[i] : nil)
        }
    }

    private func buildReviewChips(listing: Listing) -> [String] {
        var c: [String] = Array(listing.specialties.prefix(2))
        c.append(contentsOf: ["Excelente atendimento", "Serviço Premium"])
        return Array(c.prefix(4))
    }
}

// ================================================================
// MARK: - ReviewCard
// ================================================================
private struct ReviewCard: View {
    let review: Review

    private var initial: String { String(review.authorId.prefix(1)).uppercased() }

    private var date: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: review.createdAt).capitalized
    }

    private var avatarColor: Color {
        let palette: [Color] = [
            Color(red: 0.95, green: 0.47, blue: 0.18),
            Color(red: 0.22, green: 0.56, blue: 0.93),
            Color(red: 0.38, green: 0.73, blue: 0.49),
            Color(red: 0.68, green: 0.30, blue: 0.83)
        ]
        return palette[abs(review.authorId.hashValue) % palette.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(initial)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Profissional verificado")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(CRColor.Text.primary)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundColor(CRColor.Accent.default)
                        }
                    }
                }

                Spacer()

                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(CRColor.Text.tertiary)
            }

            Text(review.comment)
                .font(.system(size: 14))
                .foregroundColor(CRColor.Text.secondary)
                .lineLimit(4)
        }
    }
}

// ================================================================
// MARK: - RoundedTopCornersShape
// ================================================================
private struct RoundedTopCornersShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: radius))
        p.addArc(center: CGPoint(x: radius, y: radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
        p.addArc(center: CGPoint(x: rect.maxX - radius, y: radius), radius: radius,
                 startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: 0, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// ================================================================
// MARK: - ViewModel
// ================================================================
@MainActor
final class ListingDetailViewModel: ObservableObject {
    @Published var listing: Listing?
    @Published var owner:   UserProfile?
    @Published var reviews: [Review] = []
    @Published var isLoading = false

    func load(listingId: String) async {
        isLoading = true
        defer { isLoading = false }

        listing = try? await SupabaseManager.shared.fetchListing(id: listingId)

        if let ownerId = listing?.ownerId {
            owner = try? await SupabaseManager.shared.fetchProfile(userId: ownerId)
        }
        reviews = (try? await fetchReviews(listingId: listingId)) ?? []
    }

    private func fetchReviews(listingId: String) async throws -> [Review] {
        try await SupabaseManager.shared.client
            .from(SupabaseManager.Table.reviews)
            .select("*")
            .eq("listing_id", value: listingId)
            .order("created_at", ascending: false)
            .limit(10)
            .execute()
            .value
    }
}
