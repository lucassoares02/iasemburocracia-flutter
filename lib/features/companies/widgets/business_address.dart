import 'dart:async' as dart_async;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/models/business_address_model.dart';
import 'package:portal_assoc/shared/widgets/google_map_widget.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────
class _DS {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;

  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderFocus = Color(0xFF18181B);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFF18181B);
  static const Color accentSubtle = Color(0xFFF4F4F5);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);

  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 1, offset: const Offset(0, 0)),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
  ];
}

// ─── Widget ─────────────────────────────────────────────────────────────────
class BusinessAddress extends StatefulWidget {
  const BusinessAddress({super.key, required this.controller});

  final CompaniesController controller;

  @override
  State<BusinessAddress> createState() => _BusinessAddressState();
}

class _BusinessAddressState extends State<BusinessAddress> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Address text controllers
  late TextEditingController _streetController;
  late TextEditingController _numberController;
  late TextEditingController _complementController;
  late TextEditingController _neighborhoodController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;

  // Places search
  final _searchCtrl = TextEditingController();
  final _layerLink = LayerLink();
  final _debounce = _Debouncer(delay: const Duration(milliseconds: 500));
  List<PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  OverlayEntry? _overlayEntry;
  String? _sessionToken;

  // Pending lat/lng from Places selection
  double? _pendingLat;
  double? _pendingLng;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  BusinessAddressModel? _currentAccount;

  @override
  void initState() {
    super.initState();
    widget.controller.findBusinessAddress();
    _streetController = TextEditingController();
    _numberController = TextEditingController();
    _complementController = TextEditingController();
    _neighborhoodController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipCodeController = TextEditingController();

    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    widget.controller.stateAddressAutocomplete.addListener(_onSuggestions);
    widget.controller.stateAddressDetails.addListener(_onDetails);
  }

  @override
  void dispose() {
    _removeOverlay();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _searchCtrl.dispose();
    _debounce.cancel();
    _animController.dispose();
    widget.controller.stateAddressAutocomplete.removeListener(_onSuggestions);
    widget.controller.stateAddressDetails.removeListener(_onDetails);
    super.dispose();
  }

  // ─── Places overlay ─────────────────────────────────────────────────────────

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: _layerLink.leaderSize?.width ?? 500,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (_layerLink.leaderSize?.height ?? 44) + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_DS.radiusLg),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(_DS.radiusLg),
                border: Border.all(color: _DS.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    borderRadius: BorderRadius.circular(_DS.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: _DS.textSecondary),
                          const SizedBox(width: _DS.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.mainText ?? s.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _DS.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.secondaryText != null)
                                  Text(
                                    s.secondaryText!,
                                    style: const TextStyle(fontSize: 11, color: _DS.textTertiary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSuggestions() {
    final s = widget.controller.stateAddressAutocomplete.value;
    if (!mounted) return;
    if (s is LoadingState) {
      setState(() => _loadingSuggestions = true);
    } else if (s is SuccessState) {
      setState(() {
        _loadingSuggestions = false;
        _suggestions = (s.data as List).cast<PlaceSuggestion>();
      });
      _showOverlay();
    } else {
      setState(() => _loadingSuggestions = false);
      _removeOverlay();
    }
  }

  void _onDetails() {
    final s = widget.controller.stateAddressDetails.value;
    if (!mounted) return;
    if (s is SuccessState) {
      final d = s.data as PlaceDetails;
      setState(() {
        _pendingLat = d.lat;
        _pendingLng = d.lng;
        if (d.street != null) _streetController.text = d.street!;
        if (d.number != null) _numberController.text = d.number!;
        if (d.neighborhood != null) _neighborhoodController.text = d.neighborhood!;
        if (d.city != null) _cityController.text = d.city!;
        if (d.state != null) _stateController.text = d.state!;
        if (d.zipCode != null) _zipCodeController.text = d.zipCode!;
        _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      });
      _removeOverlay();
    }
  }

  void _onSearchChanged(String v) {
    if (v.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      _removeOverlay();
      return;
    }
    _debounce.run(() {
      widget.controller.addressAutocomplete(v.trim(), sessionToken: _sessionToken);
    });
  }

  void _selectSuggestion(PlaceSuggestion s) {
    _searchCtrl.text = s.description;
    _removeOverlay();
    widget.controller.addressDetails(s.placeId, sessionToken: _sessionToken);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _initializeControllers(BusinessAddressModel a) {
    _currentAccount = a;
    _streetController.text = a.street ?? '';
    _numberController.text = a.number ?? '';
    _complementController.text = a.complement ?? '';
    _neighborhoodController.text = a.neighborhood ?? '';
    _cityController.text = a.city ?? '';
    _stateController.text = a.state ?? '';
    _zipCodeController.text = a.zipCode ?? '';
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _searchCtrl.clear();
        _pendingLat = null;
        _pendingLng = null;
        _removeOverlay();
        if (_currentAccount != null) _initializeControllers(_currentAccount!);
      }
    });
  }

  _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;

    final lat = _pendingLat?.toString() ?? _currentAccount?.latitude;
    final lng = _pendingLng?.toString() ?? _currentAccount?.longitude;

    final updated = BusinessAddressModel.fromJson({
      'id': _currentAccount!.id,
      'street': _streetController.text,
      'company_id': companyId,
      'number': _numberController.text,
      'complement': _complementController.text,
      'neighborhood': _neighborhoodController.text,
      'city': _cityController.text,
      'state': _stateController.text,
      'zip_code': _zipCodeController.text,
      'latitude': lat,
      'longitude': lng,
    });

    await widget.controller.updateBusiness(updated);
    if (!mounted) return;
    // Mantém o snapshot de onboarding em sincronia caso o usuário tenha
    // cadastrado o endereço fora do wizard.
    context.read<OnboardingProvider>().refresh(silent: true);
    setState(() {
      _isEditing = false;
      _searchCtrl.clear();
      _pendingLat = null;
      _pendingLng = null;
    });
  }

  // ─── Map helper ───────────────────────────────────────────────────────────────

  double? _displayLat() {
    if (_isEditing && _pendingLat != null) return _pendingLat;
    final raw = _currentAccount?.latitude;
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _displayLng() {
    if (_isEditing && _pendingLng != null) return _pendingLng;
    final raw = _currentAccount?.longitude;
    if (raw == null || raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ValueListenableBuilder(
          valueListenable: widget.controller.stateFindBusinessAddress,
          builder: (context, state, _) {
            if (state is LoadingState) return _buildLoadingSkeleton();
            if (state is ErrorState) return _buildErrorState(state.message);
            if (state is SuccessState) {
              final addr = state.data as BusinessAddressModel;
              if (_currentAccount == null || !_isEditing) {
                _initializeControllers(addr);
              }
              return _buildContent(addr);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(_DS.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingContainer(height: 20, width: 160),
                  const SizedBox(height: _DS.s2),
                  LoadingContainer(height: 14, width: 240),
                ],
              ),
              LoadingContainer(height: 36, width: 80, borderRadius: BorderRadius.circular(_DS.radiusMd)),
            ],
          ),
          const SizedBox(height: _DS.s6),
          Container(
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.border),
            ),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
                  child: Row(
                    children: [
                      LoadingContainer(height: 36, width: 36, borderRadius: BorderRadius.circular(_DS.radiusMd)),
                      const SizedBox(width: _DS.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LoadingContainer(height: 11, width: 80),
                            const SizedBox(height: _DS.s2),
                            LoadingContainer(height: 16, width: double.infinity),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_DS.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _DS.dangerSubtle,
                borderRadius: BorderRadius.circular(_DS.radiusLg),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(LucideIcons.alertTriangle, size: 24, color: _DS.danger),
            ),
            const SizedBox(height: _DS.s4),
            Text(
              'Erro ao carregar endereço',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _DS.textPrimary,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: _DS.s2),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _DS.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _DS.s6),
            _SaasOutlinedButton(
              onPressed: widget.controller.findBusinessAddress,
              icon: LucideIcons.refreshCw,
              label: 'Tentar novamente',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────────

  Widget _buildContent(BusinessAddressModel addr) {
    final lat = _displayLat();
    final lng = _displayLng();

    return Column(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(_DS.s6),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: _DS.s6),

                    // Places search — only in edit mode
                    if (_isEditing) ...[
                      _buildSearchField(),
                      const SizedBox(height: _DS.s4),
                    ],

                    _buildAddressCard(addr),

                    // Map preview — if lat/lng available
                    if (lat != null && lng != null) ...[
                      const SizedBox(height: _DS.s4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(_DS.radiusLg),
                        child: GoogleMapWidget(lat: lat, lng: lng, height: 220),
                      ),
                    ],

                    const SizedBox(height: _DS.s8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Page header ──────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Endereço Comercial',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _DS.textPrimary,
                      letterSpacing: -0.5,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: _DS.s1),
              Text(
                'Gerencie o endereço registrado da sua empresa.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _DS.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: _DS.s4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(anim), child: child),
          ),
          child: _isEditing
              ? Row(
                  key: const ValueKey('editing'),
                  children: [
                    _SaasGhostButton(onPressed: _toggleEditMode, label: 'Cancelar'),
                    const SizedBox(width: _DS.s2),
                    ValueListenableBuilder<StateApp>(
                      valueListenable: widget.controller.stateUpdateBusiness,
                      builder: (_, state, __) => _SaasPrimaryButton(
                        onPressed: state is LoadingState ? () {} : _saveChanges,
                        icon: state is LoadingState ? LucideIcons.loader : LucideIcons.check,
                        label: state is LoadingState ? 'Salvando...' : 'Salvar',
                      ),
                    ),
                  ],
                )
              : _SaasOutlinedButton(
                  key: const ValueKey('viewing'),
                  onPressed: _toggleEditMode,
                  icon: LucideIcons.edit2,
                  label: 'Editar',
                ),
        ),
      ],
    );
  }

  // ─── Search field ──────────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buscar endereço com Google Maps',
          style: TextStyle(
            fontSize: 11,
            color: _DS.textTertiary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: _DS.s2),
        CompositedTransformTarget(
          link: _layerLink,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(color: _DS.border),
              boxShadow: _DS.shadowSm,
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: _DS.s3),
                  child: Icon(LucideIcons.search, size: 15, color: _DS.textSecondary),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _DS.textPrimary),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: _DS.surface,
                      hintText: 'Ex: Av. Paulista, 1000 — São Paulo...',
                      hintStyle: TextStyle(color: _DS.textTertiary, fontSize: 14, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: _DS.s3),
                    ),
                  ),
                ),
                if (_loadingSuggestions)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: _DS.s3),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _DS.s2),
        const Text(
          'Selecione um endereço para preencher os campos automaticamente.',
          style: TextStyle(fontSize: 11, color: _DS.textTertiary, height: 1.4),
        ),
      ],
    );
  }

  // ─── Address card ─────────────────────────────────────────────────────────────

  Widget _buildAddressCard(BusinessAddressModel addr) {
    final fields = [
      _FieldConfig(
        icon: LucideIcons.mapPin,
        label: 'Logradouro',
        value: addr.street,
        controller: _streetController,
        maxLength: 255,
        validator: (v) => (v == null || v.isEmpty) ? 'Logradouro é obrigatório' : null,
      ),
      _FieldConfig(
        icon: LucideIcons.hash,
        label: 'Número',
        value: addr.number,
        controller: _numberController,
        keyboardType: TextInputType.number,
      ),
      _FieldConfig(
        icon: LucideIcons.layers,
        label: 'Complemento',
        value: addr.complement,
        controller: _complementController,
        maxLength: 100,
        placeholder: 'Ex: Apto 12, Bloco B',
      ),
      _FieldConfig(
        icon: LucideIcons.grid,
        label: 'Bairro',
        value: addr.neighborhood,
        controller: _neighborhoodController,
        maxLength: 100,
      ),
      _FieldConfig(
        icon: LucideIcons.building2,
        label: 'Cidade',
        value: addr.city,
        controller: _cityController,
        maxLength: 100,
        validator: (v) => (v == null || v.isEmpty) ? 'Cidade é obrigatória' : null,
      ),
      _FieldConfig(
        icon: LucideIcons.flag,
        label: 'Estado',
        value: addr.state,
        controller: _stateController,
        maxLength: 2,
        hint: 'UF',
      ),
      _FieldConfig(
        icon: LucideIcons.mailOpen,
        label: 'CEP',
        value: addr.zipCode,
        controller: _zipCodeController,
        maxLength: 9,
        keyboardType: TextInputType.number,
        inputFormatters: [
          MaskedInputFormatter('#####-###', allowedCharMatcher: RegExp(r'[0-9]')),
        ],
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusLg),
        border: Border.all(color: _DS.border),
      ),
      padding: const EdgeInsets.all(_DS.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _DS.accentSubtle,
                  borderRadius: BorderRadius.circular(_DS.radiusSm),
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: _DS.textSecondary,
                ),
              ),
              const SizedBox(width: _DS.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dados do endereço',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _DS.textPrimary,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: _DS.s1),
                    Text(
                      _isEditing ? 'Revise os campos antes de salvar as alterações.' : 'Informações usadas no cadastro e localização da empresa.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _DS.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s3),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 760;
              final itemWidth = twoColumns ? (constraints.maxWidth - _DS.s3) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: _DS.s3,
                runSpacing: _DS.s3,
                children: fields
                    .map(
                      (field) => SizedBox(
                        width: itemWidth,
                        child: _buildFieldCard(field),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(_FieldConfig field) {
    final isEmpty = (field.value == null || field.value!.isEmpty);
    final displayValue = isEmpty ? (field.placeholder ?? '—') : field.value!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: _isEditing && field.controller != null ? const Color(0xFFFCFCFD) : _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: _DS.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(field.icon, size: 13, color: _DS.textSecondary),
              const SizedBox(width: _DS.s2),
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _DS.textTertiary,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isEditing && field.controller != null
                ? _SaasInput(
                    key: ValueKey('input_${field.label}'),
                    controller: field.controller!,
                    keyboardType: field.keyboardType,
                    validator: field.validator,
                    maxLength: field.maxLength,
                    hintText: field.hint,
                    inputFormatters: field.inputFormatters,
                  )
                : Align(
                    key: ValueKey('text_${field.label}'),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 13,
                        color: isEmpty ? _DS.textTertiary : _DS.textPrimary,
                        height: 1.25,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Config ────────────────────────────────────────────────────────────

class _FieldConfig {
  final IconData icon;
  final String label;
  final String? value;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? placeholder;
  final String? hint;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _FieldConfig({
    required this.icon,
    required this.label,
    this.value,
    this.controller,
    this.keyboardType,
    this.maxLength,
    this.placeholder,
    this.hint,
    this.inputFormatters,
    this.validator,
  });
}

// ─── Debouncer ────────────────────────────────────────────────────────────────

class _Debouncer {
  final Duration delay;
  dart_async.Timer? _timer;

  _Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = dart_async.Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}

// ─── Design System Components ────────────────────────────────────────────────

class _SaasInput extends StatefulWidget {
  const _SaasInput({
    super.key,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.hintText,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_SaasInput> createState() => _SaasInputState();
}

class _SaasInputState extends State<_SaasInput> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(
          color: _focused ? _DS.borderFocus : _DS.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused ? _DS.shadowMd : _DS.shadowSm,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        style: const TextStyle(fontSize: 14, color: _DS.textPrimary, height: 1.4),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: _DS.textTertiary, fontSize: 14, fontWeight: FontWeight.w400),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s3),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: _DS.danger, height: 1.4),
        ),
      ),
    );
  }
}

class _SaasPrimaryButton extends StatefulWidget {
  const _SaasPrimaryButton({
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  State<_SaasPrimaryButton> createState() => _SaasPrimaryButtonState();
}

class _SaasPrimaryButtonState extends State<_SaasPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s2 + 2),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF27272A) : _DS.accent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: Colors.white),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 13, color: Colors.white, letterSpacing: -0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaasOutlinedButton extends StatefulWidget {
  const _SaasOutlinedButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  State<_SaasOutlinedButton> createState() => _SaasOutlinedButtonState();
}

class _SaasOutlinedButtonState extends State<_SaasOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s2 + 2),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _DS.textSecondary),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(fontSize: 13, color: _DS.textPrimary, letterSpacing: -0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaasGhostButton extends StatefulWidget {
  const _SaasGhostButton({
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  State<_SaasGhostButton> createState() => _SaasGhostButtonState();
}

class _SaasGhostButtonState extends State<_SaasGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s2 + 2),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontSize: 13, color: _hovered ? _DS.textPrimary : _DS.textSecondary, letterSpacing: -0.1),
          ),
        ),
      ),
    );
  }
}
