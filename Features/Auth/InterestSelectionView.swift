import SwiftUI

struct InterestSelectionView: View {
    @EnvironmentObject var authVM: AuthViewModel

    /// Chamado ao confirmar — PostSignupOnboardingView avança para a tela
    /// de loading, que é quem efetivamente chama completeOnboarding().
    var onFinished: () -> Void = {}

    let allInterests = ["Odontologia","Estética","Fisioterapia","Massoterapia","Pilates","Dermatologia","Nutrição","Psicologia"]

    var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()

            VStack(spacing: CRSpacing.xxl) {
                Spacer().frame(height: CRSpacing.hero)

                VStack(alignment: .leading, spacing: CRSpacing.sm) {
                    Text("Qual seu interesse?")
                        .font(.crH1).foregroundColor(.crPrimary)
                    Text("Selecione interesse para visualização")
                        .font(.crBody).foregroundColor(.crTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CRSpacing.xl)

                ScrollView {
                    VStack(spacing: CRSpacing.sm) {
                        ForEach(allInterests, id: \.self) { interest in
                            InterestRow(
                                title: interest,
                                isSelected: authVM.selectedInterests.contains(interest)
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    if authVM.selectedInterests.contains(interest) {
                                        authVM.selectedInterests.removeAll { $0 == interest }
                                    } else {
                                        authVM.selectedInterests.append(interest)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CRSpacing.xl)
                }

                VStack(spacing: CRSpacing.md) {
                    if !authVM.selectedInterests.isEmpty {
                        Text("\(authVM.selectedInterests.count) interesse(s) selecionado(s)")
                            .font(.crBodySmall).foregroundColor(.crTextSecondary)
                    }

                    CRButton(
                        title: "Continuar",
                        isFullWidth: true,
                        action: onFinished
                    )
                    .padding(.horizontal, CRSpacing.xl)
                }
                .padding(.bottom, CRSpacing.xxxl)
            }
        }
        .navigationBarHidden(true)
    }
}

struct InterestRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CRSpacing.base) {
                ZStack {
                    Circle().fill(Color.crSecondary.opacity(0.3)).frame(width: 44, height: 44)
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 18))
                        .foregroundColor(.crPrimary)
                }
                Text(title).font(.crBodyLarge).foregroundColor(.crTextPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.crPrimary)
                }
            }
            .padding(CRSpacing.base)
            .background(isSelected ? Color.crPrimary.opacity(0.06) : Color.white)
            .cornerRadius(CRRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CRRadius.lg)
                    .stroke(isSelected ? Color.crPrimary.opacity(0.4) : Color.crDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
