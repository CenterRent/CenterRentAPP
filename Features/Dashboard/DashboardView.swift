import SwiftUI
import Combine

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @State private var selectedRole: DashboardRole = .renter

    enum DashboardRole { case renter, owner }

    var body: some View {
        VStack(spacing: 0) {
            // Role Switcher
            Picker("", selection: $selectedRole) {
                Text("Locatário").tag(DashboardRole.renter)
                Text("Locador").tag(DashboardRole.owner)
            }
            .pickerStyle(.segmented)
            .padding(CRSpacing.s4)
            .background(CRColor.Background.primary)

            ScrollView {
                VStack(spacing: CRSpacing.s6) {
                    // Financial Summary
                    financialSummary
                    // Bookings
                    bookingsSection
                }
                .padding(.bottom, CRSpacing.s10)
            }
            .background(CRColor.Background.secondary)
        }
        .navigationTitle("Painel")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Reflete o tipo de usuário real (profiles.user_type) em vez de
            // sempre abrir em "Locatário" — só quem é exclusivamente locador
            // muda o padrão; "both"/renter/nil continuam como antes, já que
            // esses usuários alternam livremente entre os dois papéis.
            if authService.currentUser?.userType == .owner {
                selectedRole = .owner
            }
            Task { await vm.load(userId: authService.currentUser?.id ?? "", role: selectedRole) }
        }
        .onChange(of: selectedRole) { _, role in Task { await vm.load(userId: authService.currentUser?.id ?? "", role: role) } }
    }

    // MARK: - Financial
    private var financialSummary: some View {
        VStack(spacing: CRSpacing.s4) {
            HStack(spacing: CRSpacing.s3) {
                FinancialCard(title: selectedRole == .owner ? "Receita total" : "Gasto total",
                              value: "R$ \(vm.totalAmount)", icon: "dollarsign.circle.fill",
                              color: CRColor.Feedback.success)
                FinancialCard(title: "Este mês",
                              value: "R$ \(vm.monthAmount)", icon: "calendar.circle.fill",
                              color: CRColor.Primary.default)
            }
            HStack(spacing: CRSpacing.s3) {
                FinancialCard(title: "Reservas", value: "\(vm.totalBookings)",
                              icon: "calendar.badge.checkmark", color: CRColor.Secondary.default)
                FinancialCard(title: "Avaliação", value: String(format: "%.1f", vm.averageRating),
                              icon: "star.fill", color: CRColor.Accent.default)
            }
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.top, CRSpacing.s4)
    }

    // MARK: - Bookings
    private var bookingsSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s4) {
            CRSectionHeader("Reservas") {}
                .padding(.horizontal, CRSpacing.screenHorizontal)

            if vm.isLoading {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: CRRadius.md).fill(CRColor.Neutral.n200)
                        .frame(height: 80).shimmer().padding(.horizontal, CRSpacing.screenHorizontal)
                }
            } else if vm.bookings.isEmpty {
                VStack(spacing: CRSpacing.s3) {
                    Image(systemName: "calendar.badge.exclamationmark").font(.system(size: 40))
                        .foregroundColor(CRColor.Neutral.n300)
                    Text("Nenhuma reserva").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                    Text(selectedRole == .renter
                         ? "Explore espaços e faça sua primeira reserva!"
                         : "Crie um anúncio para receber reservas!")
                        .font(.crBodyBase).foregroundColor(CRColor.Text.secondary).multilineTextAlignment(.center)
                    CRButton(selectedRole == .renter ? "Explorar espaços" : "Criar anúncio",
                             variant: .primary, size: .md) {
                        selectedRole == .renter ? router.switchTab(to: .home) : router.navigate(to: .createListing)
                    }
                }
                .padding(CRSpacing.s8)
            } else {
                ForEach(vm.bookings) { booking in
                    BookingCard(booking: booking,
                                onReview: { router.present(.review(booking: booking)) })
                        .padding(.horizontal, CRSpacing.screenHorizontal)
                        .onTapGesture { router.navigate(to: .bookingDetail(bookingId: booking.id)) }
                }
            }
        }
    }
}

// MARK: - Booking Card
private struct BookingCard: View {
    let booking: Booking
    var onReview: (() -> Void)? = nil

    private var statusStyle: CRBadgeStyle {
        switch booking.status {
        case .pending:   return .pending
        case .accepted, .confirmed: return .verified
        case .active:    return .custom(bg: CRColor.Feedback.infoLight, text: CRColor.Feedback.info)
        case .completed: return .custom(bg: CRColor.Neutral.n100, text: CRColor.Text.secondary)
        case .declined, .cancelled: return .rejected
        }
    }

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                HStack {
                    Text(booking.startDate.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    Text("→").foregroundColor(CRColor.Text.tertiary)
                    Text(booking.endDate.formatted(.dateTime.day().month(.abbreviated)))
                        .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                }
                Text("\(Int(booking.totalHours))h · R$ \(Int(booking.totalAmount))")
                    .font(.crBodySM).foregroundColor(CRColor.Text.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: CRSpacing.s2) {
                CRBadge(booking.status.rawValue, style: statusStyle, size: .sm)
                if booking.canReview {
                    CRButton("Avaliar", variant: .outline, size: .sm) {
                        onReview?()
                    }
                }
            }
        }
        .padding(CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
        .crShadow(CRShadow.xs)
    }
}

// MARK: - Financial Card
private struct FinancialCard: View {
    let title: String; let value: String; let icon: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s2) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: CRSize.iconLG))
                Spacer()
            }
            Text(value).font(.crHeading3).foregroundColor(CRColor.Text.primary)
            Text(title).font(.crCaptionMD).foregroundColor(CRColor.Text.secondary)
        }
        .padding(CRSpacing.s4)
        .frame(maxWidth: .infinity)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
        .crShadow(CRShadow.xs)
    }
}

// MARK: - DashboardViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var totalAmount = 0
    @Published var monthAmount = 0
    @Published var totalBookings = 0
    @Published var averageRating = 0.0
    @Published var isLoading = false

    func load(userId: String, role: DashboardView.DashboardRole) async {
        guard !userId.isEmpty else { return }
        isLoading = true; defer { isLoading = false }

        bookings = (try? await SupabaseManager.shared.fetchBookings(
            userId: userId,
            role: role == .renter ? .renter : .owner
        )) ?? []

        totalBookings = bookings.count
        totalAmount   = Int(bookings.reduce(0) { $0 + $1.totalAmount })

        // Receita / gasto no mês corrente
        let cal = Calendar.current
        let now = Date()
        let thisMonth = bookings.filter {
            cal.isDate($0.startDate, equalTo: now, toGranularity: .month)
        }
        monthAmount = Int(thisMonth.reduce(0) { $0 + $1.totalAmount })

        // Avaliação média (bookings com review)
        let rated = bookings.filter { $0.canReview == false && $0.status == .completed }
        averageRating = rated.isEmpty ? 0.0 : Double(rated.count) / Double(totalBookings) * 5.0
    }
}
