import SwiftUI

// MARK: - Banner Model (Cloudinary-ready)
struct HomeBanner: Identifiable {
    let id = UUID()
    let imageURL: String       // URL Cloudinary
    let title: String
    let subtitle: String
    let actionLabel: String
    var action: () -> Void = {}
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var showSearch = false
    @State private var showMenu = false

    // Banners prontos para receber URLs do Cloudinary (VISUAL 8)
    let banners: [HomeBanner] = [
        HomeBanner(
            imageURL: "https://res.cloudinary.com/dcmwfymws/image/upload/v1/banners/banner_home_1.webp",
            title: "Salas para profissionais de saúde",
            subtitle: "Alugue por hora, dia ou semana",
            actionLabel: "Explorar"
        ),
        HomeBanner(
            imageURL: "https://res.cloudinary.com/dcmwfymws/image/upload/v1/banners/banner_home_2.webp",
            title: "Equipamentos odontológicos",
            subtitle: "Disponíveis perto de você",
            actionLabel: "Ver mais"
        ),
        HomeBanner(
            imageURL: "https://res.cloudinary.com/dcmwfymws/image/upload/v1/banners/banner_home_3.webp",
            title: "Indique e ganhe",
            subtitle: "Programa de recompensas Center Rent",
            actionLabel: "Participar"
        )
    ]

    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Header com formas geométricas (VISUAL 9)
                    HomeHeaderView(searchText: $vm.searchText, onSearch: {
                        showSearch = true
                    }, onMenu: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenu = true
                        }
                    })

                    // Content — card branco com cantos arredondados no topo
                    VStack(spacing: 0) {
                        // Espaçamento 24px entre search area e categorias (VISUAL 7)
                        Spacer().frame(height: 24)

                        // Banners Cloudinary (VISUAL 8)
                        HomeBannersSection(banners: banners)
                            .padding(.bottom, CRSpacing.xl)

                        // Categorias
                        if !vm.categories.isEmpty {
                            CategoryGridSection(categories: vm.categories) { cat in
                                vm.selectedCategory = cat
                                router.push(.categoryDetail(cat))
                            }
                            .padding(.bottom, CRSpacing.xl)
                        }

                        // Listings próximos
                        if !vm.nearbyListings.isEmpty {
                            NearbyListingsSection(listings: vm.nearbyListings) { listing in
                                router.push(.listingDetail(listing))
                            } onFavorite: { listing in
                                vm.toggleFavorite(listing)
                            } onRent: { listing in
                                router.push(.booking(listing))
                            }
                        }

                        Spacer().frame(height: CRSpacing.xxxl)
                    }
                    .background(Color.crBackground)
                    .cornerRadius(CRRadius.xl, corners: [.topLeft, .topRight])
                    .offset(y: -24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .background(Color.crBackground)
            .fullScreenCover(isPresented: $showSearch) {
                SearchResultsView()
                    .environmentObject(vm)
                    .environmentObject(router)
            }
            .refreshable { await vm.loadData() }

            // Burger menu overlay (será implementado no FEATURE 11)
            if showMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenu = false
                        }
                    }

                SideMenuView(isShowing: $showMenu)
                    .environmentObject(router)
                    .transition(.move(edge: .leading))
            }
        }
    }
}

// MARK: - Header com formas geométricas (VISUAL 9)
struct HomeHeaderView: View {
    @Binding var searchText: String
    let onSearch: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Fundo com formas geométricas no estilo protótipo
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                // Base de cor primária
                Color.crPrimary
                    .ignoresSafeArea()

                // Forma 1 — círculo grande superior direito
                Circle()
                    .fill(Color.crSecondary.opacity(0.55))
                    .frame(width: w * 0.7)
                    .offset(x: w * 0.45, y: -h * 0.2)

