import Foundation
import SwiftUI
import Combine

// MARK: - UserDefaults Keys
private enum StorageKey {
    static let onboardingComplete   = "cr_onboarding_complete"
    static let selectedUserType     = "cr_user_type"
    static let selectedInterests    = "cr_user_interests"
    static let userTypeDone         = "cr_user_type_done"   // nunca mais perguntar
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Onboarding flags — persistidos em UserDefaults
    @Published var onboardingComplete: Bool {
        didSet { UserDefaults.standard.set(onboardingComplete, forKey: StorageKey.onboardingComplete) }
    }
    /// true depois que o usuário escolheu o UserType pela primeira vez (nunca mais pergunta)
    @Published var userTypeDone: Bool {
        didSet { UserDefaults.standard.set(userTypeDone, forKey: StorageKey.userTypeDone) }
    }

    // Registration state
    @Published var registrationEmail = ""
    @Published var registrationPassword = ""
    @Published var registrationConfirmPassword = ""
    @Published var registrationName = ""
    @Published var registrationPhone = ""
    @Published var registrationProfessionalId = ""
    @Published var acceptedTerms = false

    // OTP state
    @Published var otpCode: [String] = Array(repeating: "", count: 4)

    // User type — persistido em UserDefaults
    @Published var selectedUserType: UserType? {
        didSet {
            if let type = selectedUserType {
                UserDefaults.standard.set(type.rawValue, forKey: StorageKey.selectedUserType)
            }
        }
    }

    // Interesses — persistidos em UserDefaults
    @Published var selectedInterests: [String] {
        didSet {
            UserDefaults.standard.set(selectedInterests, forKey: StorageKey.selectedInterests)
        }
    }

    private let supabase = SupabaseManager.shared

    init() {
        // Restaurar estado persistido do UserDefaults
        self.onboardingComplete = UserDefaults.standard.bool(forKey: StorageKey.onboardingComplete)
        self.userTypeDone       = UserDefaults.standard.bool(forKey: StorageKey.userTypeDone)
        self.selectedInterests  = UserDefaults.standard.stringArray(forKey: StorageKey.selectedInterests) ?? []
        if let rawType = UserDefaults.standard.string(forKey: StorageKey.selectedUserType) {
            self.selectedUserType = UserType(rawValue: rawType)
        } else {
            self.selectedUserType = nil
        }
        checkSession()
    }

    // MARK: - Session Check
    func checkSession() {
        if let session = supabase.currentSession() {
            isAuthenticated = true
            Task { await loadCurrentUser(userId: session.user.id.uuidString) }
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let session = try await supabase.signInWithEmail(email: email, password: password)
            isAuthenticated = true
            await loadCurrentUser(userId: session.user.id.uuidString)
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Register
    func register() async {
        guard registrationPassword == registrationConfirmPassword else {
            errorMessage = "As senhas não coincidem"; return
        }
        guard acceptedTerms else {
            errorMessage = "Aceite os termos para continuar"; return
        }
        isLoading = true; errorMessage = nil
        do {
            let metadata: [String: AnyJSON] = [
                "full_name": .string(registrationName),
                "phone": .string(registrationPhone),
                "professional_id": .string(registrationProfessionalId)
            ]
            _ = try await supabase.signUpWithEmail(
                email: registrationEmail,
                password: registrationPassword,
                metadata: metadata
            )
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Verify OTP
    func verifyOTP(phone: String) async -> Bool {
        let code = otpCode.joined()
        guard code.count == 4 else { return false }
        isLoading = true; errorMessage = nil
        do {
            try await supabase.auth.verifyOTP(phone: phone, token: code, type: .sms)
            isLoading = false
            return true
        } catch {
            errorMessage = "Código inválido. Tente novamente."
            isLoading = false
            return false
        }
    }

    // MARK: - Send Phone OTP
    func sendPhoneOTP(phone: String) async {
        isLoading = true
        do {
            try await supabase.auth.signInWithOTP(phone: phone)
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Complete Onboarding
    func completeOnboarding() async {
        guard let userId = supabase.currentUser()?.id.uuidString else { return }
        isLoading = true
        do {
            var profile = try await supabase.fetchProfile(userId: userId)
            profile.userType = selectedUserType ?? .renter
            profile.interests = selectedInterests
            try await supabase.updateProfile(profile)
            currentUser = profile
        } catch {
            // Mesmo com erro de rede, marca onboarding como feito
            errorMessage = parseError(error)
        }
        // Persiste localmente independente de erro de rede
        onboardingComplete = true
        userTypeDone = true
        isLoading = false
    }

    // MARK: - Mark UserType as done (sem chamada de rede)
    func markUserTypeDone() {
        userTypeDone = true
    }

    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        do {
            try await supabase.signOut()
            isAuthenticated = false
            currentUser = nil
            // Mantém onboarding/tipo/interesses para próximo login
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Load User
    private func loadCurrentUser(userId: String) async {
        do {
            currentUser = try await supabase.fetchProfile(userId: userId)
            if let type = currentUser?.userType {
                // Sincroniza cache local com backend
                selectedUserType = type
                userTypeDone = true
                onboardingComplete = true
                if let interests = currentUser?.interests, !interests.isEmpty {
                    selectedInterests = interests
                }
            } else {
                onboardingComplete = UserDefaults.standard.bool(forKey: StorageKey.onboardingComplete)
            }
        } catch {
            // Profile pode não existir ainda (novo usuário)
        }
    }

    private func parseError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid login") { return "Email ou senha incorretos." }
        if msg.contains("email not confirmed") { return "Confirme seu email antes de entrar." }
        if msg.contains("already registered") { return "Este email já está cadastrado." }
        if msg.contains("network") { return "Sem conexão. Verifique sua internet." }
        return "Algo deu errado. Tente novamente."
    }
}
