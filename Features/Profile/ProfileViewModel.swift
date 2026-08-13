import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var myBookings: [Booking] = []
    @Published var myListings: [Listing] = []
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
            // myBookings = try await supabase.fetchMyBookings(userId: userId)
        } catch {
            loadMockProfile()
        }
        isLoading = false
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
