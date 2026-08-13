import SwiftUI

struct SetupLoadingView: View {
    @State private var progress: Double = 0
    @State private var phase = 0
    @State private var illustrationOpacity: Double = 0
    @State private var illustrationOffset: CGFloat = 20

    let messages = [
        "Criando seu perfil profissional...",
        "Configurando seu espaço...",
        "Carregando os melhores espaços...",
        "Quase lá!"
    ]

    // URL da ilustração Cloudinary (BUG 4)
    private let illustrationURL = URL(string: "https://res.cloudinary.com/dcmwfymws/image/upload/v1775435022/Ilustrac%CC%A7a%CC%83o_bottom_tela-de-loading_uinbje.webp")

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: CRSpacing.xxl) {
                Spacer()

                // Logo animado
                HStack(spacing: 0) {
                    Text("C")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.crPrimary)
                    Text("R")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.crSecondary)
                }
                .scaleEffect(1.0 + sin(Double(phase) * 0.5) * 0.03)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: phase)

                VStack(spacing: CRSpacing.md) {
                    Text(messages[min(phase, messages.count - 1)])
                        .font(.crBody)
                        .foregroundColor(.crTextSecondary)
                        .animation(.easeInOut, value: phase)

                    // Barra de progresso — GeometryReader avoids deprecated UIScreen.main
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: CRRadius.pill)
                                .fill(Color.crDivider)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: CRRadius.pill)
                                .fill(
                                    LinearGradient(colors: [.crPrimary, .crSecondary], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: progress)
                        }
                        .frame(height: 6)
                    }
                    .frame(height: 6)
                    .padding(.horizontal, CRSpacing.xxl)
                }

                Spacer()

                // Ilustração Cloudinary no lugar do ícone de sistema (BUG 4)
                AsyncImage(url: illustrationURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        // Fallback caso a imagem não carregue
                        Image(systemName: "figure.walk.motion")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.crPrimary)
                    case .empty:
                        ProgressView()
                            .tint(.crPrimary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .opacity(illustrationOpacity)
                .offset(y: illustrationOffset)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: illustrationOpacity)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onAppear {
            animateProgress()
            withAnimation {
                illustrationOpacity = 1
                illustrationOffset = 0
            }
        }
    }

    private func animateProgress() {
        let steps: [(Double, Double)] = [(0.25, 0.3), (0.5, 0.6), (0.75, 0.9), (1.0, 1.3)]
        for (i, (prog, delay)) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                progress = prog
                phase = i
            }
        }
    }
}
