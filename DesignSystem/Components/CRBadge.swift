import SwiftUI

// MARK: - Badge Style
public enum CRBadgeStyle {
    case verified         // profissional verificado
    case phoneVerified    // telefone verificado
    case pending          // verificação pendente
    case rejected         // verificação rejeitada
    case premium          // conta premium
    case new              // novo anúncio
    case hot              // anúncio em destaque
    case custom(bg: Color, text: Color)
}

// MARK: - CRBadge
public struct CRBadge: View {
    let text: String
    let style: CRBadgeStyle
    let icon: String?
    let size: BadgeSize

    public enum BadgeSize { case sm, md }

    public init(_ text: String, style: CRBadgeStyle, icon: String? = nil, size: BadgeSize = .md) {
        self.text = text; self.style = style; self.icon = icon; self.size = size
    }

    private var config: (bg: Color, fg: Color, iconName: String?) {
        switch style {
        case .verified:
            return (CRColor.Feedback.successLight, CRColor.Feedback.success, icon ?? "checkmark.seal.fill")
        case .phoneVerified:
            return (CRColor.Feedback.infoLight, CRColor.Feedback.info, icon ?? "phone.badge.checkmark.fill")
        case .pending:
            return (CRColor.Feedback.warningLight, CRColor.Feedback.warning, icon ?? "clock.fill")
        case .rejected:
            return (CRColor.Feedback.errorLight, CRColor.Feedback.error, icon ?? "xmark.circle.fill")
        case .premium:
            return (Color(hex: "#EDE9FE"), Color(hex: "#7C3AED"), icon ?? "star.fill")
        case .new:
            return (CRColor.Primary.lighter, CRColor.Primary.dark, icon)
        case .hot:
            return (Color(hex: "#FEE2E2"), Color(hex: "#DC2626"), icon ?? "flame.fill")
        case .custom(let bg, let fg):
            return (bg, fg, icon)
        }
    }

    private var hPad: CGFloat { size == .sm ? CRSpacing.s2 : CRSpacing.s3 }
    private var vPad: CGFloat { size == .sm ? CRSpacing.s1 : CRSpacing.s1 + 2 }
    private var font: Font { size == .sm ? .crCaptionSM : .crLabelXS }
    private var iconFont: CGFloat { size == .sm ? 8 : 10 }

    public var body: some View {
        HStack(spacing: 3) {
            if let iconName = config.iconName {
                Image(systemName: iconName)
                    .font(.system(size: iconFont, weight: .semibold))
                    .foregroundColor(config.fg)
            }
            Text(text)
                .font(font)
                .foregroundColor(config.fg)
                .lineLimit(1)
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
        .background(config.bg)
        .clipShape(Capsule())
    }
}

// MARK: - Notification Dot
public struct CRNotificationDot: View {
    let count: Int

    public init(_ count: Int = 0) { self.count = count }

    public var body: some View {
        if count > 0 {
            ZStack {
                Circle().fill(CRColor.Feedback.error)
                if count < 100 {
                    Text(count < 10 ? "\(count)" : "99+")
                        .font(.crCaptionSM)
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(width: count < 10 ? 18 : 24, height: 18)
        }
    }
}

// MARK: - Status Indicator
public struct CRStatusIndicator: View {
    public enum Status { case online, busy, offline }
    let status: Status

    private var color: Color {
        switch status {
        case .online:  return CRColor.Feedback.success
        case .busy:    return CRColor.Feedback.warning
        case .offline: return CRColor.Neutral.n400
        }
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().stroke(CRColor.Surface.primary, lineWidth: 2))
    }
}
