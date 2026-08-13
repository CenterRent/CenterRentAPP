import SwiftUI
import Combine
import MapKit

// MARK: - Search View
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var viewMode: ViewMode = .list
    @State private var showFilters = false
    @FocusState private var searchFocused: Bool

    enum ViewMode { case list, map }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar Header
            searchHeader

            // Active Filters Summary
            if vm.filter.isActive {
                activeFiltersBanner
            }

            // View Toggle
            viewToggle

            // Content
            ZStack {
                if viewMode == .list {
                    listView
                } else {
                    mapView
                }
            }
        }
        .background(CRColor.Background.secondary.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showFilters) {
            FilterView(filter: vm.filter)
                .onDisappear { Task { await vm.applyFilter(vm.filter) } }
        }
    }

    // MARK: - Header
    private var searchHeader: some View {
        VStack(spacing: CRSpacing.s3) {
            HStack(spacing: CRSpacing.s3) {
                HStack(spacing: CRSpacing.s2) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: CRSize.iconMD))
                        .foregroundColor(searchFocused ? CRColor.Primary.default : CRColor.Icon.secondary)
                    TextField("Cidade, bairro ou especialidade...", text: $vm.searchText)
                        .font(.crBodyBase)
                        .foregroundColor(CRColor.Text.primary)
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await vm.search() } }
                    if !vm.searchText.isEmpty {
                        Button(action: { vm.searchText = ""; Task { await vm.clearSearch() } }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(CRColor.Icon.secondary)
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.s4)
                .frame(height: CRSize.inputMD)
                .background(CRColor.Surface.primary)
                .cornerRadius(CRRadius.full)
                .crShadow(CRShadow.xs)
                .animation(CRAnimation.easeNormal, value: searchFocused)

                Button(action: { showFilters = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle\(vm.filter.isActive ? ".fill" : "")")
                            .font(.system(size: 28))
                            .foregroundColor(vm.filter.isActive ? CRColor.Primary.default : CRColor.Icon.primary)
                        if vm.filter.isActive {
                            Circle().fill(CRColor.Feedback.error).frame(width: 8, height: 8).offset(x: 2, y: -2)
                        }
                    }
                }
            }

            // Suggestions (quando focado e sem resultados)
            if searchFocused && vm.searchText.isEmpty {
                searchSuggestions
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, CRSpacing.s3)
        .background(CRColor.Background.primary)
    }

    // MARK: - Suggestions
    private var searchSuggestions: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s2) {
            Text("Buscas recentes").font(.crLabelSM).foregroundColor(CRColor.Text.tertiary)
            ForEach(vm.recentSearches, id: \.self) { term in
                Button(action: {
                    vm.searchText = term
                    searchFocused = false
                    Task { await vm.search() }
                }) {
                    HStack(spacing: CRSpacing.s2) {
                        Image(systemName: "clock")
                            .font(.system(size: CRSize.iconSM))
                            .foregroundColor(CRColor.Icon.secondary)
                        Text(term).font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundColor(CRColor.Icon.secondary)
                    }
                }
            }
            Text("Especialidades populares").font(.crLabelSM).foregroundColor(CRColor.Text.tertiary)
                .padding(.top, CRSpacing.s2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CRSpacing.s2) {
                    ForEach(["Implantodontia", "Ortodontia", "Clínica Geral", "Endodontia"], id: \.self) { spec in
                        Button(action: {
                            vm.searchText = spec
                            searchFocused = false
                            Task { await vm.search() }
                        }) {
                            Text(spec)
                                .font(.crLabelSM)
                                .foregroundColor(CRColor.Primary.default)
                                .padding(.horizontal, CRSpacing.s3)
                                .padding(.vertical, CRSpacing.s2)
                                .background(CRColor.Primary.lighter)
                                .cornerRadius(CRRadius.full)
                        }
                    }
                }
            }
        }
        .padding(CRSpacing.s3)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
        .crShadow(CRShadow.md)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Active Filters
    private var activeFiltersBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CRSpacing.s2) {
                if !vm.filter.city.isEmpty {
                    FilterChip(label: vm.filter.city) { vm.filter.city = ""; Task { await vm.search() } }
                }
                if let min = vm.filter.minPrice {
                    FilterChip(label: "De R$ \(Int(min))") { vm.filter.minPrice = nil; Task { await vm.search() } }
                }
                if let max = vm.filter.maxPrice {
                    FilterChip(label: "Até R$ \(Int(max))") { vm.filter.maxPrice = nil; Task { await vm.search() } }
                }
                ForEach(vm.filter.specialties, id: \.self) { spec in
                    FilterChip(label: spec) {
                        vm.filter.specialties.removeAll { $0 == spec }
                        Task { await vm.search() }
                    }
                }
                if vm.filter.onlyVerified {
                    FilterChip(label: "Verificados") { vm.filter.onlyVerified = false; Task { await vm.search() } }
                }
                Button(action: { vm.filter = ListingFilter(); Task { await vm.search() } }) {
                    Text("Limpar tudo").font(.crLabelSM).foregroundColor(CRColor.Feedback.error)
                        .padding(.horizontal, CRSpacing.s3).padding(.vertical, CRSpacing.s2)
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
        }
        .padding(.vertical, CRSpacing.s2)
        .background(CRColor.Background.primary)
    }

    // MARK: - View Toggle
    private var viewToggle: some View {
        HStack {
            Text(vm.isLoading ? "Buscando..." : "\(vm.results.count) espaços encontrados")
                .font(.crBodySM).foregroundColor(CRColor.Text.secondary)
            Spacer()
            // Sort Picker
            Menu {
                ForEach(ListingFilter.SortOption.allCases, id: \.self) { opt in
                    Button(action: { vm.filter.sortBy = opt; Task { await vm.search() } }) {
                        Label(opt.rawValue, systemImage: vm.filter.sortBy == opt ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: CRSpacing.s1) {
                    Text(vm.filter.sortBy.rawValue).font(.crLabelSM).foregroundColor(CRColor.Text.secondary)
                    Image(systemName: "chevron.down").font(.system(size: 10)).foregroundColor(CRColor.Icon.secondary)
                }
            }
            Divider().frame(height: 16).padding(.horizontal, CRSpacing.s2)
            HStack(spacing: CRSpacing.s2) {
                Button(action: { withAnimation { viewMode = .list } }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(viewMode == .list ? CRColor.Primary.default : CRColor.Icon.secondary)
                }
                Button(action: { withAnimation { viewMode = .map } }) {
                    Image(systemName: "map")
                        .foregroundColor(viewMode == .map ? CRColor.Primary.default : CRColor.Icon.secondary)
                }
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, CRSpacing.s3)
        .background(CRColor.Background.primary)
    }

    // MARK: - List View
    private var listView: some View {
        Group {
            if vm.isLoading {
                LazyVStack(spacing: CRSpacing.componentGap) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: CRRadius.card)
                            .fill(CRColor.Neutral.n200).frame(height: 300)
                            .shimmer().padding(.horizontal, CRSpacing.screenHorizontal)
                    }
                }
                .padding(.top, CRSpacing.s4)
            } else if vm.results.isEmpty {
                emptyResults
            } else {
                ScrollView {
                    LazyVStack(spacing: CRSpacing.componentGap) {
                        ForEach(vm.results) { listing in
                            CRListingCard(
                                listing: listing,
                                onTap: { router.navigate(to: .listingDetail(listingId: listing.id)) },
                                onFavorite: {}
                            )
                            .padding(.horizontal, CRSpacing.screenHorizontal)
                            .onAppear {
                                if listing.id == vm.results.last?.id {
                                    Task { await vm.loadMore() }
                                }
                            }
                        }
                        if vm.isLoadingMore { ProgressView().padding() }
                    }
                    .padding(.vertical, CRSpacing.s4)
                }
            }
        }
    }

    // MARK: - Map View
    private var mapView: some View {
        let annotations = vm.results.compactMap { listing -> MapAnnotationItem? in
            if let lat = listing.address.latitude, let lng = listing.address.longitude {
                return MapAnnotationItem(
                    id: listing.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    price: Int(listing.pricePerHour)
                )
            }
            return nil
        }
        return ZStack(alignment: .bottom) {
            Map(position: .constant(.region(vm.mapRegion))) {
                ForEach(annotations) { item in
                    Annotation("", coordinate: item.coordinate) {
                        Button(action: {
                            vm.selectedMapListing = vm.results.first { $0.id == item.id }
                        }) {
                            Text("R$ \(item.price)")
                                .font(.crLabelSM)
                                .foregroundColor(.white)
                                .padding(.horizontal, CRSpacing.s2)
                                .padding(.vertical, CRSpacing.s1)
                                .background(vm.selectedMapListing?.id == item.id
                                            ? CRColor.Primary.dark : CRColor.Primary.default)
                                .cornerRadius(CRRadius.full)
                                .crShadow(CRShadow.md)
                        }
                    }
                }
            }
            if let selected = vm.selectedMapListing {
                CRListingCard(
                    listing: selected,
                    onTap: { router.navigate(to: .listingDetail(listingId: selected.id)) },
                    onFavorite: {}
                )
                .padding(CRSpacing.screenHorizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(CRAnimation.springNormal, value: vm.selectedMapListing?.id)
    }

    // MARK: - Empty State
    private var emptyResults: some View {
        VStack(spacing: CRSpacing.s4) {
            Image(systemName: "magnifyingglass.circle").font(.system(size: 56))
                .foregroundColor(CRColor.Neutral.n300)
            Text("Nenhum resultado").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            Text("Tente buscar por outra cidade ou ajustar os filtros.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            CRButton("Ajustar filtros", variant: .outline, size: .md) { showFilters = true }
        }
        .padding(CRSpacing.s8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.crLabelSM).foregroundColor(CRColor.Primary.default)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
                    .foregroundColor(CRColor.Primary.default)
            }
        }
        .padding(.horizontal, CRSpacing.s3)
        .padding(.vertical, CRSpacing.s2)
        .background(CRColor.Primary.lighter)
        .cornerRadius(CRRadius.full)
    }
}

// MARK: - Map Annotation Item
struct MapAnnotationItem: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let price: Int
}

