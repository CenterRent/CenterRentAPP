import Foundation

// MARK: - Supabase Configuration
public struct SupabaseConfig {
    static let projectURL   = "https://vdfcbbycsrrdogtqyosp.supabase.co"
    static let anonKey      = "sb_publishable_yJFFYvk-Hq2EggcGBrR93w_-sdm6VxG"
    static let serviceKey   = "" // apenas server-side — não usar no app

    struct Tables {
        static let profiles         = "profiles"
        static let listings         = "listings"
        static let bookings         = "bookings"
        static let messages         = "messages"
        static let conversations    = "conversations"
        static let reviews          = "reviews"
        static let referrals        = "referrals"
        static let rewards          = "rewards"
        static let otpCodes         = "otp_codes"
        static let notifications    = "notifications"
    }

    struct Storage {
        static let profileImages    = "profile-images"
        static let listingImages    = "listing-images"
        static let documents        = "verification-documents"
    }

    struct Functions {
        static let sendOTP          = "send-otp"
        static let verifyOTP        = "verify-otp"
        static let createBooking    = "create-booking"
        static let processReferral  = "process-referral"
    }
}

// MARK: - Network Error
public enum NetworkError: LocalizedError {
    case invalidURL
    case noResponse
    case unauthorized
    case notFound
    case serverError(Int, String?)
    case decodingError(Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:              return "URL inválida."
        case .noResponse:             return "Sem resposta do servidor."
        case .unauthorized:           return "Não autorizado."
        case .notFound:               return "Recurso não encontrado."
        case .serverError(let c, _):  return "Erro do servidor (\(c))."
        case .decodingError:          return "Erro ao processar resposta."
        case .unknown:                return "Erro desconhecido."
        }
    }
}

// MARK: - SupabaseClient
/// Camada de abstração sobre o SDK Supabase Swift
/// Instalar via SPM: https://github.com/supabase/supabase-swift
/// import Supabase
public final class SupabaseClient {
    public static let shared = SupabaseClient()

    // Quando o SDK Supabase estiver integrado:
    // private let client = Supabase.SupabaseClient(
    //     supabaseURL: URL(string: SupabaseConfig.projectURL)!,
    //     supabaseKey: SupabaseConfig.anonKey
    // )

    private let baseURL: String = SupabaseConfig.projectURL
    private var session: URLSession = .shared
    private var authToken: String? = nil

    private init() {}

    // MARK: - Auth
    func getCurrentUserProfile() async throws -> UserProfile {
        // return try await client.auth.session.user → fetch profile
        throw NetworkError.unauthorized // placeholder até SDK instalado
    }

