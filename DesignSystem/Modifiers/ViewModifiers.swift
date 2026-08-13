import SwiftUI

// MARK: - Card Modifier
public struct CRCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var shadow: CRShadow.Style

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CRColor.Surface.primary)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color.opacity(shadow.opacity),
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Input Field Modifier
public struct CRInputModifier: ViewModifier {
    var isFocused: Bool
    var isError: Bool

    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, CRSpacing.s4)
            .frame(height: CRSize.inputMD)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: CRRadius.input)
                    .stroke(
                        isError ? CRColor.Border.error :
                        isFocused ? CRColor.Border.focus :
                        CRColor.Border.default,
                        lineWidth: isFocused || isError ? CRBorder.base : CRBorder.thin
                    )
            )
    }
}

// MARK: - Shimmer Loading Modifier
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) { phase = 1 }
            }
    }
}

// MARK: - Skeleton Modifier
public struct SkeletonModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .modifier(ShimmerModifier())
    }
}

// MARK: - Haptic Feedback
public struct HapticFeedback {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - View Extensions
public extension View {

    func crCard(
        padding: CGFloat = CRSpacing.s4,
        radius: CGFloat = CRRadius.card,
        shadow: CRShadow.Style = CRShadow.card
    ) -> some View {
        modifier(CRCardModifier(padding: padding, cornerRadius: radius, shadow: shadow))
    }

    func crInput(focused: Bool = false, error: Bool = false) -> some View {
        modifier(CRInputModifier(isFocused: focused, isError: error))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func skeleton() -> some View {
        modifier(SkeletonModifier())
    }

    func crShadow(_ style: CRShadow.Style) -> some View {
        shadow(
            color: style.color.opacity(style.opacity),
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    // MARK: - Semantic Shadow Aliases (backwards compat)
    func crShadowSoft()  -> some View { crShadow(CRShadow.sm) }
    func crShadowCard()  -> some View { crShadow(CRShadow.md) }
    func crShadowFloat() -> some View { crShadow(CRShadow.lg) }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Segmented Control Component
public struct CRSegmentedControl: View {
    let options: [String]
    @Binding var selected: String

    public init(options: [String], selected: Binding<String>) {
        self.options = options
        self._selected = selected
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selected = option
                    }
                } label: {
                    Text(option)
                        .font(selected == option ? .crLabel : .crBody)
                        .foregroundColor(selected == option ? .crPrimary : .crTextTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CRSpacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            GeometryReader { geo in
                let w = geo.size.width / CGFloat(max(options.count, 1))
                let idx = CGFloat(options.firstIndex(of: selected) ?? 0)
                RoundedRectangle(cornerRadius: CRRadius.full)
                    .fill(Color.crPrimary.opacity(0.1))
                    .frame(width: w)
                    .offset(x: idx * w)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
            },
            alignment: .leading
        )
    }
}
