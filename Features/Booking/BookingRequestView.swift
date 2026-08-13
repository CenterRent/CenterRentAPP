import SwiftUI
import Combine

// MARK: - Booking Request Sheet
struct BookingRequestView: View {
    let listing: Listing
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @StateObject private var vm = BookingRequestViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CRSpacing.s6) {

                    // Listing Summary
                    listingSummary

                    // Date & Time Picker
                    dateTimeSection

                    // Duration
                    durationSection

                    // Price Breakdown
                    if vm.totalHours > 0 {
                        priceBreakdown
                    }

                    // Notes
                    notesSection

                    // Terms
                    termsSection
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.bottom, 100)
            }
            .background(CRColor.Background.secondary.ignoresSafeArea())
            .navigationTitle("Solicitar reserva")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(CRColor.Icon.primary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomCTA
            }
            .alert("Reserva enviada!", isPresented: $vm.showSuccess) {
                Button("Ver minhas reservas") {
                    dismiss()
                    router.switchTab(to: .myListings)
                }
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("Sua solicitação foi enviada ao anunciante. Você receberá uma notificação quando ele responder.")
            }
        }
    }

    // MARK: - Listing Summary
    private var listingSummary: some View {
        HStack(spacing: CRSpacing.s3) {
            CRAsyncImage(url: listing.mainImageURL, aspectRatio: 1)
                .frame(width: 72, height: 72)
                .cornerRadius(CRRadius.sm)
            VStack(alignment: .leading, spacing: CRSpacing.s1) {
                Text(listing.title)
                    .font(.crLabelLG).foregroundColor(CRColor.Text.primary).lineLimit(2)
                Text(listing.address.shortAddress)
                    .font(.crBodySM).foregroundColor(CRColor.Text.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("R$ \(Int(listing.pricePerHour))").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                    Text("/hora").font(.crBodySM).foregroundColor(CRColor.Text.secondary)
                }
            }
        }
        .padding(CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.card)
        .crShadow(CRShadow.xs)
    }

    // MARK: - Date & Time
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text("Data e horário").font(.crHeading5).foregroundColor(CRColor.Text.primary)

            HStack(spacing: CRSpacing.s3) {
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("Início").font(.crLabelSM).foregroundColor(CRColor.Text.secondary)
                    DatePicker("", selection: $vm.startDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(CRColor.Primary.default)
                }
                Divider().frame(height: 40)
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("Fim").font(.crLabelSM).foregroundColor(CRColor.Text.secondary)
                    DatePicker("", selection: $vm.endDate, in: vm.startDate..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(CRColor.Primary.default)
                }
            }
            .padding(CRSpacing.s4)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.md)
        }
    }

    // MARK: - Duration
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            HStack {
                Text("Duração").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                Spacer()
                Text(vm.durationLabel).font(.crLabelLG).foregroundColor(CRColor.Primary.default)
            }

            // Quick selectors
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CRSpacing.s2) {
                    ForEach([1, 2, 4, 6, 8], id: \.self) { hours in
                        Button(action: {
                            vm.endDate = Calendar.current.date(byAdding: .hour, value: hours, to: vm.startDate) ?? vm.endDate
                        }) {
                            Text("\(hours)h")
                                .font(.crLabelMD)
                                .foregroundColor(Int(vm.totalHours) == hours ? .white : CRColor.Text.secondary)
                                .padding(.horizontal, CRSpacing.s4)
                                .padding(.vertical, CRSpacing.s2)
                                .background(Int(vm.totalHours) == hours ? CRColor.Primary.default : CRColor.Surface.primary)
                                .cornerRadius(CRRadius.full)
                                .crShadow(CRShadow.xs)
                        }
                    }
                    Button(action: {
                        let cal = Calendar.current
                        let dayStart = cal.startOfDay(for: vm.startDate)
                        vm.startDate = cal.date(bySettingHour: 8, minute: 0, second: 0, of: dayStart) ?? vm.startDate
                        vm.endDate   = cal.date(bySettingHour: 18, minute: 0, second: 0, of: dayStart) ?? vm.endDate
                    }) {
                        let isAllDay = Int(vm.totalHours) == 10
                        Text("Dia inteiro")
                            .font(.crLabelMD)
                            .foregroundColor(isAllDay ? .white : CRColor.Text.secondary)
                            .padding(.horizontal, CRSpacing.s4).padding(.vertical, CRSpacing.s2)
                            .background(isAllDay ? CRColor.Primary.default : CRColor.Surface.primary)
                            .cornerRadius(CRRadius.full).crShadow(CRShadow.xs)
                    }
                }
                .padding(.vertical, CRSpacing.s1)
            }
        }
    }

    // MARK: - Price Breakdown
    private var priceBreakdown: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text("Resumo de valores").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            VStack(spacing: CRSpacing.s3) {
                BookingPriceRow(label: "R$ \(Int(listing.pricePerHour)) × \(vm.durationLabel)",
                         value: "R$ \(Int(listing.pricePerHour * vm.totalHours))")
                BookingPriceRow(label: "Taxa da plataforma (10%)",
                         value: "R$ \(Int(listing.pricePerHour * vm.totalHours * 0.10))")
                Divider().overlay(CRColor.Border.default)
                BookingPriceRow(label: "Total",
                         value: "R$ \(Int(listing.pricePerHour * vm.totalHours * 1.10))",
                         isTotal: true)
            }
            .padding(CRSpacing.s4)
            .background(CRColor.Surface.primary)
            .cornerRadius(CRRadius.md)

            Text("Você só é cobrado após o anunciante aceitar a reserva.")
                .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Notes
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text("Mensagem para o anunciante (opcional)").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            TextEditor(text: $vm.notes)
                .font(.crBodyBase).foregroundColor(CRColor.Text.primary)
                .frame(minHeight: 80)
                .padding(CRSpacing.s3)
                .background(CRColor.Surface.primary)
                .cornerRadius(CRRadius.input)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.input)
                    .stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
        }
    }

    // MARK: - Terms
    private var termsSection: some View {
        HStack(alignment: .top, spacing: CRSpacing.s3) {
            Button(action: { vm.agreedToTerms.toggle() }) {
                Image(systemName: vm.agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: CRSize.iconLG))
                    .foregroundColor(vm.agreedToTerms ? CRColor.Primary.default : CRColor.Neutral.n400)
            }
            Text("Li e concordo com as Regras do espaço e com a Política de Cancelamento do Center Rent.")
                .font(.crBodySM).foregroundColor(CRColor.Text.secondary).lineSpacing(3)
        }
    }

    // MARK: - Bottom CTA
    private var bottomCTA: some View {
        VStack(spacing: CRSpacing.s2) {
            if let error = vm.errorMessage {
                Text(error).font(.crBodySM).foregroundColor(CRColor.Feedback.error)
                    .multilineTextAlignment(.center)
            }
            CRButton(
                "Solicitar reserva · R$ \(Int(listing.pricePerHour * vm.totalHours * 1.10))",
                variant: .primary, size: .lg,
                isLoading: vm.isLoading,
                isFullWidth: true
            ) {
                Task {
                    await vm.submitBooking(
                        listing: listing,
                        renterId: authService.currentUser?.id ?? ""
                    )
                }
            }
            .disabled(!vm.agreedToTerms || vm.totalHours <= 0)
            .opacity(!vm.agreedToTerms || vm.totalHours <= 0 ? 0.5 : 1.0)
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.vertical, CRSpacing.s4)
        .background(CRColor.Background.primary)
    }
}

