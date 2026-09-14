import SwiftUI

// MARK: - MyBookingsView — usa componentes do Design System (FEATURE 13)
struct MyBookingsView: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter

    @State private var bookingPendingCancel: Booking?

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
                    .init(icon: "bell", badge: 0) { router.profilePath.append(AppDestination.notifications) }
                ]
            )

            // ── Seletor Ativos / Futuros / Histórico com CRTabBar do DS ──
            CRTabBar(
                selectedIndex: $selectedTabIndex,
                items: tabs
            )
            .onChange(of: selectedTabIndex) { _, _ in
                vm.bookingTab = currentTab
            }

            // ── Conteúdo ──
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.filteredBookings.isEmpty {
                EmptyBookingsView(tab: vm.bookingTab) {
                    router.switchTab(to: .home)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: CRSpacing.md) {
                        ForEach(vm.filteredBookings) { booking in
                            MyBookingRowCard(
                                booking: booking,
                                listing: vm.bookingListings[booking.listingId],
                                onTap: { router.profilePath.append(AppDestination.bookingDetail(bookingId: booking.id)) },
                                onCancel: { bookingPendingCancel = booking },
                                onReview: { router.present(.review(booking: booking)) },
                                onRebook: { router.profilePath.append(AppDestination.listingDetail(listingId: booking.listingId)) }
                            )
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
        .alert("Cancelar reserva?", isPresented: Binding(
            get: { bookingPendingCancel != nil },
            set: { if !$0 { bookingPendingCancel = nil } }
        )) {
            Button("Voltar", role: .cancel) { bookingPendingCancel = nil }
            Button("Cancelar reserva", role: .destructive) {
                if let booking = bookingPendingCancel {
                    Task {
                        await vm.cancelBooking(booking)
                        bookingPendingCancel = nil
                    }
                }
            }
        } message: {
            Text("O anfitrião será avisado. Essa ação não pode ser desfeita.")
        }
    }
}

// MARK: - Booking Card
private struct MyBookingRowCard: View {
    let booking: Booking
    let listing: Listing?
    let onTap: () -> Void
    let onCancel: () -> Void
    let onReview: () -> Void
    let onRebook: () -> Void

    var body: some View {
        Button { onTap() } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Banner de categoria
                ZStack(alignment: .bottomLeading) {
                    Color.crPrimary
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, CRSpacing.base)
                        )

                    HStack {
                        Text("Reserva")
                            .font(.crLabelSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(CRRadius.pill)

                        Spacer()

                        // Pílula de status
                        Text(booking.status.label)
                            .font(.crCaption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(booking.status.color)
                            .cornerRadius(CRRadius.pill)
                    }
                    .padding(CRSpacing.sm)
                }
                .cornerRadius(CRRadius.lg, corners: [.topLeft, .topRight])

                // Conteúdo
                VStack(alignment: .leading, spacing: CRSpacing.sm) {
                    Text(listing?.title ?? "Espaço")
                        .font(.crH4)
                        .foregroundColor(.crTextPrimary)
                        .lineLimit(1)

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
                        if booking.status == .confirmed {
                            CRButton(title: "Cancelar", variant: .outline, size: .small, isFullWidth: true, action: onCancel)
                            CRButton(title: "Ver detalhes", size: .small, isFullWidth: true, action: onTap)
                        } else if booking.status == .completed {
                            CRButton(title: "Avaliar", variant: .secondary, size: .small, isFullWidth: true, action: onReview)
                            CRButton(title: "Reservar novamente", size: .small, isFullWidth: true, action: onRebook)
                        } else {
                            CRButton(title: "Ver detalhes", size: .small, isFullWidth: true, action: onTap)
                        }
                    }
                    // Botões de ação não devem repropagar o tap do card inteiro
                    .buttonStyle(.plain)
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
    var onExplore: () -> Void = {}

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

            CRButton(title: "Explorar espaços", isFullWidth: false, action: onExplore)

            Spacer()
        }
        .padding(CRSpacing.xl)
    }
}
