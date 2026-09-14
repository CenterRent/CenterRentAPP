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

    /// Faz upload da foto de perfil para o bucket `avatars/{userId}.jpg`
    /// (mesmo padrão de uploadListingImages) e retorna a URL pública.
    /// Usado por ProfileSetupView (foto no onboarding pós-cadastro).
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        let resized = image.crResized(maxDimension: 800)
        guard let data = resized.crCompressed(targetMaxBytes: 2 * 1024 * 1024) else {
            throw NSError(domain: "Storage", code: 400,
                          userInfo: [NSLocalizedDescriptionKey: "Não foi possível comprimir a imagem."])
        }
        // UUID em lowercase — RLS compara auth.uid()::text (sempre lowercase)
        let path = "\(userId.lowercased()).jpg"
        _ = try await storage.upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let publicURL = try storage.getPublicURL(path: path)
        return publicURL.absoluteString
    }

    func deleteAccount() async throws {
        try await client.functions.invoke(EdgeFunction.deleteAccount)
    }

    /// Dispara o e-mail de recuperação de senha (via provedor de SMTP configurado
    /// no painel do Supabase — Authentication > Emails). O link do e-mail volta
    /// pro app em `centerrent://reset-password`.
    func resetPassword(email: String) async throws {
        try await auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "centerrent://reset-password")
        )
    }

    /// Troca o deep link de recuperação (`centerrent://reset-password#access_token=...`)
    /// por uma sessão válida, que permite chamar `updatePassword` em seguida.
    @discardableResult
    func establishRecoverySession(from url: URL) async throws -> Session {
        try await auth.session(from: url)
    }

    /// Define uma nova senha para o usuário da sessão de recuperação atual.
    func updatePassword(_ newPassword: String) async throws {
        _ = try await auth.update(user: UserAttributes(password: newPassword))
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

    /// Busca vários listings de uma vez por ID (ex: título/imagem para cards de reserva).
    func fetchListings(ids: [String]) async throws -> [Listing] {
        guard !ids.isEmpty else { return [] }
        let rows: [ListingRow] = try await client.from(Table.listings)
            .select("*")
            .in("id", values: ids)
            .execute()
            .value
        return rows.map { $0.toListing() }
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

    /// Pausa, reativa ou soft-deleta um listing (apenas troca a coluna `status`).
    func updateListingStatus(id: String, status: Listing.ListingStatus) async throws {
        struct Patch: Encodable { let status: String }
        try await client.from(Table.listings)
            .update(Patch(status: status.rawValue))
            .eq("id", value: id)
            .execute()
    }

    /// Soft delete — marca como `deleted`, não remove a linha (mantém histórico de reservas).
    func deleteListing(id: String) async throws {
        try await updateListingStatus(id: id, status: .deleted)
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

// MARK: - Booking Row (decodifica colunas snake_case do banco → Booking)
// NOTA: mapeado a partir de supabase_migration.sql (não confirmado ao vivo —
// reconecte o projeto Center Rent no conector MCP do Supabase pra validar).
// bookings.notes na tabela chama-se `renter_notes`.
private struct BookingRow: Decodable {
    let id: String
    let listing_id: String
    let renter_id: String
    let owner_id: String
    let start_date: Date
    let end_date: Date
    let total_hours: Double?
    let total_amount: Double
    let platform_fee: Double?
    let status: String
    let renter_notes: String?
    let created_at: Date?
    let updated_at: Date?

    func toBooking() -> Booking {
        Booking(
            id: id, listingId: listing_id, renterId: renter_id, ownerId: owner_id,
            startDate: start_date, endDate: end_date,
            totalHours: total_hours ?? 0, totalAmount: total_amount,
            platformFee: platform_fee ?? 0,
            status: Booking.BookingStatus(rawValue: status) ?? .pending,
            notes: renter_notes,
            createdAt: created_at ?? Date(), updatedAt: updated_at ?? Date()
        )
    }
}

// MARK: - Booking Detail Methods (create / fetch by id / aceitar-recusar)
extension SupabaseManager {

    /// Cria a reserva do fluxo simples por hora (BookingRequestView).
    func createBooking(_ booking: Booking) async throws -> Booking {
        struct Payload: Encodable {
            let id: String
            let listing_id: String
            let renter_id: String
            let owner_id: String
            let start_date: Date
            let end_date: Date
            let total_hours: Double
            let total_amount: Double
            let platform_fee: Double
            let status: String
            let renter_notes: String?
        }
        let payload = Payload(
            id: booking.id, listing_id: booking.listingId,
            renter_id: booking.renterId, owner_id: booking.ownerId,
            start_date: booking.startDate, end_date: booking.endDate,
            total_hours: booking.totalHours, total_amount: booking.totalAmount,
            platform_fee: booking.platformFee, status: booking.status.rawValue,
            renter_notes: booking.notes
        )
        let row: BookingRow = try await client.from(Table.bookings)
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
        return row.toBooking()
    }

    /// Busca uma reserva específica (tela de detalhe / aceitar-recusar).
    func fetchBooking(id: String) async throws -> Booking {
        let row: BookingRow = try await client.from(Table.bookings)
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return row.toBooking()
    }

    /// Aceita, recusa ou muda o status de uma reserva.
    /// IMPORTANTE: 'accepted' e 'declined' precisam estar liberados na CHECK
    /// constraint de bookings.status no banco — ver migrations/sprint0_booking_status.sql.
    func updateBookingStatus(id: String, status: Booking.BookingStatus) async throws {
        struct Patch: Encodable { let status: String }
        try await client.from(Table.bookings)
            .update(Patch(status: status.rawValue))
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Chat / Messaging Methods
// NOTA: schema de `conversations`/`messages` mapeado a partir de
// supabase_migration.sql — mais simples que o modelo Swift (sem type/status/
// attachment por mensagem). Campos ausentes no banco são aproximados em Swift.
extension SupabaseManager {

    private struct ConversationRow: Decodable {
        let id: String
        let listing_id: String?
        let renter_id: String
        let owner_id: String
        let last_message: String?
        let last_message_at: Date?
        let created_at: Date?
    }

    private struct MessageRow: Decodable {
        let id: String
        let conversation_id: String
        let sender_id: String
        let content: String
        let is_read: Bool?
        let created_at: Date?

        func toChatMessage() -> ChatMessage {
            ChatMessage(
                id: id, conversationId: conversation_id, senderId: sender_id,
                content: content, type: .text,
                status: (is_read ?? false) ? .read : .sent,
                createdAt: created_at ?? Date(), readAt: nil, attachmentURL: nil
            )
        }
    }

    /// Busca a conversa existente entre locatário e anunciante pra esse anúncio,
    /// ou cria uma nova. Chamado ao tocar em "Enviar mensagem" na PDP.
    func getOrCreateConversation(listingId: String, renterId: String, ownerId: String) async throws -> String {
        let existing: [ConversationRow] = try await client.from(Table.conversations)
            .select("*")
            .eq("listing_id", value: listingId)
            .eq("renter_id", value: renterId)
            .eq("owner_id", value: ownerId)
            .limit(1)
            .execute()
            .value
        if let found = existing.first { return found.id }

        struct Insert: Encodable {
            let listing_id: String
            let renter_id: String
            let owner_id: String
        }
        struct InsertResponse: Decodable { let id: String }
        let created: InsertResponse = try await client.from(Table.conversations)
            .insert(Insert(listing_id: listingId, renter_id: renterId, owner_id: ownerId))
            .select("id")
            .single()
            .execute()
            .value
        return created.id
    }

    func fetchConversations(userId: String) async throws -> [Conversation] {
        let rows: [ConversationRow] = try await client.from(Table.conversations)
            .select("*")
            .or("renter_id.eq.\(userId),owner_id.eq.\(userId)")
            .order("last_message_at", ascending: false)
            .execute()
            .value

        var result: [Conversation] = []
        for row in rows {
            let otherUserId = row.renter_id == userId ? row.owner_id : row.renter_id
            let otherUser = try? await fetchProfile(userId: otherUserId)
            var listing: Listing? = nil
            if let lid = row.listing_id {
                listing = try? await fetchListing(id: lid)
            }
            let unread = (try? await unreadMessageCount(conversationId: row.id, excludingSender: userId)) ?? 0
            let lastMsg: ChatMessage? = row.last_message.map {
                ChatMessage(id: "", conversationId: row.id, senderId: "", content: $0,
                            type: .text, status: .sent, createdAt: row.last_message_at ?? Date())
            }
            result.append(Conversation(
                id: row.id,
                participants: [row.renter_id, row.owner_id],
                listingId: row.listing_id ?? "",
                lastMessage: lastMsg,
                unreadCount: unread,
                createdAt: row.created_at ?? Date(),
                updatedAt: row.last_message_at ?? row.created_at ?? Date(),
                otherUser: otherUser,
                listing: listing
            ))
        }
        return result
    }

    private func unreadMessageCount(conversationId: String, excludingSender userId: String) async throws -> Int {
        let response = try await client.from(Table.messages)
            .select("id", head: true, count: .exact)
            .eq("conversation_id", value: conversationId)
            .eq("is_read", value: false)
            .neq("sender_id", value: userId)
            .execute()
        return response.count ?? 0
    }

    func fetchMessages(conversationId: String) async throws -> [ChatMessage] {
        let rows: [MessageRow] = try await client.from(Table.messages)
            .select("*")
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows.map { $0.toChatMessage() }
    }

    func sendMessage(_ message: ChatMessage) async throws -> ChatMessage {
        struct Insert: Encodable {
            let conversation_id: String
            let sender_id: String
            let content: String
        }
        let row: MessageRow = try await client.from(Table.messages)
            .insert(Insert(conversation_id: message.conversationId,
                            sender_id: message.senderId, content: message.content))
            .select()
            .single()
            .execute()
            .value

        // Best-effort: atualiza o preview da conversa e notifica o destinatário
        // — nenhum dos dois deve bloquear o envio da mensagem se falhar.
        struct ConvPatch: Encodable { let last_message: String; let last_message_at: Date }
        _ = try? await client.from(Table.conversations)
            .update(ConvPatch(last_message: message.content, last_message_at: Date()))
            .eq("id", value: message.conversationId)
            .execute()

        if let convo = try? await client.from(Table.conversations)
            .select("*").eq("id", value: message.conversationId).single().execute().value as ConversationRow {
            let recipientId = convo.renter_id == message.senderId ? convo.owner_id : convo.renter_id
            try? await createNotification(
                userId: recipientId, title: "Nova mensagem",
                body: String(message.content.prefix(120)),
                type: .newMessage, referenceId: message.conversationId
            )
        }

        return row.toChatMessage()
    }

    /// Realtime: escuta novas mensagens inseridas nessa conversa.
    func subscribeToConversation(id: String, handler: @escaping ([ChatMessage]) -> Void) {
        let channel = client.channel("messages-\(id)")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: Table.messages,
            filter: "conversation_id=eq.\(id)"
        ) { action in
            guard let row = try? action.decodeRecord(as: MessageRow.self, decoder: decoder) else { return }
            handler([row.toChatMessage()])
        }
        Task { await channel.subscribe() }
    }
}

// MARK: - Review Methods
extension SupabaseManager {
    /// Cria uma avaliação (hoje: locatário avalia o espaço — targetType "listing").
    func createReview(_ review: Review) async throws -> Review {
        struct Insert: Encodable {
            let id: String
            let booking_id: String
            let author_id: String
            let target_id: String
            let target_type: String
            let rating: Int
            let comment: String
        }
        try await client.from(Table.reviews)
            .insert(Insert(
                id: review.id, booking_id: review.bookingId, author_id: review.authorId,
                target_id: review.targetId, target_type: review.targetType,
                rating: review.rating, comment: review.comment
            ))
            .execute()
        return review
    }
}

// MARK: - Referral / MGM Methods
extension SupabaseManager {
    private struct ReferralRow: Decodable {
        let id: String
        let referrer_id: String
        let referred_id: String?
        let referral_code: String
        let status: String
        let reward_amount: Double?
        let created_at: Date?

        func toReferral() -> Referral {
            Referral(
                id: id, referrerId: referrer_id, referredUserId: referred_id ?? "",
                referralCode: referral_code,
                status: Referral.ReferralStatus(rawValue: status) ?? .pending,
                rewardType: .credit,
                rewardValue: reward_amount ?? 0,
                appliedAt: nil, createdAt: created_at ?? Date()
            )
        }
    }

    func fetchReferrals(userId: String) async throws -> [Referral] {
        let rows: [ReferralRow] = try await client.from(Table.referrals)
            .select("*")
            .eq("referrer_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toReferral() }
    }
}

// MARK: - Notification Methods
extension SupabaseManager {
    private struct NotificationRow: Decodable {
        let id: String
        let user_id: String
        let title: String
        let body: String?
        let type: String?
        let is_read: Bool?
        let deep_link: String?
        let created_at: Date?

        func toNotification() -> AppNotification {
            AppNotification(
                id: id, userId: user_id, title: title, body: body ?? "",
                type: AppNotification.NotificationType(rawValue: type ?? "") ?? .system,
                referenceId: deep_link, isRead: is_read ?? false,
                createdAt: created_at ?? Date()
            )
        }
    }

    func fetchNotifications(userId: String) async throws -> [AppNotification] {
        let rows: [NotificationRow] = try await client.from(Table.notifications)
            .select("*")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return rows.map { $0.toNotification() }
    }

    func markNotificationRead(id: String) async throws {
        struct Patch: Encodable { let is_read: Bool }
        try await client.from(Table.notifications)
            .update(Patch(is_read: true))
            .eq("id", value: id)
            .execute()
    }

    func markAllNotificationsRead(userId: String) async throws {
        struct Patch: Encodable { let is_read: Bool }
        try await client.from(Table.notifications)
            .update(Patch(is_read: true))
            .eq("user_id", value: userId)
            .execute()
    }

    /// Cria uma notificação para `userId`. Best-effort por design nos call
    /// sites (reserva/mensagem/avaliação não devem falhar por causa disso) —
    /// mas a própria função propaga erro pra quem quiser tratar.
    func createNotification(
        userId: String, title: String, body: String,
        type: AppNotification.NotificationType, referenceId: String? = nil
    ) async throws {
        struct Insert: Encodable {
            let user_id: String
            let title: String
            let body: String
            let type: String
            let deep_link: String?
        }
        try await client.from(Table.notifications)
            .insert(Insert(user_id: userId, title: title, body: body,
                            type: type.rawValue, deep_link: referenceId))
            .execute()
    }
}
