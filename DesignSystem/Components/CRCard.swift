import SwiftUI

// MARK: - Async Image Component
// Agora delegado para CRRemoteImage (suporta buckets privados do Supabase via auth fallback)
public struct CRAsyncImage: View {
    let url: String?
    let aspectRatio: CGFloat

    public init(url: String?, aspectRatio: CGFloat = 16/9) {
        self.url = url; self.aspectRatio = aspectRatio
    }

    public var body: some View {
        GeometryReader { geo in
            let h = geo.size.width / aspectRatio
            if let urlString = url, !urlString.isEmpty {
                CRRemoteImage(urlString: urlString, scaledToFill: false)
                    .frame(width: geo.size.width, height: h)
                    .clipped()
            } else {
                placeholderView
                    .frame(width: geo.size.width, height: h)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var placeholderView: some View {
        ZStack {
            CRColor.Neutral.n100
            VStack(spacing: CRSpacing.s2) {
                Image(systemName: "building.2")
                    .font(.system(size: 32))
                    .foregroundColor(CRColor.Neutral.n300)
                Text("Sem foto")
                    .font(.crCaptionMD)
                    .foregroundColor(CRColor.Text.tertiary)
            }
        }
    }
}

// MARK: - Info Row
public struct CRInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color

    public init(icon: String, label: String, value: String, valueColor: Color = CRColor.Text.primary) {
        self.icon = icon; self.label = label; self.value = value; self.valueColor = valueColor
    }

    public var body: some View {
        HStack(spacing: CRSpacing.s3) {
            Image(systemName: icon)
                .font(.system(size: CRSize.iconMD))
                .foregroundColor(CRColor.Icon.accent)
                .frame(width: 24)
            Text(label)
                .font(.crBodyBase)
                .foregroundColor(CRColor.Text.secondary)
            Spacer()
            Text(value)
                .font(.crLabelMD)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Section Header
public struct CRSectionHeader: View {
    let title: String
    let actionLabel: String?
    let action: (() -> Void)?

    public init(_ title: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title; self.actionLabel = actionLabel; self.action = action
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(.crHeading5)
                .foregroundColor(CRColor.Text.primary)
            Spacer()
            if let label = actionLabel {
                Button(action: { action?() }) {
                    Text(label)
                        .font(.crLabelSM)
                        .foregroundColor(CRColor.Text.link)
                }
            }
        }
    }
}
