import SwiftUI

// MARK: - Color Tokens
// Paleta oficial Center Rent — Celvra Design System
// Primary: #7F68C1 (Roxo)  |  Secondary: #DCF289 (Lima)

public struct CRColor {

    // MARK: - Brand Primary (Roxo)
    public struct Primary {
        public static let `default`    = Color(hex: "#7F68C1")
        public static let light        = Color(hex: "#A08FD4")
        public static let lighter      = Color(hex: "#C5BAE8")
        public static let dark         = Color(hex: "#5E4D9A")
        public static let darker       = Color(hex: "#3D3270")
    }

    // MARK: - Brand Secondary (Lima)
    public struct Secondary {
        public static let `default`    = Color(hex: "#DCF289")
        public static let light        = Color(hex: "#E8F7A8")
        public static let lighter      = Color(hex: "#F3FBD0")
        public static let dark         = Color(hex: "#BADA5A")
        public static let darker       = Color(hex: "#93B230")
    }

    // MARK: - Accent
    public struct Accent {
        public static let `default`    = Color(hex: "#7F68C1")
        public static let light        = Color(hex: "#A08FD4")
        public static let dark         = Color(hex: "#5E4D9A")
    }

    // MARK: - Neutral (Grayscale)
    public struct Neutral {
        public static let n0   = Color(hex: "#FFFFFF")
        public static let n50  = Color(hex: "#F8FAFC")
        public static let n100 = Color(hex: "#F1F5F9")
        public static let n200 = Color(hex: "#E2E8F0")
        public static let n300 = Color(hex: "#CBD5E1")
        public static let n400 = Color(hex: "#94A3B8")
        public static let n500 = Color(hex: "#64748B")
        public static let n600 = Color(hex: "#475569")
        public static let n700 = Color(hex: "#334155")
        public static let n800 = Color(hex: "#1E293B")
        public static let n900 = Color(hex: "#0F172A")
    }

    // MARK: - Semantic: Feedback
    public struct Feedback {
        public static let success        = Color(hex: "#16A34A")
        public static let successLight   = Color(hex: "#DCFCE7")
        public static let warning        = Color(hex: "#D97706")
        public static let warningLight   = Color(hex: "#FEF3C7")
        public static let error          = Color(hex: "#DC2626")
        public static let errorLight     = Color(hex: "#FEE2E2")
        public static let info           = Color(hex: "#2563EB")
        public static let infoLight      = Color(hex: "#DBEAFE")
    }

    // MARK: - Semantic: Background
    public struct Background {
        public static let primary        = Color(hex: "#FFFFFF")
        public static let secondary      = Color(hex: "#F8FAFC")
        public static let tertiary       = Color(hex: "#F1F5F9")
        public static let overlay        = Color(hex: "#0F172A").opacity(0.5)
        public static let sheet          = Color(hex: "#FFFFFF")
    }

    // MARK: - Semantic: Surface
    public struct Surface {
        public static let primary        = Color(hex: "#FFFFFF")
        public static let secondary      = Color(hex: "#F8FAFC")
        public static let elevated       = Color(hex: "#FFFFFF")
        public static let pressed        = Color(hex: "#F1F5F9")
    }

    // MARK: - Semantic: Text
    public struct Text {
        public static let primary        = Color(hex: "#0F172A")
        public static let secondary      = Color(hex: "#475569")
        public static let tertiary       = Color(hex: "#94A3B8")
        public static let disabled       = Color(hex: "#CBD5E1")
        public static let onPrimary      = Color(hex: "#FFFFFF")
        public static let onSecondary    = Color(hex: "#FFFFFF")
        public static let link           = Color(hex: "#2E86C1")
        public static let destructive    = Color(hex: "#DC2626")
    }

    // MARK: - Semantic: Border
    public struct Border {
        public static let `default`      = Color(hex: "#E2E8F0")
        public static let strong         = Color(hex: "#CBD5E1")
        public static let focus          = Color(hex: "#1B4F72")
        public static let error          = Color(hex: "#DC2626")
        public static let success        = Color(hex: "#16A34A")
    }

