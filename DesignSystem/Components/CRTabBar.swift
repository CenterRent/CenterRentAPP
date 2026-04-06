import SwiftUI

// MARK: - Tab enum
enum CRTab: CaseIterable {
    case home, reservations, chat, notifications, profile

    var icon: String {
        switch self {
        case .home:          return "house"
        case .reservations:  return "bag"
        case .chat:          return "bubble.left.and.bubble.right"
        case .notifications: return "bell"
        case .profile:       return "person"
        }
    }

    var activeIcon: String {
        switch self {
        case .home:          return "house.fill"
        case .reservations:  return "bag.fill"
        case .chat:          return "bubble.left.and.bubble.right.fill"
        case .notifications: return "bell.fill"
        case .profile:       return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:          return "Home"
        case .reservations:  return "Reservas"
        case .chat:          return "Chat"
        case .notifications: return "Novidades"
        case .profile:       return "Perfil"
        }
    }
}

// MARK: - Glass TabBar (estilo Apple / VISUAL 10)
struct CRMainTabBar: View {
    @Binding var selected: CRTab
    var badgeCounts: [CRTab: Int] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CRTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, safeAreaBottom > 0 ? safeAreaBottom : 16)
        // Fundo glass: material ultraThin + borda sutil
        .background(
            ZStack {
                // Blur material — efeito vidro Apple
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(Color.white.opacity(0.6))
            }
            .overlay(alignment: .top) {
                // Linha fina no topo (separador glass)
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(height: 0.5)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private func tabItem(_ tab: CRTab) -> some View {
        let isSelected = selected == tab

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selected = tab
            }
            // Haptic feedback leve
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    // Fundo da pill ativa
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.crPrimary.opacity(0.12))
                            .frame(width: 44, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .crPrimary : .crTextTertiary)
                        .frame(width: 44, height: 32)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                    // Badge
                    if let badge = badgeCounts[tab], badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.crError)
                            .clipShape(Capsule())
                            .offset(x: 6, y: -4)
                    }
                }

                Text(tab.label)
                    .font(isSelected ? .system(size: 10, weight: .semibold) : .system(size: 10, weight: .regular))
                    .foregroundColor(isSelected ? .crPrimary : .crTextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // Safe area bottom height
    private var safeAreaBottom: CGFloat {
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom) ?? 0
    }
}
