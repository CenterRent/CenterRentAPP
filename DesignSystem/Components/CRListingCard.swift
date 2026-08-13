import SwiftUI

// MARK: - CRListingCard
// CRO-optimised card: dominant image → trust signals → price → CTA
// Conversion principles applied:
//  • Social proof: star rating + review count visible at first glance
//  • Price clarity: single clear price label (prioritises daily, falls back to hourly)
//  • Trust: verified badge + category pill
//  • Scarcity: "X reservas" (bookings count) as subtle social proof
//  • CTA: high-contrast "Alugar Agora" — always visible, never buried

struct CRListingCard: View {
    let listing: Listing
    var onTap: (() -> Void)? = nil
    var onFavorite: (() -> Void)? = nil
    var onRent: (() -> Void)? = nil

    // Layout variant
    var isCompact: Bool = false   // true = horizontal scroll (smaller)

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                infoSection
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Image Section
    private var imageSection: some View {
        ZStack(alignment: .bottom) {
            // Main photo — CRRemoteImage handles nil URL, auth fallback e placeholder
            CRRemoteImage(urlString: listing.imageURL, scaledToFill: true)
                .frame(height: isCompact ? 130 : 160)
                .clipped()

            // Bottom gradient — ensures price & info strip is readable
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.25)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Top row: category badge + favourite
            VStack {
                HStack(alignment: .top) {
                    // Category pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(categoryColor)
                            .frame(width: 7, height: 7)
                        Text(listing.categoryName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.38))
                    .clipShape(Capsule())

                    Spacer()

                    // Favourite button
                    Button(action: { onFavorite?() }) {
                        Image(systemName: listing.isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(listing.isFavorited ? Color(hex: "#FF4D6D") : .white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.28))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(10)

            // Rating chip (bottom-left, on gradient)
            HStack {
                ratingChip
                Spacer()
                if listing.isVerifiedOwner {
                    verifiedBadge
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }

    private var ratingChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "#FFB800"))
            Text(String(format: "%.1f", listing.rating))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            if listing.reviewCount > 0 {
                Text("(\(listing.reviewCount))")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.38))
        .clipShape(Capsule())
    }

    private var verifiedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#4ECDC4"))
            Text("Verificado")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.30))
        .clipShape(Capsule())
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(listing.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#1A1A2E"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Address
            if let addr = listing.shortAddress {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(CRColor.Primary.default)
                    Text(addr)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(1)
                }
            }

            // Price + CTA
            HStack(alignment: .center) {
                // Price block
                VStack(alignment: .leading, spacing: 1) {
                    Text(priceLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(priceFormatted)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(CRColor.Primary.default)
                        Text(priceSuffix)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(CRColor.Primary.light)
                    }
                }

                Spacer()

                // CTA
                Button(action: { onRent?() ?? onTap?() }) {
                    Text("Alugar Agora")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(CRColor.Primary.default)
                        .clipShape(Capsule())
                }
            }

            // Social proof — only show when meaningful
            if listing.totalBookings > 0 {
                Text("\(listing.totalBookings) reservas realizadas")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
        }
        .padding(14)
    }

    // MARK: - Helpers
    private var categoryColor: Color { listing.categoryColor }

    private var priceLabel: String {
        listing.pricePerDay != nil ? "Diária a partir de" : "Hora a partir de"
    }
    private var priceFormatted: String {
        let value = listing.pricePerDay ?? listing.pricePerHour
        return "R$ \(Int(value))"
    }
    private var priceSuffix: String {
        listing.pricePerDay != nil ? "/ dia" : "/ hora"
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
