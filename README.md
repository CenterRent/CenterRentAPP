# Center Rent

App iOS (SwiftUI) para locação de salas, equipamentos e mobiliário entre profissionais de saúde e estética — um marketplace P2P de aluguel por período.

## Stack

- **SwiftUI** (iOS, deployment target 26.4)
- **Supabase** (`supabase-swift`) — auth, banco de dados e storage
- Gerenciamento de pacotes via **Swift Package Manager**

## Estrutura do projeto

```
Center Rent V2/
├── App/                  # Entry point, roteamento e tab bar principal
├── Core/                 # Infra: auth, modelos de dados, cliente Supabase, extensões
│   ├── Auth/
│   ├── Extensions/
│   ├── Models/
│   └── Network/
├── DesignSystem/         # Componentes visuais reutilizáveis e design tokens
│   ├── Components/       # CRButton, CRCard, CRTabBar, etc. (prefixo CR = Center Rent)
│   ├── Modifiers/
│   └── Tokens/           # Cores, tipografia, espaçamento
├── Features/             # Uma pasta por domínio de produto — telas + view models juntos
│   ├── Auth/
│   ├── Booking/
│   ├── Chat/
│   ├── CreateListing/
│   ├── Dashboard/
│   ├── Home/
│   ├── Listing/
│   ├── ListingDetail/
│   ├── MGM/              # Member-get-member / indicação
│   ├── Onboarding/
│   ├── Profile/
│   └── Shared/           # Telas cross-feature (menu lateral, permissão de localização)
└── Resources/             # Info.plist e afins
```

**Convenção**: cada `Features/<Domínio>/` reúne a(s) view(s) e o(s) `ViewModel`(s) daquele domínio no mesmo lugar. Não crie novos arquivos soltos em `Views/`/`ViewModels/` na raiz — essa estrutura antiga foi removida.

## Rodando localmente

1. Abra `Center Rent V2.xcodeproj` no Xcode.
2. Deixe o Xcode resolver os pacotes Swift (Supabase, etc.) — automático na primeira abertura.
3. Configure as credenciais do Supabase (ver `Core/Network/SupabaseClient.swift` / `SupabaseManager.swift`).
4. Rode no simulador ou dispositivo (`Cmd+R`).

## Convenções de commit

Mensagens no formato `tipo: descrição`, com corpo explicando o "porquê" quando não for óbvio:

- `feat:` nova funcionalidade
- `fix:` correção de bug
- `refactor:` mudança de estrutura sem mudar comportamento
- `chore:` manutenção (deps, config, gitignore...)
- `docs:` documentação

## Branches

- `main` é protegida — mudanças entram via Pull Request, com o CI de build passando.
- Branches de trabalho: `feature/<nome>`, `fix/<nome>`.

## CI/CD

- **CI**: todo push/PR para `main` roda um build de validação (`.github/workflows/build.yml`).
- **CD**: deploy para o TestFlight via Fastlane, disparado manualmente ou por tag `v*` (`.github/workflows/deploy.yml`). Requer secrets configurados em *Settings → Secrets and variables → Actions* (ver comentários no workflow).
