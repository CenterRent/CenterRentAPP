import Foundation
import Combine
import SwiftUI

// MARK: - Space Category
public struct SpaceCategory: Codable, Identifiable, Hashable {
    public let id: String
    public var name: String
    public var colorHex: String
    public var iconName: String?
    public var displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case colorHex = "color_hex"
        case iconName = "icon_name"
        case displayOrder = "display_order"
    }

    public var color: Color { Color(hex: colorHex) }

    public static let mock: [SpaceCategory] = [
        SpaceCategory(id: "1", name: "Odontologia", colorHex: "#D94F7E", iconName: nil, displayOrder: 0),
        SpaceCategory(id: "2", name: "Estética",    colorHex: "#8BC34A", iconName: nil, displayOrder: 1),
        SpaceCategory(id: "3", name: "Fisioterapia",colorHex: "#7F68C1", iconName: nil, displayOrder: 2),
        SpaceCategory(id: "4", name: "Massoterapia",colorHex: "#F4874B", iconName: nil, displayOrder: 3),
        SpaceCategory(id: "5", name: "Pilates",     colorHex: "#E8C84A", iconName: nil, displayOrder: 4),
    ]
}

// MARK: - User / Profile
public struct UserProfile: Codable, Identifiable {
    public let id: String
    public var email: String
    public var fullName: String
    public var specialty: String
    public var registrationNumber: String     // ex: CRO/SP 123456
    public var registrationState: String
    public var phoneNumber: String
    public var phoneVerified: Bool
    public var phoneVerificationAttempts: Int
    public var profileImageURL: String?
    public var verificationStatus: VerificationStatus
    public var verificationDocumentURL: String?
    public var referralCode: String
    public var referredBy: String?
    public var bio: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var isActive: Bool
    /// Escolhido no onboarding pós-cadastro (UserTypeView) e persistido em
    /// profiles.user_type. nil = ainda não escolheu (usuários antigos, ou
    /// cadastro em andamento) — nesse caso o app trata como se não tivesse
    /// preferência definida ainda, sem assumir um valor.
    public var userType: UserType? = nil

    public enum VerificationStatus: String, Codable, CaseIterable {
        case notSubmitted = "not_submitted"
        case pendingVerification = "pending_verification"
        case verified = "verified"
        case rejected = "rejected"
    }

    // Computed
    public var displayName: String { fullName.components(separatedBy: " ").first ?? fullName }
    public var isFullyVerified: Bool { phoneVerified && verificationStatus == .verified }
    public var canCreateListings: Bool { phoneVerified }
    public var canChat: Bool { phoneVerified }
    public var canReceiveBookings: Bool { phoneVerified && verificationStatus != .notSubmitted }
    public var initials: String {
        let parts = fullName.split(separator: " ")
        guard parts.count >= 2 else { return String(fullName.prefix(2)).uppercased() }
        return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
    }

    // MARK: - Stub factory
    /// Creates a minimal valid profile when the DB row doesn't exist yet.
    /// Used as a fallback after signIn/signUp so the user can enter the app
    /// and complete their profile during onboarding.
    public static func stub(id: String, email: String) -> UserProfile {
        UserProfile(
            id: id,
            email: email,
            fullName: "",
            specialty: "",
            registrationNumber: "",
            registrationState: "",
            phoneNumber: "",
            phoneVerified: false,
            phoneVerificationAttempts: 0,
            profileImageURL: nil,
            verificationStatus: .notSubmitted,
            verificationDocumentURL: nil,
            referralCode: String(id.prefix(8)).uppercased(),
            referredBy: nil,
            bio: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true,
            userType: nil
        )
    }
}

// MARK: - Listing
public struct Listing: Codable, Identifiable, Hashable {
    public let id: String
    public var ownerId: String
    public var title: String
    public var description: String
    public var address: AddressInfo
    public var pricePerHour: Double
    public var pricePerDay: Double?
    public var pricePerMonth: Double?
    public var imageURLs: [String]
    public var amenities: [String]
    public var specialties: [String]      // especialidades odontológicas
    public var equipment: [String]
    public var capacity: Int
    public var area: Double               // m²
    public var status: ListingStatus
    public var availability: [AvailabilitySlot]
    public var rules: String?
    public var rating: Double
    public var reviewCount: Int
    public var totalBookings: Int
    public var isVerifiedOwner: Bool
    public var isPremium: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public enum ListingStatus: String, Codable {
        case draft = "draft"
        case active = "active"
        case paused = "paused"
        case deleted = "deleted"
    }

