import SwiftUI

struct PhoneVerificationView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @State private var otpCode: [String] = Array(repeating: "", count: 4)
    @State private var countdown = 60
    @State private var canResend = false
    @State private var timer: Timer?

    private var maskedPhone: String {
        let phone = authVM.registrationPhone
        guard phone.count > 4 else { return phone }
        let suffix = String(phone.suffix(4))
        return "(11) 9****-\(suffix)"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Color.crBackground.ignoresSafeArea()
            }

            // Lime wave at bottom
            VStack {
                Spacer()
                CRWaveShape()
                    .fill(Color.crSecondary.opacity(0.4))
                    .frame(height: 120)
                    .ignoresSafeArea()
            }

            VStack(spacing: CRSpacing.xxl) {
                // Back button
                HStack {
                    Button { router.pop() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.crTextPrimary)
                    }
                    Spacer()
                }

                Spacer()

                // Header
                VStack(spacing: CRSpacing.md) {
                    Text("Confirme seu telefone")
                        .font(.crH2).foregroundColor(.crPrimary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 4) {
                        Text("Enviamos o código para")
                            .font(.crBody).foregroundColor(.crTextSecondary)
                        Text(maskedPhone)
                            .font(.crH4).foregroundColor(.crPrimary)
                    }
                }

                // OTP Input
                CROTPField(code: $otpCode, count: 4)

                // Error
                if let error = authVM.errorMessage {
                    Text(error).font(.crBodySmall).foregroundColor(.crError)
                }

                // Resend
                if canResend {
                    Button("Reenviar código") {
                        Task { await resendCode() }
                    }
                    .font(.crLabel).foregroundColor(.crPrimary)
                } else {
                    HStack(spacing: 4) {
                        Text("Não recebeu?").font(.crBody).foregroundColor(.crTextSecondary)
                        Text("Reenviar em \(countdown)s").font(.crLabel).foregroundColor(.crTextTertiary)
                    }
                }

                Spacer()

                CRButton(title: "Verificar código", isLoading: authVM.isLoading) {
                    Task { await verifyCode() }
                }
            }
            .padding(.horizontal, CRSpacing.xl)
            .padding(.vertical, CRSpacing.xl)
        }
        .navigationBarHidden(true)
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }

    private func startCountdown() {
        countdown = 60; canResend = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 { countdown -= 1 } else {
                canResend = true; timer?.invalidate()
            }
        }
    }

    private func verifyCode() async {
        authVM.otpCode = otpCode
        let success = await authVM.verifyOTP(phone: authVM.registrationPhone)
        if success { router.push(.userType) }
    }

    private func resendCode() async {
        await authVM.sendPhoneOTP(phone: authVM.registrationPhone)
        startCountdown()
    }
}

// MARK: - Wave Shape
struct CRWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.3),
            control1: CGPoint(x: rect.width * 0.3, y: 0),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.6)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}
