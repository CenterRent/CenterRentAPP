import SwiftUI

// MARK: - Navigation Bar Style
public struct CRNavigationBarModifier: ViewModifier {
    let title: String
    let displayMode: NavigationBarItem.TitleDisplayMode
    let showBackground: Bool

    public func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(
                showBackground ? CRColor.Background.primary : Color.clear,
                for: .navigationBar
            )
            .toolbarBackground(showBackground ? .visible : .hidden, for: .navigationBar)
    }
}

// MARK: - CRTopBar (tela sem NavigationView, custom)
public struct CRTopBar: View {
    let title: String
    let subtitle: String?
    let showBack: Bool
    let backAction: (() -> Void)?
    let trailingItems: [TopBarAction]

    public struct TopBarAction {
        let icon: String
        let action: () -> Void
        let badge: Int

        public init(icon: String, badge: Int = 0, action: @escaping () -> Void) {
            self.icon = icon; self.badge = badge; self.action = action
        }
    }

    public init(
        title: String,
        subtitle: String? = nil,
        showBack: Bool = false,
        backAction: (() -> Void)? = nil,
        trailingItems: [TopBarAction] = []
    ) {
        self.title = title; self.subtitle = subtitle; self.showBack = showBack
        self.backAction = backAction; self.trailingItems = trailingItems
    }

    public var body: some View {
        HStack(spacing: CRSpacing.s3) {
            if showBack {
                Button(action: { backAction?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: CRSize.iconMD, weight: .semibold))
                        .foregroundColor(CRColor.Icon.primary)
                        .frame(width: CRSize.touchTarget, height: CRSize.touchTarget)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(subtitle != nil ? .crHeading5 : .crHeading4)
                    .foregroundColor(CRColor.Text.primary)
                    .lineLimit(1)
                if let sub = subtitle {
                    Text(sub)
                        .font(.crCaptionMD)
                        .foregroundColor(CRColor.Text.secondary)
                }
            }

            Spacer()

            HStack(spacing: CRSpacing.s2) {
                ForEach(trailingItems.indices, id: \.self) { i in
                    let item = trailingItems[i]
                    Button(action: item.action) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: item.icon)
                                .font(.system(size: CRSize.iconMD, weight: .medium))
                                .foregroundColor(CRColor.Icon.primary)
                                .frame(width: CRSize.touchTarget, height: CRSize.touchTarget)
                            if item.badge > 0 {
                                CRNotificationDot(item.badge)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .frame(height: CRSize.navBar)
        .background(CRColor.Background.primary)
    }
}

// MARK: - CRTabBar
public struct CRTabItem {
    public let title: String
    public let icon: String
    public let selectedIcon: String
    public var badge: Int

    public init(title: String, icon: String, selectedIcon: String? = nil, badge: Int = 0) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? "\(icon).fill"
        self.badge = badge
    }
}

public struct CRTabBar: View {
    @Binding var selectedIndex: Int
    let items: [CRTabItem]

    public init(selectedIndex: Binding<Int>, items: [CRTabItem]) {
        self._selectedIndex = selectedIndex; self.items = items
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                CRTabBarItem(
                    item: items[index],
                    isSelected: selectedIndex == index,
                    onTap: {
                        if selectedIndex == index { return }
                        HapticFeedback.selection()
                        selectedIndex = index
                    }
                )
            }
        }
        .padding(.horizontal, CRSpacing.s4)
        .padding(.bottom, CRSpacing.s2)
        .background(
            CRColor.Background.primary
                .shadow(color: CRColor.Neutral.n200, radius: 1, x: 0, y: -1)
        )
    }
}

private struct CRTabBarItem: View {
    let item: CRTabItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: CRSpacing.s1) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: CRSize.iconLG, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? CRColor.Primary.default : CRColor.Icon.secondary)
                        .frame(height: 28)
                    if item.badge > 0 {
                        CRNotificationDot(item.badge).offset(x: 8, y: -4)
                    }
                }
                Text(item.title)
                    .font(.crLabelXS)
                    .foregroundColor(isSelected ? CRColor.Primary.default : CRColor.Icon.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, CRSpacing.s2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Extension
public extension View {
    func crNavigationBar(
        title: String,
        displayMode: NavigationBarItem.TitleDisplayMode = .large,
        showBackground: Bool = true
    ) -> some View {
        modifier(CRNavigationBarModifier(title: title, displayMode: displayMode, showBackground: showBackground))
    }
}
