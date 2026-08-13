import SwiftUI

struct UserTypeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()

            VStack(spacing: CRSpacing.xxl) {
                Spacer()

                VStack(spacing: CRSpacing.sm) {
                    Text("Como você quer usar o\nCenter Rent?")
                        .font(.crH2).foregroundColor(.crPrimary)
                        .multilineTextAlignment(.center)
                    Text("Você pode mudar isso depois nas configurações.")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: CRSpacing.md) {
                    UserTypeCard(
                        title: "Tenho ativos para alugar",
                        subtitle: "Equipamentos, salas, consultórios",
                        color: .crSecondary,
                        isSelected: authVM.selectedUserType == .owner,
                        systemImage: "person.badge.plus"
                    ) { authVM.selectedUserType = .owner }

                    UserTypeCard(
                        title: "Quero alugar ativos",
                        subtitle: "Uso por hora, dia ou semana",
                        color: .crPrimary,
                        isSelected: authVM.selectedUserType == .renter,
                        systemImage: "magnifyingglass.circle.fill"
                    ) { authVM.selectedUserType = .renter }

                    UserTypeCard(
                        title: "Os dois",
                        subtitle: "Anuncio e alugue ativos.",
                        color: .crAccentOrange,
                        isSelected: authVM.selectedUserType == .both,
                        systemImage: "arrow.left.arrow.right.circle.fill"
                    ) { authVM.selectedUserType = .both }
                }
                .padding(.horizontal, CRSpacing.xl)

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onChange(of: authVM.selectedUserType) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Persiste a escolha — nunca mais perguntará após primeira vez
                authVM.markUserTypeDone()
                router.navigate(to: .home)
            }
        }
        .onAppear {
            // Se o onboarding já está completo, vai direto para o app
            if authVM.userTypeDone && authVM.onboardingComplete {
                router.popToRoot()
            }
        }
    }
}

struct UserTypeCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.base) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.crH4).foregroundColor(isSelected ? .white : .crTextPrimary)
                    Text(subtitle)
                        .font(.crBody).foregroundColor(isSelected ? .white.opacity(0.8) : .crTextSecondary)
                }
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : color.opacity(0.7))
            }
            .padding(CRSpacing.xl)
            .background(isSelected ? color : Color.white)
            .cornerRadius(CRRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: CRRadius.xl)
                    .stroke(isSelected ? color : Color.crDivider, lineWidth: isSelected ? 0 : 1)
            )
            .crShadowCard()
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
