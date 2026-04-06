import SwiftUI

// MARK: - Side Menu Item Model
private struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let subtitle: String?
    let badge: Int
    let route: AppRoute?
    var isDestructive: Bool = false

    init(_ label: String, icon: String, subtitle: String? = nil, badge: Int = 0, route: AppRoute? = nil, destructive: Bool = false) {
        self.label = label
        self.icon = icon
        self.subtitle = subtitle
        self.badge = badge
        self.route = route
        self.isDestructive = destructive
    }
}

private struct MenuSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [MenuItem]
}

// MARK: - Side Menu View (FEATURE 11)
struct SideMenuView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var router: AppRouter

    private let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.82

    private var sections: [MenuSection] {
        [
            MenuSection(title: "Descoberta", items: [
                MenuItem("Home",         icon: "house.fill",          route: .home),
                MenuItem("Buscar",       icon: "magnifyingglass",     route: .search),
                MenuItem("Filtros",      icon: "slider.horizontal.3", route: nil),
            ]),
            MenuSection(title: "Minha Conta", items: [
                MenuItem("Perfil",               icon: "person.crop.circle",   route: .editProfile),
                MenuItem("Meus Anúncios",        icon: "list.bullet.rectangle",route: .myListings),
                MenuItem("Minhas Reservas",      icon: "bag.fill",             route: nil),
                MenuItem("Favoritos",            icon: "heart.fill",            route: nil),
            ]),
            MenuSection(title: "Comunicação", items: [
                MenuItem("Chat",           icon: "bubble.left.and.bubble.right.fill", route: nil, badge: 2),
                MenuItem("Notificações",   icon: "bell.fill",  route: .notifications, badge: 1),
            ]),
            MenuSection(title: "Crescimento", items: [
                MenuItem("Indique e Ganhe (MGM)", icon: "gift.fill", subtitle: "Ganhe recompensas por indicação", route: .referral),
            ]),
            MenuSection(title: "Suporte", items: [
                MenuItem("Ajuda e FAQ",    icon: "questionmark.circle.fill", route: nil),
                MenuItem("Termos de uso",  icon: "doc.text.fill",            route: nil),
                MenuItem("Sair da conta",  icon: "rectangle.portrait.and.arrow.right", route: nil, destructive: true),
            ]),
        ]
    }

    var body: some View {
        HStack(spacing: 0) {
            // Painel do menu
            VStack(spacing: 0) {
                // Header com logo e fechar
                menuHeader

                Divider()

                // Itens do menu
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(sections) { section in
                            sectionView(section)
                        }
                        Spacer().frame(height: CRSpacing.xxxl)
                    }
                }
            }
            .frame(width: menuWidth)
            .background(Color.white)
            .ignoresSafeArea()

            Spacer()
        }
    }

    // MARK: - Header
    private var menuHeader: some View {
        HStack(spacing: CRSpacing.sm) {
            // Logo
            HStack(spacing: 0) {
                Text("C").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.crPrimary)
                Text("R").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.crSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Center Rent")
                    .font(.crH4).foregroundColor(.crTextPrimary)
                Text("Menu principal")
                    .font(.crCaption).foregroundColor(.crTextTertiary)
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isShowing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.crTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Color.crBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, CRSpacing.base)
        .padding(.top, CRSpacing.hero)
        .padding(.bottom, CRSpacing.md)
    }

    // MARK: - Section
    @ViewBuilder
    private func sectionView(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.crTextTertiary)
                .tracking(1)
                .padding(.horizontal, CRSpacing.base)
                .padding(.top, CRSpacing.xl)
                .padding(.bottom, CRSpacing.xs)

            ForEach(section.items) { item in
                menuRow(item)
            }
        }
    }

    // MARK: - Row
    @ViewBuilder
    private func menuRow(_ item: MenuItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isShowing = false
            }
            if let route = item.route {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.push(route)
                }
            }
        } label: {
            HStack(spacing: CRSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.isDestructive ? Color.crError.opacity(0.1) : Color.crPrimary.opacity(0.08))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.isDestructive ? .crError : .crPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.crBody)
                        .foregroundColor(item.isDestructive ? .crError : .crTextPrimary)
                    if let sub = item.subtitle {
                        Text(sub)
                            .font(.crCaption)
                            .foregroundColor(.crTextTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Badge
                if item.badge > 0 {
                    Text("\(item.badge)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.crError)
                        .clipShape(Capsule())
                } else if !item.isDestructive && item.route != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.crTextTertiary)
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .padding(.vertical, CRSpacing.md)
        }
        .buttonStyle(CRPressStyle())
    }
}