    // Computed
    public var mainImageURL: String? { imageURLs.first }
    public var formattedPricePerHour: String { "R$ \(Int(pricePerHour))/hora" }

    // Compatibility aliases for old Views
    public var imageURL: String? { imageURLs.first }
    public var dailyPrice: Double { pricePerDay ?? pricePerHour * 8 }
    public var cleaningFee: Double { 0 }
    public var deliveryFee: Double { 0 }
    public var categoryId: String { "" }
    public var categoryName: String { specialties.first ?? "Geral" }
    public var categoryColorHex: String { "#7F68C1" }
    public var categoryColor: Color { Color(hex: categoryColorHex) }
    public var ownerName: String { "" }
    public var ownerAvatarURL: String? { nil }
    public var ownerProfessionalId: String? { nil }
    public var ownerRating: Double { rating }
    public var isFavorited: Bool { false }
    public var shortAddress: String? { address.shortAddress }

    public static var mockList: [Listing] { [mock] }
    public static let mock = Listing(
        id: "1", ownerId: "u1", title: "Sala Odontológica Premium",
        description: "Espaço moderno para atendimento odontológico.",
        address: AddressInfo(street: "Av. Paulista", number: "1002", complement: nil, neighborhood: "Bela Vista", city: "São Paulo", state: "SP", zipCode: "01310-100", latitude: -23.5505, longitude: -46.6333),
        pricePerHour: 50, pricePerDay: 250, pricePerMonth: nil,
        imageURLs: [], amenities: ["Wi-Fi", "Ar-condicionado"],
        specialties: ["Odontologia"], equipment: ["Cadeira odontológica"],
        capacity: 1, area: 25, status: .active, availability: [],
        rules: nil, rating: 4.9, reviewCount: 144, totalBookings: 50,
        isVerifiedOwner: true, isPremium: false, createdAt: Date(), updatedAt: Date()
    )
}

public struct AddressInfo: Codable, Hashable {
    public var street: String
    public var number: String
    public var complement: String?
    public var neighborhood: String
    public var city: String
    public var state: String
    public var zipCode: String
    public var latitude: Double?
    public var longitude: Double?

    public var shortAddress: String { "\(neighborhood), \(city)" }
    public var fullAddress: String { "\(street), \(number)\(complement.map { " - \($0)" } ?? ""), \(neighborhood), \(city) - \(state)" }
}

public struct AvailabilitySlot: Codable, Identifiable, Hashable {
    public let id: String
    public var weekday: Int               // 0 = domingo, 6 = sábado
    public var startTime: String          // "08:00"
    public var endTime: String            // "18:00"
    public var isAvailable: Bool
}

// MARK: - Booking
public struct Booking: Codable, Identifiable {
    public let id: String
    public var listingId: String
    public var renterId: String
    public var ownerId: String
    public var startDate: Date
    public var endDate: Date
    public var totalHours: Double
    public var totalAmount: Double
    public var platformFee: Double
    public var status: BookingStatus
    public var notes: String?
    public var renterReview: Review?
    public var ownerReview: Review?
    public var createdAt: Date
    public var updatedAt: Date

    public enum BookingStatus: String, Codable {
        case pending    = "pending"
        case accepted   = "accepted"
        case declined   = "declined"
        case confirmed  = "confirmed"
        case active     = "active"
        case completed  = "completed"
        case cancelled  = "cancelled"

        public var label: String {
            switch self {
            case .pending:   return "Pendente"
            case .accepted:  return "Aceito"
            case .declined:  return "Recusado"
            case .confirmed: return "Agendado"
            case .active:    return "Em andamento"
            case .completed: return "Finalizado"
            case .cancelled: return "Cancelado"
            }
        }
        public var color: Color {
            switch self {
            case .pending:   return .crWarning
            case .accepted:  return .crSuccess
            case .declined:  return .crError
            case .confirmed: return .crPrimary
            case .active:    return .crSuccess
            case .completed: return .crTextTertiary
            case .cancelled: return .crError
            }
        }
    }

