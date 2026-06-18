import 'dart:async';
import 'dart:math' as math;

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/widgets/banner_crop_dialog.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/shared/widgets/upload_validation.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:provider/provider.dart';

// Cor de ação padrão da plataforma. A cor da marca da empresa NÃO é usada
// nesta tela (será aplicada apenas no cardápio público, em outro momento).
const Color _kPlatformInk = Color(0xFF1C1C1E);
const List<Color> _kBrandSwatches = [
  Color(0xFF1C1C1E),
  Color(0xFF4262FF),
  Color(0xFF00B473),
  Color(0xFFE53935),
  Color(0xFFFF6B35),
  Color(0xFF7C3AED),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
];

/// Seções renderizadas pela tela. Os controladores são sempre carregados por
/// inteiro do servidor (o autosave envia o modelo completo), então cada seção
/// edita apenas seus campos sem afetar os demais.
enum BusinessSection {
  /// Identidade visual, dados da empresa e preferências operacionais.
  info,

  /// Inteligência Artificial & Cardápio (atendente virtual, tipo de cozinha,
  /// restrições alimentares).
  ai,
}

class BusinessInformations extends StatefulWidget {
  const BusinessInformations({
    super.key,
    required this.controller,
    this.section = BusinessSection.info,
  });

  final CompaniesController controller;
  final BusinessSection section;

  @override
  State<BusinessInformations> createState() => _BusinessInformationsState();
}

enum _SaveStatus { idle, pending, saving, saved, error }

class _BusinessInformationsState extends State<BusinessInformations> {
  // ── Design tokens (consistência visual da tela) ──────────────────────────
  static const _surface = Color(0xFFF7F8FA);
  static const _canvas = Colors.white;
  static const _hairlineSoft = Color(0xFFEEF0F3);
  static const _ink = Color(0xFF1C1C1E);
  static const _slate = Color(0xFF555A6A);
  static const _steel = Color(0xFF6B6F7E);

  final _repo = CompaniesRepository();

  // Controladores são inicializados uma única vez a partir do servidor; depois
  // a UI é a fonte da verdade e salva automaticamente (sem botão "Salvar").
  bool _loaded = false;
  Timer? _debounce;
  _SaveStatus _saveStatus = _SaveStatus.idle;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _logoUrlCtrl;
  late TextEditingController _bannerUrlCtrl;
  late TextEditingController _hexCtrl; // RRGGBB without #

  bool _uploadingLogo = false;
  bool _uploadingBanner = false;

  late TextEditingController _aiNameCtrl;
  late TextEditingController _aiPersonalityCtrl;
  late TextEditingController _cuisineTypeCtrl;
  late TextEditingController _maxDistanceDeliveryCtrl;
  late TextEditingController _kilometerPriceCtrl;
  late TextEditingController _maxDistanceFreeDeliveryCtrl;
  late TextEditingController _minPriceOrderCtrl;
  late TextEditingController _minTaxDeliveryCtrl;
  // Métodos de pedido aceitos pela empresa.
  bool _acceptsDelivery = true;
  bool _acceptsPickup = true;
  String? _aiGender;
  // Restrições selecionadas (padrão + personalizadas). É exatamente o que é
  // persistido na coluna `dietary_restrictions`.
  final Set<String> _dietaryRestrictions = {};
  // Restrições personalizadas disponíveis na sessão (selecionadas ou não),
  // preservando a ordem de inserção. As padrão vêm de [_kDietaryOptions].
  final List<String> _customDietaryRestrictions = [];
  late TextEditingController _customDietaryCtrl;
  String? _dietaryError;
  // Controla a seção (campo de texto) que abre ao clicar em "Adicionar".
  bool _showCustomDietaryInput = false;
  String? _selectedPersonalityPreset;
  // Catálogo de personalidades personalizadas (título + prompt), persistido em
  // `custom_ai_personalities`.
  final List<({String label, String prompt})> _customPersonalities = [];

  CompaniesModel? _company;

