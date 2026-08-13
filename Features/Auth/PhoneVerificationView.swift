import SwiftUI

// MARK: - Phone Verification Flow
struct PhoneVerificationView: View {
    let isOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var phase: VerificationPhase = .enterPhone
    @State private var phoneNumber = ""
    @State private var ddd = ""
    @State private var phoneLocal = ""
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var cooldownSeconds = 0
    @State private var timer: Timer? = nil
    @State private var attempts = 0
    let maxAttempts = 3
    let otpExpireSeconds = 300

    enum VerificationPhase {
        case enterPhone
        case enterOTP
        case success
    }

    var formattedPhone: String { "+55 (\(ddd)) \(phoneLocal)" }
    var rawPhone: String { "+55\(ddd)\(phoneLocal.filter { $0.isNumber })" }

    var body: some View {
        ZStack {
            CRColor.Background.primary.ignoresSafeArea()

            VStack(spacing: 0) {
                if isOnboarding {
                    SetupProgressBar(currentStep: 3, totalSteps: 5)
                }

                ScrollView {
                    VStack(spacing: CRSpacing.s8) {
                        // Icon + Header
                        VStack(spacing: CRSpacing.s4) {
                            ZStack {
                                Circle().fill(CRColor.Feedback.infoLight)
                                    .frame(width: 96, height: 96)
                                Image(systemName: phaseIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(CRColor.Feedback.info)
                            }
                            .padding(.top, CRSpacing.s10)

                            Text(phaseTitle)
                                .font(.crHeading2)
                                .foregroundColor(CRColor.Text.primary)
                                .multilineTextAlignment(.center)
                            Text(phaseSubtitle)
                                .font(.crBodyBase)
                                .foregroundColor(CRColor.Text.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, CRSpacing.s6)
                        }

                        // Phase Content
                        Group {
                            switch phase {
                            case .enterPhone:   phoneInputView
                            case .enterOTP:     otpInputView
                            case .success:      successView
                            }
                        }

                        // Error
                        if let error = errorMessage {
                            HStack(spacing: CRSpacing.s2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(CRColor.Feedback.error)
                                Text(error).font(.crBodySM).foregroundColor(CRColor.Feedback.error)
                                Spacer()
                            }
                            .padding(CRSpacing.s3)
                            .background(CRColor.Feedback.errorLight)
                            .cornerRadius(CRRadius.sm)
                        }

                        if let success = successMessage {
                            HStack(spacing: CRSpacing.s2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(CRColor.Feedback.success)
                                Text(success).font(.crBodySM).foregroundColor(CRColor.Feedback.success)
                                Spacer()
                            }
                            .padding(CRSpacing.s3)
                            .background(CRColor.Feedback.successLight)
                            .cornerRadius(CRRadius.sm)
                        }

                        // CTA
                        if phase != .success {
                            VStack(spacing: CRSpacing.s3) {
                                CRButton(
                                    phaseActionLabel,
                                    variant: .primary,
                                    size: .lg,
                                    isLoading: isLoading,
                                    isFullWidth: true
                                ) { Task { await handlePhaseAction() } }

                                if phase == .enterOTP {
                                    resendButton
                                    Button(action: {
                                        withAnimation(CRAnimation.easeNormal) {
                                            phase = .enterPhone
                                            otpCode = ""
                                            errorMessage = nil
                                        }
                                    }) {
                                        Text("Alterar número")
                                            .font(.crLabelSM)
                                            .foregroundColor(CRColor.Text.link)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CRSpacing.screenHorizontal)
                    .padding(.bottom, CRSpacing.s12)
                }
            }
        }
        .onDisappear {
            // Evita timer leak quando a view é dispensada
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Phone Input
    private var phoneInputView: some View {
        VStack(spacing: CRSpacing.s4) {
            HStack(spacing: CRSpacing.s3) {
                // DDD
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("DDD *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    HStack {
                        Text("+55").font(.crBodyBase).foregroundColor(CRColor.Text.secondary)
                        TextField("11", text: $ddd)
                            .font(.crBodyBase)
                            .foregroundColor(CRColor.Text.primary)
                            .keyboardType(.numberPad)
                            .onChange(of: ddd) { _, newValue in ddd = String(newValue.filter { $0.isNumber }.prefix(2)) }
                    }
                    .padding(.horizontal, CRSpacing.s3)
                    .frame(height: CRSize.inputMD)
                    .background(CRColor.Surface.primary)
                    .cornerRadius(CRRadius.input)
                    .overlay(RoundedRectangle(cornerRadius: CRRadius.input).stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
                }
                .frame(width: 100)

                // Number
                VStack(alignment: .leading, spacing: CRSpacing.s2) {
                    Text("Número *").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                    TextField("9 9999-9999", text: $phoneLocal)
                        .font(.crBodyBase)
                        .foregroundColor(CRColor.Text.primary)
                        .keyboardType(.numberPad)
                        .padding(.horizontal, CRSpacing.s4)
                        .frame(height: CRSize.inputMD)
                        .background(CRColor.Surface.primary)
                        .cornerRadius(CRRadius.input)
                        .overlay(RoundedRectangle(cornerRadius: CRRadius.input).stroke(CRColor.Border.default, lineWidth: CRBorder.thin))
                        .onChange(of: phoneLocal) { _, newValue in phoneLocal = String(newValue.filter { $0.isNumber }.prefix(9)) }
                }
            }

            HStack(spacing: CRSpacing.s2) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(CRColor.Feedback.success)
                    .font(.system(size: CRSize.iconSM))
                Text("Seu número é privado e nunca será compartilhado.")
                    .font(.crCaptionMD)
                    .foregroundColor(CRColor.Text.tertiary)
            }
        }
    }

    // MARK: - OTP Input
    private var otpInputView: some View {
        VStack(spacing: CRSpacing.s6) {
            Text("Código enviado para\n\(formattedPhone)")
                .font(.crLabelMD)
                .foregroundColor(CRColor.Text.secondary)
                .multilineTextAlignment(.center)

            CROTPTextField(length: 6, otpCode: $otpCode)
                .frame(maxWidth: .infinity)

            if attempts > 0 {
                Text("\(maxAttempts - attempts) tentativa(s) restante(s)")
                    .font(.crCaptionMD)
                    .foregroundColor(attempts >= 2 ? CRColor.Feedback.error : CRColor.Text.tertiary)
            }
        }
    }

    // MARK: - Success
    private var successView: some View {
        VStack(spacing: CRSpacing.s6) {
            ZStack {
                Circle().fill(CRColor.Feedback.successLight).frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(CRColor.Feedback.success)
            }
            Text("Telefone verificado com sucesso!")
                .font(.crHeading4)
                .foregroundColor(CRColor.Text.primary)
                .multilineTextAlignment(.center)
            Text("Sua conta está ativa. Agora você pode criar anúncios e conversar com outros profissionais.")
                .font(.crBodyBase)
                .foregroundColor(CRColor.Text.secondary)
                .multilineTextAlignment(.center)
            CRButton("Continuar", variant: .primary, size: .lg, isFullWidth: true) {
                // If presented as a sheet (non-onboarding), dismiss it.
                // For onboarding, the router/authService state drives the next step.
                if !isOnboarding { dismiss() }
            }
        }
    }

    // MARK: - Resend Button
    private var resendButton: some View {
        Group {
            if cooldownSeconds > 0 {
                Text("Reenviar código em \(cooldownSeconds)s")
                    .font(.crLabelSM)
                    .foregroundColor(CRColor.Text.tertiary)
            } else {
                Button(action: { Task { await resendOTP() } }) {
                    Text("Reenviar código")
                        .font(.crLabelSM)
                        .foregroundColor(CRColor.Text.link)
                }
            }
        }
    }

    // MARK: - Phase Helpers
    private var phaseIcon: String {
        switch phase {
        case .enterPhone: return "phone.badge.plus"
        case .enterOTP:   return "lock.open.rotation"
        case .success:    return "phone.badge.checkmark.fill"
        }
    }
    private var phaseTitle: String {
        switch phase {
        case .enterPhone: return "Verificar telefone"
        case .enterOTP:   return "Código de verificação"
        case .success:    return "Tudo certo!"
        }
    }
    private var phaseSubtitle: String {
        switch phase {
        case .enterPhone: return "Precisamos verificar seu número para ativar sua conta e garantir a segurança."
        case .enterOTP:   return "Insira o código de 6 dígitos enviado via SMS."
        case .success:    return "Sua identidade foi confirmada."
        }
    }
    private var phaseActionLabel: String {
        switch phase {
        case .enterPhone: return "Enviar código"
        case .enterOTP:   return "Verificar"
        case .success:    return "Continuar"
        }
    }

    // MARK: - Actions
    private func handlePhaseAction() async {
        errorMessage = nil
        switch phase {
        case .enterPhone: await sendOTP()
        case .enterOTP:   await verifyOTP()
        case .success:    break
        }
    }

    private func sendOTP() async {
        guard ddd.count == 2, phoneLocal.count >= 8 else {
            errorMessage = "Número inválido. Verifique o DDD e o número."; return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.sendOTP(to: rawPhone)
            withAnimation(CRAnimation.springNormal) { phase = .enterOTP }
            startCooldown()
        } catch { errorMessage = error.localizedDescription }
    }

    private func verifyOTP() async {
        guard otpCode.count == 6 else { errorMessage = "Digite os 6 dígitos do código."; return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authService.verifyOTP(phoneNumber: rawPhone, code: otpCode)
            HapticFeedback.success()
            withAnimation(CRAnimation.springNormal) { phase = .success }
        } catch {
            attempts += 1
            HapticFeedback.error()
            if attempts >= maxAttempts {
                errorMessage = "Número máximo de tentativas atingido. Solicite um novo código."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func resendOTP() async {
        await sendOTP()
    }

    private func startCooldown() {
        cooldownSeconds = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            cooldownSeconds -= 1
            if cooldownSeconds <= 0 { t.invalidate() }
        }
    }
}

private struct SetupProgressBar: View {
    let currentStep: Int; let totalSteps: Int
    var progress: CGFloat { CGFloat(currentStep + 1) / CGFloat(totalSteps) }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(CRColor.Neutral.n200).frame(height: 4)
                Rectangle().fill(CRColor.Primary.default).frame(width: geo.size.width * progress, height: 4)
                    .animation(CRAnimation.easeNormal, value: progress)
            }
        }
        .frame(height: 4)
    }
}
