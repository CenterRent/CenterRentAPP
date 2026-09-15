import Foundation
import SwiftUI
import UIKit
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
        Task {
            do {
                let profile = try await supabase.getCurrentUserProfile()
                await MainActor.run {
                    self.isAuthenticated = true
                    self.currentUser = profile
                    // Sessão restaurada = usuário existente → garante que não
                    // seja redirecionado para onboarding/auth ao reabrir o app.
                    self.onboardingComplete = true
                    self.userTypeDone = true
                    // AuthService é quem Profile/Dashboard/Settings/Booking
                    // leem -- sem isso, ele fica nil a sessão inteira porque
                    // seu próprio restoreSession() só roda 1x no init, antes
                    // de qualquer login acontecer por aqui.
                    AuthService.shared.syncCurrentUser(profile)
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                }
            }
        }
    }

    // MARK: - Refresh Current User (pull-to-refresh)
    /// Busca o perfil de novo do Supabase e atualiza os dois lados
    /// (authVM + AuthService). Usado como saída manual em .refreshable —
    /// se por algum motivo currentUser ficou desatualizado/vazio na tela
    /// (ex: uma corrida de timing que não reproduzimos ainda), isso força
    /// buscar de novo sem precisar deslogar/logar ou fechar o app.
    func refreshCurrentUser() async {
        guard let userId = currentUser?.id ?? AuthService.shared.currentUser?.id else {
            checkSession()
            return
        }
        do {
            let profile = try await supabase.fetchProfile(userId: userId)
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
        } catch {
            errorMessage = parseError(error)
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let profile = try await supabase.signInWithEmail(email: email, password: password)
            isAuthenticated = true
            currentUser = profile
            // Usuário existente — marca onboarding como concluído para
            // evitar que o RootView mostre telas de apresentação após login.
            onboardingComplete = true
            userTypeDone = true
            AuthService.shared.syncCurrentUser(profile)
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
            let profile = try await supabase.signUpWithEmail(
                email: registrationEmail,
                password: registrationPassword
            )
            isAuthenticated = true
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
            // onboardingComplete fica false aqui de propósito: RootView mostra
            // PostSignupOnboardingView (tipo de usuário + interesses) antes de
            // liberar o app. Só vira true em completeOnboarding().
        } catch let err as NSError where err.domain == "Auth" && err.code == 202 {
            // Email confirmation required — show message but don't throw
            errorMessage = err.localizedDescription
            isLoading = false
            return
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
            try await supabase.verifyOTP(phoneNumber: phone, code: code)
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
            try await supabase.sendOTP(phoneNumber: phone)
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Complete Onboarding
    func completeOnboarding() async {
        guard let profile = currentUser else { return }
        isLoading = true
        do {
            // userType já foi salvo em saveUserType(); aqui só garante que o
            // perfil local está em dia (ex: se saveUserType falhou por rede).
            try await supabase.updateProfile(profile)
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
        } catch {
            // Mesmo com erro de rede, marca onboarding como feito
            errorMessage = parseError(error)
        }
        // Persiste localmente independente de erro de rede
        onboardingComplete = true
        userTypeDone = true
        isLoading = false
    }

    // MARK: - Save User Type
    /// Persiste o tipo de usuário escolhido (locador/locatário/ambos) no
    /// perfil real no Supabase — antes ficava só em UserDefaults, sem
    /// UserProfile ter esse campo. Chamado assim que o usuário toca num
    /// cartão em UserTypeView.
    func saveUserType(_ type: UserType) async {
        selectedUserType = type
        guard var profile = currentUser else { return }
        profile.userType = type
        do {
            try await supabase.updateProfile(profile)
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
        } catch {
            // Não bloqueia o onboarding por erro de rede — o valor já está
            // em UserDefaults (selectedUserType) e completeOnboarding()
            // tenta salvar de novo ao final do fluxo.
            errorMessage = parseError(error)
        }
    }

    // MARK: - Save Profile Setup (onboarding — nome, especialidade, registro, foto)
    /// Chamado por ProfileSetupView.saveProfile(), etapa opcional do
    /// onboarding pós-cadastro (o usuário pode ter deixado alguns campos
    /// em branco — validateCurrentStep() já garante o mínimo obrigatório).
    func saveProfileSetup(fullName: String, specialty: String, registrationNumber: String,
                           registrationState: String, bio: String, profileImage: UIImage?) async {
        errorMessage = nil
        guard var profile = currentUser else { return }
        profile.fullName = fullName
        profile.specialty = specialty
        profile.registrationNumber = registrationNumber
        profile.registrationState = registrationState
        profile.bio = bio.isEmpty ? nil : bio
        do {
            if let image = profileImage {
                profile.profileImageURL = try await supabase.uploadAvatar(image: image, userId: profile.id)
            }
            try await supabase.updateProfile(profile)
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
        } catch {
            errorMessage = parseError(error)
        }
    }

    // MARK: - Update Basic Profile (EditProfileView)
    /// Chamado por EditProfileView.save() — diferente de saveProfileSetup
    /// (onboarding), essa tela não edita especialidade/estado de registro,
    /// então preserva o que já estava salvo em vez de sobrescrever com
    /// campos vazios.
    func updateBasicProfile(fullName: String, phoneNumber: String, registrationNumber: String,
                             bio: String, profileImage: UIImage?) async {
        errorMessage = nil
        guard var profile = currentUser else { return }
        profile.fullName = fullName
        profile.phoneNumber = phoneNumber
        profile.registrationNumber = registrationNumber
        profile.bio = bio.isEmpty ? nil : bio
        do {
            if let image = profileImage {
                profile.profileImageURL = try await supabase.uploadAvatar(image: image, userId: profile.id)
            }
            try await supabase.updateProfile(profile)
            currentUser = profile
            AuthService.shared.syncCurrentUser(profile)
        } catch {
            errorMessage = parseError(error)
        }
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
            AuthService.shared.clearCurrentUser()
            // Mantém onboarding/tipo/interesses para próximo login
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Delete Account
    func deleteAccount() async {
        isLoading = true
        do {
            try await supabase.deleteAccount()
            isAuthenticated = false
            currentUser = nil
            AuthService.shared.clearCurrentUser()
        } catch {
            errorMessage = parseError(error)
        }
        isLoading = false
    }

    // MARK: - Load User
    private func loadCurrentUser(userId: String) async {
        do {
            currentUser = try await supabase.fetchProfile(userId: userId)
            onboardingComplete = UserDefaults.standard.bool(forKey: StorageKey.onboardingComplete)
        } catch {
            // Profile pode não existir ainda (novo usuário)
        }
    }

    private func parseError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        // Supabase-specific strings
        if msg.contains("invalid login credentials") || msg.contains("invalid login") {
            return "Email ou senha incorretos."
        }
        if msg.contains("email not confirmed") || msg.contains("email link") {
            return "Confirme seu email antes de entrar."
        }
        if msg.contains("already registered") || msg.contains("user already registered") {
            return "Este email já está cadastrado."
        }
        if msg.contains("network") || msg.contains("could not connect") {
            return "Sem conexão. Verifique sua internet."
        }
        if msg.contains("password") && msg.contains("characters") {
            return "A senha deve ter pelo menos 6 caracteres."
        }
        // Passthrough — our own messages (e.g. email confirmation)
        if error._domain == "Auth" && (error as NSError).code == 202 {
            return error.localizedDescription
        }
        // Modo diagnóstico — mostra o erro real para facilitar debug
        let ns = error as NSError
        print("🔐 [Auth] Erro não mapeado — domain: \(ns.domain), code: \(ns.code), userInfo: \(ns.userInfo)")
        return "Erro: \(error.localizedDescription) [\(ns.domain)#\(ns.code)]"
    }
}
