import Foundation

// MARK: - Supabase Configuration
// URL + anon key usados por SupabaseManager (Core/Network/SupabaseManager.swift),
// que é a única camada de acesso real ao Supabase no app.
public struct SupabaseConfig {
    static let projectURL   = "https://vdfcbbycsrrdogtqyosp.supabase.co"
    static let anonKey      = "sb_publishable_yJFFYvk-Hq2EggcGBrR93w_-sdm6VxG"
    static let serviceKey   = "" // apenas server-side — não usar no app
}

// MARK: - Booking Role
public enum BookingRole {
    case renter, owner
}
