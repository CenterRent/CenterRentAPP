import SwiftUI
import Combine

struct MGMView: View {
    @StateObject private var vm = MGMViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: CRSpacing.s6) {
                // Hero
                heroSection

                // Referral Code Card
                referralCodeCard

                // Stats
                statsSection

                // How it works
                howItWorksSection

                // Referrals List
                if !vm.referrals.isEmpty {
                    referralListSection
                }
            }
            .padding(.bottom, CRSpacing.s10)
        }
        .background(CRColor.Background.secondary.ignoresSafeArea())
        .navigationTitle("Indique e Ganhe")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { Task { await vm.load(userId: authService.currentUser?.id ?? "") } }
        .sheet(isPresented: $showShareSheet) {
            if let url = vm.shareURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [CRColor.Primary.default, CRColor.Primary.light],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: CRSpacing.s4) {
                Image(systemName: "gift.fill").font(.system(size: 56)).foregroundColor(.white.opacity(0.9))
                Text("Indique um colega,\nganhe recompensas!").font(.crHeading2).foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Para cada colega que se cadastrar e realizar\nsua primeira reserva, você e ele ganham créditos.")
                    .font(.crBodyBase).foregroundColor(.white.opacity(0.85)).multilineTextAlignment(.center)
            }
            .padding(CRSpacing.s8)
        }
        .cornerRadius(CRRadius.xl2)
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .padding(.top, CRSpacing.s4)
    }

    // MARK: - Referral Code
    private var referralCodeCard: some View {
        VStack(spacing: CRSpacing.s4) {
            Text("Seu código de indicação").font(.crHeading5).foregroundColor(CRColor.Text.primary)
            HStack(spacing: CRSpacing.s3) {
                Text(authService.currentUser?.referralCode ?? "LOADING")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(CRColor.Primary.default)
                    .tracking(4)
                Spacer()
                CRIconButton(icon: "doc.on.doc", color: .white, background: CRColor.Primary.default) {
                    UIPasteboard.general.string = authService.currentUser?.referralCode
                    HapticFeedback.success()
                    vm.showCopiedFeedback()
                }
            }
            .padding(CRSpacing.s4)
            .background(CRColor.Primary.lighter)
            .cornerRadius(CRRadius.md)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.md)
                .stroke(CRColor.Primary.default.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6])))

            if vm.codeCopied {
                HStack(spacing: CRSpacing.s1) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(CRColor.Feedback.success)
                    Text("Código copiado!").font(.crLabelSM).foregroundColor(CRColor.Feedback.success)
                }
                .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: CRSpacing.s3) {
                CRButton("Compartilhar link", variant: .primary, size: .md,
                         icon: "square.and.arrow.up", isFullWidth: true) {
                    showShareSheet = true
                }
                CRButton("Copiar link", variant: .outline, size: .md,
                         icon: "link", isFullWidth: true) {
                    UIPasteboard.general.string = vm.shareURL?.absoluteString
                    HapticFeedback.success()
                }
            }
        }
        .padding(CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.card)
        .crShadow(CRShadow.card)
        .padding(.horizontal, CRSpacing.screenHorizontal)
        .animation(CRAnimation.springFast, value: vm.codeCopied)
    }

    // MARK: - Stats
    private var statsSection: some View {
        HStack(spacing: CRSpacing.s3) {
            RewardStatBox(value: "\(vm.totalReferrals)", label: "Indicações", icon: "person.2", color: CRColor.Primary.default)
            RewardStatBox(value: "\(vm.completedReferrals)", label: "Convertidas", icon: "checkmark.circle", color: CRColor.Feedback.success)
            RewardStatBox(value: "R$ \(vm.totalCredits)", label: "Créditos", icon: "dollarsign.circle", color: CRColor.Accent.default)
        }
        .padding(.horizontal, CRSpacing.screenHorizontal)
    }

    // MARK: - How it works
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s4) {
            Text("Como funciona").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                .padding(.horizontal, CRSpacing.screenHorizontal)
            VStack(spacing: CRSpacing.s3) {
                HowItWorksStep(number: "1", title: "Compartilhe seu código",
                               description: "Envie seu link ou código para colegas dentistas")
                HowItWorksStep(number: "2", title: "Colega se cadastra",
                               description: "Seu colega cria a conta usando seu código")
                HowItWorksStep(number: "3", title: "Realiza primeira reserva",
                               description: "Quando a primeira reserva for concluída...")
                HowItWorksStep(number: "🎉", title: "Vocês dois ganham!",
                               description: "R$ 50 em créditos para você e R$ 30 para seu colega")
            }
            .padding(.horizontal, CRSpacing.screenHorizontal)
        }
    }

    // MARK: - Referrals List
    private var referralListSection: some View {
        VStack(alignment: .leading, spacing: CRSpacing.s4) {
            Text("Suas indicações").font(.crHeading5).foregroundColor(CRColor.Text.primary)
                .padding(.horizontal, CRSpacing.screenHorizontal)
            ForEach(vm.referrals) { referral in
                ReferralRow(referral: referral)
                    .padding(.horizontal, CRSpacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Supporting Views
private struct RewardStatBox: View {
    let value: String; let label: String; let icon: String; let color: Color

    var body: some View {
        VStack(spacing: CRSpacing.s2) {
            Image(systemName: icon).font(.system(size: CRSize.iconLG)).foregroundColor(color)
            Text(value).font(.crHeading4).foregroundColor(CRColor.Text.primary)
            Text(label).font(.crCaptionMD).foregroundColor(CRColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(CRSpacing.s4)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
        .crShadow(CRShadow.xs)
    }
}

private struct HowItWorksStep: View {
    let number: String; let title: String; let description: String

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            ZStack {
                Circle().fill(CRColor.Primary.lighter).frame(width: 40, height: 40)
                Text(number).font(.crHeading5).foregroundColor(CRColor.Primary.default)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                Text(description).font(.crBodySM).foregroundColor(CRColor.Text.secondary)
            }
            Spacer()
        }
        .padding(CRSpacing.s3)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
    }
}

private struct ReferralRow: View {
    let referral: Referral

    private var statusBadge: CRBadgeStyle {
        switch referral.status {
        case .pending:   return .pending
        case .completed: return .verified
        case .rewarded:  return .custom(bg: CRColor.Feedback.infoLight, text: CRColor.Feedback.info)
        case .fraudulent: return .rejected
        }
    }

    var body: some View {
        HStack(spacing: CRSpacing.s3) {
            CRAvatar(name: "Indicado", size: CRSize.avatarSM)
            VStack(alignment: .leading, spacing: 2) {
                Text("Indicação #\(referral.id.prefix(8))").font(.crLabelMD).foregroundColor(CRColor.Text.primary)
                Text(referral.createdAt.formatted(.relative(presentation: .named)))
                    .font(.crCaptionMD).foregroundColor(CRColor.Text.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                CRBadge(referral.status.rawValue, style: statusBadge, size: .sm)
                if referral.status == .rewarded {
                    Text("+ R$ \(Int(referral.rewardValue))").font(.crLabelSM).foregroundColor(CRColor.Feedback.success)
                }
            }
        }
        .padding(CRSpacing.s3)
        .background(CRColor.Surface.primary)
        .cornerRadius(CRRadius.md)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - MGMViewModel
@MainActor
final class MGMViewModel: ObservableObject {
    @Published var referrals: [Referral] = []
    @Published var totalReferrals = 0
    @Published var completedReferrals = 0
    @Published var totalCredits = 0
    @Published var codeCopied = false
    @Published var shareURL: URL? = nil

    func load(userId: String) async {
        referrals = (try? await SupabaseManager.shared.fetchReferrals(userId: userId)) ?? []
        totalReferrals = referrals.count
        completedReferrals = referrals.filter { $0.status == .completed || $0.status == .rewarded }.count
        totalCredits = referrals.filter { $0.status == .rewarded }.reduce(0) { $0 + Int($1.rewardValue) }
        shareURL = URL(string: "https://centerrent.com.br/referral/\(userId)")
    }

    func showCopiedFeedback() {
        codeCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self.codeCopied = false }
    }
}
