import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/companies_usecase.dart';
import 'package:portal_assoc/features/companies/models/business_address_model.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_step_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressStep extends StatefulWidget {
  final OnboardingSnapshot snapshot;
  final Future<void> Function() onSaved;

  const AddressStep({
    super.key,
    required this.snapshot,
    required this.onSaved,
  });

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _minTax = TextEditingController();
  final _kmPrice = TextEditingController();
  final _searchCtrl = TextEditingController();

  final _repo = CompaniesRepository();
  late final CompaniesController _controller = CompaniesController(StartState(), CompaniesUseCase(CompaniesRepository()));

  bool _saving = false;
  String? _serverError;

  final _layerLink = LayerLink();
  Timer? _debounce;
  OverlayEntry? _overlay;
  List<PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  String? _sessionToken;
  double? _pendingLat;
  double? _pendingLng;

  @override
  void initState() {
    super.initState();
    final a = widget.snapshot.address;
    final c = widget.snapshot.company;
    _street.text = a?.street ?? '';
    _number.text = a?.number ?? '';
    _complement.text = a?.complement ?? '';
    _neighborhood.text = a?.neighborhood ?? '';
    _city.text = a?.city ?? '';
    _state.text = a?.state ?? '';
    _zip.text = a?.zipCode ?? '';
    _minTax.text = c?.minTaxDelivery?.toStringAsFixed(2) ?? '';
    _kmPrice.text = c?.kilometerPrice?.toStringAsFixed(2) ?? '';
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();

    _controller.stateAddressAutocomplete.addListener(_onSuggestions);
    _controller.stateAddressDetails.addListener(_onDetails);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    _controller.stateAddressAutocomplete.removeListener(_onSuggestions);
    _controller.stateAddressDetails.removeListener(_onDetails);
    _street.dispose();
    _number.dispose();
    _complement.dispose();
    _neighborhood.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _minTax.dispose();
    _kmPrice.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Places autocomplete overlay ────────────────────────────────────────────

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.addressAutocomplete(v.trim(), sessionToken: _sessionToken);
    });
  }

  void _onSuggestions() {
    final s = _controller.stateAddressAutocomplete.value;
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
    final s = _controller.stateAddressDetails.value;
    if (!mounted || s is! SuccessState) return;
    final d = s.data as PlaceDetails;
    setState(() {
      _pendingLat = d.lat;
      _pendingLng = d.lng;
      if (d.street != null) _street.text = d.street!;
      if (d.number != null) _number.text = d.number!;
      if (d.neighborhood != null) _neighborhood.text = d.neighborhood!;
      if (d.city != null) _city.text = d.city!;
      if (d.state != null) _state.text = d.state!;
      if (d.zipCode != null) _zip.text = d.zipCode!;
      _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    });
    _removeOverlay();
  }

  void _selectSuggestion(PlaceSuggestion s) {
    _searchCtrl.text = s.description;
    _removeOverlay();
    _controller.addressDetails(s.placeId, sessionToken: _sessionToken);
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: _layerLink.leaderSize?.width ?? 480,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (_layerLink.leaderSize?.height ?? 48) + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(OnboardingDS.rLg),
            child: Container(
              decoration: BoxDecoration(
                color: OnboardingDS.canvas,
                borderRadius: BorderRadius.circular(OnboardingDS.rLg),
                border: Border.all(color: OnboardingDS.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    borderRadius: BorderRadius.circular(OnboardingDS.rLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: OnboardingDS.stone),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.mainText ?? s.description, style: const TextStyle(fontSize: 13, color: OnboardingDS.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (s.secondaryText != null) Text(s.secondaryText!, style: const TextStyle(fontSize: 11, color: OnboardingDS.stone), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    Overlay.of(context).insert(_overlay!);
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company') ?? 0;
      final base = widget.snapshot.address;
      final company = widget.snapshot.company;
      final lat = _pendingLat?.toString() ?? base?.latitude;
      final lng = _pendingLng?.toString() ?? base?.longitude;

      final updated = BusinessAddressModel.fromJson({
        'id': base?.id,
        'street': _street.text.trim(),
        'company_id': companyId,
        'number': _number.text.trim(),
        'complement': _complement.text.trim(),
        'neighborhood': _neighborhood.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'zip_code': _zip.text.trim(),
        'latitude': lat,
        'longitude': lng,
      });

      final addrResp = await _repo.updateBusiness(updated);
      if (!addrResp.success) {
        setState(() => _serverError = addrResp.message);
        return;
      }

      // Persiste config de entrega na company
      final minTax = double.tryParse(_minTax.text.trim().replaceAll(',', '.'));
      final kmPrice = double.tryParse(_kmPrice.text.trim().replaceAll(',', '.'));
      final updatedCompany = CompaniesModel.fromJson({
        'id': company?.id,
        'name': company?.name,
        'description': company?.description,
        'status': company?.status,
        'phone': company?.phone,
        'logo_url': company?.logoUrl,
        'brand_color': company?.brandColor,
        'banner_url': company?.bannerUrl,
        'ai_name': company?.aiName,
        'ai_gender': company?.aiGender,
        'ai_personality': company?.aiPersonality,
        'cuisine_type': company?.cuisineType,
        'dietary_restrictions': company?.dietaryRestrictions,
        'max_distance_meters_delivery': company?.maxDistanceMetersDelivery,
        'kilometer_price': kmPrice,
        'max_distance_meters_free_delivery': company?.maxDistanceMetersFreeDelivery,
        'min_price_order': company?.minPriceOrder,
        'min_tax_delivery': minTax,
      });
      final compResp = await _repo.update(updatedCompany);
      if (!compResp.success) {
        setState(() => _serverError = compResp.message);
        return;
      }

      await widget.onSaved();
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SetupStepContainer(
      stepIndex: 2,
      descriptor: kSetupSteps[2],
      headlinePrefix: 'Etapa',
      description: 'Onde a sua empresa fica e como funciona a entrega para os clientes.',
      footer: Row(
        children: [
          if (_serverError != null)
            Expanded(
              child: Text(_serverError!, style: const TextStyle(color: OnboardingDS.danger, fontSize: 12)),
            )
          else
            const Spacer(),
          OnboardingPrimaryButton(onPressed: _save, loading: _saving, isLast: false),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchField(),
            const SizedBox(height: 18),
            _AddressGrid(
              street: _street,
              number: _number,
              complement: _complement,
              neighborhood: _neighborhood,
              city: _city,
              state: _state,
              zip: _zip,
            ),
            const SizedBox(height: 22),
            _DeliveryConfigCard(
              minTaxCtrl: _minTax,
              kmPriceCtrl: _kmPrice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: OnboardingDS.canvas,
          borderRadius: BorderRadius.circular(OnboardingDS.rMd),
          border: Border.all(color: OnboardingDS.hairline),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(LucideIcons.search, size: 16, color: OnboardingDS.stone),
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: OnboardingDS.ink),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: OnboardingDS.canvas,
                  hintText: 'Buscar endereço (ex: Av. Paulista, 1000...)',
                  hintStyle: TextStyle(color: OnboardingDS.muted, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 14),
                ),
              ),
            ),
            if (_loadingSuggestions)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: OnboardingDS.brandBlue)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Address grid ────────────────────────────────────────────────────────────

class _AddressGrid extends StatelessWidget {
  final TextEditingController street;
  final TextEditingController number;
  final TextEditingController complement;
  final TextEditingController neighborhood;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController zip;

  const _AddressGrid({
    required this.street,
    required this.number,
    required this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zip,
  });

  String? Function(String?) _req(String f) => (v) => (v == null || v.trim().isEmpty) ? '$f é obrigatório' : null;

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? formatters,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      OnboardingFieldCard(
        child: TextFormField(
          controller: c,
          decoration: onboardingFieldDecoration(label, hint: hint),
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: formatters,
          textCapitalization: caps,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final twoCol = c.maxWidth >= 520;
      if (twoCol) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(flex: 3, child: _field(street, 'Logradouro', validator: _req('Logradouro'))),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _field(number, 'Número', keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(complement, 'Complemento', hint: 'Apto, Bloco...')),
                const SizedBox(width: 10),
                Expanded(child: _field(neighborhood, 'Bairro')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 2, child: _field(city, 'Cidade', validator: _req('Cidade'))),
                const SizedBox(width: 10),
                Expanded(flex: 1, child: _field(state, 'UF', caps: TextCapitalization.characters)),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: _field(zip, 'CEP', keyboardType: TextInputType.number, formatters: [MaskedInputFormatter('#####-###', allowedCharMatcher: RegExp(r'[0-9]'))], validator: _req('CEP'))),
              ],
            ),
          ],
        );
      }
      return Column(
        children: [
          _field(street, 'Logradouro', validator: _req('Logradouro')),
          const SizedBox(height: 10),
          _field(number, 'Número', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          _field(complement, 'Complemento', hint: 'Apto, Bloco...'),
          const SizedBox(height: 10),
          _field(neighborhood, 'Bairro'),
          const SizedBox(height: 10),
          _field(city, 'Cidade', validator: _req('Cidade')),
          const SizedBox(height: 10),
          _field(state, 'Estado (UF)', maxLength: 2, caps: TextCapitalization.characters),
          const SizedBox(height: 10),
          _field(zip, 'CEP', keyboardType: TextInputType.number, formatters: [MaskedInputFormatter('#####-###', allowedCharMatcher: RegExp(r'[0-9]'))], validator: _req('CEP')),
        ],
      );
    });
  }
}