    public var isPast: Bool { endDate < Date() }
    public var isUpcoming: Bool { startDate > Date() }
    public var isActive: Bool { status == .active }
    public var canReview: Bool { status == .completed }
    public var netAmount: Double { totalAmount - platformFee }
}

// MARK: - Review
public struct Review: Codable, Identifiable {
    public let id: String
    public var authorId: String
    public var targetId: String            // userId ou listingId
    public var targetType: String = "listing"  // "listing" | "user" — coluna real no Supabase
    public var bookingId: String
    public var rating: Int                 // 1–5
    public var comment: String
    public var createdAt: Date
    public var isPublic: Bool
}

// MARK: - Message / Chat
public struct ChatMessage: Codable, Identifiable {
    public let id: String
    public var conversationId: String
    public var senderId: String
    public var content: String
    public var type: MessageType
    public var status: MessageStatus
    public var createdAt: Date
    public var readAt: Date?
    public var attachmentURL: String?

    public enum MessageType: String, Codable {
        case text       = "text"
        case image      = "image"
        case booking    = "booking"
        case system     = "system"
    }
    public enum MessageStatus: String, Codable {
        case sending = "sending"
        case sent    = "sent"
        case delivered = "delivered"
        case read    = "read"
        case failed  = "failed"
    }

    public var isFromCurrentUser: Bool = false
}

public struct Conversation: Codable, Identifiable {
    public let id: String
    public var participants: [String]
    public var listingId: String
    public var lastMessage: ChatMessage?
    public var unreadCount: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var otherUser: UserProfile?
    public var listing: Listing?
}

// MARK: - OTP
public struct OTPVerification: Codable {
    public let id: String
    public var phoneNumber: String
    public var expiresAt: Date
    public var attempts: Int
    public var status: OTPStatus
    public var maxAttempts: Int = 3
    public var cooldownSeconds: Int = 60

    public enum OTPStatus: String, Codable {
        case pending  = "pending"
        case verified = "verified"
        case expired  = "expired"
        case failed   = "failed"
    }

    public var isExpired: Bool { expiresAt < Date() }
    public var canRetry: Bool { attempts < maxAttempts && !isExpired }
}

// MARK: - Referral / MGM
public struct Referral: Codable, Identifiable {
    public let id: String
    public var referrerId: String
    public var referredUserId: String
    public var referralCode: String
    public var status: ReferralStatus
    public var rewardType: RewardType
    public var rewardValue: Double
    public var appliedAt: Date?
    public var createdAt: Date

    public enum ReferralStatus: String, Codable {
        case pending    = "pending"
        case completed  = "completed"
        case rewarded   = "rewarded"
        case fraudulent = "fraudulent"
    }
    public enum RewardType: String, Codable {
        case credit     = "credit"
        case discount   = "discount"
        case boost      = "boost"          // destaque do anúncio
    }
}

// MARK: - Notification
public struct AppNotification: Codable, Identifiable {
    public let id: String
    public var userId: String
    public var title: String
    public var body: String
    public var type: NotificationType
    public var referenceId: String?        // bookingId, listingId, etc.
    public var isRead: Bool
    public var createdAt: Date

    public enum NotificationType: String, Codable {
        case bookingRequest   = "booking_request"
        case bookingAccepted  = "booking_accepted"
        case bookingDeclined  = "booking_declined"
        case newMessage       = "new_message"
        case reviewReceived   = "review_received"
        case verificationDone = "verification_done"
        case referralReward   = "referral_reward"
        case system           = "system"
    }
}

// MARK: - Filter & Search
public struct ListingFilter: Hashable {
    public var query: String = ""
    public var city: String = ""
    public var state: String = ""
    public var minPrice: Double? = nil
    public var maxPrice: Double? = nil
    public var specialties: [String] = []
    public var amenities: [String] = []
    public var availableNow: Bool = false
    public var onlyVerified: Bool = false
    public var sortBy: SortOption = .relevance
    public var priceType: PriceType = .hour

    public enum SortOption: String, CaseIterable {
        case relevance  = "Relevância"
        case priceLow   = "Menor preço"
        case priceHigh  = "Maior preço"
        case rating     = "Melhor avaliação"
        case newest     = "Mais recente"
    }
    public enum PriceType: String, CaseIterable {
        case hour  = "Por hora"
        case day   = "Por dia"
        case month = "Por mês"
    }