// MARK: - Price Row
private struct BookingPriceRow: View {
    let label: String; let value: String; var isTotal: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .crLabelLG : .crBodyBase)
                .foregroundColor(isTotal ? CRColor.Text.primary : CRColor.Text.secondary)
            Spacer()
            Text(value)
                .font(isTotal ? .crHeading4 : .crLabelMD)
                .foregroundColor(isTotal ? CRColor.Text.primary : CRColor.Text.secondary)
        }
    }
}

// MARK: - Booking Request Detail View
struct BookingRequestDetailView: View {
    let bookingId: String
    @State private var booking: Booking? = nil
    @State private var isLoading = true
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if isLoading {
                ProgressView().tint(CRColor.Primary.default).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if booking == nil {
                VStack(spacing: CRSpacing.s4) {
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(CRColor.Feedback.error.opacity(0.5))
                    Text("Reserva não encontrada")
                        .font(.crHeading5).foregroundColor(CRColor.Text.primary)
                    Text("Não foi possível carregar os detalhes desta reserva.")
                        .font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(CRSpacing.xl)
            } else if let booking {
                ScrollView {
                    VStack(spacing: CRSpacing.s6) {
                        // Status Header
                        statusHeader(booking: booking)
                        // Dates
                        datesSection(booking: booking)
                        // Financials
                        financialsSection(booking: booking)
                        // Actions
                        actionsSection(booking: booking)
                    }
                    .padding(.horizontal, CRSpacing.screenHorizontal)
                    .padding(.bottom, CRSpacing.s10)
                }
                .background(CRColor.Background.secondary.ignoresSafeArea())
            }
        }
        .navigationTitle("Reserva")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                defer { isLoading = false }
                booking = try? await SupabaseClient.shared.fetchBooking(id: bookingId)
            }
        }
    }

    private func statusHeader(booking: Booking) -> some View {
        VStack(spacing: CRSpacing.s3) {
            let isOwner = booking.ownerId == authService.currentUser?.id
            Text(isOwner ? "Solicitação recebida" : "Sua reserva")
                .font(.crHeading3).foregroundColor(CRColor.Text.primary).padding(.top, CRSpacing.s6)
            bookingStatusBadge(booking.status)
        }
    }

    private func bookingStatusBadge(_ status: Booking.BookingStatus) -> some View {
        let config: (label: String, style: CRBadgeStyle) = {
            switch status {
            case .pending:   return ("Aguardando confirmação", .pending)
            case .accepted:  return ("Aceita", .verified)
            case .confirmed: return ("Confirmada", .verified)
            case .active:    return ("Em andamento", .custom(bg: CRColor.Feedback.infoLight, text: CRColor.Feedback.info))
            case .completed: return ("Concluída", .custom(bg: CRColor.Neutral.n100, text: CRColor.Text.secondary))
            case .declined:  return ("Recusada", .rejected)
            case .cancelled: return ("Cancelada", .rejected)
            }
        }()
        return CRBadge(config.label, style: config.style)
    }

    private func datesSection(booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text("Período da reserva").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            HStack(spacing: CRSpacing.s4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Início").font(.crLabelSM).foregroundColor(CRColor.Text.secondary)
                    Text(booking.startDate.formatted(.dateTime.day().month(.wide).hour().minute()))
                        .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Fim").font(.crLabelSM).foregroundColor(CRColor.Text.secondary)
                    Text(booking.endDate.formatted(.dateTime.day().month(.wide).hour().minute()))
                        .font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                }
            }
            .padding(CRSpacing.s4).background(CRColor.Surface.primary).cornerRadius(CRRadius.md)
        }
    }

    private func financialsSection(booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: CRSpacing.s3) {
            Text("Valores").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            VStack(spacing: CRSpacing.s3) {
                BookingPriceRow(label: "Subtotal", value: "R$ \(Int(booking.totalAmount))")
                BookingPriceRow(label: "Taxa plataforma", value: "R$ \(Int(booking.platformFee))")
                Divider()
                BookingPriceRow(label: "Total pago", value: "R$ \(Int(booking.totalAmount))", isTotal: true)
            }
            .padding(CRSpacing.s4).background(CRColor.Surface.primary).cornerRadius(CRRadius.md)
        }
    }

    private func actionsSection(booking: Booking) -> some View {
        VStack(spacing: CRSpacing.s3) {
            let isOwner = booking.ownerId == authService.currentUser?.id
            if isOwner && booking.status == .pending {
                CRButton("Aceitar reserva", variant: .primary, size: .lg, icon: "checkmark",
                         isFullWidth: true) {}
                CRButton("Recusar", variant: .outline, size: .md, isFullWidth: true) {}
            }
            if booking.canReview {
                CRButton("Avaliar experiência", variant: .primary, size: .lg,
                         icon: "star", isFullWidth: true) {
                    router.present(.review(booking: booking))
                }
            }
            CRButton("Abrir chat", variant: .ghost, size: .md,
                     icon: "message", isFullWidth: true) {}
        }
    }
}

