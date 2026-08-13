import SwiftUI

// MARK: - Spacing Tokens
// Base unit: 4pt — escala de 4 em 4

public struct CRSpacing {
    public static let px    : CGFloat = 1
    public static let s1    : CGFloat = 4     // 4pt
    public static let s2    : CGFloat = 8     // 8pt
    public static let s3    : CGFloat = 12    // 12pt
    public static let s4    : CGFloat = 16    // 16pt  ← base
    public static let s5    : CGFloat = 20    // 20pt
    public static let s6    : CGFloat = 24    // 24pt
    public static let s7    : CGFloat = 28    // 28pt
    public static let s8    : CGFloat = 32    // 32pt
    public static let s9    : CGFloat = 36    // 36pt
    public static let s10   : CGFloat = 40    // 40pt
    public static let s12   : CGFloat = 48    // 48pt
    public static let s14   : CGFloat = 56    // 56pt
    public static let s16   : CGFloat = 64    // 64pt
    public static let s20   : CGFloat = 80    // 80pt
    public static let s24   : CGFloat = 96    // 96pt
    public static let s32   : CGFloat = 128   // 128pt

    // Semantic aliases
    public static let insetXS   : CGFloat = s2
    public static let insetSM   : CGFloat = s3
    public static let insetMD   : CGFloat = s4
    public static let insetLG   : CGFloat = s6
    public static let insetXL   : CGFloat = s8

    public static let gapXS     : CGFloat = s2
    public static let gapSM     : CGFloat = s3
    public static let gapMD     : CGFloat = s4
    public static let gapLG     : CGFloat = s6
    public static let gapXL     : CGFloat = s8

    public static let screenHorizontal : CGFloat = s4   // margem lateral de tela
    public static let sectionGap       : CGFloat = s8   // espaço entre seções
    public static let componentGap     : CGFloat = s4   // espaço entre componentes
    public static let itemGap          : CGFloat = s3   // espaço entre itens de lista
}

// MARK: - Border Radius Tokens
public struct CRRadius {
    public static let none   : CGFloat = 0
    public static let xs     : CGFloat = 4
    public static let sm     : CGFloat = 8
    public static let md     : CGFloat = 12
    public static let lg     : CGFloat = 16
    public static let xl     : CGFloat = 20
    public static let xl2    : CGFloat = 24
    public static let xl3    : CGFloat = 32
    public static let full   : CGFloat = 9999  // pill / círculo

    // Semantic aliases
    public static let button     : CGFloat = md
    public static let card       : CGFloat = lg
    public static let sheet      : CGFloat = xl2
    public static let input      : CGFloat = sm
    public static let badge      : CGFloat = full
    public static let avatar     : CGFloat = full
    public static let chip       : CGFloat = full
    public static let pill       : CGFloat = full   // compatibility alias
}

// MARK: - Shadow Tokens
public struct CRShadow {
    public struct Style {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }

    public static let none = Style(color: .clear, radius: 0, x: 0, y: 0, opacity: 0)

    public static let xs = Style(
        color: Color(hex: "#0F172A"), radius: 2, x: 0, y: 1, opacity: 0.04
    )
    public static let sm = Style(
        color: Color(hex: "#0F172A"), radius: 4, x: 0, y: 2, opacity: 0.06
    )
    public static let md = Style(
        color: Color(hex: "#0F172A"), radius: 8, x: 0, y: 4, opacity: 0.08
    )
    public static let lg = Style(
        color: Color(hex: "#0F172A"), radius: 16, x: 0, y: 8, opacity: 0.10
    )
    public static let xl = Style(
        color: Color(hex: "#0F172A"), radius: 24, x: 0, y: 12, opacity: 0.12
    )
    public static let xl2 = Style(
        color: Color(hex: "#0F172A"), radius: 40, x: 0, y: 20, opacity: 0.14
    )

    // Semantic aliases
    public static let card      = md
    public static let button    = sm
    public static let modal     = xl
    public static let dropdown  = lg
    public static let fab       = xl
}

// MARK: - Size Tokens (componentes)
public struct CRSize {
    // Ícones
    public static let iconXS  : CGFloat = 12
    public static let iconSM  : CGFloat = 16
    public static let iconMD  : CGFloat = 20
    public static let iconLG  : CGFloat = 24
    public static let iconXL  : CGFloat = 32

    // Avatares
    public static let avatarXS  : CGFloat = 24
    public static let avatarSM  : CGFloat = 32
    public static let avatarMD  : CGFloat = 40
    public static let avatarLG  : CGFloat = 56
    public static let avatarXL  : CGFloat = 80
    public static let avatar2XL : CGFloat = 120

    // Botões (altura)
    public static let buttonSM  : CGFloat = 36
    public static let buttonMD  : CGFloat = 44
    public static let buttonLG  : CGFloat = 52

    // Inputs (altura)
    public static let inputSM   : CGFloat = 40
    public static let inputMD   : CGFloat = 48
    public static let inputLG   : CGFloat = 56

    // Tab Bar
    public static let tabBar    : CGFloat = 83

    // Navigation Bar
    public static let navBar    : CGFloat = 44

    // Touch target mínimo (Apple HIG)
    public static let touchTarget: CGFloat = 44
}

// MARK: - CRSpacing Compatibility Aliases (old naming → new tokens)
extension CRSpacing {
    public static let xs:   CGFloat = s1    // 4
    public static let sm:   CGFloat = s2    // 8
    public static let md:   CGFloat = s3    // 12
    public static let base: CGFloat = s4    // 16
    public static let lg:   CGFloat = s5    // 20
    public static let xl:   CGFloat = s6    // 24
    public static let xxl:  CGFloat = s8    // 32
    public static let xxxl: CGFloat = s10   // 40
    public static let hero: CGFloat = s14   // 56
}

// MARK: - Border Width Tokens
public struct CRBorder {
    public static let thin   : CGFloat = 1
    public static let base   : CGFloat = 1.5
    public static let thick  : CGFloat = 2
    public static let heavy  : CGFloat = 3
}

// MARK: - Animation Tokens
public struct CRAnimation {
    public static let durationFast     : Double = 0.15
    public static let durationNormal   : Double = 0.25
    public static let durationSlow     : Double = 0.35
    public static let durationXSlow    : Double = 0.5

    public static let springFast    = Animation.spring(response: 0.3, dampingFraction: 0.7)
    public static let springNormal  = Animation.spring(response: 0.45, dampingFraction: 0.75)
    public static let easeNormal    = Animation.easeInOut(duration: durationNormal)
    public static let easeOut       = Animation.easeOut(duration: durationNormal)
}
