# Portal — Flutter

## Estrutura e convenções do projeto

- **Nome do projeto:** `portal_assoc`
- **Dart SDK:** `>=3.2.6 <4.0.0`
- **Plataforma alvo principal:** Flutter Web
- **Fonte:** Inter

### Gerenciamento de estado

Solução híbrida em dois níveis:

1. **Provider** — estado global da sessão (`lib/core/providers/`)
   - `AuthProvider` — token JWT, tipo de usuário, empresa ativa
   - `ThemeProvider` — tema claro/escuro
   - `LocaleProvider` — idioma (PT-BR / EN-US)

2. **ValueNotifier + StateApp** — operações assíncronas por feature (`lib/core/state/`)
   - `StartState` | `LoadingState` | `SuccessState` | `ErrorState`
   - Controllers de feature estendem `BaseController<T>`
   - Widgets consomem com `ValueListenableBuilder<StateApp>`

### Pacotes principais

| Categoria | Pacotes em uso |
| --------- | --------------- |
| Roteamento | `go_router` |
| Estado/DI | `provider` |
| HTTP/API | `dio`, `http` |
| Persistência local | `shared_preferences` |
| Tempo real | `socket_io_client`, `web_socket_channel` |
| I18n | `flutter_localizations`, `intl` |
| UI base | `flutter_svg`, `lucide_icons`, `dropdown_button2`, `animated_custom_dropdown`, `shimmer`, `fl_chart` |
| Feedback | `toastification` |
| Formatação/validação | `validators`, `flutter_multi_formatter`, `currency_text_input_formatter` |
| Arquivos/import-export | `file_picker`, `path_provider`, `share_plus`, `file_saver`, `excel`, `csv`, `syncfusion_flutter_xlsio` |
| Firebase | `firebase_core` |
| Utilitários | `collection` |

### Estrutura de pastas

```text
lib/
├── core/
│   ├── config/          # tema, tipografia, espaçamentos e raios
│   ├── constants/
│   ├── exceptions/
│   ├── providers/       # auth/theme/locale
│   ├── services/        # http_service, websocket_service, response_model
│   ├── state/           # app_state e base_controller
│   └── utils/           # formatadores e utilitários
├── features/
│   ├── app/             # shell principal (header, side menu, etc.)
│   ├── auth/
│   ├── users/
│   ├── default/
│   └── demais features de negócio (account, companies, menu_items, ...)
├── l10n/                # ARB + localizations geradas
├── router/              # app_router.dart
└── shared/
    ├── extensions/
    ├── themes/
    └── widgets/
```

### Padrão de arquitetura por feature

Há dois padrões coexistindo no projeto:

1. **Estrutura em camadas `data/domain/presentation`**
   - Em uso em features como: `auth`, `users`, `default`

2. **Estrutura flat por feature**
   - Arquivos como `*_entity.dart`, `*_model.dart`, `*_repository.dart`, `*_usecase.dart`, `*_controller.dart`, `*_page.dart`
   - Em uso em features como: `account`, `companies`, `connections`, `home`, `menu_categories`, `menu_items`, `payment_methods`, `register`, `company_opening_hours`, `additional_info`

### Rotas configuradas (GoRouter)

```text
/                  → Login (AuthPage)
/register          → Registro
/home              → HomePage
/account           → AccountPage
/business-settings → CompaniesPage
/payment-methods   → PaymentMethodsPage
```

## Integração com API

- **Base URL** configurada em `lib/core/services/http_service.dart`
  - Desenvolvimento: `http://localhost:3003/api/`
  - Produção: `https://api.iasemburocracia.com.br/api/`
  - Detecção automática via `Uri.base.origin`
- **Cliente HTTP:** `Dio` com interceptor Bearer token (`SharedPreferences`, chave `access_token`)
- **Métodos disponíveis:** `get`, `post`, `put`, `patch`, `delete`, `uploadFile`
- **Resposta padronizada:** `ResponseModel { bool success, String message, dynamic data }`
- Erros de rede são tratados com feedback visual via `toastification`

## 2. Padrão visual

Spec completa em `DESIGN_SYSTEM.md`. Referência rápida abaixo.

### Cores (classe `_DS` em cada page)

| Token | Hex | Uso |
|---|---|---|
| `ink` | #1C1C1E | Texto principal, botão primário |
| `brandBlue` | #4262FF | Ação, foco, links |
| `canvas` | #FFFFFF | Fundo de card |
| `surface` | #F7F8FA | Fundo de página, inputs |
| `hairline` | #E0E2E8 | Bordas padrão |
| `hairlineSoft` | #EEF0F3 | Bordas suaves (cards) |
| `slate` | #555A6A | Labels de seção |
| `steel` | #6B6F7E | Texto secundário |
| `stone` | #8E91A0 | Ícones, captions |
| `muted` | #A5A8B5 | Placeholder |
| `successAccent` | #00B473 | Sucesso |
| `danger` | #E53935 | Erro |
| `yellowLight` | #FFF4C4 | Badge de categoria (bg) |
| `yellowDark` | #746019 | Badge de categoria (texto) |
| `surfacePricing` | #F5F3FF | Chip de seleção ativo |

### Border radius

| Token | Valor | Uso |
|---|---|---|
| `rFull` | 9999 | Botões, badges, pills |
| `rXxxl` | 28 | Modals/dialogs |
| `rXl` | 16 | Cards |
| `rLg` | 12 | Dropdowns |
| `rMd` | 8 | Inputs, thumbnails |

### Botões

```dart
// Primário (preto)
FilledButton(style: FilledButton.styleFrom(
  backgroundColor: _DS.ink, foregroundColor: Colors.white,
  shape: const StadiumBorder(),
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
))

// Ação (azul, menor)
FilledButton(style: FilledButton.styleFrom(
  backgroundColor: _DS.brandBlue, shape: const StadiumBorder(),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
))

// Secundário (outline)
OutlinedButton(style: OutlinedButton.styleFrom(
  foregroundColor: _DS.ink,
  side: const BorderSide(color: _DS.hairline),
  shape: const StadiumBorder(),
))
```

### Inputs

```dart
TextField(decoration: InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _DS.hairline)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
  filled: true, fillColor: _DS.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
))
```

### Cards

```dart
Container(decoration: BoxDecoration(
  color: _DS.canvas,
  borderRadius: BorderRadius.circular(_DS.rXl),  // 16
  border: Border.all(color: _DS.hairlineSoft),
))
```

### Skeletons

Containers cinzas sem conteúdo, mesmas dimensões e `borderRadius` do componente real.

### Princípios

- Botões sempre com `StadiumBorder` (pill)
- Sem sombras em cards planos — apenas borda `hairlineSoft`
- Hover sutil (150ms), nunca dramático
- `shimmer` disponível no pubspec para skeleton animado
