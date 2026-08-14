import SwiftUI
import Combine

struct MyListingsView: View {
    @StateObject private var vm = MyListingsViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @State private var filter: ListingStatusFilter = .all
    @State private var showCreateListing = false
    @State private var editingListingId: String? = nil

    enum ListingStatusFilter: String, CaseIterable {
        case all = "Todos"
        case active = "Ativos"
        case draft = "Rascunhos"
        case paused = "Pausados"
    }

    var filteredListings: [Listing] {
        switch filter {
        case .all:    return vm.listings
        case .active: return vm.listings.filter { $0.status == .active }
        case .draft:  return vm.listings.filter { $0.status == .draft }
        case .paused: return vm.listings.filter { $0.status == .paused }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CRSpacing.s2) {
                    ForEach(ListingStatusFilter.allCases, id: \.self) { f in
                        Button(action: { withAnimation { filter = f } }) {
                            Text(f.rawValue)
                                .font(.crLabelSM)
                                .foregroundColor(filter == f ? .white : CRColor.Text.secondary)
                                .padding(.horizontal, CRSpacing.s4)
                                .padding(.vertical, CRSpacing.s2)
                                .background(filter == f ? CRColor.Primary.default : CRColor.Surface.primary)
                                .cornerRadius(CRRadius.full)
                                .crShadow(CRShadow.xs)
                        }
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.vertical, CRSpacing.s3)
            }
            .background(CRColor.Background.primary)

            if vm.isLoading {
                loadingView
            } else if filteredListings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: CRSpacing.componentGap) {
                        ForEach(filteredListings) { listing in
                            MyListingCard(listing: listing,
                                onTap: { router.profilePath.append(AppDestination.listingDetail(listingId: listing.id)) },
                                onEdit: { editingListingId = listing.id },
                                onToggle: { vm.toggleStatus(listing) },
                                onDelete: { vm.delete(listing) }
                            )
                            .padding(.horizontal, CRSpacing.screenHorizontal)
                        }
                    }
                    .padding(.vertical, CRSpacing.s4)
                    .padding(.bottom, CRSpacing.s10)
                }
                .background(CRColor.Background.secondary)
            }
        }
        .navigationTitle("Meus Espaços")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateListing = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(CRColor.Primary.default)
                }
            }
        }
        .sheet(isPresented: $showCreateListing) {
            CreateListingView(editingListingId: nil)
                .environmentObject(router)
                .environmentObject(authService)
        }
        .sheet(isPresented: Binding(
            get: { editingListingId != nil },
            set: { if !$0 { editingListingId = nil } }
        )) {
            CreateListingView(editingListingId: editingListingId)
                .environmentObject(router)
                .environmentObject(authService)
        }
        .onAppear {
            Task {
                var uid = authService.currentUser?.id ?? ""
                if uid.isEmpty {
                    uid = (try? await SupabaseManager.shared.client.auth.session.user.id.uuidString) ?? ""
                }
                await vm.load(ownerId: uid)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: CRSpacing.s4) {
            Image(systemName: "building.2.slash").font(.system(size: 56)).foregroundColor(CRColor.Neutral.n300)
            Text("Nenhum anúncio ainda").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            Text("Crie seu primeiro anúncio e comece a receber reservas de colegas dentistas.")
                .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
            CRButton("Criar primeiro anúncio", variant: .primary, size: .lg,
                     icon: "plus", isFullWidth: false) {
                showCreateListing = true
            }
        }
        .padding(CRSpacing.s8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CRColor.Background.secondary)
    }

    private var loadingView: some View {
        LazyVStack(spacing: CRSpacing.componentGap) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: CRRadius.card)
                    .fill(CRColor.Neutral.n200).frame(height: 120)
                    .shimmer().padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
        .padding(.top, CRSpacing.s4)
    }
}

// MARK: - My Listing Card
private struct MyListingCard: View {
    let listing: Listing
    let onTap: () -> Void
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            // Thumbnail
            CRAsyncImage(url: listing.mainImageURL, aspectRatio: 1)
                .frame(width: 80, height: 80).cornerRadius(CRRadius.sm)
                .onTapGesture { onTap() }

            // Info
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                HStack {
                    Text(listing.title).font(.crLabelMD).foregroundColor(CRColor.Text.primary).lineLimit(1)
                    Spacer()
                    listingStatusBadge
                }
                Text("R$ \(Int(listing.pricePerHour))/hora · \(listing.address.shortAddress)")
                    .font(.crBodySM).foregroundColor(CRColor.Text.secondary)
                HStack(spacing: CRSpacing.s3) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill").font(.system(size: 10))
                            .foregroundColor(CRColor.Accent.default)
                        Text(String(format: "%.1f", listing.rating)).font(.crCaptionMD)
                            .foregroundColor(CRColor.Text.secondary)
                    }
                    HStack(spacing: 2) {
                        Image(systemName: "calendar").font(.system(size: 10))
                            .foregroundColor(CRColor.Icon.secondary)
                        Text("\(listing.totalBookings) reservas").font(.crCaptionMD)
                            .foregroundColor(CRColor.Text.secondary)
                    }
                }
            }

            // Actions
            Menu {
                Button(action: onTap) { Label("Visualizar", systemImage: "eye") }
                Button(action: onEdit) { Label("Editar", systemImage: "pencil") }
                Button(action: onToggle) {
                    Label(listing.status == .active ? "Pausar" : "Ativar",
                          systemImage: listing.status == .active ? "pause.circle" : "play.circle")
                }
                Divider()
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    Label("Excluir", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: CRSize.iconLG))
                    .foregroundColor(CRColor.Icon.secondary)
            }
        }
        .padding(CRSpacing.s3)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.card)
        .crShadow(CRShadow.xs)
        .alert("Excluir anúncio?", isPresented: $showDeleteAlert) {
            Button("Excluir", role: .destructive) { onDelete() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var listingStatusBadge: some View {
        let config: (label: String, style: CRBadgeStyle) = {
            switch listing.status {
            case .active:  return ("Ativo", .verified)
            case .draft:   return ("Rascunho", .pending)
            case .paused:  return ("Pausado", .custom(bg: CRColor.Neutral.n100, text: CRColor.Text.secondary))
            case .deleted: return ("Deletado", .rejected)
            }
        }()
        return CRBadge(config.label, style: config.style, size: .sm)
    }
}

// MARK: - MyListingsViewModel
@MainActor
final class MyListingsViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func load(ownerId: String) async {
        guard !ownerId.isEmpty else { return }
        isLoading = true; defer { isLoading = false }
        errorMessage = nil
        do {
            listings = try await SupabaseManager.shared.fetchListings(ownerId: ownerId)
        } catch {
            errorMessage = "Não foi possível carregar seus anúncios."
            listings = []
        }
    }

    func toggleStatus(_ listing: Listing) {
        HapticFeedback.impact(.medium)
        let newStatus: Listing.ListingStatus = listing.status == .active ? .paused : .active
        Task {
            try? await SupabaseManager.shared.updateListingStatus(id: listing.id, status: newStatus)
        }
        if let idx = listings.firstIndex(where: { $0.id == listing.id }) {
            listings[idx].status = newStatus
        }
    }

    func delete(_ listing: Listing) {
        HapticFeedback.error()
        Task { try? await SupabaseManager.shared.deleteListing(id: listing.id) }
        listings.removeAll { $0.id == listing.id }
    }
}