  @override
  void initState() {
    super.initState();
    widget.controller.find();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _logoUrlCtrl = TextEditingController();
    _bannerUrlCtrl = TextEditingController();
    _hexCtrl = TextEditingController();
    _aiNameCtrl = TextEditingController();
    _aiPersonalityCtrl = TextEditingController();
    _cuisineTypeCtrl = TextEditingController();
    _maxDistanceDeliveryCtrl = TextEditingController();
    _kilometerPriceCtrl = TextEditingController();
    _maxDistanceFreeDeliveryCtrl = TextEditingController();
    _minPriceOrderCtrl = TextEditingController();
    _minTaxDeliveryCtrl = TextEditingController();
    _customDietaryCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _logoUrlCtrl.dispose();
    _bannerUrlCtrl.dispose();
    _hexCtrl.dispose();
    _aiNameCtrl.dispose();
    _aiPersonalityCtrl.dispose();
    _cuisineTypeCtrl.dispose();
    _maxDistanceDeliveryCtrl.dispose();
    _kilometerPriceCtrl.dispose();
    _maxDistanceFreeDeliveryCtrl.dispose();
    _minPriceOrderCtrl.dispose();
    _minTaxDeliveryCtrl.dispose();
    _customDietaryCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _initCtrls(CompaniesModel c) {
    _company = c;
    _acceptsDelivery = c.acceptsDelivery ?? true;
    _acceptsPickup = c.acceptsPickup ?? true;
    _nameCtrl.text = c.name ?? '';
    _descCtrl.text = c.description ?? '';
    _phoneCtrl.text = c.phone ?? '';
    _logoUrlCtrl.text = c.logoUrl ?? '';
    _bannerUrlCtrl.text = c.bannerUrl ?? '';
    _hexCtrl.text = (c.brandColor ?? '').replaceAll('#', '');
    _aiNameCtrl.text = c.aiName ?? '';
    _aiPersonalityCtrl.text = c.aiPersonality ?? '';
    _customPersonalities
      ..clear()
      ..addAll((c.customAiPersonalities ?? const <Map<String, dynamic>>[])
          .map((e) => (
                label: (e['label'] ?? '').toString(),
                prompt: (e['prompt'] ?? '').toString()
              ))
          .where((p) => p.label.isNotEmpty && p.prompt.isNotEmpty));
    _selectedPersonalityPreset =
        _matchPersonalityLabel(_aiPersonalityCtrl.text);
    _cuisineTypeCtrl.text = c.cuisineType ?? '';
    _aiGender = c.aiGender;
    final loadedRestrictions = c.dietaryRestrictions ?? const <String>[];
    _dietaryRestrictions
      ..clear()
      ..addAll(loadedRestrictions);
    // O catálogo de personalizadas vem da coluna própria e persiste mesmo
    // desmarcado. Como fallback (dados antigos, sem a coluna), recupera as
    // selecionadas que não pertencem ao conjunto padrão.
    final catalog = <String>[
      ...(c.customDietaryRestrictions ?? const <String>[])
    ];
    for (final r in loadedRestrictions) {
      if (!_isPredefinedRestriction(r) &&
          catalog.every((c) => c.toLowerCase() != r.toLowerCase())) {
        catalog.add(r);
      }
    }
    _customDietaryRestrictions
      ..clear()
      ..addAll(catalog);
    _customDietaryCtrl.clear();
    _dietaryError = null;
    _showCustomDietaryInput = false;
    _maxDistanceDeliveryCtrl.text =
        c.maxDistanceMetersDelivery?.toString() ?? '';
    _kilometerPriceCtrl.text = _formatPrice(c.kilometerPrice);
    _maxDistanceFreeDeliveryCtrl.text =
        c.maxDistanceMetersFreeDelivery?.toString() ?? '';
    _minPriceOrderCtrl.text = _formatPrice(c.minPriceOrder);
    _minTaxDeliveryCtrl.text = _formatPrice(c.minTaxDelivery);
  }

  // ── Máscara de moeda (R$) ────────────────────────────────────────────────
  static final _priceFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$ ', decimalDigits: 2);
  CurrencyTextInputFormatter _currencyMask() =>
      CurrencyTextInputFormatter.currency(
          locale: 'pt_BR',
          symbol: r'R$ ',
          decimalDigits: 2,
          enableNegative: false);

  String _formatPrice(double? v) => v == null ? '' : _priceFormat.format(v);

  // Extrai o valor numérico de um texto mascarado ("R$ 1.234,56" → 1234.56).
  double? _parsePrice(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.parse(digits) / 100;
  }

  // Cor de ação fixa (preto da plataforma).
  Color get _actionColor => _kPlatformInk;

  // ── Edição fluida: autosave ──────────────────────────────────────────────
  // Monta o modelo atual a partir de TODOS os controladores/estados da UI.
  CompaniesModel _currentModel() {
    final brandColor = _normalizedBrandColor();
    return CompaniesModel.fromJson({
      'id': _company?.id,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'status': _company?.status,
      'logo_url':
          _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
      'brand_color': brandColor,
      'banner_url': _bannerUrlCtrl.text.trim().isEmpty
          ? null
          : _bannerUrlCtrl.text.trim(),
      'ai_name':
          _aiNameCtrl.text.trim().isEmpty ? null : _aiNameCtrl.text.trim(),
      'ai_gender': _aiGender,
      'ai_personality': _aiPersonalityCtrl.text.trim().isEmpty
          ? null
          : _aiPersonalityCtrl.text.trim(),
      'custom_ai_personalities': _customPersonalities.isEmpty
          ? null
          : _customPersonalities
              .map((p) => {'label': p.label, 'prompt': p.prompt})
              .toList(),
      'cuisine_type': _cuisineTypeCtrl.text.trim().isEmpty
          ? null
          : _cuisineTypeCtrl.text.trim(),
      'dietary_restrictions':
          _dietaryRestrictions.isEmpty ? null : _dietaryRestrictions.toList(),
      'custom_dietary_restrictions': _customDietaryRestrictions.isEmpty
          ? null
          : List<String>.from(_customDietaryRestrictions),
      'accepts_delivery': _acceptsDelivery,
      'accepts_pickup': _acceptsPickup,
      'max_distance_meters_delivery':
          int.tryParse(_maxDistanceDeliveryCtrl.text.trim()),
      'kilometer_price': _parsePrice(_kilometerPriceCtrl.text),
      'max_distance_meters_free_delivery':
          int.tryParse(_maxDistanceFreeDeliveryCtrl.text.trim()),
      'min_price_order': _parsePrice(_minPriceOrderCtrl.text),
      'min_tax_delivery': _parsePrice(_minTaxDeliveryCtrl.text),
    });
  }

  // Agenda salvamento após o usuário parar de digitar (campos de texto).
  void _scheduleAutosave() {
    _debounce?.cancel();
    if (_saveStatus != _SaveStatus.pending) {
      setState(() => _saveStatus = _SaveStatus.pending);
    }
    _debounce = Timer(const Duration(milliseconds: 900), _autosaveNow);
  }

  // Salva imediatamente (ações discretas: chips, gênero, presets, imagens).
  Future<void> _autosaveNow() async {
    _debounce?.cancel();
    if (_company == null) return;
    final model = _currentModel();
    _company = model;
    setState(() => _saveStatus = _SaveStatus.saving);
    try {
      // Salva direto pelo repositório para não recarregar a tela (sem flicker).
      await _repo.update(model);
      if (!mounted) return;
      context.read<OnboardingProvider>().refresh(silent: true);
      setState(() => _saveStatus = _SaveStatus.saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveStatus = _SaveStatus.error);
    }
  }

  Color? _parseHexColor(String? hex) {
    final h = (hex ?? '').replaceAll('#', '').trim();
    if (h.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(h)) {
      return null;
    }
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorHex(Color color) {
    return color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  String? _normalizedBrandColor() {
    final hex = _hexCtrl.text.replaceAll('#', '').trim();
    if (hex.isEmpty) return null;
    if (hex.length == 6 && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return '#${hex.toUpperCase()}';
    }
    return _company?.brandColor;
  }

  void _selectBrandColor(Color color) {
    setState(() => _hexCtrl.text = _colorHex(color));
    _autosaveNow();
  }

  void _onBrandHexChanged(String value) {
    setState(() {});
    final hex = value.trim();
    if (hex.isEmpty || hex.length == 6) {
      _scheduleAutosave();
    }
  }

  Future<void> _uploadImage({required bool isLogo}) async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;

    // Validação preventiva (tamanho/formato) ANTES do recorte/upload — evita o
    // 413 do backend e informa o tamanho encontrado vs. o limite.
    final validation = validateImageUpload(f);
    if (!validation.ok) {
      if (!mounted) return;
      await showUploadErrorDialog(
        context,
        title: validation.title!,
        message: validation.message!,
        fileBytes: validation.fileBytes,
      );
      return;
    }

    Uint8List bytes = f.bytes!;
    String filename = f.name;
    String mime = switch ((f.extension ?? 'jpg').toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    // O banner é exibido em 21:9 — abre o editor de recorte para o usuário
    // ajustar a imagem antes de enviar.
    if (!isLogo) {
      if (!mounted) return;
      final cropped = await showBannerCropDialog(context, bytes);
      if (cropped == null) return; // usuário cancelou
      bytes = cropped;
      filename = 'banner.png';
      mime = 'image/png';
    }

    setState(() => isLogo ? _uploadingLogo = true : _uploadingBanner = true);
    try {
      final resp = await _repo.uploadCompanyImage(
        bytes,
        filename,
        mime,
        type: isLogo ? 'logo' : 'banner',
      );
      if (resp.success && resp.data != null) {
        final url = resp.data['url'] as String?;
        if (url != null) {
          setState(() =>
              isLogo ? _logoUrlCtrl.text = url : _bannerUrlCtrl.text = url);
          await _autosaveNow(); // salva a nova imagem imediatamente
        }
      } else if (mounted) {
        // Falha do backend (inclui 413 mapeado pelo HttpService) — feedback
        // amigável, sem stacktrace ou termos técnicos.
        await showUploadErrorDialog(
          context,
          title: 'Não foi possível enviar a imagem',
          message: resp.message.isNotEmpty
              ? resp.message
              : 'Falha no upload da imagem. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(
            () => isLogo ? _uploadingLogo = false : _uploadingBanner = false);
      }
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Sem BaseAccount: o conteúdo encosta no topo e no menu lateral (sem o
    // padding/título extras que o BaseAccount impunha).
    return Expanded(
      child: ValueListenableBuilder(
        valueListenable: widget.controller.stateFind,
        builder: (context, state, _) {
          if (state is LoadingState) return _skeleton();
          if (state is ErrorState) return _errorView(state.message);
          if (state is SuccessState) {
            final c = state.data as CompaniesModel;
            // Inicializa os campos uma única vez; depois a UI é a fonte da
            // verdade (autosave) e não sobrescreve o que está sendo editado.
            if (!_loaded) {
              _initCtrls(c);
              _loaded = true;
            }
            return _content(c);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _content(CompaniesModel c) {
    return Container(
      color: _surface,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 4, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _saveIndicator(),
              ),
              const SizedBox(height: 12),
              if (widget.section == BusinessSection.info) ...[
                _buildBrandingSection(),
                const SizedBox(height: 16),
                _buildInfoSection(c),
                const SizedBox(height: 16),
                _buildOrderMethodsSection(c),
                const SizedBox(height: 16),
                _buildOperationalPreferencesSection(c),
              ] else ...[
                _buildAiSection(c),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Indicador de autosave (substitui os botões Editar/Salvar) ────────────
  Widget _saveIndicator() {
    final (IconData icon, String label, Color color) = switch (_saveStatus) {
      _SaveStatus.idle => (LucideIcons.cloud, 'Tudo certo', _steel),
      _SaveStatus.pending => (LucideIcons.pencil, 'Editando…', _steel),
      _SaveStatus.saving => (LucideIcons.loader, 'Salvando…', _steel),
      _SaveStatus.saved => (
          LucideIcons.checkCircle2,
          'Salvo',
          const Color(0xFF00B473)
        ),
      _SaveStatus.error => (
          LucideIcons.alertCircle,
          'Erro ao salvar',
          const Color(0xFFE53935)
        ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _hairlineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_saveStatus == _SaveStatus.saving)
            const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: _steel),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Dados da empresa ─────────────────────────────────────────────────────

  Widget _buildInfoSection(CompaniesModel c) {
    return _section(
      icon: LucideIcons.building2,
      title: 'Dados da empresa',
      subtitle: 'Informações principais exibidas aos seus clientes.',
      children: [
        _field(
          ctrl: _nameCtrl,
          label: 'Nome',
          icon: LucideIcons.store,
          maxLength: 100,
        ),
        _field(
          ctrl: _phoneCtrl,
          label: 'Telefone',
          icon: LucideIcons.phone,
          keyboardType: TextInputType.phone,
          formatters: [
            MaskedInputFormatter('(##) #####-####',
                allowedCharMatcher: RegExp(r'[0-9]')),
          ],
        ),
        _field(
          ctrl: _descCtrl,
          label: 'Descrição',
          icon: LucideIcons.alignLeft,
          maxLength: 500,
          maxLines: 4,
        ),
      ],
    );
  }

  // Campo de texto que dispara autosave (debounced) ao alterar.
  Widget _field({
    required TextEditingController ctrl,
    required String label,
    IconData? icon,
    int maxLines = 1,
    int maxLength = 100,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? helper,
  }) {
    return CustomInput(
      controller: ctrl,
      title: label,
      icon: icon,
      maxLines: maxLines,
      maxLenght: maxLength,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      helperText: helper,
      onChanged: (_) => _scheduleAutosave(),
    );
  }

  // ─── Métodos de pedido aceitos ───────────────────────────────────────────────

  Widget _buildOrderMethodsSection(CompaniesModel c) {
    return _section(
      icon: LucideIcons.shoppingBag,
      title: 'Métodos de pedido',
      subtitle: 'Defina como os clientes podem receber os pedidos.',
      children: [
        _orderMethodTile(
          icon: LucideIcons.truck,
          label: 'Delivery',
          description: 'Entrega no endereço do cliente.',
          value: _acceptsDelivery,
          onChanged: (v) {
            setState(() => _acceptsDelivery = v);
            _autosaveNow();
          },
        ),
        const SizedBox(height: 8),
        _orderMethodTile(
          icon: LucideIcons.store,
          label: 'Retirada',
          description: 'Cliente retira o pedido no local.',
          value: _acceptsPickup,
          onChanged: (v) {
            setState(() => _acceptsPickup = v);
            _autosaveNow();
          },
        ),
        if (!_acceptsDelivery && !_acceptsPickup) ...[
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 15, color: Color(0xFFE53935)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Habilite ao menos um método para receber pedidos.',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _orderMethodTile({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairlineSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? _ink : _steel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _ink,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(description,
                    style: const TextStyle(fontSize: 12, color: _steel)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _kPlatformInk,
          ),
        ],
      ),
    );
  }

  // ─── AI & Cardápio section ───────────────────────────────────────────────────

  Widget _buildOperationalPreferencesSection(CompaniesModel c) {
    return _section(
      icon: LucideIcons.truck,
      title: 'Preferências operacionais',
      subtitle: 'Regras de entrega, distância e valores mínimos.',
      children: [
        _fieldGrid([
          _field(
            ctrl: _maxDistanceDeliveryCtrl,
            label: 'Distância máx. de entrega',
            icon: LucideIcons.mapPin,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 7,
            helper: 'Em metros',
          ),
          _field(
            ctrl: _maxDistanceFreeDeliveryCtrl,
            label: 'Distância p/ frete grátis',
            icon: LucideIcons.gift,
            keyboardType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 7,
            helper: 'Em metros',
          ),
          _priceField(
              ctrl: _kilometerPriceCtrl,
              label: 'Preço por quilômetro',
              icon: LucideIcons.gauge),
          _priceField(
              ctrl: _minPriceOrderCtrl,
              label: 'Pedido mínimo',
              icon: LucideIcons.shoppingCart),
          _priceField(
              ctrl: _minTaxDeliveryCtrl,
              label: 'Taxa mínima de entrega',
              icon: LucideIcons.receipt),
        ]),
      ],
    );
  }

  // Campo de preço com máscara de moeda (R$), autosave debounced.
  Widget _priceField({
    required TextEditingController ctrl,
    required String label,
    IconData? icon,
  }) {
    return CustomInput(
      controller: ctrl,
      title: label,
      icon: icon,
      maxLenght: 14,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_currencyMask()],
      onChanged: (_) => _scheduleAutosave(),
    );
  }

  // Distribui os campos em 2 colunas no desktop e 1 coluna no mobile.
  Widget _fieldGrid(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final twoCols = constraints.maxWidth >= 520;
        final itemWidth = twoCols
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final f in fields) SizedBox(width: itemWidth, child: f),
          ],
        );
      },
    );
  }

  static const _kGenderOptions = [
    ('masculino', 'Masculino'),
    ('feminino', 'Feminino'),
    ('neutro', 'Neutro'),
  ];

  static const _kDietaryOptions = [
    'Vegetariano',
    'Vegano',
    'Sem glúten',
    'Halal',
    'Kosher',
    'Sem lactose',
    'Sem nozes',
  ];

  static const List<({String label, String prompt})> _kPersonalityPresets = [
    (
      label: 'Amigável',
      prompt:
          'Você é um atendente amigável e acolhedor. Cumprimente o cliente com cordialidade, trate pelo nome quando possível e use linguagem simples, positiva e próxima. Demonstre interesse genuíno no pedido, ofereça ajuda para escolher e confirme os detalhes finais com gentileza.'
    ),
    (
      label: 'Enérgico',
      prompt:
          'Você é um atendente enérgico e objetivo. Responda com agilidade, mantenha tom empolgado e destaque opções do cardápio com entusiasmo. Incentive o cliente a concluir o pedido com chamadas claras para ação, sem ser insistente.'
    ),
    (
      label: 'Simpático',
      prompt:
          'Você é um atendente simpático, educado e leve. Use frases cordiais, seja paciente e transmita cuidado em cada resposta. Faça sugestões suaves de combinações e adicionais, mantendo a conversa agradável e acolhedora.'
    ),
    (
      label: 'Profissional',
      prompt:
          'Você é um atendente profissional e preciso. Comunique-se com clareza, organização e objetividade, evitando informalidade excessiva. Confirme itens, quantidades, forma de pagamento e entrega antes de finalizar, priorizando segurança da informação.'
    ),
    (
      label: 'Consultivo',
      prompt:
          'Você é um atendente consultivo. Antes de sugerir, entenda preferências do cliente com perguntas curtas (gosto, restrições, tamanho da fome, orçamento). Recomende itens com justificativa clara e proponha alternativas quando necessário.'
    ),
    (
      label: 'Premium',
      prompt:
          'Você é um atendente de experiência premium. Use tom sofisticado, atencioso e confiante, valorizando qualidade, ingredientes e experiência. Sugira harmonizações e combinações de valor, mantendo comunicação elegante, clara e sem exageros.'
    ),
  ];

  Widget _buildAiSection(CompaniesModel c) {
    return _section(
      icon: LucideIcons.bot,
      title: 'Inteligência Artificial & Cardápio',
      subtitle: 'Como o atendente virtual se apresenta e atende.',
      children: [
        _fieldGrid([
          _field(
              ctrl: _aiNameCtrl,
              label: 'Nome da IA',
              icon: LucideIcons.sparkles,
              maxLength: 100),
          _field(
              ctrl: _cuisineTypeCtrl,
              label: 'Tipo de culinária',
              icon: LucideIcons.utensils,
              maxLength: 100),
        ]),
        _genderRow(c),
        const SizedBox(height: 8),
        _personalityRow(c),
        const SizedBox(height: 8),
        _dietaryRow(c),
      ],
    );
  }

  // Rótulo de subcampo dentro de uma seção.
  Widget _fieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _steel),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: _slate, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _personalityRow(CompaniesModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(LucideIcons.messageSquare, 'Personalidade da IA'),
        const SizedBox(height: 10),
        CustomInput(
          controller: _aiPersonalityCtrl,
          maxLenght: 500,
          maxLines: 4,
          keyboardType: TextInputType.text,
          hint:
              'Descreva o tom de voz do atendente ou escolha um preset abaixo',
          floatingLabel: false,
          onChanged: (_) => _scheduleAutosave(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._kPersonalityPresets.map((p) => _personalityChip(
                label: p.label, prompt: p.prompt, custom: false)),
            ..._customPersonalities.map((p) => _personalityChip(
                label: p.label, prompt: p.prompt, custom: true)),
            _addPersonalityButton(),
          ],
        ),
      ],
    );
  }

  // Chip de personalidade — preset padrão ou personalizada (removível).
  // Ao tocar, aplica o prompt no campo e marca como selecionada.
  Widget _personalityChip(
      {required String label, required String prompt, required bool custom}) {
    final selected = _selectedPersonalityPreset == label;
    return FilterChip(
      label: Text(label),
      selected: selected,
      avatar: Icon(
        LucideIcons.sparkles,
        size: 14,
        color: selected ? _actionColor : const Color(0xFF8E91A0),
      ),
      tooltip: custom ? 'Personalidade personalizada' : null,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedPersonalityPreset = label;
          _aiPersonalityCtrl.text = prompt;
        });
        _autosaveNow();
      },
      onDeleted: custom ? () => _removeCustomPersonality(label) : null,
      deleteIcon: custom ? const Icon(LucideIcons.x, size: 13) : null,
      deleteIconColor: selected ? _actionColor : Colors.grey[500],
      selectedColor: _actionColor.withValues(alpha: 0.12),
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? _actionColor : _slate,
        fontWeight: selected ? FontWeight.bold : FontWeight.w400,
      ),
      shape: const StadiumBorder(),
      side: BorderSide(color: selected ? _actionColor : Colors.grey[300]!),
      backgroundColor: _canvas,
    );
  }

  // Botão (no fim da lista) que abre o diálogo de nova personalidade.
  Widget _addPersonalityButton() {
    return OutlinedButton.icon(
      onPressed: _openAddPersonality,
      icon: const Icon(LucideIcons.plus, size: 16),
      label: const Text('Adicionar personalidade'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _actionColor,
        side: BorderSide(color: _actionColor.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  // Retorna o label do preset/custom cujo prompt casa com [prompt], ou null.
  String? _matchPersonalityLabel(String prompt) {
    final p = prompt.trim();
    if (p.isEmpty) return null;
    for (final preset in _kPersonalityPresets) {
      if (preset.prompt.trim() == p) return preset.label;
    }
    for (final c in _customPersonalities) {
      if (c.prompt.trim() == p) return c.label;
    }
    return null;
  }

  Future<void> _openAddPersonality() async {
    final result = await showDialog<({String label, String prompt})>(
      context: context,
      builder: (_) => _PersonalityDialog(
        isDuplicateLabel: (label) {
          final l = label.trim().toLowerCase();
          return _kPersonalityPresets.any((p) => p.label.toLowerCase() == l) ||
              _customPersonalities.any((p) => p.label.toLowerCase() == l);
        },
      ),
    );
    if (result == null) return;
    setState(() {
      _customPersonalities.add(result);
      _selectedPersonalityPreset = result.label; // já entra selecionada
      _aiPersonalityCtrl.text = result.prompt;
    });
    await _autosaveNow(); // salva imediatamente
  }

  Future<void> _removeCustomPersonality(String label) async {
    setState(() {
      _customPersonalities.removeWhere((p) => p.label == label);
      if (_selectedPersonalityPreset == label) {
        _selectedPersonalityPreset = null;
      }
    });
    await _autosaveNow();
  }

  Widget _genderRow(CompaniesModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(LucideIcons.user, 'Gênero da IA'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _kGenderOptions.map((opt) {
            final selected = _aiGender == opt.$1;
            return ChoiceChip(
              label: Text(opt.$2),
              selected: selected,
              onSelected: (_) {
                setState(() => _aiGender = opt.$1);
                _autosaveNow();
              },
              selectedColor: _actionColor.withValues(alpha: 0.12),
              checkmarkColor: _actionColor,
              labelStyle: TextStyle(
                fontSize: 13,
                color: selected ? _actionColor : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.w400,
              ),
              shape: const StadiumBorder(),
              side: BorderSide(
                  color: selected ? _actionColor : Colors.grey[300]!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dietaryRow(CompaniesModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(LucideIcons.leaf, 'Restrições alimentares'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._kDietaryOptions.map((opt) => _dietaryChip(opt, custom: false)),
            ..._customDietaryRestrictions
                .map((opt) => _dietaryChip(opt, custom: true)),
            // Campo entra no lugar do botão (logo após a última restrição),
            // voltando ao botão quando salva.
            _showCustomDietaryInput
                ? _customDietaryInput()
                : _customDietaryAddButton(),
          ],
        ),
      ],
    );
  }

  // Chip de restrição — padrão (não removível) ou personalizada (removível,
  // marcada com o ícone de "faísca" e tooltip "Restrição personalizada").
  Widget _dietaryChip(String opt, {required bool custom}) {
    final selected = _dietaryRestrictions.contains(opt);
    return FilterChip(
      label: Text(opt),
      selected: selected,
      avatar: custom
          ? Icon(
              LucideIcons.sparkles,
              size: 13,
              color: selected ? _actionColor : const Color(0xFF8E91A0),
            )
          : null,
      tooltip: custom ? 'Restrição personalizada' : null,
      onSelected: (v) => _toggleDietary(opt, v),
      // Apenas as personalizadas podem ser removidas.
      onDeleted: custom ? () => _removeCustomDietary(opt) : null,
      deleteIcon: custom ? const Icon(LucideIcons.x, size: 13) : null,
      deleteIconColor: selected ? _actionColor : Colors.grey[500],
      selectedColor: _actionColor.withValues(alpha: 0.12),
      checkmarkColor: _actionColor,
      // A faísca já identifica a personalizada; o checkmark fica só nas padrão.
      showCheckmark: !custom,
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? _actionColor : Colors.grey[700],
        fontWeight: selected ? FontWeight.bold : FontWeight.w400,
      ),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected ? _actionColor : Colors.grey[300]!,
      ),
    );
  }

  // Botão que revela o campo de texto no seu próprio lugar. Único botão da
  // seção; reaparece após salvar.
  Widget _customDietaryAddButton() {
    return OutlinedButton.icon(
      onPressed: () => setState(() {
        _showCustomDietaryInput = true;
        _dietaryError = null;
      }),
      icon: const Icon(LucideIcons.plus, size: 16),
      label: const Text('Adicionar restrição'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _actionColor,
        side: BorderSide(color: _actionColor.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }

  // Campo de texto pequeno; ao pressionar Enter salva imediatamente.
  Widget _customDietaryInput() {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: _customDietaryCtrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        maxLength: 60,
        onChanged: (_) {
          if (_dietaryError != null) setState(() => _dietaryError = null);
        },
        onSubmitted: (_) => _addCustomDietary(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Nome da restrição',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          errorText: _dietaryError,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _actionColor, width: 2)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  // Verifica se [value] equivale a uma restrição padrão (case-insensitive).
  bool _isPredefinedRestriction(String value) {
    final v = value.trim().toLowerCase();
    return _kDietaryOptions.any((o) => o.toLowerCase() == v);
  }

  // Retorna o rótulo já existente (padrão ou personalizado) que casa com
  // [value] ignorando maiúsculas/minúsculas, ou null se não houver duplicata.
  String? _findExistingRestriction(String value) {
    final v = value.trim().toLowerCase();
    for (final o in _kDietaryOptions) {
      if (o.toLowerCase() == v) return o;
    }
    for (final o in _customDietaryRestrictions) {
      if (o.toLowerCase() == v) return o;
    }
    return null;
  }

  // Persiste APENAS as restrições, imediatamente, sem exigir o "Salvar" do
  // topo. Mescla sobre o último estado salvo da empresa (_company) para não
  // gravar edições em andamento dos demais campos.
  Future<void> _toggleDietary(String opt, bool selected) async {
    setState(() {
      if (selected) {
        _dietaryRestrictions.add(opt);
      } else {
        _dietaryRestrictions.remove(opt);
      }
    });
    await _autosaveNow();
  }

  Future<void> _addCustomDietary() async {
    final raw = _customDietaryCtrl.text.trim();
    if (raw.isEmpty) {
      // Enter com campo vazio = cancela e volta a mostrar o botão.
      setState(() {
        _showCustomDietaryInput = false;
        _customDietaryCtrl.clear();
        _dietaryError = null;
      });
      return;
    }
    final existing = _findExistingRestriction(raw);
    if (existing != null) {
      setState(() => _dietaryError = '"$existing" já está na lista');
      return;
    }
    setState(() {
      _customDietaryRestrictions.add(raw);
      _dietaryRestrictions.add(raw); // já entra selecionada
      _customDietaryCtrl.clear();
      _dietaryError = null;
      _showCustomDietaryInput = false; // volta a mostrar o botão
    });
    await _autosaveNow(); // salva imediatamente no banco
  }

  Future<void> _removeCustomDietary(String value) async {
    setState(() {
      _customDietaryRestrictions.remove(value);
      _dietaryRestrictions.remove(value);
    });
    await _autosaveNow();
  }

  // ─── Identidade visual ────────────────────────────────────────────────────

  Widget _buildBrandingSection() {
    return _section(
      icon: LucideIcons.image,
      title: 'Identidade Visual',
      subtitle: 'Banner, logo e cor principal exibidos no seu cardápio.',
      bodyPadding: EdgeInsets.zero,
      children: [
        _BrandingHeader(
          logoUrl: _logoUrlCtrl.text.trim(),
          bannerUrl: _bannerUrlCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          fallbackInitials: _getInitials(_nameCtrl.text),
          uploadingLogo: _uploadingLogo,
          uploadingBanner: _uploadingBanner,
          onUploadLogo: () => _uploadImage(isLogo: true),
          onRemoveLogo: () => _removeImage(isLogo: true),
          onUploadBanner: () => _uploadImage(isLogo: false),
          onRemoveBanner: () => _removeImage(isLogo: false),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _BrandColorEditor(
            selectedColor: _parseHexColor(_hexCtrl.text),
            hexCtrl: _hexCtrl,
            onColorSelected: _selectBrandColor,
            onHexChanged: _onBrandHexChanged,
          ),
        ),
      ],
    );
  }

  // Remove a imagem e persiste imediatamente.
  Future<void> _removeImage({required bool isLogo}) async {
    setState(() => isLogo ? _logoUrlCtrl.text = '' : _bannerUrlCtrl.text = '');
    await _autosaveNow();
  }

  // ─── Section scaffold ─────────────────────────────────────────────────────

  // Card branco com cabeçalho (ícone + título + subtítulo) e corpo de campos
  // que fluem com espaçamento consistente.
  Widget _section({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
    EdgeInsets bodyPadding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _hairlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _hairlineSoft),
                  ),
                  child: Icon(icon, size: 17, color: _ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              color: _ink,
                              fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12.5, color: _steel, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _hairlineSoft),
          Padding(
            padding: bodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _intersperse(children, const SizedBox(height: 18)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading / error ──────────────────────────────────────────────────────────

  Widget _skeleton() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingContainer(
                  height: 80,
                  width: 80,
                  borderRadius: BorderRadius.all(Radius.circular(100))),
              SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingContainer(height: 24, width: 200),
                    SizedBox(height: 8),
                    LoadingContainer(height: 16, width: 150),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          LoadingContainer(height: 100, width: double.infinity),
          SizedBox(height: 16),
          LoadingContainer(height: 100, width: double.infinity),
        ],
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar informações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => widget.controller.findAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Misc helpers ─────────────────────────────────────────────────────────────

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Iterable<Widget> _intersperse(List<Widget> list, Widget sep) sync* {
    for (var i = 0; i < list.length; i++) {
      yield list[i];
      if (i < list.length - 1) yield sep;
    }
  }
}

// ─── Brand color editor ─────────────────────────────────────────────────────

class _BrandColorEditor extends StatelessWidget {
  final Color? selectedColor;
  final TextEditingController hexCtrl;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<String> onHexChanged;

  const _BrandColorEditor({
    required this.selectedColor,
    required this.hexCtrl,
    required this.onColorSelected,
    required this.onHexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _BusinessInformationsState._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _BusinessInformationsState._hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.palette,
                  size: 15, color: _BusinessInformationsState._steel),
              SizedBox(width: 8),
              Text(
                'Cor principal da marca',
                style: TextStyle(
                    fontSize: 13,
                    color: _BusinessInformationsState._slate,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Aplicada em botões e destaques do cardápio online.',
            style: TextStyle(
                fontSize: 12, color: _BusinessInformationsState._steel),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kBrandSwatches.map((color) {
              final selected = selectedColor?.toARGB32() == color.toARGB32();
              return Tooltip(
                message:
                    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                child: GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? _BusinessInformationsState._ink
                            : _BusinessInformationsState._canvas,
                        width: selected ? 2.5 : 2,
                      ),
                      boxShadow: _DSColorShadow.small,
                    ),
                    child: selected
                        ? const Icon(LucideIcons.check,
                            color: Colors.white, size: 15)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selectedColor ?? _BusinessInformationsState._canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _BusinessInformationsState._hairlineSoft),
                ),
              ),
              const SizedBox(width: 10),
              const Text('#',
                  style: TextStyle(
                      fontSize: 14, color: _BusinessInformationsState._slate)),
              const SizedBox(width: 4),
              SizedBox(
                width: 122,
                child: TextField(
                  controller: hexCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: onHexChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                      fontSize: 13, color: _BusinessInformationsState._ink),
                  decoration: InputDecoration(
                    hintText: '4262FF',
                    hintStyle: const TextStyle(
                        color: _BusinessInformationsState._steel, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _BusinessInformationsState._hairlineSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _BusinessInformationsState._hairlineSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: _BusinessInformationsState._ink, width: 1.5),
                    ),
                    filled: true,
                    fillColor: _BusinessInformationsState._canvas,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DSColorShadow {
  static List<BoxShadow> small = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

// ─── Branding header (banner + logo flutuante, estilo cardápio) ─────────────
class _BrandingHeader extends StatefulWidget {
  final String logoUrl;
  final String bannerUrl;
  final String name;
  final String fallbackInitials;
  final bool uploadingLogo;
  final bool uploadingBanner;
  final VoidCallback onUploadLogo;
  final VoidCallback onRemoveLogo;
  final VoidCallback onUploadBanner;
  final VoidCallback onRemoveBanner;

  const _BrandingHeader({
    required this.logoUrl,
    required this.bannerUrl,
    required this.name,
    required this.fallbackInitials,
    required this.uploadingLogo,
    required this.uploadingBanner,
    required this.onUploadLogo,
    required this.onRemoveLogo,
    required this.onUploadBanner,
    required this.onRemoveBanner,
  });

  @override
  State<_BrandingHeader> createState() => _BrandingHeaderState();
}

class _BrandingHeaderState extends State<_BrandingHeader> {
  static const _ink = Color(0xFF1C1C1E);
  // Banner full-bleed com altura compacta. A imagem continua sendo recortada
  // em 21:9 no upload; aqui é só a faixa de preview, mais elegante.
  static const double _bannerHeight = 150;
  static const double _logoSize = 88;

  bool _bannerHover = false;
  bool _logoHover = false;

  @override
  Widget build(BuildContext context) {
    // Sem card próprio — a seção que o contém já fornece o card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            _buildBanner(),
            Positioned(
              bottom: -_logoSize / 2,
              child: _buildLogo(),
            ),
          ],
        ),
        // Espaço reservado para a metade da logo que "flutua" sobre o branco.
        const SizedBox(height: _logoSize / 2 + 14),
        if (widget.name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, color: _ink, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 8),
        // Requisitos do upload: formatos, limite e resolução recomendada.
        Center(
          child: UploadHints(
            recommendation: 'Banner recomendado: ${kBannerOutW.toInt()} × ${kBannerOutH.toInt()} px (21:9)',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    final hasImage = widget.bannerUrl.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _bannerHover = true),
      onExit: (_) => setState(() => _bannerHover = false),
      child: GestureDetector(
        onTap:
            !widget.uploadingBanner && !hasImage ? widget.onUploadBanner : null,
        child: SizedBox(
          height: _bannerHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  widget.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _bannerPlaceholder(),
                )
              else
                _bannerPlaceholder(),
              if (widget.uploadingBanner)
                _loadingOverlay()
              else if (_bannerHover)
                _bannerHoverOverlay(hasImage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerPlaceholder() {
    return Container(
      color: const Color(0xFFF1F2F4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.image, size: 30, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Adicionar banner',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 2),
            Text(
              '${kBannerOutW.toInt()} × ${kBannerOutH.toInt()} px · 21:9',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerHoverOverlay(bool hasImage) {
    return Container(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _overlayButton(
              icon: hasImage ? LucideIcons.refreshCw : LucideIcons.upload,
              label: hasImage ? 'Trocar banner' : 'Enviar banner',
              onTap: widget.onUploadBanner,
              filled: true,
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              _overlayButton(
                icon: LucideIcons.trash2,
                label: 'Remover',
                onTap: widget.onRemoveBanner,
                filled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    final hasImage = widget.logoUrl.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _logoHover = true),
      onExit: (_) => setState(() => _logoHover = false),
      child: GestureDetector(
        onTap: !widget.uploadingLogo && !hasImage ? widget.onUploadLogo : null,
        child: Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.network(
                  widget.logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _logoPlaceholder(),
                )
              else
                _logoPlaceholder(),
              if (widget.uploadingLogo)
                _loadingOverlay()
              else if (_logoHover)
                _logoHoverOverlay(hasImage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    final hasInitials =
        widget.fallbackInitials.isNotEmpty && widget.fallbackInitials != '?';
    return Container(
      color: const Color(0xFFF1F2F4),
      child: Center(
        child: hasInitials
            ? Text(
                widget.fallbackInitials,
                style: const TextStyle(
                    fontSize: 26, color: _ink, fontWeight: FontWeight.w600),
              )
            : Icon(LucideIcons.image, size: 24, color: Colors.grey[400]),
      ),
    );
  }

  Widget _logoHoverOverlay(bool hasImage) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _logoIconAction(
            icon: hasImage ? LucideIcons.refreshCw : LucideIcons.upload,
            tooltip: hasImage ? 'Trocar logo' : 'Enviar logo',
            onTap: widget.onUploadLogo,
          ),
          if (hasImage) ...[
            const SizedBox(width: 6),
            _logoIconAction(
              icon: LucideIcons.trash2,
              tooltip: 'Remover logo',
              onTap: widget.onRemoveLogo,
            ),
          ],
        ],
      ),
    );
  }

  Widget _logoIconAction(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  // ── Shared ──────────────────────────────────────────────────────────────
  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _overlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final fg = filled ? _ink : Colors.white;
    final bg = filled ? Colors.white : Colors.transparent;
    return Material(
      color: bg,
      shape: StadiumBorder(
          side: filled
              ? BorderSide.none
              : const BorderSide(color: Colors.white70)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo de nova personalidade da IA (título + texto) ───────────────────
class _PersonalityDialog extends StatefulWidget {
  final bool Function(String label) isDuplicateLabel;
  const _PersonalityDialog({required this.isDuplicateLabel});

  @override
  State<_PersonalityDialog> createState() => _PersonalityDialogState();
}

class _PersonalityDialogState extends State<_PersonalityDialog> {
  static const _ink = Color(0xFF1C1C1E);
  static const _steel = Color(0xFF6B6F7E);

  final _labelCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  String? _labelError;
  String? _promptError;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    final prompt = _promptCtrl.text.trim();
    setState(() {
      _labelError = label.isEmpty
          ? 'Informe um título'
          : widget.isDuplicateLabel(label)
              ? 'Já existe uma personalidade com esse título'
              : null;
      _promptError = prompt.isEmpty ? 'Descreva a personalidade' : null;
    });
    if (_labelError != null || _promptError != null) return;
    Navigator.of(context).pop((label: label, prompt: prompt));
  }

  InputDecoration _dec({required String label, String? hint, String? error}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      labelStyle: const TextStyle(fontSize: 13, color: _steel),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ink, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width * 0.9, 480.0);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nova personalidade',
                  style: TextStyle(
                      fontSize: 17, color: _ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                'Dê um título e descreva como o atendente deve se comportar.',
                style: TextStyle(fontSize: 12.5, color: _steel, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelCtrl,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
                decoration: _dec(
                        label: 'Título',
                        hint: 'Ex.: Divertido',
                        error: _labelError)
                    .copyWith(counterText: ''),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _promptCtrl,
                maxLength: 500,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                onChanged: (_) {
                  if (_promptError != null) setState(() => _promptError = null);
                },
                decoration: _dec(
                  label: 'Personalidade',
                  hint:
                      'Ex.: Você é um atendente bem-humorado, faz piadas leves...',
                  error: _promptError,
                ).copyWith(counterText: ''),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: _steel),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Salvar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
