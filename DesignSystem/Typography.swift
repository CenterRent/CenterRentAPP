import SwiftUI

// MARK: - Center Rent Typography System
extension Font {
    // Display
    static let crDisplay1  = Font.system(size: 40, weight: .bold,   design: .rounded)
    static let crDisplay2  = Font.system(size: 32, weight: .bold,   design: .rounded)

    // Heading
    static let crH1        = Font.system(size: 28, weight: .bold,   design: .rounded)
    static let crH2        = Font.system(size: 24, weight: .bold,   design: .rounded)
    static let crH3        = Font.system(size: 20, weight: .semibold,design: .rounded)
    static let crH4        = Font.system(size: 18, weight: .semibold,design: .rounded)

    // Body
    static let crBodyLarge  = Font.system(size: 16, weight: .regular, design: .rounded)
    static let crBody       = Font.system(size: 14, weight: .regular, design: .rounded)
    static let crBodySmall  = Font.system(size: 12, weight: .regular, design: .rounded)

    // Label / Caption
    static let crLabelLarge = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let crLabel      = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let crLabelSmall = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let crCaption    = Font.system(size: 11, weight: .regular,  design: .rounded)

    // Price
    static let crPriceLarge = Font.system(size: 22, weight: .bold,   design: .rounded)
    static let crPrice      = Font.system(size: 18, weight: .bold,   design: .rounded)
    static let crPriceSmall = Font.system(size: 14, weight: .bold,   design: .rounded)

    // Button
    static let crButtonLarge = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let crButton      = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let crButtonSmall = Font.system(size: 13, weight: .semibold, design: .rounded)
}

// MARK: - Text Style Modifiers
struct CRTextStyle: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    init(font: Font, color: Color = .crTextPrimary, lineSpacing: CGFloat = 0) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .lineSpacing(lineSpacing)
    }
}

extension View {
    func crTextStyle(_ font: Font, color: Color = .crTextPrimary, lineSpacing: CGFloat = 0) -> some View {
        modifier(CRTextStyle(font: font, color: color, lineSpacing: lineSpacing))
    }
}
