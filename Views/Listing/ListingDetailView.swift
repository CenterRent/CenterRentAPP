import SwiftUI
import MapKit

// MARK: - Listing Detail View (FEATURE 12 — completamente refatorada)
struct ListingDetailView: View {
    let listing: Listing
    @EnvironmentObject var router: AppRouter

    @State private var selectedImageIndex = 0
    @State private var showAllAmenities = false
    @State private var showAllReviews = false
    @State private var isFavorited: Bool
    @State private var region: MKCoordinateRegion
    @State private var headerVisible = true
    @State private var scrollOffset: CGFloat = 0

    // Fotos cadastradas no fluxo de publicação de anúncios
    // Prioriza listing.imageURLs (do fluxo de criação), com fallback para imageURL
    private var allImageURLs: [String] {
        if !listing.imageURLs.isEmpty {
            return listing.imageURLs
        } else if let single = listing.imageURL, !single.isEmpty {
            return [single]
        }
        return []
    }

    init(listing: Listing) {
        self.listing = listing
        _isFavorited = State(initialValue: listing.isFavorited)
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: listing.latitude ?? -23.5505,
                longitude: listing.longitude ?? -46.6333
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Banner de imagens do fluxo de publicação ──
                    ListingImageBanner(
                        imageURLs: allImageURLs,
                        selectedIndex: $selectedImageIndex,
                        isFavorited: isFavorited,
                        onBack: { router.pop() },
                        onFavorite: { isFavorited.toggle() }
                    )

                    // ── Conteúdo principal ──
                    VStack(alignment: .leading, spacing: 0) {
                        // Pílula de categorias + status
                        categoryStatusRow
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.top, CRSpacing.lg)

                        // Título, localização, rating
                        titleBlock
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.top, CRSpacing.md)

                        divider

                        // Proprietário
                        OwnerCard(listing: listing)
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)

                        divider

                        // Preço
                        priceBlock
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)

                        divider

                        // Descrição
                        if let desc = listing.description, !desc.isEmpty {
                            descriptionBlock(desc)
                                .padding(.horizontal, CRSpacing.base)
                                .padding(.vertical, CRSpacing.md)
                            divider
                        }

                        // Comodidades
                        if !listing.amenities.isEmpty {
                            AmenitiesSection(amenities: listing.amenities, showAll: $showAllAmenities)
                                .padding(.horizontal, CRSpacing.base)
                                .padding(.vertical, CRSpacing.md)
                            divider
                        }

                        // Localização
                        locationBlock
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)
                        divider

                        // Avaliações
                        if let reviews = listing.reviews, !reviews.isEmpty {
                            ReviewsSection(
                                reviews: reviews,
                                rating: listing.rating,
                                reviewCount: listing.reviewCount,
                                showAll: $showAllReviews
                            )
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)
                            divider
                        }

                        // Anfitrião
                        HostSummaryCard(listing: listing) {}
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)
                        divider

                        // Política de cancelamento
                        cancellationPolicy
                            .padding(.horizontal, CRSpacing.base)
                            .padding(.vertical, CRSpacing.md)

                        // Espaço para o CTA fixo
                        Spacer().frame(height: 100)
                    }
                    .background(Color.white)
                    .cornerRadius(CRRadius.xl, corners: [.topLeft, .topRight])
                    .offset(y: -20)
                }
            }
            .ignoresSafeArea(edges: .top)

            // ── CTA fixo no rodapé ──
            listingCTA
        }
        .navigationBarHidden(true)
        .background(Color.crBackground)
    }

    // MARK: - Sub-views

    private var divider: some View {
        Divider().padding(.horizontal, CRSpacing.base)
    }

    private var categoryStatusRow: some View {
        HStack(spacing: CRSpacing.sm) {
            // Categoria
            Text(listing.categoryName)
                .font(.crLabelSmall)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(listing.categoryColor)
                .cornerRadius(CRRadius.pill)

            // Verificado
            Label("Verificado", systemImage: "checkmark.seal.fill")
                .font(.crLabelSmall)
                .foregroundColor(.crSuccess)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.crSuccess.opacity(0.1))
                .cornerRadius(CRRadius.pill)

            Spacer()

            // Compartilhar
            Button {
                // share sheet
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.crTextSecondary)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Text(listing.title)
                .font(.crH2)
                .foregroundColor(.crTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: CRSpacing.md) {
                if let city = listing.city, let state = listing.state {
                    Label("\(city), \(state)", systemImage: "mappin.circle.fill")
                        .font(.crBody)
                        .foregroundColor(.crTextSecondary)
                }
                Spacer()
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.crWarning)
                    Text(String(format: "%.1f", listing.rating))
                        .font(.crLabelLarge)
                        .foregroundColor(.crTextPrimary)
                    Text("(\(listing.reviewCount))")
                        .font(.crBodySmall)
                        .foregroundColor(.crTextTertiary)
                }
            }
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Text("Investimento na visita")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)

            HStack(alignment: .bottom, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("por hora")
                        .font(.crCaption)
                        .foregroundColor(.crTextTertiary)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("R$")
                            .font(.crBodySmall)
                            .foregroundColor(.crPrimary)
                        Text("\(Int(listing.dailyPrice / 8))")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.crPrimary)
                    }
                }

                Text("ou")
                    .font(.crBodySmall)
                    .foregroundColor(.crTextTertiary)
                    .padding(.bottom, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text("por dia")
                        .font(.crCaption)
                        .foregroundColor(.crTextTertiary)
                    Text("R$ \(Int(listing.dailyPrice))")
                        .font(.crPrice)
                        .foregroundColor(.crTextSecondary)
                }

                Spacer()

                // Taxa de limpeza
                VStack(alignment: .trailing, spacing: 2) {
                    Text("+ limpeza")
                        .font(.crCaption)
                        .foregroundColor(.crTextTertiary)
                    Text("R$ \(Int(listing.cleaningFee))")
                        .font(.crLabel)
                        .foregroundColor(.crTextSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func descriptionBlock(_ desc: String) -> some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Text("Sobre o espaço")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)
            Text(desc)
                .font(.crBody)
                .foregroundColor(.crTextSecondary)
                .lineSpacing(4)
                .lineLimit(5)
            Button("Ler mais") {}
                .font(.crLabel)
                .foregroundColor(.crPrimary)
        }
    }

    private var locationBlock: some View {
        VStack(alignment: .leading, spacing: CRSpacing.md) {
            Text("Onde você irá atender")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)

            Map(coordinateRegion: $region, annotationItems: [
                MapPin(coordinate: CLLocationCoordinate2D(
                    latitude: listing.latitude ?? -23.5505,
                    longitude: listing.longitude ?? -46.6333
                ))
            ]) { pin in
                MapMarker(coordinate: pin.coordinate, tint: .crPrimary)
            }
            .frame(height: 180)
            .cornerRadius(CRRadius.lg)

            if let address = listing.address {
                Label(address, systemImage: "mappin")
                    .font(.crBody)
                    .foregroundColor(.crTextSecondary)
            }
        }
    }

    private var cancellationPolicy: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Label("Política de cancelamento", systemImage: "doc.text")
                .font(.crLabel)
                .foregroundColor(.crTextPrimary)
            Text("Cancelamento gratuito até 24h antes. Após isso, 50% do valor será retido.")
                .font(.crBodySmall)
                .foregroundColor(.crTextSecondary)
        }
    }

    private var listingCTA: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: CRSpacing.base) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Diária a partir de")
                        .font(.crCaption)
                        .foregroundColor(.crTextTertiary)
                    Text("R$ \(Int(listing.dailyPrice))")
                        .font(.crPrice)
                        .foregroundColor(.crPrimary)
                }
                Spacer()
                CRButton(title: "Conferir disponibilidade", isFullWidth: false) {
                    router.push(.booking(listing))
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
            .background(Color.white)
        }
    }
}

