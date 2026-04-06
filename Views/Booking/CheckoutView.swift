import SwiftUI

// MARK: - Main Checkout Container
struct CheckoutView: View {
    let listing: Listing
    @StateObject private var vm = BookingViewModel()
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            CheckoutHeader(step: vm.currentStep) {
                if vm.currentStep == .dates { dismiss() }
                else { vm.goBack() }
            }

            // Progress bar
            if vm.currentStep != .processing && vm.currentStep != .confirmation {
                CheckoutProgressBar(progress: vm.currentStep.progress)
            }

            // Step Content
            ZStack {
                switch vm.currentStep {
                case .dates:       BookingDatesView(vm: vm)
                case .details:     BookingDetailsView(vm: vm)
                case .review:      BookingReviewView(vm: vm)
                case .payment:     BookingPaymentView(vm: vm)
                case .processing:  BookingProcessingView()
                case .confirmation:
                    if let booking = vm.completedBooking {
                        BookingConfirmationView(booking: booking, listing: listing) {
                            router.setRoot(.main)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
        }
        .background(Color.crBackground)
        .navigationBarHidden(true)
        .onAppear {
            vm.listing = listing
            vm.loadMockCards()
        }
    }
}

// MARK: - Header
struct CheckoutHeader: View {
    let step: CheckoutStep
    let onBack: () -> Void
    var body: some View {
        HStack {
            if step != .processing && step != .confirmation {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.crTextPrimary)
                }
            }
            Spacer()
            Text(step.title).font(.crH4).foregroundColor(.crTextPrimary)
            Spacer()
            if step != .processing && step != .confirmation {
                // Placeholder for alignment
                Image(systemName: "chevron.left").opacity(0)
            }
        }
        .padding(.horizontal, CRSpacing.base)
        .padding(.vertical, CRSpacing.md)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct CheckoutProgressBar: View {
    let progress: Double
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle().fill(Color.crDivider).frame(height: 3)
            Rectangle()
                .fill(LinearGradient(colors: [.crPrimary, Color(hex: "#9B85D9")], startPoint: .leading, endPoint: .trailing))
                .frame(width: UIScreen.main.bounds.width * progress, height: 3)
                .animation(.spring(response: 0.4), value: progress)
        }
    }
}

// MARK: - Step 1: Dates
struct BookingDatesView: View {
    @ObservedObject var vm: BookingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CRSpacing.xl) {
                // Listing summary
                if let listing = vm.listing {
                    ListingSummaryCard(listing: listing)
                }

                // Date selection
                VStack(alignment: .leading, spacing: CRSpacing.md) {
                    Label("Período", systemImage: "calendar").font(.crH4).foregroundColor(.crTextPrimary)

                    HStack(spacing: CRSpacing.md) {
                        DatePickerField(label: "De", date: $vm.startDate)
                        DatePickerField(label: "Até", date: $vm.endDate)
                    }

                    // Calendar
                    CalendarPickerView(startDate: $vm.startDate, endDate: $vm.endDate)
                        .padding(CRSpacing.md)
                        .background(Color.white)
                        .cornerRadius(CRRadius.lg)
                        .crShadowSoft()
                }

                // Address
                if let listing = vm.listing {
                    Label(listing.address ?? "Endereço não disponível", systemImage: "mappin.circle")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                }

                // Coupon
                CouponField(vm: vm)

                // Price summary
                PriceSummaryCard(vm: vm)

                // CTA
                CRButton(title: "Continuar para pagamento") {
                    vm.advance()
                }
                .padding(.bottom, CRSpacing.xxxl)
            }
            .padding(CRSpacing.base)
        }
    }
}

struct DatePickerField: View {
    let label: String
    @Binding var date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.crCaption).foregroundColor(.crTextTertiary)
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(.crPrimary)
                .padding(CRSpacing.sm)
                .background(Color.white)
                .cornerRadius(CRRadius.md)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.md).stroke(Color.crDivider, lineWidth: 1))
        }
    }
}