// MARK: - BookingRequestViewModel
@MainActor
final class BookingRequestViewModel: ObservableObject {
    @Published var startDate = Date()
    @Published var endDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @Published var notes = ""
    @Published var agreedToTerms = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showSuccess = false

    var totalHours: Double {
        max(0, endDate.timeIntervalSince(startDate) / 3600)
    }

    var durationLabel: String {
        let h = Int(totalHours)
        let m = Int((totalHours - Double(h)) * 60)
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)min"
    }

    func submitBooking(listing: Listing, renterId: String) async {
        guard !renterId.isEmpty else { errorMessage = "Você precisa estar logado para fazer uma reserva."; return }
        guard totalHours > 0 else { errorMessage = "Selecione um período válido."; return }
        guard agreedToTerms else { errorMessage = "Aceite os termos para continuar."; return }
        isLoading = true; defer { isLoading = false }
        errorMessage = nil
        let booking = Booking(
            id: UUID().uuidString,
            listingId: listing.id,
            renterId: renterId,
            ownerId: listing.ownerId,
            startDate: startDate,
            endDate: endDate,
            totalHours: totalHours,
            totalAmount: listing.pricePerHour * totalHours * 1.10,
            platformFee: listing.pricePerHour * totalHours * 0.10,
            status: .pending,
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            updatedAt: Date()
        )
        do {
            _ = try await SupabaseClient.shared.createBooking(booking)
            HapticFeedback.success()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
    }
}
