import Foundation
import UIKit
import Supabase

// MARK: - Supabase Manager
// Singleton de acesso ao cliente Supabase do Center Rent

final class SupabaseManager {

    // MARK: - Singleton
    static let shared = SupabaseManager()
    private init() {}

    // MARK: - Client
    // Usa SupabaseConfig como fonte única — URL + anon key estão em SupabaseClient.swift
    let client = Supabase.SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.projectURL)!,
        supabaseKey: SupabaseConfig.anonKey
    )

    // MARK: - Convenience accessors
    var auth: AuthClient { client.auth }
    // `client.database` deprecated in SDK 2.x — use `client.from()` directly
    var storage: StorageFileApi { client.storage.from("avatars") }
    var realtime: RealtimeClientV2 { client.realtimeV2 }
}

// MARK: - Table Names
extension SupabaseManager {
    enum Table {
        static let profiles       = "profiles"
        static let listings       = "listings"
        static let bookings       = "bookings"
        static let conversations  = "conversations"
        static let messages       = "messages"
        static let reviews        = "reviews"
        static let referrals      = "referrals"
        static let rewards        = "rewards"
        static let notifications  = "notifications"
        static let favorites      = "favorites"
        static let otpCodes       = "otp_codes"
        static let availabilitySlots = "availability_slots"
        static let amenities         = "amenities"
        static let listingAmenities  = "listing_amenities"
    }
}

// MARK: - ListingRow  (decodifica colunas snake_case do banco → converte para Listing)
private struct ListingRow: Decodable {
    let id: String
    let owner_id: String
    let title: String
    let description: String?
    let address: AddressInfo
    let price_per_hour: Double
    let price_per_day: Double?
    let price_per_month: Double?
    let image_urls: [String]?
    let amenities: [String]?
    let specialties: [String]?
    let equipment: [String]?
    let capacity: Int?
    let area: Double?
    let status: String
    let rules: String?
    let rating: Double?
    let review_count: Int?
    let total_bookings: Int?
    let is_verified_owner: Bool?
    let is_premium: Bool?
    let created_at: Date?
    let updated_at: Date?

    func toListing() -> Listing {
        Listing(
            id: id, ownerId: owner_id,
            title: title, description: description ?? "",
            address: address,
            pricePerHour: price_per_hour,
            pricePerDay: price_per_day,
            pricePerMonth: price_per_month,
            imageURLs: image_urls ?? [],
            amenities: amenities ?? [],
            specialties: specialties ?? [],
            equipment: equipment ?? [],
            capacity: capacity ?? 1,
            area: area ?? 0,
            status: Listing.ListingStatus(rawValue: status) ?? .draft,
            availability: [],
            rules: rules,
            rating: rating ?? 0,
            reviewCount: review_count ?? 0,
            totalBookings: total_bookings ?? 0,
            isVerifiedOwner: is_verified_owner ?? false,
            isPremium: is_premium ?? false,
            createdAt: created_at ?? Date(),
            updatedAt: updated_at ?? Date()
        )
    }
}

// MARK: - Storage Buckets
extension SupabaseManager {
    enum Bucket {
        static let avatars        = "avatars"
        static let listingImages  = "listing-images"
    }
}

// MARK: - Edge Functions
extension SupabaseManager {
    enum EdgeFunction {
        static let sendOTP        = "send-otp"
        static let verifyOTP      = "verify-otp"
        static let createBooking  = "create-booking"
        static let processReferral = "process-referral"
        static let sendNotification = "send-notification"
        static let deleteAccount  = "delete-account"
    }
}