// MARK: - Step 2: Details
struct BookingDetailsView: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CRSpacing.xl) {
                Text("Detalhes da entrega").font(.crH4)

                VStack(spacing: CRSpacing.md) {
                    Toggle(isOn: $vm.needsDelivery.animation()) {
                        HStack {
                            Image(systemName: "shippingbox.fill").foregroundColor(.crPrimary)
                            VStack(alignment: .leading) {
                                Text("Quero entrega").font(.crLabel)
                                Text("+ R$ \(Int(vm.listing?.deliveryFee ?? 0))").font(.crBodySmall).foregroundColor(.crTextTertiary)
                            }
                        }
                    }.tint(.crPrimary)

                    if vm.needsDelivery {
                        CRTextField(label: "Endereço de entrega", placeholder: "Rua, número, bairro", text: $vm.deliveryAddress, icon: "mappin")
                        CRTextField(label: "Observações (opcional)", placeholder: "Portão lateral, chamar pelo interfone...", text: $vm.deliveryNotes, icon: "note.text")
                    }
                }
                .padding(CRSpacing.base)
                .background(Color.white)
                .cornerRadius(CRRadius.lg)
                .crShadowSoft()

                // Price update
                PriceSummaryCard(vm: vm)

                CRButton(title: "Revisar pedido") { vm.advance() }
                    .padding(.bottom, CRSpacing.xxxl)
            }
            .padding(CRSpacing.base)
        }
    }
}

// MARK: - Step 3: Review
struct BookingReviewView: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CRSpacing.xl) {
                Text("Revise seu pedido").font(.crH3).foregroundColor(.crTextPrimary)

                if let listing = vm.listing {
                    ListingSummaryCard(listing: listing)
                }

                // Period
                VStack(alignment: .leading, spacing: CRSpacing.sm) {
                    Label("Período", systemImage: "calendar").font(.crH4)
                    HStack {
                        ReviewDetailRow(label: "Check-in", value: vm.startDate.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        ReviewDetailRow(label: "Check-out", value: vm.endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .padding(CRSpacing.md)
                    .background(Color.white)
                    .cornerRadius(CRRadius.md)
                    .crShadowSoft()
                }

                // Delivery
                if vm.needsDelivery {
                    VStack(alignment: .leading, spacing: CRSpacing.sm) {
                        Label("Entrega", systemImage: "shippingbox").font(.crH4)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.deliveryAddress).font(.crBody)
                            if !vm.deliveryNotes.isEmpty {
                                Text(vm.deliveryNotes).font(.crBodySmall).foregroundColor(.crTextSecondary)
                            }
                        }
                        .padding(CRSpacing.md)
                        .background(Color.white)
                        .cornerRadius(CRRadius.md)
                        .crShadowSoft()
                    }
                }

                // Price
                PriceSummaryCard(vm: vm)

                CRButton(title: "Escolher pagamento") { vm.advance() }
                    .padding(.bottom, CRSpacing.xxxl)
            }
            .padding(CRSpacing.base)
        }
    }
}

struct ReviewDetailRow: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.crCaption).foregroundColor(.crTextTertiary)
            Text(value).font(.crLabel).foregroundColor(.crTextPrimary)
        }
    }
}