    func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        // let session = try await client.auth.signIn(email: email, password: password)
        // return try await fetchProfile(userId: session.user.id)
        throw NetworkError.unknown
    }

    func signUpWithEmail(email: String, password: String) async throws -> UserProfile {
        // let session = try await client.auth.signUp(email: email, password: password)
        // return try await createProfile(userId: session.user.id, email: email)
        throw NetworkError.unknown
    }

    func signInWithGoogle() async throws -> UserProfile {
        // try await client.auth.signInWithOAuth(provider: .google)
        throw NetworkError.unknown
    }

    func signInWithApple() async throws -> UserProfile {
        // try await client.auth.signInWithOAuth(provider: .apple)
        throw NetworkError.unknown
    }

    func signOut() async throws {
        // try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        // try await client.auth.resetPasswordForEmail(email)
    }

    func deleteAccount() async throws {
        // try await client.functions.invoke("delete-account")
    }

    // MARK: - OTP (via Supabase Edge Function → Twilio)
    func sendOTP(phoneNumber: String) async throws {
        // try await client.functions.invoke(
        //   SupabaseConfig.Functions.sendOTP,
        //   invokeOptions: .init(body: ["phone": phoneNumber])
        // )
    }

    func verifyOTP(phoneNumber: String, code: String) async throws {
        // let result = try await client.functions.invoke(
        //   SupabaseConfig.Functions.verifyOTP,
        //   invokeOptions: .init(body: ["phone": phoneNumber, "code": code])
        // )
        // guard result.status == "verified" else { throw AuthError.otpInvalid }
    }

    // MARK: - Profile
    func fetchProfile(userId: String) async throws -> UserProfile {
        // return try await client.database
        //   .from(SupabaseConfig.Tables.profiles)
        //   .select()
        //   .eq("id", value: userId)
        //   .single()
        //   .execute()
        //   .value
        throw NetworkError.notFound
    }

    func updateProfile(_ profile: UserProfile) async throws {
        // try await client.database
        //   .from(SupabaseConfig.Tables.profiles)
        //   .update(profile)
        //   .eq("id", value: profile.id)
        //   .execute()
    }

    // MARK: - Listings
    func fetchListings(filter: ListingFilter) async throws -> [Listing] {
        // var query = client.database
        //   .from(SupabaseConfig.Tables.listings)
        //   .select("*, profiles(*)")
        //   .eq("status", value: "active")
        // if !filter.city.isEmpty { query = query.eq("address->city", value: filter.city) }
        // if filter.onlyVerified { query = query.eq("is_verified_owner", value: true) }
        // return try await query.execute().value
        return []
    }

    func fetchListing(id: String) async throws -> Listing {
        // return try await client.database
        //   .from(SupabaseConfig.Tables.listings)
        //   .select("*, profiles(*), reviews(*)")
        //   .eq("id", value: id)
        //   .single()
        //   .execute()
        //   .value
        throw NetworkError.notFound
    }

    func createListing(_ listing: Listing) async throws -> Listing {
        throw NetworkError.unknown
    }

    func updateListing(_ listing: Listing) async throws -> Listing {
        throw NetworkError.unknown
    }

    func updateListingStatus(id: String, status: Listing.ListingStatus) async throws {
        // try await client.database
        //   .from(SupabaseConfig.Tables.listings)
        //   .update(["status": status.rawValue, "updated_at": Date()])
        //   .eq("id", value: id)
        //   .execute()
    }

    func deleteListing(id: String) async throws {
        // soft delete: .update(["status": "deleted"])
    }

    // MARK: - Bookings
    func createBooking(_ booking: Booking) async throws -> Booking {
        // try await client.functions.invoke(
        //   SupabaseConfig.Functions.createBooking,
        //   invokeOptions: .init(body: booking)
        // )
        throw NetworkError.unknown
    }

    func fetchBooking(id: String) async throws -> Booking {
        // return try await client.database
        //   .from(SupabaseConfig.Tables.bookings)
        //   .select("*, listings(*)")
        //   .eq("id", value: id)
        //   .single()
        //   .execute()
        //   .value
        throw NetworkError.notFound
    }

    func fetchBookings(userId: String, role: BookingRole) async throws -> [Booking] {
        // let column = role == .renter ? "renter_id" : "owner_id"
        // return try await client.database
        //   .from(SupabaseConfig.Tables.bookings)
        //   .select("*, listings(*)")
        //   .eq(column, value: userId)
        //   .order("created_at", ascending: false)
        //   .execute()
        //   .value
        return []
    }

    func updateBookingStatus(id: String, status: Booking.BookingStatus) async throws {
        // try await client.database
        //   .from(SupabaseConfig.Tables.bookings)
        //   .update(["status": status.rawValue, "updated_at": Date()])
        //   .eq("id", value: id)
        //   .execute()
    }

    // MARK: - Messages (Realtime)
    func fetchConversations(userId: String) async throws -> [Conversation] { return [] }
    func fetchMessages(conversationId: String) async throws -> [ChatMessage] { return [] }
    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage { throw NetworkError.unknown }

    func subscribeToConversation(id: String, handler: @escaping ([ChatMessage]) -> Void) {
        // client.realtime
        //   .channel("conversation:\(id)")
        //   .on(.postgresChanges, filter: .init(event: .insert, schema: "public", table: "messages"))
        //   { payload in handler([payload.newRecord]) }
        //   .subscribe()
    }

    // MARK: - Reviews
    func createReview(_ review: Review) async throws -> Review { throw NetworkError.unknown }
    func fetchReviews(targetId: String) async throws -> [Review] { return [] }

    // MARK: - Referrals
    func applyReferralCode(_ code: String, userId: String) async throws { }
    func fetchReferrals(userId: String) async throws -> [Referral] { return [] }

    // MARK: - Storage
    func uploadImage(data: Data, bucket: String, path: String) async throws -> String {
        // let response = try await client.storage.from(bucket).upload(path: path, file: data)
        // return client.storage.from(bucket).getPublicURL(path: path).absoluteString
        throw NetworkError.unknown
    }
}

// MARK: - Booking Role
public enum BookingRole {
    case renter, owner
}