// ─── Delivery config ─────────────────────────────────────────────────────────

class _DeliveryConfigCard extends StatelessWidget {
  final TextEditingController minTaxCtrl;
  final TextEditingController kmPriceCtrl;

  const _DeliveryConfigCard({
    required this.minTaxCtrl,
    required this.kmPriceCtrl,
  });

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    if (parsed == null || parsed < 0) return 'Valor inválido';
    return null;
  }

  String? _validateOneRequired(String? v, String? otherText) {
    final hasThis = v != null && v.trim().isNotEmpty;
    final hasOther = otherText != null && otherText.trim().isNotEmpty;
    if (!hasThis && !hasOther) {
      return 'Informe ao menos uma das taxas de entrega';
    }
    return _validate(v);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingDS.surface,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(color: OnboardingDS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.truck, size: 16, color: OnboardingDS.stone),
              SizedBox(width: 8),
              Text(
                'Configurações de entrega',
                style: TextStyle(
                  fontSize: 14,
                  color: OnboardingDS.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Informe pelo menos uma forma de cobrança. Pode ajustar depois.',
            style: TextStyle(fontSize: 12, color: OnboardingDS.stone),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (_, c) {
            final twoCol = c.maxWidth >= 460;
            final taxField = OnboardingFieldCard(
              child: TextFormField(
                controller: minTaxCtrl,
                decoration: onboardingFieldDecoration('Taxa mínima (R\$)', hint: 'Ex: 5,00', icon: LucideIcons.receipt),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                validator: (v) => _validateOneRequired(v, kmPriceCtrl.text),
                style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
              ),
            );
            final kmField = OnboardingFieldCard(
              child: TextFormField(
                controller: kmPriceCtrl,
                decoration: onboardingFieldDecoration('Preço por quilômetro (R\$)', hint: 'Ex: 2,50', icon: LucideIcons.gauge),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                validator: (v) => _validateOneRequired(v, minTaxCtrl.text),
                style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
              ),
            );
            if (twoCol) {
              return Row(
                children: [
                  Expanded(child: taxField),
                  const SizedBox(width: 10),
                  Expanded(child: kmField),
                ],
              );
            }
            return Column(
              children: [
                taxField,
                const SizedBox(height: 10),
                kmField,
              ],
            );
          }),
        ],
      ),
    );
  }
}