// MARK: - Step 4: Payment (Stripe-Ready)
struct BookingPaymentView: View {
    @ObservedObject var vm: BookingViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CRSpacing.xl) {
                // Credit Cards
                VStack(alignment: .leading, spacing: CRSpacing.md) {
                    Label("Cartão de crédito", systemImage: "creditcard").font(.crH4).foregroundColor(.crTextPrimary)

                    VStack(spacing: 0) {
                        // Add new card (Stripe sheet trigger)
                        PaymentOptionRow(
                            title: "Novo cartão de crédito",
                            subtitle: nil,
                            icon: "plus.circle",
                            iconColor: .crPrimary,
                            isSelected: false,
                            hasChevron: true
                        ) {
                            // Will trigger Stripe's card sheet
                        }

                        Divider().padding(.leading, 52)

                        ForEach(vm.savedCards) { card in
                            PaymentOptionRow(
                                title: card.displayName,
                                subtitle: "Exp. \(card.expiryMonth)/\(card.expiryYear)",
                                icon: card.brandIcon,
                                iconColor: .crTextTertiary,
                                isSelected: vm.selectedCardId == card.id && vm.selectedPaymentMethod == .creditCard,
                                hasChevron: false
                            ) {
                                vm.selectedPaymentMethod = .creditCard
                                vm.selectedCardId = card.id
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(CRRadius.lg)
                    .crShadowSoft()
                }

                // Other payment methods
                VStack(alignment: .leading, spacing: CRSpacing.md) {
                    Text("Outras formas de pagamento").font(.crH4).foregroundColor(.crTextPrimary)

                    VStack(spacing: 0) {
                        // PIX
                        PaymentOptionRow(
                            title: "PIX",
                            subtitle: nil,
                            icon: "qrcode",
                            iconColor: .crSuccess,
                            isSelected: vm.selectedPaymentMethod == .pix,
                            badge: "10% de desconto",
                            hasChevron: false
                        ) {
                            vm.selectedPaymentMethod = .pix
                        }

                        Divider().padding(.leading, 52)

                        // Apple Pay
                        PaymentOptionRow(
                            title: "Apple Pay",
                            subtitle: nil,
                            icon: "apple.logo",
                            iconColor: .black,
                            isSelected: vm.selectedPaymentMethod == .applePay,
                            hasChevron: false
                        ) {
                            vm.selectedPaymentMethod = .applePay
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(CRRadius.lg)
                    .crShadowSoft()
                }

                // PIX discount notice
                if vm.selectedPaymentMethod == .pix {
                    HStack(spacing: CRSpacing.sm) {
                        Image(systemName: "tag.fill").foregroundColor(.crSuccess)
                        Text("Pagando com PIX você economiza R$ \(String(format: "%.0f", vm.totalAmount * 0.10))!")
                            .font(.crBodySmall).foregroundColor(.crSuccess)
                    }
                    .padding(CRSpacing.md)
                    .background(Color.crSuccess.opacity(0.08))
                    .cornerRadius(CRRadius.md)
                }

                // Coupon
                CouponField(vm: vm)

                // Price summary (with PIX discount if applicable)
                PaymentSummaryCard(vm: vm)

                // Error
                if let error = vm.errorMessage {
                    Text(error).font(.crBodySmall).foregroundColor(.crError)
                        .padding(CRSpacing.md).background(Color.crError.opacity(0.1)).cornerRadius(CRRadius.sm)
                }

                // CTA
                CRButton(
                    title: paymentButtonTitle,
                    isLoading: vm.isLoading
                ) {
                    Task {
                        if let userId = authVM.currentUser?.id {
                            await vm.createBookingAndGetIntent(userId: userId)
                        }
                    }
                }
                .padding(.bottom, CRSpacing.xxxl)

                // Security note
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 11)).foregroundColor(.crTextTertiary)
                    Text("Pagamento processado com segurança via Stripe. Seus dados estão protegidos.")
                        .font(.crCaption).foregroundColor(.crTextTertiary)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, CRSpacing.xl)
            }
            .padding(CRSpacing.base)
        }
    }

    private var paymentButtonTitle: String {
        switch vm.selectedPaymentMethod {
        case .pix: return "Pagar com PIX – R$ \(String(format: "%.0f", vm.pixDiscountedTotal))"
        case .applePay: return "Pagar com Apple Pay"
        case .creditCard: return "Confirmar reserva – R$ \(String(format: "%.0f", vm.totalAmount))"
        }
    }
}

struct PaymentOptionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    var badge: String? = nil
    let hasChevron: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.crBody).foregroundColor(.crTextPrimary)
                    if let sub = subtitle { Text(sub).font(.crCaption).foregroundColor(.crTextTertiary) }
                }

                if let badge = badge {
                    Text(badge)
                        .font(.crCaption).foregroundColor(.crSuccess)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.crSuccess.opacity(0.12)).cornerRadius(CRRadius.pill)
                }

                Spacer()

                if hasChevron {
                    Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.crTextTertiary)
                } else {
                    Circle()
                        .stroke(isSelected ? Color.crPrimary : Color.crDivider, lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().fill(Color.crPrimary).frame(width: 12, height: 12).opacity(isSelected ? 1 : 0))
                }
            }
            .padding(CRSpacing.base)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 5: Processing