    public var isActive: Bool {
        !query.isEmpty || !city.isEmpty || minPrice != nil || maxPrice != nil
        || !specialties.isEmpty || availableNow || onlyVerified
    }
}

// MARK: - Amenity
/// Equipamento/comodidade de um espaço. Pode ser do sistema (is_system = true)
/// ou cadastrado pelo próprio usuário (is_system = false, created_by = userId).
public struct Amenity: Codable, Identifiable, Hashable {
    public let id: String
    public var name: String
    public var icon: String           // SF Symbol name
    public var category: AmenityCategory
    public var isSystem: Bool
    public var createdBy: String?
    public var createdAt: Date?

    public enum AmenityCategory: String, Codable, CaseIterable {
        case equipment      = "equipment"
        case infrastructure = "infrastructure"
        case service        = "service"
        case safety         = "safety"

        public var label: String {
            switch self {
            case .equipment:      return "Equipamentos"
            case .infrastructure: return "Infraestrutura"
            case .service:        return "Serviços"
            case .safety:         return "Segurança"
            }
        }
        public var categoryIcon: String {
            switch self {
            case .equipment:      return "stethoscope"
            case .infrastructure: return "wifi"
            case .service:        return "person.2.fill"
            case .safety:         return "lock.shield"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, icon, category
        case isSystem  = "is_system"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    /// Lista local usada como fallback quando o banco ainda não foi migrado.
    public static let defaults: [Amenity] = [
        // Equipamentos
        .init(id: "eq1",  name: "Cadeira odontológica",   icon: "chair.lounge",       category: .equipment,      isSystem: true),
        .init(id: "eq2",  name: "Raio-X digital",         icon: "rays",               category: .equipment,      isSystem: true),
        .init(id: "eq3",  name: "Tomógrafo",              icon: "arrow.clockwise",    category: .equipment,      isSystem: true),
        .init(id: "eq4",  name: "Esterilizador",          icon: "flame.fill",         category: .equipment,      isSystem: true),
        .init(id: "eq5",  name: "Compressor de ar",       icon: "wind",               category: .equipment,      isSystem: true),
        .init(id: "eq6",  name: "Fotopolimerizador",      icon: "sun.max.fill",       category: .equipment,      isSystem: true),
        .init(id: "eq7",  name: "Scanner intraoral",      icon: "camera.viewfinder",  category: .equipment,      isSystem: true),
        .init(id: "eq8",  name: "Microscópio",            icon: "eye",                category: .equipment,      isSystem: true),
        .init(id: "eq9",  name: "Laser",                  icon: "waveform.path",      category: .equipment,      isSystem: true),
        .init(id: "eq10", name: "Negatoscópio",           icon: "rectangle.fill",     category: .equipment,      isSystem: true),
        // Infraestrutura
        .init(id: "in1",  name: "Ar-condicionado",        icon: "thermometer",        category: .infrastructure, isSystem: true),
        .init(id: "in2",  name: "Wi-Fi",                  icon: "wifi",               category: .infrastructure, isSystem: true),
        .init(id: "in3",  name: "Estacionamento",         icon: "car.fill",           category: .infrastructure, isSystem: true),
        .init(id: "in4",  name: "Sala de espera",         icon: "person.2.fill",      category: .infrastructure, isSystem: true),
        .init(id: "in5",  name: "Banheiro privativo",     icon: "drop.fill",          category: .infrastructure, isSystem: true),
        // Serviços
        .init(id: "sv1",  name: "Recepção compartilhada", icon: "person.badge.plus",  category: .service,        isSystem: true),
        .init(id: "sv2",  name: "Sistema de aspiração",   icon: "arrow.down.circle",  category: .service,        isSystem: true),
    ]
}

// MARK: - Listing Insert Payload  (snake_case para Supabase)
struct ListingInsertPayload: Encodable {
    let owner_id: String
    let title: String
    let description: String
    let address: AddressInfo     // JSONB — encode camelCase, round-trip consistente
    let price_per_hour: Double
    let price_per_day: Double?
    let price_per_month: Double?
    let image_urls: [String]
    let amenities: [String]      // nomes — snapshot para exibição rápida
    let specialties: [String]
    let equipment: [String]
    let capacity: Int
    let area: Double
    let status: String           // "active" | "draft"
    let rules: String?
}

// MARK: - Listing Update Payload (PATCH — apenas campos editáveis)
struct ListingUpdatePayload: Encodable {
    let title: String
    let description: String
    let address: AddressInfo
    let price_per_hour: Double
    let price_per_day: Double?
    let price_per_month: Double?
    let amenities: [String]
    let specialties: [String]
    let equipment: [String]
    let capacity: Int
    let area: Double
    let status: String
    let rules: String?
}

// MARK: - Dental Specialties
public struct DentalSpecialties {
    public static let all: [String] = [
        "Clínica Geral", "Ortodontia", "Implantodontia", "Endodontia",
        "Periodontia", "Odontopediatria", "Prótese Dentária", "Cirurgia Bucomaxilofacial",
        "Estética Dental", "Radiologia", "Patologia Oral", "Disfunção Temporomandibular",
        "Odontologia do Sono", "Saúde Coletiva", "Dentística"
    ]
}

public struct DentalAmenities {
    public static let all: [String] = [
        "Cadeira odontológica", "Raio-X digital", "Tomógrafo", "Esterilizador",
        "Compressor de ar", "Aparelho de fotopolimerização", "Scanner intraoral",
        "Sistema de aspiração", "Negatoscópio", "Microscópio", "Laser",
        "Ar condicionado", "Wi-Fi", "Estacionamento", "Recepção compartilhada",
        "Sala de espera", "Banheiro privativo"
    ]
}

// MARK: - Payment
public enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard = "credit_card"
    case pix        = "pix"
    case applePay   = "apple_pay"
}

public enum PaymentStatus: String, Codable {
    case pending    = "pending"
    case processing = "processing"
    case paid       = "paid"
    case failed     = "failed"
    case refunded   = "refunded"
}

// MARK: - Booking Status (standalone, with display helpers)
public enum BookingStatus: String, Codable {
    case pending    = "pending"
    case confirmed  = "confirmed"
    case active     = "active"
    case completed  = "completed"
    case cancelled  = "cancelled"

