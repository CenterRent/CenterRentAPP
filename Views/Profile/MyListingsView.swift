import SwiftUI

struct MyListingsView: View {
    @EnvironmentObject var router: AppRouter
    @State private var listings: [Listing] = Listing.mockList
    @State private var selectedFilter: ListingFilter = .active

    enum ListingFilter: String, CaseIterable {
        case active = "Ativos"
        case paused = "Pausados"
        case draft  = "Rascunhos"
    }

    var body: some View {
        VStack(spacing: 0) {
            CRNavigationHeader(
                title: "Meus Anúncios",
                onBack: { router.pop() },
                trailing: AnyView(
                    Button { router.push(.createListing) } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.crPrimary)
                    }
                )
            )

            CRSegmentedControl(
                options: ListingFilter.allCases.map(\.rawValue),
                selected: Binding(get: { selectedFilter.rawValue }, set: { selectedFilter = ListingFilter(rawValue: $0) ?? .active })
            )
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)

            if listings.isEmpty {
                VStack(spacing: CRSpacing.xl) {
                    Spacer()
                    Image(systemName: "building.2").font(.system(size: 64)).foregroundColor(.crDivider)
                    Text("Nenhum anúncio ainda")
                        .font(.crH4).foregroundColor(.crTextSecondary)
                    CRButton(title: "Criar primeiro anúncio", isFullWidth: false) {
                        router.push(.createListing)
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: CRSpacing.md) {
                        ForEach(listings) { listing in
                            MyListingCard(listing: listing, onEdit: {
                                // Navigate to edit
                            }, onToggle: {
                                // Toggle active status
                            })
                        }
                    }
                    .padding(CRSpacing.base)
                    .padding(.bottom, CRSpacing.xxxl)
                }
            }
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
    }
}

struct MyListingCard: View {
    let listing: Listing
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: CRSpacing.md) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: CRRadius.md)
                    .fill(listing.categoryColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(listing.categoryColor)
            }

            VStack(alignment: .leading, spacing: CRSpacing.xs) {
                HStack {
                    Text(listing.title)
                        .font(.crLabel).foregroundColor(.crTextPrimary).lineLimit(1)
                    Spacer()
                    // Status dot
                    Circle()
                        .fill(listing.isActive ? Color.crSuccess : Color.crWarning)
                        .frame(width: 8, height: 8)
                }

                Text(listing.categoryName)
                    .font(.crCaption).foregroundColor(listing.categoryColor)

                Text("R$ \(Int(listing.dailyPrice))/dia")
                    .font(.crPriceSmall).foregroundColor(.crPrimary)

                HStack(spacing: CRSpacing.md) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.crWarning)
                        Text(String(format: "%.1f", listing.rating)).font(.crCaption)
                    }
                    Text("·")
                    Text("\(listing.reviewCount) avaliações").font(.crCaption).foregroundColor(.crTextTertiary)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: CRSpacing.sm) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.crPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.crPrimary.opacity(0.1))
                        .cornerRadius(CRRadius.sm)
                }
                Button(action: onToggle) {
                    Image(systemName: listing.isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.crTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.crDivider)
                        .cornerRadius(CRRadius.sm)
                }
            }
        }
        .padding(CRSpacing.md)
        .background(Color.white)
        .cornerRadius(CRRadius.lg)
        .crShadowSoft()
    }
}
