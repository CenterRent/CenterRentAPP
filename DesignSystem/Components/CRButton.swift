import SwiftUI

// MARK: - CRButton Style Enums
enum CRButtonVariant { case primary, secondary, outline, ghost, destructive }

enum CRButtonSize {
    case large, medium, small
    /// Aliases matching new design-token naming used in Features/
    static var lg: CRButtonSize { .large }
    static var md: CRButtonSize { .medium }
    static var sm: CRButtonSize { .small }
    static var xl: CRButtonSize { .large }   // extra-large → large

    var height: CGFloat       { switch self { case .large: 56; case .medium: 48; case .small: 36 } }
    var font: Font            { switch self { case .large: .crButtonLarge; case .medium: .crButton; case .small: .crButtonSmall } }
    var hPadding: CGFloat     { switch self { case .large: 24; case .medium: 20; case .small: 16 } }
    var cornerRadius: CGFloat { switch self { case .large: 28; case .medium: 24; case .small: 18 } }
}

enum CRButtonIconPosition { case leading, trailing }

struct CRButton: View {
    let title: String
    var variant: CRButtonVariant = .primary
    var size: CRButtonSize = .large
    var icon: String? = nil
    var iconPosition: CRButtonIconPosition = .leading
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    // MARK: - Unlabeled first-arg init (used by Features/ files)
    init(_ title: String,
         variant: CRButtonVariant = .primary,
         size: CRButtonSize = .large,
         icon: String? = nil,
         iconPosition: CRButtonIconPosition = .leading,
         isLoading: Bool = false,
         isFullWidth: Bool = true,
         action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    // MARK: - Labeled init (used by old Views/ files)
    init(title: String,
         variant: CRButtonVariant = .primary,
         size: CRButtonSize = .large,
         icon: String? = nil,
         iconPosition: CRButtonIconPosition = .leading,
         isLoading: Bool = false,
         isFullWidth: Bool = true,
         action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.size = size
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.sm) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: fgColor)).scaleEffect(0.8)
                } else {
                    if let icon, iconPosition == .leading  { Image(systemName: icon) }
                    Text(title).font(size.font)
                    if let icon, iconPosition == .trailing { Image(systemName: icon) }
                }
            }
            .foregroundColor(fgColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, isFullWidth ? 0 : size.hPadding)
            .background(bgColor)
            .cornerRadius(size.cornerRadius)
            .overlay(RoundedRectangle(cornerRadius: size.cornerRadius).stroke(borderColor, lineWidth: variant == .outline ? 1.5 : 0))
        }
        .disabled(isLoading)
        .buttonStyle(CRPressStyle())
    }

    private var fgColor: Color {
        switch variant {
        case .primary, .destructive: return .crTextOnPrimary
        case .secondary: return .crTextPrimary
        case .outline, .ghost: return .crPrimary
        }
    }
    private var bgColor: Color {
        switch variant {
        case .primary: return .crPrimary
        case .secondary: return .crSecondary
        case .outline: return .clear
        case .ghost: return .crPrimary.opacity(0.08)
        case .destructive: return .crError
        }
    }
    private var borderColor: Color { variant == .outline ? .crPrimary : .clear }
}

struct CRPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CRIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var color: Color = .crTextPrimary
    var background: Color = Color.white.opacity(0.9)
    let action: () -> Void

    // Memberwise init (systemName: CGFloat size)
    init(systemName: String, size: CGFloat = 44, color: Color = .crTextPrimary, background: Color = Color.white.opacity(0.9), action: @escaping () -> Void) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.background = background
        self.action = action
    }

    // Convenience init with icon: label and CRButtonSize
    init(icon: String, size: CRButtonSize = .medium, color: Color = .crTextPrimary, background: Color = Color.white.opacity(0.9), action: @escaping () -> Void) {
        self.systemName = icon
        switch size {
        case .small:  self.size = 36
        case .medium: self.size = 44
        case .large:  self.size = 52
        }
        self.color = color
        self.background = background
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .crShadowSoft()
        }.buttonStyle(CRPressStyle())
    }
}