    // MARK: - Semantic: Icon
    public struct Icon {
        public static let primary        = Color(hex: "#0F172A")
        public static let secondary      = Color(hex: "#64748B")
        public static let tertiary       = Color(hex: "#94A3B8")
        public static let onPrimary      = Color(hex: "#FFFFFF")
        public static let accent         = Color(hex: "#1B4F72")
    }

    // MARK: - Lemon Colors (Tailwind-like scale)
    public struct Lemon {
        public static let c50  = Color(hex: "#FEFFF0")
        public static let c100 = Color(hex: "#FEFCE8")
        public static let c200 = Color(hex: "#FEF08A")
        public static let c300 = Color(hex: "#FDE047")
        public static let c400 = Color(hex: "#FACC15")
        public static let c500 = Color(hex: "#EAB308")
        public static let c600 = Color(hex: "#CA8A04")
        public static let c700 = Color(hex: "#A16207")
        public static let c800 = Color(hex: "#854D0E")
        public static let c900 = Color(hex: "#713F12")
    }

    // MARK: - Orange Colors (Tailwind-like scale)
    public struct Orange {
        public static let c50  = Color(hex: "#FFF7ED")
        public static let c100 = Color(hex: "#FFEDD5")
        public static let c200 = Color(hex: "#FED7AA")
        public static let c300 = Color(hex: "#FDBA74")
        public static let c400 = Color(hex: "#FB923C")
        public static let c500 = Color(hex: "#F97316")
        public static let c600 = Color(hex: "#EA580C")
        public static let c700 = Color(hex: "#C2410C")
        public static let c800 = Color(hex: "#9A3412")
        public static let c900 = Color(hex: "#7C2D12")
    }

    // MARK: - Verification Badges
    public struct Badge {
        public static let verified       = Color(hex: "#16A34A")
        public static let pending        = Color(hex: "#D97706")
        public static let rejected       = Color(hex: "#DC2626")
        public static let premium        = Color(hex: "#7C3AED")
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Compatibility Aliases (legacy naming)
    static let crPrimary       = CRColor.Primary.default       // Purple
    static let crSecondary     = CRColor.Secondary.default     // Lime Green
    static let crAccentOrange  = Color(hex: "#F4874B")          // Orange accent
    static let crAccentPink    = Color(hex: "#D94F7E")          // Pink/Red accent

    // Neutrals
    static let crBackground    = CRColor.Neutral.n50
    static let crSurface       = CRColor.Neutral.n0
    static let crDivider       = CRColor.Neutral.n200
    static let crSkeleton      = CRColor.Neutral.n200

    // Text
    static let crTextPrimary   = CRColor.Text.primary
    static let crTextSecondary = CRColor.Text.secondary
    static let crTextTertiary  = CRColor.Text.tertiary
    static let crTextOnPrimary = CRColor.Text.onPrimary
    static let crTextLink      = CRColor.Text.link

    // Semantic
    static let crSuccess       = CRColor.Feedback.success
    static let crWarning       = CRColor.Feedback.warning
    static let crError         = CRColor.Feedback.error
    static let crInfo          = CRColor.Feedback.info

    // Status
    static let crStatusActive  = CRColor.Feedback.success
    static let crStatusPending = CRColor.Feedback.warning
    static let crStatusDone    = CRColor.Text.tertiary
    static let crStatusCancel  = CRColor.Feedback.error

    // Tab bar
    static let crTabActive     = CRColor.Primary.default
    static let crTabInactive   = Color(hex: "#AAAABC")
}

// MARK: - Gradient Presets
extension LinearGradient {
    static let crPrimaryGradient = LinearGradient(
        colors: [CRColor.Primary.default, Color(hex: "#9B85D9")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let crHeroGradient = LinearGradient(
        colors: [Color.crAccentPink, Color.crPrimary, Color.crSecondary],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let crOnboarding1 = LinearGradient(
        colors: [Color(hex: "#C0392B"), Color(hex: "#D94F7E")],
        startPoint: .top, endPoint: .bottom
    )
    static let crOnboarding2 = LinearGradient(
        colors: [Color(hex: "#F4874B"), Color(hex: "#E8C84A")],
        startPoint: .top, endPoint: .bottom
    )
    static let crOnboarding3 = LinearGradient(
        colors: [Color.crSecondary, Color(hex: "#B8E04A")],
        startPoint: .top, endPoint: .bottom
    )
}