// MARK: - SearchViewModel
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [Listing] = []
    @Published var filter = ListingFilter()
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333), // São Paulo
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var selectedMapListing: Listing? = nil
    @Published var recentSearches: [String] = ["São Paulo", "Implantodontia", "Moema"]

    private let pageSize = 20
    private var page = 0
    private var hasMore = true

    func search() async {
        isLoading = true; defer { isLoading = false }
        page = 0; hasMore = true
        filter.query = searchText
        saveRecentSearch(searchText)
        results = (try? await SupabaseManager.shared.searchListings(
            query: searchText, filter: filter, limit: pageSize, offset: 0
        )) ?? []
        hasMore = results.count == pageSize
    }

    func loadMore() async {
        guard !isLoadingMore && hasMore else { return }
        isLoadingMore = true; defer { isLoadingMore = false }
        page += 1
        let more = (try? await SupabaseManager.shared.searchListings(
            query: searchText, filter: filter, limit: pageSize, offset: page * pageSize
        )) ?? []
        if more.isEmpty { hasMore = false } else { results.append(contentsOf: more) }
    }

    func clearSearch() async {
        searchText = ""; filter.query = ""; page = 0; hasMore = true
        results = (try? await SupabaseManager.shared.searchListings(
            query: "", filter: filter, limit: pageSize, offset: 0
        )) ?? []
    }

    func applyFilter(_ newFilter: ListingFilter) async {
        filter = newFilter
        await search()
    }

    private func saveRecentSearch(_ term: String) {
        guard !term.isEmpty, !recentSearches.contains(term) else { return }
        recentSearches.insert(term, at: 0)
        if recentSearches.count > 5 { recentSearches.removeLast() }
    }
}