    public var label: String {
        switch self {
        case .pending:   return "Pendente"
        case .confirmed: return "Agendado"
        case .active:    return "Em andamento"
        case .completed: return "Finalizado"
        case .cancelled: return "Cancelado"
        }
    }
    public var color: Color {
        switch self {
        case .pending:   return .crWarning
        case .confirmed: return .crPrimary
        case .active:    return .crSuccess
        case .completed: return .crTextTertiary
        case .cancelled: return .crError
        }
    }
}

// MARK: - Booking Request
public struct BookingRequest: Codable {
    public var listingId: String
    public var renterId: String
    public var ownerId: String
    public var startDate: Date
    public var endDate: Date
    public var dailyPrice: Double
    public var daysCount: Int
    public var cleaningFee: Double
    public var deliveryFee: Double
    public var discountAmount: Double
    public var totalAmount: Double
    public var couponCode: String?
    public var paymentMethod: PaymentMethod
    enum CodingKeys: String, CodingKey {
        case listingId = "listing_id"
        case renterId = "renter_id"
        case ownerId = "owner_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case dailyPrice = "daily_price"
        case daysCount = "days_count"
        case cleaningFee = "cleaning_fee"
        case deliveryFee = "delivery_fee"
        case discountAmount = "discount_amount"
        case totalAmount = "total_amount"
        case couponCode = "coupon_code"
        case paymentMethod = "payment_method"
    }
}

// MARK: - User Type
public enum UserType: String, Codable {
    case renter = "renter"
    case owner  = "owner"
    case both   = "both"
}

// MARK: - Chat Conversation (legacy compatibility)
public struct ChatConversation: Identifiable, Codable, Hashable {
    public let id: String
    public var otherUserId: String
    public var otherUserName: String
    public var otherUserAvatarURL: String?
    public var lastMessage: String
    public var lastMessageTime: Date
    public var unreadCount: Int
    public var listingTitle: String?
    enum CodingKeys: String, CodingKey {
        case id
        case otherUserId = "other_user_id"
        case otherUserName = "other_user_name"
        case otherUserAvatarURL = "other_user_avatar_url"
        case lastMessage = "last_message"
        case lastMessageTime = "last_message_time"
        case unreadCount = "unread_count"
        case listingTitle = "listing_title"
    }
}
