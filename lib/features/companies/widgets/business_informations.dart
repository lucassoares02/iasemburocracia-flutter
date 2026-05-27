import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/account/widgets/base_account.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:provider/provider.dart';

const List<Color> _kSwatches = [
  Color(0xFF1C1C1E),
  Color(0xFF4262FF),
  Color(0xFF00B473),
  Color(0xFFE53935),
  Color(0xFFFF6B35),
  Color(0xFF7C3AED),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
];

class BusinessInformations extends StatefulWidget {
  const BusinessInformations({super.key, required this.controller});

  final CompaniesController controller;

  @override
  State<BusinessInformations> createState() => _BusinessInformationsState();
}

class _BusinessInformationsState extends State<BusinessInformations> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _repo = CompaniesRepository();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _logoUrlCtrl;
  late TextEditingController _bannerUrlCtrl;
  late TextEditingController _hexCtrl; // RRGGBB without #

  Color? _selectedColor;
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
  String? _aiGender;
  final Set<String> _dietaryRestrictions = {};
  String? _selectedPersonalityPreset;

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
    super.dispose();
  }

  void _initCtrls(CompaniesModel c) {
    _company = c;
    _nameCtrl.text = c.name ?? '';
    _descCtrl.text = c.description ?? '';
    _phoneCtrl.text = c.phone ?? '';
    _logoUrlCtrl.text = c.logoUrl ?? '';
    _bannerUrlCtrl.text = c.bannerUrl ?? '';
    _selectedColor = _parseHex(c.brandColor);
    _hexCtrl.text = (c.brandColor ?? '').replaceAll('#', '');
    _aiNameCtrl.text = c.aiName ?? '';
    _aiPersonalityCtrl.text = c.aiPersonality ?? '';
    _cuisineTypeCtrl.text = c.cuisineType ?? '';
    _aiGender = c.aiGender;
    _dietaryRestrictions
      ..clear()
      ..addAll(c.dietaryRestrictions ?? []);
    _maxDistanceDeliveryCtrl.text = c.maxDistanceMetersDelivery?.toString() ?? '';
    _kilometerPriceCtrl.text = c.kilometerPrice?.toStringAsFixed(2) ?? '';
    _maxDistanceFreeDeliveryCtrl.text = c.maxDistanceMetersFreeDelivery?.toString() ?? '';
    _minPriceOrderCtrl.text = c.minPriceOrder?.toStringAsFixed(2) ?? '';
    _minTaxDeliveryCtrl.text = c.minTaxDelivery?.toStringAsFixed(2) ?? '';
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return null;
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  // Effective brand color: live selection while editing, saved color otherwise,
  // theme primary as final fallback.
  Color get _actionColor {
    final live = _isEditing ? _selectedColor : _parseHex(_company?.brandColor);
    return live ?? Theme.of(context).primaryColor;
  }

  String _colorHex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  void _toggleEdit() => setState(() {
        _isEditing = !_isEditing;
        if (!_isEditing && _company != null) _initCtrls(_company!);
      });

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final hex = _hexCtrl.text.trim();
    final updatedCompany = CompaniesModel.fromJson({
      'id': _company?.id,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'status': _company?.status,
      'logo_url': _logoUrlCtrl.text.trim().isEmpty ? null : _logoUrlCtrl.text.trim(),
      'brand_color': hex.isEmpty ? null : '#${hex.toUpperCase()}',
      'banner_url': _bannerUrlCtrl.text.trim().isEmpty ? null : _bannerUrlCtrl.text.trim(),
      'ai_name': _aiNameCtrl.text.trim().isEmpty ? null : _aiNameCtrl.text.trim(),
      'ai_gender': _aiGender,
      'ai_personality': _aiPersonalityCtrl.text.trim().isEmpty ? null : _aiPersonalityCtrl.text.trim(),
      'cuisine_type': _cuisineTypeCtrl.text.trim().isEmpty ? null : _cuisineTypeCtrl.text.trim(),
      'dietary_restrictions': _dietaryRestrictions.isEmpty ? null : _dietaryRestrictions.toList(),
      'max_distance_meters_delivery': int.tryParse(_maxDistanceDeliveryCtrl.text.trim()),
      'kilometer_price': double.tryParse(_kilometerPriceCtrl.text.trim().replaceAll(',', '.')),
      'max_distance_meters_free_delivery': int.tryParse(_maxDistanceFreeDeliveryCtrl.text.trim()),
      'min_price_order': double.tryParse(_minPriceOrderCtrl.text.trim().replaceAll(',', '.')),
      'min_tax_delivery': double.tryParse(_minTaxDeliveryCtrl.text.trim().replaceAll(',', '.')),
    });
    await widget.controller.update(updatedCompany);
    if (!mounted) return;
    context.read<OnboardingProvider>().refresh(silent: true);
    setState(() => _isEditing = false);
  }

  Future<void> _uploadImage({required bool isLogo}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;

    final mime = switch ((f.extension ?? 'jpg').toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    setState(() => isLogo ? _uploadingLogo = true : _uploadingBanner = true);
    try {
      final resp = await _repo.uploadCompanyImage(
        f.bytes!,
        f.name,
        mime,
        type: isLogo ? 'logo' : 'banner',
      );
      if (resp.success && resp.data != null) {
        final url = resp.data['url'] as String?;
        if (url != null) {
          setState(() => isLogo ? _logoUrlCtrl.text = url : _bannerUrlCtrl.text = url);
        }
      }
    } finally {
      setState(() => isLogo ? _uploadingLogo = false : _uploadingBanner = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BaseAccount(
      title: '',
      child: Expanded(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: widget.controller.stateFind,
                builder: (context, state, _) {
                  if (state is LoadingState) return _skeleton();
                  if (state is ErrorState) return _errorView(state.message);
                  if (state is SuccessState) {
                    final c = state.data as CompaniesModel;
                    if (_company == null || !_isEditing) _initCtrls(c);
                    return _content(c);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CompaniesModel c) {
    return Column(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(c),
                    const Spacing(),
                    _buildInfoSection(c),
                    const SizedBox(height: 24),
                    _buildOperationalPreferencesSection(c),
                    const SizedBox(height: 24),
                    _buildAiSection(c),
                    const SizedBox(height: 24),
                    _buildBrandingSection(),
                    const SizedBox(height: 24),
                    _buildPreviewCard(c),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(CompaniesModel c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações da Empresa',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      letterSpacing: -0.5,
                      color: const Color(0xFF09090B),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gerencie os dados principais e identidade visual da empresa.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF71717A),
                    ),
              ),
              const SizedBox(height: 10),
              _statusBadge(c.status ?? false),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            if (_isEditing) ...[
              OutlinedButton(
                onPressed: _toggleEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C1C1E),
                  side: const BorderSide(color: Color(0xFFE0E2E8)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text('Salvar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(LucideIcons.edit2, size: 16),
                label: const Text('Editar'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Basic info section ───────────────────────────────────────────────────────

  Widget _buildInfoSection(CompaniesModel c) {
    return _sectionCard(children: [
      _infoRow(
        icon: Icons.badge_outlined,
        label: 'Nome',
        value: c.name ?? 'Não informado',
        ctrl: _nameCtrl,
        maxLength: 100,
        validator: (v) => (v == null || v.isEmpty) ? 'Nome é obrigatório' : null,
      ),
      _infoRow(
        icon: Icons.phone_outlined,
        label: 'Telefone',
        value: c.phone ?? 'Não informado',
        ctrl: _phoneCtrl,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          MaskedInputFormatter(
            '(##) #####-####',
            allowedCharMatcher: RegExp(r'[0-9]'),
          ),
        ],
      ),
      _infoRow(
        icon: Icons.description_outlined,
        label: 'Descrição',
        value: c.description ?? 'Não informado',
        ctrl: _descCtrl,
        maxLength: 500,
        maxLines: 5,
        keyboardType: TextInputType.text,
      ),
    ]);
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? ctrl,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6B6F7E)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (_isEditing && ctrl != null)
                  CustomInput(
                    controller: ctrl,
                    keyboardType: keyboardType,
                    validator: validator,
                    maxLenght: maxLength,
                    maxLines: maxLines ?? 1,
                    inputFormatters: inputFormatters,
                  )
                else
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── AI & Cardápio section ───────────────────────────────────────────────────

  Widget _buildOperationalPreferencesSection(CompaniesModel c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Preferências operacionais'),
        const SizedBox(height: 16),
        _sectionCard(
          children: [
            _infoRow(
              icon: LucideIcons.mapPin,
              label: 'Distância máxima de entrega (metros)',
              value: _distanceValue(c.maxDistanceMetersDelivery),
              ctrl: _maxDistanceDeliveryCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 7,
            ),
            _infoRow(
              icon: LucideIcons.gauge,
              label: 'Preço por quilômetro (R\$)',
              value: _currencyValue(c.kilometerPrice),
              ctrl: _kilometerPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              maxLength: 10,
            ),
            _infoRow(
              icon: LucideIcons.truck,
              label: 'Distância máxima para frete grátis (metros)',
              value: _distanceValue(c.maxDistanceMetersFreeDelivery),
              ctrl: _maxDistanceFreeDeliveryCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 7,
            ),
            _infoRow(
              icon: LucideIcons.shoppingCart,
              label: 'Pedido mínimo (R\$)',
              value: _currencyValue(c.minPriceOrder),
              ctrl: _minPriceOrderCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              maxLength: 10,
            ),
            _infoRow(
              icon: LucideIcons.receipt,
              label: 'Taxa mínima de entrega (R\$)',
              value: _currencyValue(c.minTaxDelivery),
              ctrl: _minTaxDeliveryCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              maxLength: 10,
            ),
          ],
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Inteligência Artificial & Cardápio'),
        const SizedBox(height: 16),
        _sectionCard(children: [
          _infoRow(
            icon: LucideIcons.bot,
            label: 'Nome da IA',
            value: c.aiName ?? 'Não informado',
            ctrl: _aiNameCtrl,
            maxLength: 100,
          ),
          _genderRow(c),
          _personalityRow(c),
          _infoRow(
            icon: LucideIcons.utensils,
            label: 'Tipo de culinária',
            value: c.cuisineType ?? 'Não informado',
            ctrl: _cuisineTypeCtrl,
            maxLength: 100,
          ),
          _dietaryRow(c),
        ]),
      ],
    );
  }

  Widget _personalityRow(CompaniesModel c) {
    final displayValue = _aiPersonalityCtrl.text.trim().isEmpty ? (c.aiPersonality ?? 'Não informado') : _aiPersonalityCtrl.text.trim();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingIcon(LucideIcons.messageSquare),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalidade da IA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (_isEditing) ...[
                  CustomInput(
                    controller: _aiPersonalityCtrl,
                    maxLenght: 500,
                    maxLines: 4,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kPersonalityPresets.map((preset) {
                      final selected = _selectedPersonalityPreset == preset.label;
                      return ActionChip(
                        avatar: Icon(
                          LucideIcons.sparkles,
                          size: 14,
                          color: selected ? _actionColor : const Color(0xFF8E91A0),
                        ),
                        label: Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected ? _actionColor : const Color(0xFF555A6A),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedPersonalityPreset = preset.label;
                            _aiPersonalityCtrl.text = preset.prompt;
                          });
                        },
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? _actionColor.withValues(alpha: 0.35) : Colors.grey[300]!,
                        ),
                        backgroundColor: selected ? _actionColor.withValues(alpha: 0.12) : Colors.white,
                        elevation: 0,
                        pressElevation: 0,
                      );
                    }).toList(),
                  ),
                ] else
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRow(CompaniesModel c) {
    final displayValue = switch (c.aiGender) {
      'masculino' => 'Masculino',
      'feminino' => 'Feminino',
      'neutro' => 'Neutro',
      _ => 'Não informado',
    };
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingIcon(LucideIcons.user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gênero da IA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Wrap(
                    spacing: 8,
                    children: _kGenderOptions.map((opt) {
                      final selected = _aiGender == opt.$1;
                      return ChoiceChip(
                        label: Text(opt.$2),
                        selected: selected,
                        onSelected: (_) => setState(() => _aiGender = opt.$1),
                        selectedColor: _actionColor.withValues(alpha: 0.12),
                        checkmarkColor: _actionColor,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: selected ? _actionColor : Colors.grey[700],
                          fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? _actionColor : Colors.grey[300]!,
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dietaryRow(CompaniesModel c) {
    final displayValue = _dietaryRestrictions.isEmpty ? 'Nenhuma' : _dietaryRestrictions.join(', ');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingIcon(LucideIcons.leaf),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restrições alimentares',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _kDietaryOptions.map((opt) {
                      final selected = _dietaryRestrictions.contains(opt);
                      return FilterChip(
                        label: Text(opt),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _dietaryRestrictions.add(opt);
                          } else {
                            _dietaryRestrictions.remove(opt);
                          }
                        }),
                        selectedColor: _actionColor.withValues(alpha: 0.12),
                        checkmarkColor: _actionColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? _actionColor : Colors.grey[700],
                          fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? _actionColor : Colors.grey[300]!,
                        ),
                        showCheckmark: true,
                      );
                    }).toList(),
                  )
                else
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Branding section ─────────────────────────────────────────────────────────

  Widget _buildBrandingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Identidade Visual'),
        const SizedBox(height: 16),
        _sectionCard(children: [
          _logoRow(),
          _colorRow(),
          _bannerRow(),
        ]),
      ],
    );
  }

  Widget _logoRow() {
    final url = _logoUrlCtrl.text.trim();
    final hasImage = url.isNotEmpty;
    final brand = _actionColor;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingLabel(LucideIcons.image, 'Logo'),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'Aparece no cabeçalho do cardápio público',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 20),
          // ── Centered preview / drop zone ─────────────────────────────────
          Center(
            child: _LogoDropZone(
              url: hasImage ? url : null,
              uploading: _uploadingLogo,
              isEditing: _isEditing,
              brand: brand,
              fallbackInitials: _getInitials(_nameCtrl.text),
              onUpload: _isEditing ? () => _uploadImage(isLogo: true) : null,
              onRemove: _isEditing && hasImage ? () => setState(() => _logoUrlCtrl.text = '') : null,
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            _urlField(_logoUrlCtrl, 'URL da logo', brand),
          ],
        ],
      ),
    );
  }

  Widget _colorRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingIcon(LucideIcons.palette),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cor da marca',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B6F7E)),
                ),
                const SizedBox(height: 12),
                if (_isEditing) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kSwatches.map((c) {
                      final selected = _selectedColor?.toARGB32() == c.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedColor = c;
                          _hexCtrl.text = _colorHex(c);
                        }),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: Colors.black87, width: 2.5) : Border.all(color: Colors.transparent),
                          ),
                          child: selected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor ?? Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('#', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
                      const SizedBox(width: 2),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _hexCtrl,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (v) {
                            final parsed = _parseHex(v);
                            if (parsed != null) {
                              setState(() => _selectedColor = parsed);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: InputDecoration(
                            hintText: '4262FF',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor ?? Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _hexCtrl.text.isEmpty ? 'Não definida' : '#${_hexCtrl.text.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerRow() {
    final url = _bannerUrlCtrl.text.trim();
    final hasImage = url.isNotEmpty;
    final brand = _actionColor;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandingLabel(LucideIcons.layoutTemplate, 'Banner'),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'Imagem grande exibida no topo do cardápio',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 20),
          _BannerDropZone(
            url: hasImage ? url : null,
            uploading: _uploadingBanner,
            isEditing: _isEditing,
            brand: brand,
            onUpload: _isEditing ? () => _uploadImage(isLogo: false) : null,
            onRemove: _isEditing && hasImage ? () => setState(() => _bannerUrlCtrl.text = '') : null,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 16),
            _urlField(_bannerUrlCtrl, 'URL do banner', brand),
          ],
        ],
      ),
    );
  }

  // ─── Public preview card ──────────────────────────────────────────────────────

  Widget _buildPreviewCard(CompaniesModel c) {
    final logoUrl = _isEditing ? _logoUrlCtrl.text.trim() : (c.logoUrl ?? '');
    final bannerUrl = _isEditing ? _bannerUrlCtrl.text.trim() : (c.bannerUrl ?? '');
    final brandColor = (_isEditing ? _selectedColor : _parseHex(c.brandColor)) ?? const Color(0xFF1C1C1E);
    final name = _isEditing ? _nameCtrl.text : (c.name ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pré-visualização do cardápio público'),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: bannerUrl.isNotEmpty
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: brandColor.withValues(alpha: 0.18)),
                        )
                      : Container(color: brandColor.withValues(alpha: 0.12)),
                ),
                // Logo + company info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initialsWidget(name, brandColor, 17),
                              )
                            : _initialsWidget(name, brandColor, 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Nome da empresa' : name,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Aberto',
                                style: TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[100]),
                // Sample product row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Produto exemplo',
                              style: TextStyle(fontSize: 13, color: Color(0xFF1C1C1E)),
                            ),
                            Text(
                              'R\$ 25,00',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1C1C1E)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: brandColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Atualiza em tempo real conforme você edita',
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  String _currencyValue(double? value) {
    if (value == null) return 'Não informado';
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }

  String _distanceValue(int? value) {
    if (value == null) return 'Não informado';
    return '$value m';
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _initialsWidget(String name, Color brandColor, double fontSize) {
    return Container(
      color: brandColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(fontSize: fontSize, color: brandColor),
        ),
      ),
    );
  }

  Widget _brandingLabel(IconData icon, String label) {
    return Row(
      children: [
        _brandingIcon(icon),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E))),
      ],
    );
  }

  Widget _brandingIcon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _actionColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: _actionColor),
    );
  }

  Widget _urlField(TextEditingController ctrl, String label, [Color? focusColor]) {
    final accent = focusColor ?? _actionColor;
    return TextField(
      controller: ctrl,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
        hintText: 'https://...',
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
        prefixIcon: Icon(LucideIcons.link, size: 14, color: Colors.grey[400]),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 2)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[800],
          ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: _intersperse(
          children,
          Divider(height: 1, color: Colors.grey[200]),
        ).toList(),
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
              LoadingContainer(height: 80, width: 80, borderRadius: BorderRadius.all(Radius.circular(100))),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Ativa' : 'Inativa',
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

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

// ─── Logo drop zone (centered circular) ─────────────────────────────────────
class _LogoDropZone extends StatefulWidget {
  final String? url;
  final bool uploading;
  final bool isEditing;
  final Color brand;
  final String fallbackInitials;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;

  const _LogoDropZone({
    required this.url,
    required this.uploading,
    required this.isEditing,
    required this.brand,
    required this.fallbackInitials,
    this.onUpload,
    this.onRemove,
  });

  @override
  State<_LogoDropZone> createState() => _LogoDropZoneState();
}

class _LogoDropZoneState extends State<_LogoDropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = (widget.url ?? '').isNotEmpty;
    final clickable = widget.isEditing && widget.onUpload != null;

    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: clickable && !widget.uploading ? (hasImage ? null : widget.onUpload) : null,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasImage ? Colors.white : Colors.grey[50],
                border: Border.all(
                  color: hasImage ? Colors.grey[200]! : (_hover && clickable ? widget.brand : Colors.grey[300]!),
                  width: hasImage ? 1 : 1.5,
                  style: hasImage ? BorderStyle.solid : BorderStyle.solid,
                ),
                boxShadow: _hover && clickable
                    ? [
                        BoxShadow(
                          color: widget.brand.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    Image.network(
                      widget.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emptyContent(clickable),
                    )
                  else
                    _emptyContent(clickable),
                  if (widget.uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isEditing && !widget.uploading) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: widget.onUpload,
                    icon: Icon(
                      hasImage ? LucideIcons.refreshCw : LucideIcons.upload,
                      size: 14,
                    ),
                    label: Text(hasImage ? 'Trocar' : 'Enviar imagem'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.brand,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (hasImage && widget.onRemove != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onRemove,
                      icon: const Icon(LucideIcons.trash2, size: 14),
                      label: const Text('Remover'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (!widget.isEditing && hasImage) ...[
              // view mode: no actions
            ] else if (!widget.isEditing && !hasImage) ...[
              const SizedBox(height: 10),
              Text(
                'Nenhuma logo definida',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyContent(bool clickable) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              clickable ? LucideIcons.upload : LucideIcons.image,
              size: 26,
              color: clickable && _hover ? widget.brand : Colors.grey[400],
            ),
            if (clickable) ...[
              const SizedBox(height: 6),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 11,
                  color: _hover ? widget.brand : Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Banner drop zone (centered rectangular) ────────────────────────────────
class _BannerDropZone extends StatefulWidget {
  final String? url;
  final bool uploading;
  final bool isEditing;
  final Color brand;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;

  const _BannerDropZone({
    required this.url,
    required this.uploading,
    required this.isEditing,
    required this.brand,
    this.onUpload,
    this.onRemove,
  });

  @override
  State<_BannerDropZone> createState() => _BannerDropZoneState();
}

class _BannerDropZoneState extends State<_BannerDropZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = (widget.url ?? '').isNotEmpty;
    final clickable = widget.isEditing && widget.onUpload != null;

    return MouseRegion(
      cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: clickable && !widget.uploading ? (hasImage ? null : widget.onUpload) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 150,
              decoration: BoxDecoration(
                color: hasImage ? Colors.white : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasImage ? Colors.grey[200]! : (_hover && clickable ? widget.brand : Colors.grey[300]!),
                  width: hasImage ? 1 : 1.5,
                ),
                boxShadow: _hover && clickable
                    ? [
                        BoxShadow(
                          color: widget.brand.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      widget.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emptyContent(clickable),
                    )
                  else
                    _emptyContent(clickable),
                  if (widget.uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isEditing && !widget.uploading) ...[
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: widget.onUpload,
                      icon: Icon(
                        hasImage ? LucideIcons.refreshCw : LucideIcons.upload,
                        size: 14,
                      ),
                      label: Text(hasImage ? 'Trocar' : 'Enviar imagem'),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.brand,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (hasImage && widget.onRemove != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onRemove,
                        icon: const Icon(LucideIcons.trash2, size: 14),
                        label: const Text('Remover'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (!widget.isEditing && !hasImage) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Nenhum banner definido',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyContent(bool clickable) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              clickable ? LucideIcons.upload : LucideIcons.layoutTemplate,
              size: 32,
              color: clickable && _hover ? widget.brand : Colors.grey[400],
            ),
            if (clickable) ...[
              const SizedBox(height: 8),
              Text(
                'Clique para enviar uma imagem',
                style: TextStyle(
                  fontSize: 12,
                  color: _hover ? widget.brand : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PNG, JPG ou WEBP · até 10 MB',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
