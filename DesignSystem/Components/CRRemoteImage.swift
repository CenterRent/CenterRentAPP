import SwiftUI

// MARK: - Image load state
enum CRImageLoadState {
    case loading, success(Image), failure
}

// MARK: - Shared fetch helper
// Tenta URL direta; se 4xx, retenta com credenciais Supabase em 3 camadas:
//   1) URL pública sem auth
//   2) anon key (bucket não-RLS)
//   3) JWT da sessão do usuário (bucket com RLS — listing-images, avatars)
private func fetchRemoteImage(urlString: String) async -> CRImageLoadState {
    guard !urlString.isEmpty, let url = URL(string: urlString) else {
        print("🖼️ [CRImage] URL vazia/inválida: '\(urlString)'")
        return .failure
    }

    print("🖼️ [CRImage] Iniciando fetch: \(urlString)")

    // 1ª tentativa — URL pública sem nenhum header
    if let img = await httpGet(url: url, tag: "public") { return .success(img) }

    guard urlString.contains(SupabaseConfig.projectURL) else {
        print("🖼️ [CRImage] ❌ Falhou tentativa pública e URL não é do Supabase. Abortando.")
        return .failure
    }

    let anonKey = SupabaseConfig.anonKey

    // 2ª tentativa — anon key (buckets com acesso público anon)
    if let img = await httpGet(url: url, extraHeaders: [
        "apikey": anonKey,
        "Authorization": "Bearer \(anonKey)"
    ], tag: "anon-key") { return .success(img) }

    // 3ª tentativa — JWT da sessão ativa (buckets com RLS por usuário)
    if let session = try? await SupabaseManager.shared.client.auth.session {
        let jwt = session.accessToken
        if !jwt.isEmpty,
           let img = await httpGet(url: url, extraHeaders: [
               "apikey": anonKey,
               "Authorization": "Bearer \(jwt)"
           ], tag: "jwt") { return .success(img) }
    }

    print("🖼️ [CRImage] ❌ Todas as 3 tentativas falharam para: \(urlString)")
    return .failure
}

private func httpGet(url: URL, extraHeaders: [String: String] = [:], tag: String = "") async -> Image? {
    var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
    for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
    do {
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            print("🖼️ [CRImage:\(tag)] Sem HTTPURLResponse para \(url.lastPathComponent)")
            return nil
        }
        if !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            print("🖼️ [CRImage:\(tag)] HTTP \(http.statusCode) em \(url.lastPathComponent) — body: \(body)")
            return nil
        }
        guard let ui = UIImage(data: data) else {
            print("🖼️ [CRImage:\(tag)] Bytes não são imagem válida (\(data.count) bytes) em \(url.lastPathComponent)")
            return nil
        }
        print("🖼️ [CRImage:\(tag)] ✅ OK — \(url.lastPathComponent)")
        return Image(uiImage: ui)
    } catch {
        print("🖼️ [CRImage:\(tag)] Erro de rede: \(error.localizedDescription)")
        return nil
    }
}

// MARK: - CRRemoteImage
// Uso geral: hero, cards de sala, thumbnails.
// Mostra shimmer enquanto carrega e placeholder de foto em falha.
struct CRRemoteImage: View {
    let urlString: String?
    var scaledToFill: Bool = true

    @State private var state: CRImageLoadState = .loading

    var body: some View {
        contentView
            .task(id: urlString) { await reload() }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .loading:
            CRColor.Neutral.n200.shimmer()
        case .success(let image):
            if scaledToFill {
                image.resizable().scaledToFill()
            } else {
                image.resizable().scaledToFit()
            }
        case .failure:
            ZStack {
                CRColor.Neutral.n200
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundColor(CRColor.Neutral.n400)
            }
        }
    }

    private func reload() async {
        state = .loading
        state = await fetchRemoteImage(urlString: urlString ?? "")
    }
}

// MARK: - CRAvatarImage
// Variante para avatares: mostra a view de fallback (iniciais) durante loading e em falha.
struct CRAvatarImage<Fallback: View>: View {
    let urlString: String
    @ViewBuilder let fallback: () -> Fallback

    @State private var state: CRImageLoadState = .loading

    var body: some View {
        contentView
            .task(id: urlString) { await reload() }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .loading:
            fallback()
                .overlay(
                    ProgressView()
                        .scaleEffect(0.55)
                        .tint(CRColor.Primary.default.opacity(0.5))
                )
        case .success(let image):
            image.resizable().scaledToFill()
        case .failure:
            fallback()
        }
    }

    private func reload() async {
        state = .loading
        state = await fetchRemoteImage(urlString: urlString)
    }
}

// MARK: - CRListingThumbnail
// Variante para cards de gerenciamento de anúncio ("Sem foto" em falha).
struct CRListingThumbnail: View {
    let urlString: String?

    @State private var state: CRImageLoadState = .loading

    var body: some View {
        contentView
            .task(id: urlString) { await reload() }
    }

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .loading:
            CRColor.Neutral.n200.shimmer()
        case .success(let image):
            image.resizable().scaledToFill()
        case .failure:
            ZStack {
                CRColor.Neutral.n100
                VStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.system(size: 22))
                        .foregroundColor(CRColor.Neutral.n300)
                    Text("Sem foto")
                        .font(.system(size: 11))
                        .foregroundColor(CRColor.Text.tertiary)
                }
            }
        }
    }

    private func reload() async {
        state = .loading
        state = await fetchRemoteImage(urlString: urlString ?? "")
    }
}
