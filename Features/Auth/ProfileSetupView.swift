import SwiftUI
import PhotosUI

// MARK: - Profile Setup (após cadastro)
struct ProfileSetupView: View {
    @EnvironmentObject var authService: AuthService
    @State private var step: SetupStep = .basicInfo
    @State private var fullName = ""
    @State private var specialty = ""
    @State private var registrationNumber = ""
    @State private var registrationState = ""
    @State private var bio = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    enum SetupStep: Int, CaseIterable {
        case basicInfo = 0
        case professional = 1
        case photo = 2

        var title: String {
            switch self {
            case .basicInfo:    return "Informações básicas"
            case .professional: return "Dados profissionais"
            case .photo:        return "Foto de perfil"
            }
        }
        var subtitle: String {
            switch self {
            case .basicInfo:    return "Como você se chama?"
            case .professional: return "Sua especialidade e registro"
            case .photo:        return "Adicione uma foto profissional"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            SetupProgressBar(currentStep: step.rawValue, totalSteps: SetupStep.allCases.count)

            ScrollView {
                VStack(spacing: CRSpacing.s8) {
                    // Header
                    VStack(spacing: CRSpacing.s2) {
                        Text(step.title)
                            .font(.crHeading2)
                            .foregroundColor(CRColor.Text.primary)
                        Text(step.subtitle)
                            .font(.crBodyBase)
                            .foregroundColor(CRColor.Text.secondary)
                    }
                    .padding(.top, CRSpacing.s8)

                    // Step Content
                    Group {
                        switch step {
                        case .basicInfo:    basicInfoStep
                        case .professional: professionalStep
                        case .photo:        photoStep
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    if let error = errorMessage {
                        Text(error)
                            .font(.crBodySM)
                            .foregroundColor(CRColor.Feedback.error)
                    }
                }
                .padding(.horizontal, CRSpacing.screenHorizontal)
                .padding(.bottom, CRSpacing.s10)
            }

            // Bottom CTA
            VStack(spacing: CRSpacing.s3) {
                CRButton(
                    step == SetupStep.allCases.last ? "Finalizar" : "Continuar",
                    variant: .primary,
                    size: .lg,
                    icon: step == SetupStep.allCases.last ? "checkmark" : "arrow.right",
                    iconPosition: .trailing,
                    isLoading: isLoading,
                    isFullWidth: true
                ) { Task { await advance() } }

                if step != .basicInfo {
                    CRButton("Voltar", variant: .ghost, size: .md, isFullWidth: true) {
                        withAnimation(CRAnimation.springNormal) {
                            step = SetupStep(rawValue: step.rawValue - 1) ?? .basicInfo
                        }
                    }
                }
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
            .padding(.bottom, CRSpacing.s10)
            .background(CRColor.Background.primary)
        }
        .background(CRColor.Background.secondary.ignoresSafeArea())
    }

    // MARK: - Basic Info Step
    private var basicInfoStep: some View {
        VStack(spacing: CRSpacing.s4) {
            CRTextField("Nome completo", text: $fullName,
                        placeholder: "Dr. João Silva",
                        isRequired: true,
                        textContentType: .name,
                        leadingIcon: "person")
            CRTextField("Mini bio (opcional)", text: $bio,
                        placeholder: "Especialista em implantes com 10 anos de experiência",
                        leadingIcon: "text.quote",
                        maxLength: 160)
        }
    }

    // MARK: - Professional Step
    private var professionalStep: some View {
        VStack(spacing: CRSpacing.s4) {
            // Specialty picker
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                Text("Especialidade").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CRSpacing.s2) {
                        ForEach(DentalSpecialties.all, id: \.self) { spec in
                            Button(action: { specialty = spec }) {
                                Text(spec)
                                    .font(.crLabelSM)
                                    .foregroundColor(specialty == spec ? .white : CRColor.Primary.default)
                                    .padding(.horizontal, CRSpacing.s3)
                                    .padding(.vertical, CRSpacing.s2)
                                    .background(specialty == spec ? CRColor.Primary.default : CRColor.Primary.lighter)
                                    .cornerRadius(CRRadius.full)
                            }
                        }
                    }
                    .padding(.vertical, CRSpacing.s1)
                }
            }

            // State picker
            VStack(alignment: .leading, spacing: CRSpacing.s2) {
                Text("Estado de registro *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CRSpacing.s2) {
                        ForEach(["SP", "RJ", "MG", "RS", "PR", "SC", "BA", "PE", "CE", "GO", "DF"], id: \.self) { state in
                            Button(action: { registrationState = state }) {
                                Text(state)
                                    .font(.crLabelSM)
                                    .foregroundColor(registrationState == state ? .white : CRColor.Primary.default)
                                    .padding(.horizontal, CRSpacing.s3)
                                    .padding(.vertical, CRSpacing.s2)
                                    .background(registrationState == state ? CRColor.Primary.default : CRColor.Primary.lighter)
                                    .cornerRadius(CRRadius.full)
                            }
                        }
                    }
                }
            }

            // CRO Number
            CRTextField("Número CRO", text: $registrationNumber,
                        placeholder: "Ex: \(registrationState.isEmpty ? "SP" : registrationState) 123456",
                        isRequired: true,
                        keyboardType: .numbersAndPunctuation,
                        leadingIcon: "person.badge.key",
                        helperText: "Seu número de registro no Conselho Regional de Odontologia",
                        prefix: registrationState.isEmpty ? "CRO/" : "CRO/\(registrationState)")

            // Info card
            HStack(spacing: CRSpacing.s3) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(CRColor.Feedback.info)
                    .font(.system(size: CRSize.iconMD))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Por que pedimos isso?")
                        .font(.crLabelSM).foregroundColor(CRColor.Text.primary)
                    Text("O CRO garante que todos os profissionais na plataforma são verificados e habilitados.")
                        .font(.crCaptionMD).foregroundColor(CRColor.Text.secondary)
                }
            }
            .padding(CRSpacing.s3)
            .background(CRColor.Feedback.infoLight)
            .cornerRadius(CRRadius.sm)
        }
    }

    // MARK: - Photo Step
    private var photoStep: some View {
        VStack(spacing: CRSpacing.s6) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let img = profileImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: CRSize.avatar2XL, height: CRSize.avatar2XL)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(CRColor.Primary.lighter)
                            .frame(width: CRSize.avatar2XL, height: CRSize.avatar2XL)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(CRColor.Primary.default)
                            )
                    }
                    Circle()
                        .fill(CRColor.Primary.default)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        profileImage = img
                    }
                }
            }

            Text("Uma foto profissional aumenta a confiança dos outros usuários em até 3x.")
                .font(.crBodyBase)
                .foregroundColor(CRColor.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CRSpacing.s6)

            if profileImage != nil {
                Button(action: { profileImage = nil; selectedPhoto = nil }) {
                    Text("Remover foto")
                        .font(.crLabelSM)
                        .foregroundColor(CRColor.Feedback.error)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Advance
    private func advance() async {
        guard validateCurrentStep() else { return }
        errorMessage = nil
        if step == SetupStep.allCases.last {
            await saveProfile()
        } else {
            withAnimation(CRAnimation.springNormal) {
                step = SetupStep(rawValue: step.rawValue + 1) ?? step
            }
        }
    }

    private func validateCurrentStep() -> Bool {
        switch step {
        case .basicInfo:
            if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Nome completo é obrigatório."
                return false
            }
        case .professional:
            if specialty.isEmpty {
                errorMessage = "Selecione sua especialidade."
                return false
            }
            if registrationState.isEmpty {
                errorMessage = "Selecione seu estado de registro."
                return false
            }
            if registrationNumber.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Número CRO é obrigatório."
                return false
            }
        case .photo: break
        }
        return true
    }

    private func saveProfile() async {
        isLoading = true
        // TODO: Salvar perfil no Supabase
        // try await authService.updateProfile(...)
        isLoading = false
    }
}

// MARK: - Progress Bar
private struct SetupProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var progress: CGFloat { CGFloat(currentStep + 1) / CGFloat(totalSteps) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(CRColor.Neutral.n200)
                    .frame(height: 4)
                Rectangle()
                    .fill(CRColor.Primary.default)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(CRAnimation.easeNormal, value: progress)
            }
        }
        .frame(height: 4)
    }
}