struct BookingProcessingView: View {
    @State private var rotation: Double = 0
    var body: some View {
        VStack(spacing: CRSpacing.xxl) {
            Spacer()
            ZStack {
                Circle().stroke(Color.crPrimary.opacity(0.2), lineWidth: 6).frame(width: 100, height: 100)
                Circle().trim(from: 0, to: 0.7)
                    .stroke(Color.crPrimary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 32)).foregroundColor(.crPrimary)
            }
            VStack(spacing: CRSpacing.sm) {
                Text("Processando pagamento").font(.crH3).foregroundColor(.crTextPrimary)
                Text("Aguarde, estamos confirmando sua reserva...").font(.crBody).foregroundColor(.crTextSecondary)
            }
            Spacer()
        }
        .padding(CRSpacing.xl)
    }
}

// MARK: - Confirmation
struct BookingConfirmationView: View {
    let booking: Booking
    let listing: Listing
    let onDone: () -> Void
    @State private var checkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: CRSpacing.xxl) {
                Spacer().frame(height: CRSpacing.hero)

                // Success animation
                ZStack {
                    Circle().fill(Color.crSuccess.opacity(0.15)).frame(width: 120, height: 120)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.crSuccess)
                        .scaleEffect(checkScale)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                        checkScale = 1.0
                    }
                    withAnimation(.easeIn.delay(0.3)) { contentOpacity = 1 }
                }

                VStack(spacing: CRSpacing.sm) {
                    Text("Reserva confirmada! 🎉")
                        .font(.crH2).foregroundColor(.crTextPrimary)
                    Text("Você receberá uma confirmação por email e pelo app.")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)

                // Booking summary card
                VStack(alignment: .leading, spacing: CRSpacing.md) {
                    ListingSummaryCard(listing: listing)

                    VStack(spacing: CRSpacing.sm) {
                        ConfirmationRow(label: "Código da reserva", value: "#\(String(booking.id.prefix(8)).uppercased())")
                        ConfirmationRow(label: "Check-in", value: booking.startDate.formatted(date: .long, time: .omitted))
                        ConfirmationRow(label: "Check-out", value: booking.endDate.formatted(date: .long, time: .omitted))
                        ConfirmationRow(label: "Total pago", value: "R$ \(String(format: "%.2f", booking.totalAmount))")
                        ConfirmationRow(label: "Status", value: booking.bookingStatus.label, valueColor: booking.bookingStatus.color)
                    }
                    .padding(CRSpacing.base)
                    .background(Color.white)
                    .cornerRadius(CRRadius.lg)
                    .crShadowSoft()
                }
                .opacity(contentOpacity)

                VStack(spacing: CRSpacing.md) {
                    CRButton(title: "Ver minhas reservas", variant: .outline) {
                        onDone()
                    }
                    CRButton(title: "Ir para o início") {
                        onDone()
                    }
                }
                .opacity(contentOpacity)
                .padding(.bottom, CRSpacing.xxxl)
            }
            .padding(CRSpacing.base)
        }
    }
}

struct ConfirmationRow: View {
    let label: String
    let value: String
    var valueColor: Color = .crTextPrimary
    var body: some View {
        HStack {
            Text(label).font(.crBody).foregroundColor(.crTextSecondary)
            Spacer()
            Text(value).font(.crLabel).foregroundColor(valueColor)
        }
    }
}

