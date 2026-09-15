import Foundation

// MARK: - Postgres Timestamp Decoding
//
// O JSONDecoder padrão do supabase-swift só decodifica datas com fração de
// segundos de exatamente 3 dígitos (milissegundos) ou nenhuma fração. O
// Postgres manda timestamptz com até 6 dígitos (microssegundos), ex:
// "2026-06-25T14:46:57.814938+00:00" -- isso fazia o decode de QUALQUER
// campo Date vindo direto do banco falhar, silenciosamente na maioria dos
// lugares por causa de `try?`/fallbacks espalhados pelo app (o sintoma
// virava "dados sumiram" em vez de um erro visível).
//
// Usado em SupabaseManager.swift, passado como o decoder do client inteiro
// (SupabaseClientOptions(db: .init(decoder:))) -- corrige pra todas as
// tabelas de uma vez, não só uma struct específica.

extension String {
    /// Faz o parse de um timestamp do Postgres aceitando 0, 3 ou 6 dígitos
    /// de fração de segundos (o formatter é estrito quanto à contagem
    /// exata de dígitos, por isso várias tentativas em vez de um só padrão).
    var postgresTimestamp: Date? {
        for pattern in [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
        ] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = pattern
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
    }
}

extension JSONDecoder {
    static var postgresTimestampDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = string.postgresTimestamp {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Timestamp do Postgres em formato inesperado: \(string)"
            )
        }
        return decoder
    }
}
