import SwiftUI

struct CategoryDetailView: View {
    let category: Category
    @EnvironmentObject var router: AppRouter
    @StateObject private var homeVM = HomeViewModel()
    @State private var listings: [Listing] = []
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            // Hero banner
            ZStack(alignment: .bottomLeading) {
                category.color.ignoresSafeArea(edges: .top)
                    .frame(height: 160)
                    .overlay(
                        Circle().fill(Color.white.opacity(0.15)).frame(width: 200).offset(x: 120, y: 30)
                    )
                    .overlay(
                        Circle().fill(Color.white.opacity(0.1)).frame(width: 130).offset(x: 200, y: -20)
                    )

                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, CRSpacing.base)
                .padding(.bottom, CRSpacing.base)

                Text(category.name)
                    .font(.crDisplay2)
                    .foregroundColor(.white)
                    .padding(.horizontal, CRSpacing.xl)
                    .padding(.bottom, CRSpacing.xl)
            }
            .frame(height: 160)

            // Listings
            VStack(alignment: .leading, spacing: CRSpacing.base) {
                HStack {
                    Text("Veja os itens dessa categoria")
                        .font(.crH4).foregroundColor(.crTextPrimary)
                    Spacer()
                    Button {
                        router.push(.search)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(.crPrimary)
                    }
                }
                .padding(.horizontal, CRSpacing.base)
                .padding(.top, CRSpacing.lg)
            }

            if isLoading {
                Spacer()
                ProgressView().tint(.crPrimary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: CRSpacing.md) {
                        ForEach(listings) { listing in
                            CRListingCard(
                                listing: listing,
                                onFavorite: { homeVM.toggleFavorite(listing) },
                                onRent: { router.push(.booking(listing)) }
                            )
                            .onTapGesture { router.push(.listingDetail(listing)) }
                        }
                    }
                    .padding(.horizontal, CRSpacing.base)
                    .padding(.bottom, CRSpacing.xxxl)
                }
            }
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
        .task {
            listings = await homeVM.loadCategoryListings(category)
            if listings.isEmpty {
                listings = Listing.mockList.filter { $0.categoryId == category.id }
                if listings.isEmpty { listings = Listing.mockList }
            }
            isLoading = false
        }
    }
}
