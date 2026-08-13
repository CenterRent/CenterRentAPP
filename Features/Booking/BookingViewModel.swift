import Foundation
import SwiftUI
import Combine

// MARK: - Checkout Steps (Stripe-Ready Flow)
enum CheckoutStep: Int, CaseIterable {
    case dates       = 0  // Select dates & review listing
    case details     = 1  // Delivery address / notes
    case review      = 2  // Full order review
    case payment     = 3  // Payment method selection
    case processing  = 4  // Processing payment
    case confirmation = 5 // Success screen

    var title: String {
        switch self {
        case .dates:        return "Reserva"
        case .details:      return "Detalhes"
        case .review:       return "Revise e continue"
        case .payment:      return "Pagamento"
        case .processing:   return "Processando"
        case .confirmation: return "Confirmado!"
        }
    }
    var progress: Double {
        switch self {
        case .dates:        return 0.2
        case .details:      return 0.4
        case .review:       return 0.6
        case .payment:      return 0.8
        case .processing:   return 0.9
        case .confirmation: return 1.0
        }
    }
}

@MainActor
final class BookingViewModel: ObservableObject {
    // Listing
    @Published var listing: Listing?

    // Date Selection
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    // Delivery
    @Published var deliveryAddress = ""
    @Published var deliveryNotes = ""
    @Published var needsDelivery = false

    // Coupon
    @Published var couponCode = ""
    @Published var appliedCoupon: AppliedCoupon?
    @Published var couponError: String?
    @Published var isValidatingCoupon = false

    // Payment
    @Published var selectedPaymentMethod: PaymentMethod = .creditCard
    @Published var savedCards: [SavedCard] = []
    @Published var selectedCardId: String?

    // Checkout flow
    @Published var currentStep: CheckoutStep = .dates
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var completedBooking: Booking?

    // Stripe
    @Published var stripeClientSecret: String?

    private let supabase = SupabaseManager.shared

    // MARK: - Computed Price
    var daysCount: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }
    var subtotal: Double   { Double(daysCount) * (listing?.dailyPrice ?? 0) }
    var cleaningFee: Double { listing?.cleaningFee ?? 0 }
    var deliveryFee: Double { needsDelivery ? (listing?.deliveryFee ?? 0) : 0 }
    var discountAmount: Double { appliedCoupon?.discountAmount(for: subtotal) ?? 0 }
    var totalAmount: Double { subtotal + cleaningFee + deliveryFee - discountAmount }

    // Stripe amount in cents
    var stripeAmountCents: Int { Int(totalAmount * 100) }

    // PIX discount (10%)
    var pixDiscountedTotal: Double { totalAmount * 0.90 }

    // MARK: - Navigation
    func advance() {
        let next = CheckoutStep(rawValue: currentStep.rawValue + 1) ?? .confirmation
        withAnimation(.easeInOut(duration: 0.3)) { currentStep = next }
    }

    func goBack() {
        guard currentStep.rawValue > 0 else { return }
        let prev = CheckoutStep(rawValue: currentStep.rawValue - 1) ?? .dates
        withAnimation(.easeInOut(duration: 0.3)) { currentStep = prev }
    }

    func goToStep(_ step: CheckoutStep) {
        withAnimation(.easeInOut(duration: 0.3)) { currentStep = step }
    }

    // MARK: - Validate Coupon
    func validateCoupon() async {
        guard !couponCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isValidatingCoupon = true; couponError = nil
        // Simulate API call - replace with actual Supabase/Stripe coupon validation
        try? await Task.sleep(nanoseconds: 800_000_000)
        let validCoupons: [String: Double] = ["CENTRO10": 10, "WELCOME20": 20, "FIRSTRENT": 15]
        if let discount = validCoupons[couponCode.uppercased()] {
            appliedCoupon = AppliedCoupon(code: couponCode, discountPercent: discount)
        } else {
            couponError = "Cupom inválido ou expirado"
            appliedCoupon = nil
        }
        isValidatingCoupon = false
    }

    func removeCoupon() {
        appliedCoupon = nil
        couponCode = ""
        couponError = nil
    }

    // MARK: - Create Booking & Get Stripe Intent
    func createBookingAndGetIntent(userId: String) async {
        guard let listing = listing else { return }
        isLoading = true; errorMessage = nil
        goToStep(.processing)

        do {
            // 1. Create booking in Supabase
            let request = BookingRequest(
                listingId: listing.id, renterId: userId, ownerId: listing.ownerId,
                startDate: startDate, endDate: endDate,
                dailyPrice: listing.dailyPrice, daysCount: daysCount,
                cleaningFee: cleaningFee, deliveryFee: deliveryFee,
                discountAmount: discountAmount, totalAmount: totalAmount,
                couponCode: appliedCoupon?.code,
                paymentMethod: selectedPaymentMethod
            )
            let booking = try await supabase.createBooking(request)

            // 2. Get Stripe Payment Intent (for card payments)
            if selectedPaymentMethod == .creditCard {
                let intentResponse = try await supabase.createPaymentIntent(
                    bookingId: booking.id, amount: stripeAmountCents
                )
                stripeClientSecret = intentResponse.clientSecret
            }

            completedBooking = booking
            goToStep(.confirmation)
        } catch {
            errorMessage = "Erro ao processar reserva. Tente novamente."
            goToStep(.payment)
        }
        isLoading = false
    }

    // MARK: - Mock data load
    func loadMockCards() {
        savedCards = [
            SavedCard(id: "c1", brand: "Mastercard", lastFour: "0498", expiryMonth: 12, expiryYear: 2028),
        ]
        selectedCardId = savedCards.first?.id
    }
}

// MARK: - Supporting Types
struct AppliedCoupon {
    let code: String
    let discountPercent: Double

    func discountAmount(for subtotal: Double) -> Double {
        subtotal * (discountPercent / 100)
    }
}

struct SavedCard: Identifiable {
    let id: String
    let brand: String
    let lastFour: String
    let expiryMonth: Int
    let expiryYear: Int

    var displayName: String { "\(brand) **** **** **** \(lastFour)" }
    var brandIcon: String {
        switch brand.lowercased() {
        case "visa": return "creditcard.fill"
        case "mastercard": return "creditcard.fill"
        default: return "creditcard.fill"
        }
    }
}
