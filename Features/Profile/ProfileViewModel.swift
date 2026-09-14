import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var myBookings: [Booking] = []
    @Published var myListings: [Listing] = []
    /// Listing (título, imagens...) de cada reserva em myBookings, por listingId —
    /// usado pelos cards de MyBookingsView em vez de texto fixo.
    @Published var bookingListings: [String: Listing] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Tabs for bookings
    @Published var bookingTab: BookingTab = .active

    enum BookingTab: String, CaseIterable {
        case active   = "Ativos"
        case upcoming = "Futuros"
        case history  = "Histórico"
    }

    private let supabase = SupabaseManager.shared

    var filteredBookings: [Booking] {
        switch bookingTab {
        case .active:   return myBookings.filter { $0.status == .active }
        case .upcoming: return myBookings.filter { $0.status == .confirmed }
        case .history:  return myBookings.filter { $0.status == .completed || $0.status == .cancelled }
        }
    }

    var isOwnerOrBoth: Bool {
        profile?.registrationNumber.isEmpty == false
    }

    func loadProfile(userId: String) async {
        isLoading = true
        do {
            profile = try await supabase.fetchProfile(userId: userId)
        } catch {
            loadMockProfile()
        }
        await loadMyBookings(userId: userId)
        isLoading = false
    }

    /// Busca as reservas do usuário como locatário e, em seguida, os listings
    /// associados (título/imagens) para os cards de MyBookingsView.
    func loadMyBookings(userId: String) async {
        do {
            myBookings = try await supabase.fetchBookings(userId: userId, role: .renter)
            let listingIds = Array(Set(myBookings.map { $0.listingId }))
            let listings = try await supabase.fetchListings(ids: listingIds)
            bookingListings = Dictionary(uniqueKeysWithValues: listings.map { ($0.id, $0) })
        } catch {
            errorMessage = "Não foi possível carregar suas reservas."
        }
    }

    /// Cancela uma reserva confirmada e atualiza a lista local.
    func cancelBooking(_ booking: Booking) async {
        do {
            try await supabase.updateBookingStatus(id: booking.id, status: .cancelled)
            if let index = myBookings.firstIndex(where: { $0.id == booking.id }) {
                myBookings[index].status = .cancelled
            }
        } catch {
            errorMessage = "Não foi possível cancelar a reserva."
        }
    }

    func signOut(authVM: AuthViewModel) async {
        await authVM.signOut()
    }

    private func loadMockProfile() {
        profile = UserProfile(
            id: "mock", email: "marcela@exemplo.com", fullName: "Dra. Marcela Oliveira",
            specialty: "Odontologia", registrationNumber: "CRO 12345", registrationState: "SP",
            phoneNumber: "(11) 99999-9999", phoneVerified: true, phoneVerificationAttempts: 0,
            profileImageURL: nil, verificationStatus: .verified, verificationDocumentURL: nil,
            referralCode: "MARCELA123", referredBy: nil, bio: "Dentista especialista em implantes.",
            createdAt: Date(), updatedAt: Date(), isActive: true
        )
    }
}
