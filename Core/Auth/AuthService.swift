import Foundation
import Combine

// MARK: - Auth State
public enum AuthState {
    case unauthenticated
    case authenticated(UserProfile)
    case loading
}

// MARK: - Auth Error
public enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case phoneVerificationRequired
    case otpInvalid
    case otpExpired
    case tooManyAttempts
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:         return "E-mail ou senha inválidos."
        case .emailAlreadyInUse:          return "Este e-mail já está cadastrado."
        case .weakPassword:               return "A senha deve ter ao menos 8 caracteres."
        case .networkError:               return "Erro de conexão. Verifique sua internet."
        case .phoneVerificationRequired:  return "Verificação de telefone necessária."
        case .otpInvalid:                 return "Código inválido. Tente novamente."
        case .otpExpired:                 return "Código expirado. Solicite um novo."
        case .tooManyAttempts:            return "Muitas tentativas. Aguarde antes de tentar novamente."
        case .unknown(let msg):           return msg
        }
    }
}

// MARK: - AuthService Protocol
public protocol AuthServiceProtocol: AnyObject {
    var authStatePublisher: AnyPublisher<AuthState, Never> { get }
    var currentUser: UserProfile? { get }

    func signInWithEmail(email: String, password: String) async throws -> UserProfile
    func signUpWithEmail(email: String, password: String) async throws -> UserProfile
    func signInWithGoogle() async throws -> UserProfile
    func signInWithApple() async throws -> UserProfile
    func signOut() async throws
    func sendOTP(to phoneNumber: String) async throws
    func verifyOTP(phoneNumber: String, code: String) async throws
    func updateProfile(_ profile: UserProfile) async throws
    func deleteAccount() async throws
    func resetPassword(email: String) async throws
    func establishRecoverySession(from url: URL) async throws
    func updatePassword(_ newPassword: String) async throws
}

// MARK: - AuthService (Supabase implementation)
public final class AuthService: AuthServiceProtocol, ObservableObject {
    public static let shared = AuthService()

    @Published public private(set) var authState: AuthState = .unauthenticated
    @Published public private(set) var currentUser: UserProfile? = nil

    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    public var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }

    private init() {
        Task { await restoreSession() }
    }

    // MARK: - Session Restore
    private func restoreSession() async {
        await MainActor.run { authState = .loading }
        do {
            let profile = try await supabase.getCurrentUserProfile()
            await MainActor.run {
                self.currentUser = profile
                self.authState = .authenticated(profile)
            }
        } catch {
            await MainActor.run { authState = .unauthenticated }
        }
    }

    // MARK: - Email Sign In
    public func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        let profile = try await supabase.signInWithEmail(email: email, password: password)
        await MainActor.run {
            self.currentUser = profile
            self.authState = .authenticated(profile)
        }
        return profile
    }

    // MARK: - Email Sign Up
    public func signUpWithEmail(email: String, password: String) async throws -> UserProfile {
        guard password.count >= 8 else { throw AuthError.weakPassword }
        let profile = try await supabase.signUpWithEmail(email: email, password: password)
        await MainActor.run {
            self.currentUser = profile
            self.authState = .authenticated(profile)
        }
        return profile
    }

    // MARK: - Google Sign In
    public func signInWithGoogle() async throws -> UserProfile {
        let profile = try await supabase.signInWithGoogle()
        await MainActor.run {
            self.currentUser = profile
            self.authState = .authenticated(profile)
        }
        return profile
    }

    // MARK: - Apple Sign In
    public func signInWithApple() async throws -> UserProfile {
        let profile = try await supabase.signInWithApple()
        await MainActor.run {
            self.currentUser = profile
            self.authState = .authenticated(profile)
        }
        return profile
    }

    // MARK: - Sign Out
    public func signOut() async throws {
        try await supabase.signOut()
        await MainActor.run {
            self.currentUser = nil
            self.authState = .unauthenticated
        }
    }

    // MARK: - OTP
    public func sendOTP(to phoneNumber: String) async throws {
        try await supabase.sendOTP(phoneNumber: phoneNumber)
    }

    public func verifyOTP(phoneNumber: String, code: String) async throws {
        try await supabase.verifyOTP(phoneNumber: phoneNumber, code: code)
        if var profile = currentUser {
            profile.phoneVerified = true
            profile.phoneNumber = phoneNumber
            let updatedProfile = profile   // let-capture avoids concurrency warning
            await MainActor.run {
                self.currentUser = updatedProfile
                self.authState = .authenticated(updatedProfile)
            }
            try await updateProfile(updatedProfile)
        }
    }

    // MARK: - Profile Update
    public func updateProfile(_ profile: UserProfile) async throws {
        try await supabase.updateProfile(profile)
        await MainActor.run {
            self.currentUser = profile
            self.authState = .authenticated(profile)
        }
    }

    // MARK: - Local Sync (sem chamada de rede)
    /// AuthService e AuthViewModel mantêm cada um sua própria cópia de
    /// `currentUser` (dívida técnica pré-existente — telas como Dashboard/
    /// Profile/Settings leem daqui, mas cadastro e onboarding rodam por
    /// AuthViewModel). Usado para refletir aqui uma mudança que outro lugar
    /// do app já persistiu no Supabase, sem duplicar a chamada de rede.
    @MainActor
    public func syncCurrentUser(_ profile: UserProfile) {
        currentUser = profile
        authState = .authenticated(profile)
    }

    /// Mesma ideia de syncCurrentUser, mas pro caso de logout: AuthViewModel
    /// é quem controla o gate de RootView (authVM.isAuthenticated), mas
    /// telas como ProfileView chamavam authService.signOut() direto -- isso
    /// limpava currentUser aqui, mas authVM.isAuthenticated continuava true,
    /// então RootView nunca trocava pra tela de login de verdade.
    @MainActor
    public func clearCurrentUser() {
        currentUser = nil
        authState = .unauthenticated
    }

    // MARK: - Delete Account
    public func deleteAccount() async throws {
        try await supabase.deleteAccount()
        await MainActor.run {
            self.currentUser = nil
            self.authState = .unauthenticated
        }
    }

    // MARK: - Reset Password
    public func resetPassword(email: String) async throws {
        try await supabase.resetPassword(email: email)
    }

    public func establishRecoverySession(from url: URL) async throws {
        try await supabase.establishRecoverySession(from: url)
    }

    public func updatePassword(_ newPassword: String) async throws {
        try await supabase.updatePassword(newPassword)
    }
}
