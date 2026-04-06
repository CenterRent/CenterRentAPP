import SwiftUI

// MARK: - MyBookingsView — usa componentes do Design System (FEATURE 13)
struct MyBookingsView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter

    // Tabs de status usando o Design System
    private let tabs: [CRTabItem] = [
        CRTabItem(title: "Ativos",   icon: "clock",          selectedIcon: "clock.fill"),
        CRTabItem(title: "Futuros",  icon: "calendar",       selectedIcon: "calendar"),
        CRTabItem(title: "Histórico", icon: "archivebox",    selectedIcon: "archivebox.fill"),
    ]

    // Mapeia selectedTabIndex → BookingTab
    @State private var selectedTabIndex: Int = 0

    private var currentTab: ProfileViewModel.BookingTab {
        switch selectedTabIndex {
        case 0: return .active
        case 1: return .upcoming
        default: return .history
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Bar do Design System ──
            CRTopBar(
                title: "Minhas Reservas",
                subtitle: nil,
                showBack: false,
                trailingItems: [
                    .init(icon: "bell", badge: 0) { router.push(.notifications) }
                ]
            )

            // ── Seletor Ativos / Futuros / Histórico com CRTabBar do DS ──
            CRTabBar(
                selectedIndex: $selectedTabIndex,
                items: tabs
            )
            .onChange(of: selectedTabIndex) { idx in
                vm.bookingTab = currentTab
            }

            // ── Conteúdo ──
            if vm.filteredBookings.isEmpty {
                EmptyBookingsView(tab: vm.bookingTab)
            } else {
                ScrollView {
                    LazyVStack(spacing: CRSpacing.md) {
                        ForEach(vm.filteredBookings) { booking in
                            BookingCard(booking: booking) {
                                // Navegar para detalhe da reserva
                            }
                        }
                    }
                    .padding(CRSpacing.base)
                    .padding(.bottom, CRSpacing.xxxl)
                }
            }
        }
        .background(Color.crBackground)
        .task {
            if let userId = authVM.currentUser?.id {
                await vm.loadProfile(userId: userId)
            }
            vm.bookingTab = currentTab
        }
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let booking: Booking
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Banner de categoria
                ZStack(alignment: .bottomLeading) {
                    booking.categoryColor
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, CRSpacing.base)
                        )

                    HStack {
                        Text(booking.categoryName ?? "Reserva")
                            .font(.crLabelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(CRRadius.pill)

                        Spacer()

                        // Pílula de status
                        Text(booking.bookingStatus.label)
                            .font(.crCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(booking.bookingStatus.color)
                            .cornerRadius(CRRadius.pill)
                    }
                    .padding(CRSpacing.sm)
                }
                .cornerRadius(CRRadius.lg, corners: [.topLeft, .topRight])

                // Conteúdo
                VStack(alignment: .leading, spacing: CRSpacing.sm) {
                    Text(booking.listingTitle ?? "Sala profissional")
                        .font(.crH4)
                        .foregroundColor(.crTextPrimary)

                    // Datas
                    HStack(spacing: CRSpacing.xl) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check-in").font(.crCaption).foregroundColor(.crTextTertiary)
                            Text(booking.startDate.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.crLabel).foregroundColor(.crTextPrimary)
                        }
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.crTextTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Check-out").font(.crCaption).foregroundColor(.crTextTertiary)
                            Text(booking.endDate.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.crLabel).foregroundColor(.crTextPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total").font(.crCaption).foregroundColor(.crTextTertiary)
                            Text("R$ \(String(format: "%.0f", booking.totalAmount))")
                                .font(.crPrice).foregroundColor(.crPrimary)
                        }
                    }

                    // Código
                    Text("Código: #\(String(booking.id.prefix(8)).uppercased())")
                        .font(.crCaption)
                        .foregroundColor(.crTextTertiary)

                    // Ações
                    HStack(spacing: CRSpacing.sm) {
                        if booking.bookingStatus == .confirmed {
                            CRButton(title: "Cancelar", variant: .outline, size: .small, isFullWidth: true) {}
                            CRButton(title: "Ver detalhes", size: .small, isFullWidth: true) {}
                        } else if booking.bookingStatus == .completed {
                            CRButton(title: "Avaliar", variant: .secondary, size: .small, isFullWidth: true) {}
                            CRButton(title: "Reservar novamente", size: .small, isFullWidth: true) {}
                        } else {
                            CRButton(title: "Ver detalhes", size: .small, isFullWidth: true) {}
                        }
                    }
                }
                .padding(CRSpacing.md)
            }
            .background(Color.white)
            .cornerRadius(CRRadius.lg)
            .crShadowCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State
struct EmptyBookingsView: View {
    let tab: ProfileViewModel.BookingTab

    var body: some View {
        VStack(spacing: CRSpacing.xl) {
            Spacer()

            Image(systemName: tab == .history ? "clock.arrow.circlepath" : "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.crDivider)

            VStack(spacing: CRSpacing.sm) {
                Text(tab == .history ? "Sem histórico ainda" : "Nenhuma reserva \(tab.rawValue.lowercased())")
                    .font(.crH4)
                    .foregroundColor(.crTextSecondary)
                Text("Explore espaços e equipamentos disponíveis\npróximos a você.")
                    .font(.crBody)
                    .foregroundColor(.crTextTertiary)
                    .multilineTextAlignment(.center)
            }

            CRButton(title: "Explorar espaços", isFullWidth: false) {}

            Spacer()
        }
        .padding(CRSpacing.xl)
    }
}