// MARK: - Banner de Imagens (fotos do fluxo de publicação)
struct ListingImageBanner: View {
    let imageURLs: [String]
    @Binding var selectedIndex: Int
    let isFavorited: Bool
    let onBack: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Gallery
            if imageURLs.isEmpty {
                // Estado vazio — gradiente placeholder
                LinearGradient(
                    colors: [Color.crPrimary.opacity(0.4), Color.crSecondary.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 340)
                .overlay(
                    VStack(spacing: CRSpacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Sem fotos cadastradas")
                            .font(.crBody)
                            .foregroundColor(.white.opacity(0.8))
                    }
                )
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(imageURLs.indices, id: \.self) { i in
                        AsyncImage(url: URL(string: imageURLs[i])) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            case .failure:
                                Rectangle()
                                    .fill(Color.crSkeleton)
                                    .overlay(
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.4))
                                    )
                            case .empty:
                                Rectangle().fill(Color.crSkeleton)
                                    .overlay(ProgressView().tint(.crPrimary))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 340)
                        .clipped()
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)
            }

            // Overlay gradiente no topo (para os botões)
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 120)

            // Botões de controle
            HStack {
                // Botão voltar estilo Apple
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Contador de imagens
                if imageURLs.count > 1 {
                    Text("\(selectedIndex + 1)/\(imageURLs.count)")
                        .font(.crLabelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(CRRadius.pill)
                }

                Spacer()

                // Favoritar
                Button(action: onFavorite) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isFavorited ? .crError : .white)
                    }
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.top, CRSpacing.hero)

            // Indicador de dots no rodapé da galeria
            if imageURLs.count > 1 {
                HStack(spacing: 5) {
                    ForEach(imageURLs.indices, id: \.self) { i in
                        Circle()
                            .fill(i == selectedIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: i == selectedIndex ? 8 : 5, height: i == selectedIndex ? 8 : 5)
                            .animation(.spring(response: 0.3), value: selectedIndex)
                    }
                }
                .padding(.bottom, CRSpacing.lg)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 340)
            }
        }
    }
}

