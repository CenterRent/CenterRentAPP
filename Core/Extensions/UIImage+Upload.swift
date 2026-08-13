import UIKit

// MARK: - UIImage upload helpers
// Garante que imagens enviadas ao Supabase sejam redimensionadas e comprimidas
// para ficarem bem abaixo do limite do bucket (padrão: 50 MB).

extension UIImage {

    /// Redimensiona a imagem mantendo a proporção, limitando o lado maior a `maxDimension` pontos.
    func crResized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }

        let scale = maxDimension / longest
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Comprime para JPEG tentando qualidades decrescentes (0.80 → 0.60 → 0.40 → 0.25)
    /// até o resultado caber em `targetMaxBytes`. Retorna nil se todas as tentativas falharem.
    func crCompressed(targetMaxBytes: Int) -> Data? {
        let qualities: [CGFloat] = [0.80, 0.60, 0.40, 0.25]
        for q in qualities {
            if let data = self.jpegData(compressionQuality: q),
               data.count <= targetMaxBytes {
                return data
            }
        }
        // Última tentativa com qualidade mínima
        return self.jpegData(compressionQuality: 0.10)
    }
}