// MARK: - Shared Components
struct ListingSummaryCard: View {
    let listing: Listing
    var body: some View {
        HStack(spacing: CRSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CRRadius.sm)
                    .fill(listing.categoryColor.opacity(0.2))
                    .frame(width: 72, height: 72)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 28)).foregroundColor(listing.categoryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title).font(.crLabel).foregroundColor(.crTextPrimary).lineLimit(1)
                Text(listing.categoryName)
                    .font(.crCaption).foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(listing.categoryColor).cornerRadius(CRRadius.pill)
                Text("Valor da diária · R$ \(Int(listing.dailyPrice))").font(.crBodySmall).foregroundColor(.crTextTertiary)
            }
            Spacer()
        }
        .padding(CRSpacing.md)
        .background(Color.white)
        .cornerRadius(CRRadius.lg)
        .crShadowSoft()
    }
}

struct CouponField: View {
    @ObservedObject var vm: BookingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.sm) {
            Text("Cupom").font(.crH4).foregroundColor(.crTextPrimary)

            if let coupon = vm.appliedCoupon {
                HStack {
                    Image(systemName: "tag.fill").foregroundColor(.crSuccess)
                    Text("\(coupon.code) · \(Int(coupon.discountPercent))% OFF").font(.crLabel).foregroundColor(.crSuccess)
                    Spacer()
                    Button { vm.removeCoupon() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.crTextTertiary)
                    }
                }
                .padding(CRSpacing.md)
                .background(Color.crSuccess.opacity(0.08))
                .cornerRadius(CRRadius.md)
            } else {
                HStack(spacing: CRSpacing.sm) {
                    TextField("Digite seu cupom", text: $vm.couponCode)
                        .font(.crBodyLarge).autocorrectionDisabled()
                        .foregroundColor(.crPrimary)
                    Button(action: { Task { await vm.validateCoupon() } }) {
                        if vm.isValidatingCoupon {
                            ProgressView().scaleEffect(0.8).tint(.crPrimary)
                        } else {
                            Text("Aplicar").font(.crLabel).foregroundColor(vm.couponCode.isEmpty ? .crTextTertiary : .crPrimary)
                        }
                    }
                    .disabled(vm.couponCode.isEmpty || vm.isValidatingCoupon)
                }
                .padding(.horizontal, CRSpacing.base)
                .frame(height: 48)
                .background(Color.white)
                .cornerRadius(CRRadius.md)
                .overlay(RoundedRectangle(cornerRadius: CRRadius.md).stroke(Color.crDivider, lineWidth: 1))

                if let error = vm.couponError {
                    Text(error).font(.crCaption).foregroundColor(.crError)
                }
            }
        }
    }
}

struct PriceSummaryCard: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        VStack(spacing: CRSpacing.sm) {
            PriceRow(label: "Diárias (\(vm.daysCount) dia\(vm.daysCount != 1 ? "s" : ""))", value: "R$ \(String(format: "%.0f", vm.subtotal))")
            if vm.cleaningFee > 0 { PriceRow(label: "Taxa de limpeza", value: "R$ \(Int(vm.cleaningFee))") }
            if vm.deliveryFee > 0 { PriceRow(label: "Entrega", value: "R$ \(Int(vm.deliveryFee))") }
            if vm.discountAmount > 0 { PriceRow(label: "Desconto cupom", value: "- R$ \(String(format: "%.0f", vm.discountAmount))", valueColor: .crSuccess) }
            Divider()
            HStack {
                Text("Total").font(.crLabelLarge).foregroundColor(.crTextPrimary)
                Spacer()
                Text("R$ \(String(format: "%.2f", vm.totalAmount))").font(.crPriceLarge).foregroundColor(.crPrimary)
            }
        }
        .padding(CRSpacing.base)
        .background(Color.white)
        .cornerRadius(CRRadius.lg)
        .crShadowSoft()
    }
}