// MARK: - Auth Methods (used by AuthService)
extension SupabaseManager {
    func getCurrentUserProfile() async throws -> UserProfile {
        guard let user = auth.currentUser else {
            throw NSError(domain: "Auth", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        return try await fetchProfile(userId: user.id.uuidString)
    }

    func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        let session = try await auth.signIn(email: email, password: password)
        let userId  = session.user.id.uuidString
        // Profile might not exist yet if trigger hasn't created it — fall back to stub
        do {
            return try await fetchProfile(userId: userId)
        } catch {
            // Create a minimal profile so the user can continue into the app
            let stub = UserProfile.stub(id: userId, email: session.user.email ?? email)
            _ = try? await client
                .from(Table.profiles)
                .upsert(stub, onConflict: "id")
                .execute()
            return stub
        }
    }

    func signUpWithEmail(email: String, password: String) async throws -> UserProfile {
        let response = try await auth.signUp(email: email, password: password)

        // Case 1 — email confirmation NOT required → session returned
        if let session = response.session {
            let userId = session.user.id.uuidString
            do {
                return try await fetchProfile(userId: userId)
            } catch {
                // Profile not created by trigger yet — create stub
                let stub = UserProfile.stub(id: userId, email: session.user.email ?? email)
                _ = try? await client
                    .from(Table.profiles)
                    .upsert(stub, onConflict: "id")
                    .execute()
                return stub
            }
        }

        // Case 2 — email confirmation IS required → no session
        // User exists in auth.users but needs to verify email before logging in
        throw NSError(
            domain: "Auth", code: 202,
            userInfo: [NSLocalizedDescriptionKey:
                "Cadastro realizado! Verifique seu e-mail para confirmar a conta."]
        )
    }

    func signInWithGoogle() async throws -> UserProfile {
        // OAuth requires platform-specific handling
        throw NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "Google sign-in not yet implemented"])
    }

    func signInWithApple() async throws -> UserProfile {
        throw NSError(domain: "Auth", code: 501, userInfo: [NSLocalizedDescriptionKey: "Apple sign-in not yet implemented"])
    }

    func signOut() async throws {
        try await auth.signOut()
    }

    func sendOTP(phoneNumber: String) async throws {
        try await client.functions.invoke(EdgeFunction.sendOTP, options: FunctionInvokeOptions(body: ["phone": phoneNumber]))
    }

    func verifyOTP(phoneNumber: String, code: String) async throws {
        try await client.functions.invoke(EdgeFunction.verifyOTP, options: FunctionInvokeOptions(body: ["phone": phoneNumber, "code": code]))
    }

    func updateProfile(_ profile: UserProfile) async throws {
        try await client.from(Table.profiles).update(profile).eq("id", value: profile.id).execute()
    }

    func deleteAccount() async throws {
        try await client.functions.invoke(EdgeFunction.deleteAccount)
    }

    func resetPassword(email: String) async throws {
        try await auth.resetPasswordForEmail(email)
    }

    func fetchProfile(userId: String) async throws -> UserProfile {
        try await client.from(Table.profiles).select("*").eq("id", value: userId).single().execute().value
    }
}

// MARK: - Booking Methods
extension SupabaseManager {
    func createBooking(_ booking: BookingRequest) async throws -> Booking {
        return try await client.from(Table.bookings)
            .insert(booking)
            .select()
            .single()
            .execute()
            .value
    }

    func createPaymentIntent(bookingId: String, amount: Int, currency: String = "brl") async throws -> PaymentIntentResponse {
        return try await client.functions.invoke(
            EdgeFunction.createBooking,
            options: FunctionInvokeOptions(body: [
                "booking_id": bookingId,
                "amount": String(amount),
                "currency": currency
            ])
        )
    }
}

// MARK: - Payment Intent Response
struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
    enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case paymentIntentId = "payment_intent_id"
    }
}



// MARK: - Listing Methods
extension SupabaseManager {
    func fetchCategories() async throws -> [SpaceCategory] {
        return try await client.from("space_categories")
            .select("*")
            .order("display_order")
            .execute()
            .value
    }

    func fetchListings(limit: Int) async throws -> [Listing] {
        let rows: [ListingRow] = try await client.from(Table.listings)
            .select("*")
            .eq("status", value: "active")
            .limit(limit)
            .execute()
            .value
        return rows.map { $0.toListing() }
    }

    func fetchListings(categoryId: String, limit: Int) async throws -> [Listing] {
        let rows: [ListingRow] = try await client.from(Table.listings)
            .select("*")
            .eq("status", value: "active")
            .limit(limit)
            .execute()
            .value
        return rows.map { $0.toListing() }
    }

    /// Full-text search + filter for SearchView (with pagination)
    /// IMPORTANT: In the Supabase Swift SDK, all filter methods (eq/ilike/gte/lte)
    /// must be called BEFORE transform methods (order/range/limit).
    /// Calling .range() first changes the type to PostgrestTransformBuilder,
    /// which has no filter members — causing build errors.
    func searchListings(query: String, filter: ListingFilter, limit: Int = 20, offset: Int = 0) async throws -> [Listing] {
        // 1. Build filter chain first (all on PostgrestFilterBuilder)
        var q = client.from(Table.listings)
            .select("*")
            .eq("status", value: "active")

        if !query.isEmpty       { q = q.ilike("title",            pattern: "%\(query)%") }
        if !filter.city.isEmpty { q = q.ilike("city",             pattern: "%\(filter.city)%") }
        if let min = filter.minPrice { q = q.gte("price_per_hour", value: min) }
        if let max = filter.maxPrice { q = q.lte("price_per_hour", value: max) }
        if filter.onlyVerified  { q = q.eq("is_verified_owner",   value: true) }

        // 2. Apply transform ops (order + range) in a single terminal chain
        let from = offset, to = offset + limit - 1
        let rows: [ListingRow]
        switch filter.sortBy {
        case .priceLow:
            rows = try await q.order("price_per_hour", ascending: true).range(from: from, to: to).execute().value
        case .priceHigh:
            rows = try await q.order("price_per_hour", ascending: false).range(from: from, to: to).execute().value
        case .rating:
            rows = try await q.order("rating", ascending: false).range(from: from, to: to).execute().value
        case .newest:
            rows = try await q.order("created_at", ascending: false).range(from: from, to: to).execute().value
        case .relevance:
            rows = try await q.range(from: from, to: to).execute().value
        }
        return rows.map { $0.toListing() }
    }