// MARK: - Map Pin
struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Owner Card
struct OwnerCard: View {
    let listing: Listing
    var body: some View {
        HStack(spacing: CRSpacing.md) {
            // Avatar com iniciais
            Circle()
                .fill(Color.crPrimary.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(listing.ownerName.prefix(1)))
                        .font(.crH3)
                        .foregroundColor(.crPrimary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.ownerName)
                    .font(.crLabel)
                    .foregroundColor(.crTextPrimary)
                if let pid = listing.ownerProfessionalId {
                    Text(pid)
                        .font(.crBodySmall)
                        .foregroundColor(.crTextTertiary)
                }
            }

            Spacer()

            // Rating do proprietário
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.crWarning)
                Text(String(format: "%.1f", listing.ownerRating))
                    .font(.crLabel)
            }

            CRButton(title: "Contatar", variant: .outline, size: .small, isFullWidth: false) {}
        }
    }
}

// MARK: - Amenities Section
struct AmenitiesSection: View {
    let amenities: [String]
    @Binding var showAll: Bool
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var displayed: [String] { showAll ? amenities : Array(amenities.prefix(6)) }

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.md) {
            Text("O que o lugar oferece")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)

            LazyVGrid(columns: columns, spacing: CRSpacing.sm) {
                ForEach(displayed, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: amenityIcon(item))
                            .font(.system(size: 16))
                            .foregroundColor(.crPrimary)
                            .frame(width: 20)
                        Text(item)
                            .font(.crBody)
                            .foregroundColor(.crTextSecondary)
                        Spacer()
                    }
                }
            }

            if amenities.count > 6 {
                Button(showAll ? "Ver menos" : "Ver todas as \(amenities.count) comodidades") {
                    withAnimation { showAll.toggle() }
                }
                .font(.crLabel)
                .foregroundColor(.crPrimary)
            }
        }
    }

    private func amenityIcon(_ name: String) -> String {
        let map: [String: String] = [
            "Wi-Fi": "wifi",
            "Estacionamento": "car.fill",
            "Ar-condicionado": "air.conditioner.horizontal.fill",
            "Autoclave": "medical.thermometer",
            "Câmera intraoral": "camera.fill"
        ]
        return map[name] ?? "checkmark.circle"
    }
}

// MARK: - Reviews Section
struct ReviewsSection: View {
    let reviews: [Review]
    let rating: Double
    let reviewCount: Int
    @Binding var showAll: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.md) {
            HStack {
                Image(systemName: "star.fill").foregroundColor(.crWarning)
                Text(String(format: "%.1f", rating)).font(.crH4)
                Text("· \(reviewCount) avaliações").font(.crBody).foregroundColor(.crTextSecondary)
            }

            ForEach(showAll ? reviews : Array(reviews.prefix(2))) { review in
                ReviewRow(review: review)
            }

            if reviews.count > 2 {
                Button("Ver todas as \(reviewCount) avaliações") {
                    withAnimation { showAll.toggle() }
                }
                .font(.crLabel).foregroundColor(.crPrimary)
            }
        }
    }
}

struct ReviewRow: View {
    let review: Review
    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            HStack(spacing: CRSpacing.sm) {
                Circle()
                    .fill(Color.crPrimary.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(review.authorName.prefix(2)))
                            .font(.crLabelSmall)
                            .foregroundColor(.crPrimary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.authorName).font(.crLabel)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < Int(review.rating) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.crWarning)
                        }
                    }
                }
                Spacer()
                Text(review.createdAt, style: .date)
                    .font(.crCaption)
                    .foregroundColor(.crTextTertiary)
            }
            Text(review.comment)
                .font(.crBody)
                .foregroundColor(.crTextSecondary)
                .lineSpacing(3)
        }
        .padding(CRSpacing.md)
        .background(Color.crBackground)
        .cornerRadius(CRRadius.md)
    }
}

// MARK: - Host Summary
struct HostSummaryCard: View {
    let listing: Listing
    let onViewProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.md) {
            Text("Conheça o anfitrião")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)

            HStack(spacing: CRSpacing.base) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.crPrimary.opacity(0.2))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Text(String(listing.ownerName.prefix(1)))
                                .font(.crH2)
                                .foregroundColor(.crPrimary)
                        )
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.crPrimary)
                        .background(Color.white.clipShape(Circle()))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.ownerName).font(.crH4)
                    if let pid = listing.ownerProfessionalId {
                        Text(pid).font(.crBodySmall).foregroundColor(.crTextTertiary)
                    }
                    HStack(spacing: CRSpacing.lg) {
                        StatItem(value: "4.9", label: "Avaliação")
                        StatItem(value: "24", label: "Aluguéis")
                        StatItem(value: "2", label: "Anos")
                    }
                }
                Spacer()
            }

            CRButton(title: "Ver perfil do anfitrião", variant: .outline) {
                onViewProfile()
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.crH4).foregroundColor(.crTextPrimary)
            Text(label).font(.crCaption).foregroundColor(.crTextTertiary)
        }
    }
}
