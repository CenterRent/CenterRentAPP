import SwiftUI
import Combine

// MARK: - Typography Tokens
// Sistema tipográfico baseado em SF Pro (nativo iOS) com escala Minor Third (1.2)
// ⚠️ Substituir por tokens do Celvra DS quando disponíveis

public struct CRTypography {

    // MARK: - Font Families
    public struct FontFamily {
        public static let display   = "SF Pro Display"
        public static let text      = "SF Pro Text"
        public static let rounded   = "SF Pro Rounded"
        public static let mono      = "SF Mono"
    }

    // MARK: - Font Sizes (escala Minor Third 1.200)
    public struct FontSize {
        public static let xs    : CGFloat = 10
        public static let sm    : CGFloat = 12
        public static let base  : CGFloat = 14
        public static let md    : CGFloat = 16
        public static let lg    : CGFloat = 18
        public static let xl    : CGFloat = 20
        public static let xl2   : CGFloat = 24
        public static let xl3   : CGFloat = 28
        public static let xl4   : CGFloat = 32
        public static let xl5   : CGFloat = 36
        public static let xl6   : CGFloat = 48
        public static let xl7   : CGFloat = 56
    }

    // MARK: - Font Weights
    public struct FontWeight {
        public static let regular   : Font.Weight = .regular
        public static let medium    : Font.Weight = .medium
        public static let semibold  : Font.Weight = .semibold
        public static let bold      : Font.Weight = .bold
        public static let heavy     : Font.Weight = .heavy
    }

    // MARK: - Line Heights
    public struct LineHeight {
        public static let tight     : CGFloat = 1.2
        public static let snug      : CGFloat = 1.375
        public static let normal    : CGFloat = 1.5
        public static let relaxed   : CGFloat = 1.625
        public static let loose     : CGFloat = 2.0
    }

    // MARK: - Letter Spacing
    public struct LetterSpacing {
        public static let tighter   : CGFloat = -0.05
        public static let tight     : CGFloat = -0.025
        public static let normal    : CGFloat = 0
        public static let wide      : CGFloat = 0.025
        public static let wider     : CGFloat = 0.05
        public static let widest    : CGFloat = 0.1
    }
}

// MARK: - Text Style Presets
public extension Font {

    // MARK: Display
    static var crDisplayXL   : Font { .system(size: CRTypography.FontSize.xl6, weight: .bold,     design: .default) }
    static var crDisplayLG   : Font { .system(size: CRTypography.FontSize.xl5, weight: .bold,     design: .default) }
    static var crDisplayMD   : Font { .system(size: CRTypography.FontSize.xl4, weight: .bold,     design: .default) }
    static var crDisplaySM   : Font { .system(size: CRTypography.FontSize.xl3, weight: .semibold, design: .default) }

    // MARK: Heading
    static var crHeading1    : Font { .system(size: CRTypography.FontSize.xl3, weight: .bold,     design: .default) }
    static var crHeading2    : Font { .system(size: CRTypography.FontSize.xl2, weight: .bold,     design: .default) }
    static var crHeading3    : Font { .system(size: CRTypography.FontSize.xl,  weight: .semibold, design: .default) }
    static var crHeading4    : Font { .system(size: CRTypography.FontSize.lg,  weight: .semibold, design: .default) }
    static var crHeading5    : Font { .system(size: CRTypography.FontSize.md,  weight: .semibold, design: .default) }
    static var crHeading6    : Font { .system(size: CRTypography.FontSize.base,weight: .semibold, design: .default) }

    // MARK: Body
    static var crBodyLG      : Font { .system(size: CRTypography.FontSize.lg,  weight: .regular,  design: .default) }
    static var crBodyMD      : Font { .system(size: CRTypography.FontSize.md,  weight: .regular,  design: .default) }
    static var crBodyBase    : Font { .system(size: CRTypography.FontSize.base,weight: .regular,  design: .default) }
    static var crBodySM      : Font { .system(size: CRTypography.FontSize.sm,  weight: .regular,  design: .default) }

    // MARK: Label
    static var crLabelLG     : Font { .system(size: CRTypography.FontSize.md,  weight: .medium,   design: .default) }
    static var crLabelMD     : Font { .system(size: CRTypography.FontSize.base,weight: .medium,   design: .default) }
    static var crLabelSM     : Font { .system(size: CRTypography.FontSize.sm,  weight: .medium,   design: .default) }
    static var crLabelXS     : Font { .system(size: CRTypography.FontSize.xs,  weight: .medium,   design: .default) }

    // MARK: Caption
    static var crCaptionMD   : Font { .system(size: CRTypography.FontSize.sm,  weight: .regular,  design: .default) }
    static var crCaptionSM   : Font { .system(size: CRTypography.FontSize.xs,  weight: .regular,  design: .default) }

    // MARK: Button
    static var crButtonLG    : Font { .system(size: CRTypography.FontSize.md,  weight: .semibold, design: .default) }
    static var crButtonMD    : Font { .system(size: CRTypography.FontSize.base,weight: .semibold, design: .default) }
    static var crButtonSM    : Font { .system(size: CRTypography.FontSize.sm,  weight: .semibold, design: .default) }

    // MARK: Overline / Tag
    static var crOverline    : Font { .system(size: CRTypography.FontSize.xs,  weight: .semibold, design: .default) }
    static var crTag         : Font { .system(size: CRTypography.FontSize.xs,  weight: .medium,   design: .default) }
}