                // Forma 2 — círculo médio superior esquerdo
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: w * 0.45)
                    .offset(x: -w * 0.1, y: -h * 0.1)

                // Forma 3 — elipse inferior (cria transição suave)
                Ellipse()
                    .fill(Color.crAccentOrange.opacity(0.3))
                    .frame(width: w * 0.5, height: h * 0.4)
                    .offset(x: w * 0.55, y: h * 0.5)

                // Forma 4 — retângulo diagonal (detalhe geométrico)
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: w * 0.4, height: w * 0.4)
                    .rotationEffect(.degrees(30))
                    .offset(x: w * 0.1, y: h * 0.3)
            }
            .frame(height: 200)
            .clipped()
            .ignoresSafeArea()

            // Saudação + Search bar
            VStack(alignment: .leading, spacing: CRSpacing.md) {
                // Saudação
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Olá, profissional 👋")
                            .font(.crBodySmall)
                            .foregroundColor(.white.opacity(0.85))
                        Text("O que você busca hoje?")
                            .font(.crH4)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // Botão menu (burger)
                    Button(action: onMenu) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 40, height: 40)
                            VStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white)
                                        .frame(width: 18, height: 2)
                                }
                            }
                        }
                    }
                }

                // Search bar
                Button(action: onSearch) {
                    HStack(spacing: CRSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.crTextTertiary)
                        Text("Buscar salas, equipamentos...")
                            .font(.crBody)
                            .foregroundColor(.crTextTertiary)
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14))
                            .foregroundColor(.crPrimary)
                    }
                    .padding(.horizontal, CRSpacing.base)
                    .frame(height: 48)
                    .background(Color.white)
                    .cornerRadius(CRRadius.pill)
                    .crShadowSoft()
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.bottom, CRSpacing.xxl + 24) // extra para sobreposição com o card
        }
        .frame(height: 200)
    }
}

// MARK: - Banners Cloudinary (VISUAL 8)
struct HomeBannersSection: View {
    let banners: [HomeBanner]
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: CRSpacing.sm) {
            TabView(selection: $currentIndex) {
                ForEach(banners.indices, id: \.self) { i in
                    BannerCard(banner: banners[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 160)
            .padding(.horizontal, CRSpacing.base)

            // Indicador de página
            HStack(spacing: 6) {
                ForEach(banners.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == currentIndex ? Color.crPrimary : Color.crDivider)
                        .frame(width: i == currentIndex ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3), value: currentIndex)
                }
            }
        }
    }
}

struct BannerCard: View {
    let banner: HomeBanner

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Imagem do Cloudinary
            AsyncImage(url: URL(string: banner.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    // Placeholder com gradiente enquanto carrega
                    LinearGradient(
                        colors: [Color.crPrimary, Color.crSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                @unknown default:
                    Color.crSkeleton
                }
            }
            .clipped()

            // Overlay escuro no rodapé para o texto
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Texto
            VStack(alignment: .leading, spacing: 4) {
                Text(banner.title)
                    .font(.crH4)
                    .foregroundColor(.white)
                    .lineLimit(2)
                HStack {
                    Text(banner.subtitle)
                        .font(.crBodySmall)
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Button(action: banner.action) {
                        Text(banner.actionLabel)
                            .font(.crLabelSmall)
                            .foregroundColor(.crPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(CRRadius.pill)
                    }
                }
            }
            .padding(CRSpacing.md)
        }
        .cornerRadius(CRRadius.xl)
        .crShadowCard()
    }
}

// MARK: - Category Grid
struct CategoryGridSection: View {
    let categories: [Category]
    let onSelect: (Category) -> Void

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.base) {
            Text("Categorias")
                .font(.crH4)
                .foregroundColor(.crTextPrimary)
                .padding(.horizontal, CRSpacing.base)

            LazyVGrid(columns: columns, spacing: CRSpacing.sm) {
                ForEach(categories) { cat in
                    CategoryCard(category: cat) { onSelect(cat) }
                }
            }
            .padding(.horizontal, CRSpacing.base)
        }
    }
}

struct CategoryCard: View {
    let category: Category
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: CRRadius.lg)
                    .fill(category.color)
                    .frame(height: 90)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                            .offset(x: 40, y: -10)
                    )
                    .clipped()

                Text(category.name)
                    .font(.crLabel)
                    .foregroundColor(.white)
                    .padding(CRSpacing.sm)
            }
        }
        .buttonStyle(CRPressStyle())
    }
}

// MARK: - Nearby Listings
struct NearbyListingsSection: View {
    let listings: [Listing]
    let onSelect: (Listing) -> Void
    let onFavorite: (Listing) -> Void
    let onRent: (Listing) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.base) {
            HStack {
                Text("Próximos a você")
                    .font(.crH4).foregroundColor(.crTextPrimary)
                HStack(spacing: 4) {
                    Circle().fill(Color.crAccentOrange).frame(width: 8, height: 8)
                    Text("SP").font(.crLabelSmall).foregroundColor(.crAccentOrange)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.crAccentOrange.opacity(0.1)).cornerRadius(CRRadius.pill)
                Spacer()
                Button("Ver todos") { }
                    .font(.crLabel).foregroundColor(.crPrimary)
            }
            .padding(.horizontal, CRSpacing.base)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CRSpacing.md) {
                ForEach(listings) { listing in
                    CRListingCard(
                        listing: listing,
                        onFavorite: { onFavorite(listing) },
                        onRent: { onRent(listing) }
                    )
                    .onTapGesture { onSelect(listing) }
                }
            }
            .padding(.horizontal, CRSpacing.base)
        }
    }
}