    /// Fetch all listings belonging to a specific owner (for MyListingsView)
    func fetchListings(ownerId: String) async throws -> [Listing] {
        let rows: [ListingRow] = try await client.from(Table.listings)
            .select("*")
            .eq("owner_id", value: ownerId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toListing() }
    }

    /// Busca um único listing por ID.
    func fetchListing(id: String) async throws -> Listing {
        let row: ListingRow = try await client.from(Table.listings)
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return row.toListing()
    }

    // MARK: - Create Listing
    /// Insere listing no banco e associa os amenity IDs na junction table.
    /// Retorna o UUID do listing criado.
    func createListing(payload: ListingInsertPayload, amenityIds: [String]) async throws -> String {
        struct InsertResponse: Decodable { let id: String }

        let response: InsertResponse = try await client
            .from(Table.listings)
            .insert(payload)
            .select("id")
            .single()
            .execute()
            .value

        // Junction listing_amenities (best-effort — não bloqueia publicação se falhar)
        if !amenityIds.isEmpty {
            struct Junction: Encodable {
                let listing_id: String
                let amenity_id: String
            }
            let junctions = amenityIds.map { Junction(listing_id: response.id, amenity_id: $0) }
            _ = try? await client.from(Table.listingAmenities).insert(junctions).execute()
        }

        return response.id
    }

    // MARK: - Update Listing
    /// Atualiza os campos editáveis de um listing existente (sem alterar owner_id, created_at, etc).
    func updateListing(id: String, payload: ListingUpdatePayload) async throws {
        try await client.from(Table.listings)
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Upload Listing Images
    /// Faz upload de imagens para o bucket `listing-images/{ownerId}/{listingId}/N.jpg`
    /// e retorna a lista de URLs públicas.
    /// Lança erro se nenhuma imagem for enviada com sucesso.
    func uploadListingImages(images: [UIImage],
                             ownerId: String,
                             listingId: String) async throws -> [String] {
        var urls: [String] = []
        var lastError: Error? = nil
        let bucket = client.storage.from(Bucket.listingImages)

        for (index, image) in images.enumerated() {
            // 1. Redimensiona para max 1920px
            let resized = image.crResized(maxDimension: 1920)

            // 2. Comprime em JPEG — tenta qualidades decrescentes até caber em 4 MB
            guard let data = resized.crCompressed(targetMaxBytes: 4 * 1024 * 1024) else {
                print("⚠️ Não foi possível comprimir imagem \(index)")
                continue
            }

            // UUIDs em lowercase — RLS compara auth.uid()::text (sempre lowercase)
            let path = "\(ownerId.lowercased())/\(listingId.lowercased())/\(index).jpg"
            do {
                _ = try await bucket.upload(
                    path,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
                let publicURL = try bucket.getPublicURL(path: path)
                urls.append(publicURL.absoluteString)
                print("✅ Upload OK: \(publicURL.absoluteString)")
            } catch {
                print("❌ Upload falhou para \(path): \(error.localizedDescription)")
                lastError = error
            }
        }

        // Lança erro apenas se NENHUMA imagem foi enviada
        if urls.isEmpty, let err = lastError {
            throw err
        }

        return urls
    }

    /// Atualiza a coluna `image_urls` de um listing existente.
    func updateListingImageURLs(listingId: String, urls: [String]) async throws {
        struct Patch: Encodable { let image_urls: [String] }
        try await client.from(Table.listings)
            .update(Patch(image_urls: urls))
            .eq("id", value: listingId)
            .execute()
    }
}

// MARK: - Amenity Methods
extension SupabaseManager {

    /// Busca amenities do banco (sistema + do usuário logado).
    /// Cai no fallback local se o banco ainda não tiver a tabela migrada.
    func fetchAmenities(userId: String) async throws -> [Amenity] {
        do {
            return try await client.from(Table.amenities)
                .select("*")
                .or("is_system.eq.true,created_by.eq.\(userId)")
                .order("category")
                .order("name")
                .execute()
                .value
        } catch {
            // Tabela ainda não migrada → retorna lista local
            return Amenity.defaults
        }
    }

    /// Cria um amenity personalizado pelo usuário e o retorna com o UUID do banco.
    func createAmenity(name: String, icon: String, category: String, userId: String) async throws -> Amenity {
        struct Payload: Encodable {
            let name: String
            let icon: String
            let category: String
            let is_system: Bool
            let created_by: String
        }
        return try await client
            .from(Table.amenities)
            .insert(Payload(name: name, icon: icon, category: category, is_system: false, created_by: userId))
            .select()
            .single()
            .execute()
            .value
    }

    /// Fetch bookings for a user (as renter or owner)
    func fetchBookings(userId: String, role: BookingRole) async throws -> [Booking] {
        let column = role == .renter ? "renter_id" : "owner_id"
        return try await client.from(Table.bookings)
            .select("*")
            .eq(column, value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
