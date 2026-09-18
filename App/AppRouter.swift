import SwiftUI
import Combine

// MARK: - App Destinations
public enum AppDestination: Hashable {
    // Main app navigation
    case home
    case main

    // Authentication/Onboarding
    // NOTA: escolha de tipo de usuário + interesses pós-cadastro não usa mais
    // destinos empurrados aqui — é PostSignupOnboardingView, um mini state
    // machine local acionado direto por RootView (ver CenterRentApp.swift).
    case register
    case phoneVerification

    // Discovery & Listing
    case listingDetail(listingId: String)
    case categoryDetail(categoryId: String)
    case search
    case createListing

    // Chat & Communication
    case chat(conversationId: String)
    case chatDetail(conversationId: String)

    // Profile & Account
    case profile(userId: String)
    case editProfile

    // Booking & Reservations
    case bookingDetail(bookingId: String)
    case myBookings

    // Notifications & User
    case notifications
    case referral

    // Dashboard & Settings
    case dashboard
    case mgm
    case settings
    case myListings
}

// MARK: - Sheet Presentation
public enum SheetDestination: Identifiable {
    case filters(ListingFilter)
    case booking(listing: Listing)
    case review(booking: Booking)
    case imageViewer(urls: [String], startIndex: Int)
    case shareSheet(items: [Any])
    case reportListing(listingId: String)

    public var id: String {
        switch self {
        case .filters:            return "filters"
        case .booking:            return "booking"
        case .review:             return "review"
        case .imageViewer:        return "imageViewer"
        case .shareSheet:         return "shareSheet"
        case .reportListing:      return "reportListing"
        }
    }
}

// MARK: - Auth Screen State Machine
public enum AuthScreen: Equatable {
    case splash
    case login
    case register
    case forgotPassword
}

// MARK: - AppRouter
public final class AppRouter: ObservableObject {
    @Published public var selectedTab: Int = 0
    @Published public var navigationPath = NavigationPath()
    @Published public var profilePath = NavigationPath()
    @Published public var presentedSheet: SheetDestination? = nil
    @Published public var presentedFullScreen: AppDestination? = nil
    @Published public var pendingDeepLink: URL? = nil

    /// Controls which auth screen is currently displayed (state machine)
    @Published public var authScreen: AuthScreen = .splash

    /// Guest mode — user skipped auth entirely
    @Published public var isGuest: Bool = false

    /// true enquanto o usuário está no meio do fluxo de "esqueci minha senha"
    /// (deep link de recuperação já trocou por uma sessão, falta definir a
    /// nova senha). RootView prioriza mostrar NewPasswordView nesse estado,
    /// mesmo que authVM.isAuthenticated já esteja true.
    @Published public var isPasswordRecovery: Bool = false

    // MARK: - Guest Navigation
    public func navigateAsGuest() {
        isGuest = true
    }

    public func exitGuestMode() {
        isGuest = false
        authScreen = .splash
    }

    // Tab indices — match the Tab(value:) declarations in MainTabView.swift
    public enum Tab: Int {
        case home       = 0
        case chat       = 1
        case profile    = 2
        case myListings = 3
        case search     = 4   // Tab(role: .search) — appears as separate pill
    }

    // MARK: - Navigation
    /// Modern navigation method
    public func navigate(to destination: AppDestination) {
        navigationPath.append(destination)
    }

    /// Alias for navigate() for compatibility
    public func push(_ destination: AppDestination) {
        navigate(to: destination)
    }

    /// Pop current view from navigation stack
    public func pop() {
        goBack()
    }

    /// Pop all views and set root destination
    public func setRoot(_ destination: AppDestination) {
        navigationPath = NavigationPath()
        // If destination is .main or .home, just clear the stack
        if destination == .main || destination == .home {
            selectedTab = Tab.home.rawValue
        } else {
            navigationPath.append(destination)
        }
    }

    /// Navigate back to previous screen
    public func popToRoot() {
        navigationPath = NavigationPath()
    }

    /// Pop the last item from navigation stack
    public func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    /// Switch to a specific tab
    public func switchTab(to tab: Tab) {
        selectedTab = tab.rawValue
    }

    // MARK: - Sheet
    public func present(_ sheet: SheetDestination) {
        presentedSheet = sheet
    }

    public func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Deep Link Handler
    // centerrent://listing/ID
    // centerrent://referral/CODE
    // centerrent://booking/ID
    // centerrent://search
    //
    // IMPORTANTE: o "tipo" (listing/booking/referral/chat/search) é o HOST
    // da URL, não o primeiro componente do path -- pra "centerrent://booking/123",
    // URLComponents entende "booking" como host e "/123" como path (é o
    // formato scheme://host/path padrão, mesmo usado por
    // CenterRentApp.handleIncomingURL pro link de recuperação de senha,
    // que já lê url.host). A versão antiga lia tudo de components.path
    // (só "/123", sem o "booking"), então pathComponents nunca tinha os
    // 2 elementos esperados e o guard sempre falhava -- bug pré-existente
    // nunca pego porque nenhum link desses tinha sido testado de verdade
    // ainda (só descoberto construindo os e-mails de reserva, que dependem
    // do link centerrent://booking/ID abrindo o app na tela certa).
    public func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let type = components.host, !type.isEmpty else { return }
        let value = components.path.split(separator: "/").map(String.init).first

        switch type {
        case "listing":
            guard let value else { return }
            selectedTab = Tab.home.rawValue
            navigate(to: .listingDetail(listingId: value))
        case "referral":
            guard let value else { return }
            UserDefaults.standard.set(value, forKey: "pendingReferralCode")
            selectedTab = Tab.profile.rawValue
        case "booking":
            guard let value else { return }
            navigate(to: .bookingDetail(bookingId: value))
        case "chat":
            guard let value else { return }
            selectedTab = Tab.chat.rawValue
            navigate(to: .chat(conversationId: value))
        case "search":
            selectedTab = Tab.search.rawValue
        default:
            break
        }
    }
}