struct PaymentSummaryCard: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        let total = vm.selectedPaymentMethod == .pix ? vm.pixDiscountedTotal : vm.totalAmount
        VStack(spacing: CRSpacing.sm) {
            PriceRow(label: "Diárias (\(vm.daysCount) dia\(vm.daysCount != 1 ? "s" : ""))", value: "R$ \(String(format: "%.0f", vm.subtotal))")
            if vm.cleaningFee > 0 { PriceRow(label: "Taxa de limpeza", value: "R$ \(Int(vm.cleaningFee))") }
            if vm.deliveryFee > 0 { PriceRow(label: "Entrega", value: "R$ \(Int(vm.deliveryFee))") }
            if vm.discountAmount > 0 { PriceRow(label: "Desconto cupom", value: "- R$ \(String(format: "%.0f", vm.discountAmount))", valueColor: .crSuccess) }
            if vm.selectedPaymentMethod == .pix { PriceRow(label: "Desconto PIX (10%)", value: "- R$ \(String(format: "%.0f", vm.totalAmount * 0.10))", valueColor: .crSuccess) }
            Divider()
            HStack {
                Text("Total").font(.crLabelLarge).foregroundColor(.crTextPrimary)
                Spacer()
                Text("R$ \(String(format: "%.2f", total))").font(.crPriceLarge).foregroundColor(.crPrimary)
            }
        }
        .padding(CRSpacing.base)
        .background(Color.white)
        .cornerRadius(CRRadius.lg)
        .crShadowSoft()
    }
}

struct PriceRow: View {
    let label: String
    let value: String
    var valueColor: Color = .crTextPrimary
    var body: some View {
        HStack {
            Text(label).font(.crBody).foregroundColor(.crTextSecondary)
            Spacer()
            Text(value).font(.crLabel).foregroundColor(valueColor)
        }
    }
}

// MARK: - Calendar Picker
struct CalendarPickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var displayedMonth: Date = Date()
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: CRSpacing.md) {
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.crPrimary)
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.crLabel)
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold)).foregroundColor(.crPrimary)
                }
            }

            let days = ["D","S","T","Q","Q","S","S"]
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { d in
                    Text(d).font(.crCaption).foregroundColor(.crTextTertiary).frame(maxWidth: .infinity)
                }
            }

            let monthDays = daysInMonth(displayedMonth)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(monthDays, id: \.self) { date in
                    if let date = date {
                        DayCell(date: date, startDate: startDate, endDate: endDate) {
                            handleDateTap(date)
                        }
                    } else {
                        Text("").frame(height: 36)
                    }
                }
            }
        }
    }

    private func changeMonth(_ by: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: by, to: displayedMonth) ?? displayedMonth
    }

    private func handleDateTap(_ date: Date) {
        let today = calendar.startOfDay(for: Date())
        guard date >= today else { return }
        if date <= startDate || date == startDate {
            startDate = date
            endDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        } else {
            endDate = date
        }
    }

    private func daysInMonth(_ date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else { return [] }
        let weekday = calendar.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for d in range {
            days.append(calendar.date(byAdding: .day, value: d - 1, to: first))
        }
        return days
    }
}

struct DayCell: View {
    let date: Date
    let startDate: Date
    let endDate: Date
    let action: () -> Void
    private let calendar = Calendar.current

    var isStart: Bool { calendar.isDate(date, inSameDayAs: startDate) }
    var isEnd:   Bool { calendar.isDate(date, inSameDayAs: endDate) }
    var isInRange: Bool {
        date > startDate && date < endDate
    }
    var isPast: Bool { date < calendar.startOfDay(for: Date()) }

    var body: some View {
        Button(action: action) {
            Text("\(calendar.component(.day, from: date))")
                .font(isStart || isEnd ? .crLabel : .crBody)
                .foregroundColor(cellTextColor)
                .frame(width: 36, height: 36)
                .background(cellBg)
                .cornerRadius(isStart || isEnd ? CRRadius.pill : (isInRange ? 0 : CRRadius.pill))
        }
        .buttonStyle(.plain)
        .disabled(isPast)
        .opacity(isPast ? 0.3 : 1)
    }

    var cellTextColor: Color {
        if isStart || isEnd { return .white }
        if isInRange { return .crPrimary }
        return .crTextPrimary
    }
    var cellBg: Color {
        if isStart || isEnd { return .crPrimary }
        if isInRange { return .crPrimary.opacity(0.12) }
        return .clear
    }
}
