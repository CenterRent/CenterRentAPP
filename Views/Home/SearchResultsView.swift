import SwiftUI

// MARK: - SearchResultsView (UX 15 — sem botão xmark, apenas chevron.left estilo Apple)
struct SearchResultsView: View {
    @EnvironmentObject var vm: HomeViewModel
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var localSearch = ""

    var body: some View {
        VStack(spacing: 0) {
            // ── Header com botão voltar Apple + campo de busca ──
            HStack(spacing: CRSpacing.md) {
                // Botão voltar estilo Apple (chevron.left + label "Voltar")
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Voltar")
                            .font(.crBody)
                    }
                    .foregroundColor(.crPrimary)
                    .frame(height: 48)
                }

                // Campo de busca
                HStack(spacing: CRSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.crPrimary)
                        .font(.system(size: 16))

                    TextField("O que você busca hoje?", text: $localSearch)
                        .font(.crBodyLarge)
                        .focused($isSearchFocused)
                        .onChange(of: localSearch) { vm.search(query: $0) }

                    // Limpar campo — apenas o X dentro do campo, não botão externo
                    if !localSearch.isEmpty {
                        Button {
                            localSearch = ""
                            vm.search(query: "")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.crTextTertiary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.base)
                .frame(height: 48)
                .background(Color.crBackground)
                .cornerRadius(CRRadius.pill)

                // Filtros
                Button {
                    vm.showFilters = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundColor(.crPrimary)
                        .frame(width: 48, height: 48)
                        .background(Color.crPrimary.opacity(0.1))
                        .cornerRadius(CRRadius.md)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
            .background(Color.white)

            Divider()

            // ── Conteúdo ──
            if vm.isSearching {
                Spacer()
                ProgressView().tint(.crPrimary)
                Spacer()
            } else if !localSearch.isEmpty && vm.searchResults.isEmpty {
                EmptySearchView(query: localSearch)
            } else {
                let listings = localSearch.isEmpty ? vm.nearbyListings : vm.searchResults

                ScrollView {
                    VStack(alignment: .leading, spacing: CRSpacing.base) {
                        // Contagem e filtro
                        HStack {
                            Text("\(listings.count) resultado\(listings.count != 1 ? "s" : "") encontrado\(listings.count != 1 ? "s" : "")")
                                .font(.crLabel).foregroundColor(.crTextPrimary)
                            Spacer()
                            Button {
                                vm.showFilters = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "slider.horizontal.3").font(.system(size: 14))
                                    Text("Filtros")
                                }
                                .font(.crLabelSmall)
                                .foregroundColor(.crPrimary)
                            }
                        }
                        .padding(.horizontal, CRSpacing.base)
                        .padding(.top, CRSpacing.base)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: CRSpacing.md
                        ) {
                            ForEach(listings) { listing in
                                CRListingCard(
                                    listing: listing,
                                    onFavorite: { vm.toggleFavorite(listing) },
                                    onRent: { router.push(.booking(listing)); dismiss() }
                                )
                                .onTapGesture {
                                    router.push(.listingDetail(listing)); dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, CRSpacing.base)
                        .padding(.bottom, CRSpacing.xxxl)
                    }
                }
            }
        }
        .background(Color.crBackground)
        .sheet(isPresented: $vm.showFilters) {
            FilterView(vm: vm)
        }
        .onAppear { isSearchFocused = true }
    }
}

// MARK: - Empty Search State
struct EmptySearchView: View {
    let query: String

    var body: some View {
        VStack(spacing: CRSpacing.xl) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.crDivider)
            VStack(spacing: CRSpacing.sm) {
                Text("Nenhum resultado para")
                    .font(.crH4).foregroundColor(.crTextSecondary)
                Text(""\(query)"")
                    .font(.crH3).foregroundColor(.crTextPrimary)
            }
            Text("Tente buscar por categoria, cidade ou tipo de equipamento.")
                .font(.crBody)
                .foregroundColor(.crTextTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(CRSpacing.xl)
    }
}
