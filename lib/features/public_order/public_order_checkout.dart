part of 'public_order_page.dart';

// ─── Private Places models ────────────────────────────────────────────────────
class _PubPlaceSuggestion {
  final String placeId, description;
  final String? mainText, secondaryText;
  const _PubPlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });
  factory _PubPlaceSuggestion.fromJson(Map<String, dynamic> j) => _PubPlaceSuggestion(
        placeId: (j['placeId'] ?? j['place_id'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        mainText: j['mainText'] as String?,
        secondaryText: j['secondaryText'] as String?,
      );
}

class _PubPlaceDetails {
  final String placeId;
  final String? formattedAddress, street, number, neighborhood, city, state, zipCode;
  final double? lat, lng;
  const _PubPlaceDetails({
    required this.placeId,
    this.formattedAddress,
    this.street,
    this.number,
    this.neighborhood,
    this.city,
    this.state,
    this.zipCode,
    this.lat,
    this.lng,
  });
  factory _PubPlaceDetails.fromJson(Map<String, dynamic> j) {
    double? toD(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return _PubPlaceDetails(
      placeId: (j['placeId'] ?? '') as String,
      formattedAddress: j['formattedAddress'] as String?,
      street: j['street'] as String?,
      number: j['number'] as String?,
      neighborhood: j['neighborhood'] as String?,
      city: j['city'] as String?,
      state: j['state'] as String?,
      zipCode: j['zipCode'] as String?,
      lat: toD(j['lat']),
      lng: toD(j['lng']),
    );
  }
}

// ─── Identify screen ──────────────────────────────────────────────────────────
class _IdentifyScreen extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final Color brandColor;
  final VoidCallback onBack;
  final Future<String?> Function(String name, String phone) onSave;
  const _IdentifyScreen({
    this.initialName,
    this.initialPhone,
    required this.brandColor,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<_IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<_IdentifyScreen> {
  // Máscara de telefone: (27) 9 9999-9999. A API recebe apenas os dígitos.
  final _phoneMask = MaskedInputFormatter('(##) # ####-####', allowedCharMatcher: RegExp(r'[0-9]'));
  late final _nameCtrl = TextEditingController(text: widget.initialName ?? '');
  late final _phoneCtrl = TextEditingController(
    text: _phoneMask
        .formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: widget.initialPhone ?? ''),
        )
        .text,
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    // Envia somente os dígitos do telefone para a API.
    final phone = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (name.isEmpty) {
      setState(() => _error = 'Informe seu nome.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.onSave(name, phone);
    if (mounted) {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brandColor;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineBackArrow(onBack: widget.onBack),
                const SizedBox(height: 4),
                const _PubLabel('Nome *'),
                const SizedBox(height: 6),
                _PubField(controller: _nameCtrl, hint: 'João da Silva', focusColor: brand),
                const SizedBox(height: 12),
                const _PubLabel('Telefone / WhatsApp'),
                const SizedBox(height: 6),
                _PubField(controller: _phoneCtrl, hint: '(27) 9 9999-9999', inputType: TextInputType.phone, focusColor: brand, inputFormatters: [_phoneMask]),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: _DS.danger, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: brand,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continuar',
                            style: TextStyle(
                              fontSize: 16,
                            )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Address screen ───────────────────────────────────────────────────────────
class _AddressScreen extends StatefulWidget {
  final PublicClientModel customer;
  final Color brandColor;
  final VoidCallback onBack;
  final Future<String?> Function(Map<String, dynamic> data) onSave;
  const _AddressScreen({
    required this.customer,
    required this.brandColor,
    required this.onBack,
    required this.onSave,
  });

  @override
  State<_AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<_AddressScreen> {
  final _http = PublicHttpService();
  final _searchCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _layerLink = LayerLink();
  final _searchFocus = FocusNode();

  List<_PubPlaceSuggestion> _suggestions = [];
  _PubPlaceDetails? _selectedPlace;
  bool _loadingSuggestions = false;
  bool _saving = false;
  String? _error;
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  String _sessionToken = '';

  @override
  void initState() {
    super.initState();
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    if (widget.customer.hasAddress) {
      _numberCtrl.text = widget.customer.number ?? '';
      _notesCtrl.text = widget.customer.complement ?? '';
    }
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _searchCtrl.dispose();
    _numberCtrl.dispose();
    _notesCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: _layerLink.leaderSize?.width ?? 360,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (_layerLink.leaderSize?.height ?? 46) + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.canvas,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _DS.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: _DS.stone),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.mainText ?? s.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _DS.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.secondaryText != null)
                                  Text(
                                    s.secondaryText!,
                                    style: const TextStyle(fontSize: 11, color: _DS.stone),
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() => _suggestions = []);
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    final res = await _http.get('address/autocomplete?input=${Uri.encodeComponent(input)}&sessionToken=$_sessionToken');
    if (!mounted) return;
    setState(() => _loadingSuggestions = false);
    if (res.success && res.data is List) {
      _suggestions = (res.data as List).map((e) => _PubPlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _suggestions = [];
    }
    _showOverlay();
  }

  Future<void> _selectSuggestion(_PubPlaceSuggestion s) async {
    _removeOverlay();
    _searchCtrl.text = s.description;
    FocusScope.of(context).unfocus();
    setState(() => _loadingSuggestions = true);
    final res = await _http.get('address/details/${s.placeId}?sessionToken=$_sessionToken');
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    if (!mounted) return;
    setState(() => _loadingSuggestions = false);
    if (res.success && res.data is Map) {
      final details = _PubPlaceDetails.fromJson(res.data as Map<String, dynamic>);
      setState(() {
        _selectedPlace = details;
        _suggestions = [];
        if (_numberCtrl.text.isEmpty && (details.number ?? '').isNotEmpty) {
          _numberCtrl.text = details.number!;
        }
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedPlace = null;
      _suggestions = [];
      _searchCtrl.clear();
    });
    _removeOverlay();
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  Future<void> _submit() async {
    final place = _selectedPlace;
    if (place == null && !widget.customer.hasAddress) {
      setState(() => _error = 'Busque e selecione um endereço para continuar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final Map<String, dynamic> data;
    if (place != null) {
      data = {
        'zip_code': place.zipCode,
        'street': place.street,
        'number': _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
        'complement': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'neighborhood': place.neighborhood,
        'city': place.city,
        'state': place.state,
        'lat': place.lat,
        'lng': place.lng,
      };
    } else {
      data = {
        'zip_code': widget.customer.zipCode,
        'street': widget.customer.street,
        'number': _numberCtrl.text.trim().isEmpty ? widget.customer.number : _numberCtrl.text.trim(),
        'complement': _notesCtrl.text.trim().isEmpty ? widget.customer.complement : _notesCtrl.text.trim(),
        'neighborhood': widget.customer.neighborhood,
        'city': widget.customer.city,
        'state': widget.customer.state,
        'lat': widget.customer.lat,
        'lng': widget.customer.lng,
      };
    }
    final err = await widget.onSave(data);
    if (mounted) {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brandColor;
    final hasSelection = _selectedPlace != null;
    final hasExisting = widget.customer.hasAddress;
    final showConfirm = hasSelection || hasExisting;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineBackArrow(onBack: widget.onBack),
                const SizedBox(height: 4),
                // ── Search field ──────────────────────────────────────
                if (!hasSelection) ...[
                  const _PubLabel('Buscar endereço'),
                  const SizedBox(height: 6),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(fontSize: 14, color: _DS.ink),
                      decoration: InputDecoration(
                        hintText: 'Digite rua, bairro ou cidade...',
                        hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                        prefixIcon: _loadingSuggestions
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _DS.stone),
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 18, color: _DS.stone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: brand, width: 2)),
                        filled: true,
                        fillColor: _DS.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  // Tip
                  if (!hasExisting) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Digite pelo menos 3 caracteres para buscar.',
                      style: TextStyle(fontSize: 11, color: _DS.stone),
                    ),
                  ],
                ],

                const SizedBox(height: 12),

                // ── Selected / existing address card ──────────────────
                if (showConfirm) ...[
                  _AddressConfirmCard(
                    place: _selectedPlace,
                    customer: widget.customer,
                    brandColor: brand,
                    onClear: _clearSelection,
                  ),
                  const SizedBox(height: 12),

                  // ── Map ───────────────────────────────────────────────
                  if (_selectedPlace?.lat != null && _selectedPlace?.lng != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(_DS.rXl),
                      child: GoogleMapWidget(
                        lat: _selectedPlace!.lat!,
                        lng: _selectedPlace!.lng!,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Number ────────────────────────────────────────────
                  const _PubLabel('Número'),
                  const SizedBox(height: 6),
                  _PubField(
                    controller: _numberCtrl,
                    hint: '123',
                    inputType: TextInputType.streetAddress,
                    focusColor: brand,
                  ),
                  const SizedBox(height: 12),

                  // ── Observation ───────────────────────────────────────
                  const _PubLabel('Complemento / Observação'),
                  const SizedBox(height: 6),
                  _PubField(
                    controller: _notesCtrl,
                    hint: 'Apto 42, portão verde, próximo ao mercado...',
                    maxLines: 2,
                    focusColor: brand,
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: _DS.danger, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_saving || !showConfirm) ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: brand,
                      disabledBackgroundColor: brand.withValues(alpha: 0.4),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continuar',
                            style: TextStyle(
                              fontSize: 16,
                            )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Address confirmation card ────────────────────────────────────────────────
class _AddressConfirmCard extends StatelessWidget {
  final _PubPlaceDetails? place;
  final PublicClientModel customer;
  final Color brandColor;
  final VoidCallback onClear;
  const _AddressConfirmCard({
    required this.place,
    required this.customer,
    required this.brandColor,
    required this.onClear,
  });

  String get _addressLine {
    if (place != null) {
      final parts = <String>[];
      if ((place!.street ?? '').isNotEmpty) parts.add(place!.street!);
      if ((place!.neighborhood ?? '').isNotEmpty) {
        parts.add(place!.neighborhood!);
      }
      final cs = [place!.city, place!.state].where((s) => s != null && s.isNotEmpty).cast<String>().join(', ');
      if (cs.isNotEmpty) parts.add(cs);
      return parts.join(' — ');
    }
    return customer.toAddressString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on_rounded, size: 18, color: brandColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _addressLine,
              style: const TextStyle(fontSize: 13, color: _DS.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _DS.hairline),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 12, color: _DS.slate),
                  SizedBox(width: 4),
                  Text('Trocar', style: TextStyle(fontSize: 11, color: _DS.slate)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checkout screen ──────────────────────────────────────────────────────────
class _CheckoutScreen extends StatelessWidget {
  final List<_PubCartItem> cart;
  final PublicClientModel customer;
  final PublicCompanyModel company;
  final String? companyDescription;
  final int? avgPrepMinutes;
  final List<PublicPaymentMethodModel> paymentMethods;
  final int? selectedPaymentMethodId;
  final void Function(int) onSelectPaymentMethod;
  final Color brandColor;
  final bool isOpen;
  final List<PublicOpeningHourModel> openingHours;
  final bool useScheduling;
  final DateTime? scheduledFor;
  final void Function(bool) onScheduleToggle;
  final void Function(DateTime) onScheduleChange;
  final VoidCallback onBack;
  final VoidCallback onEditCustomer;
  final VoidCallback onEditAddress;
  final Future<void> Function() onConfirm;
  final bool placing;
  final double deliveryFee;
  final String? deliveryDistanceLabel;
  final String? deliveryDurationText;
  final bool isFreeDelivery;
  final bool loadingDeliveryFee;
  final String? deliveryRuleError;
  final VoidCallback onRetryDeliveryFee;
  final double? minOrderValue;
  final String? error;
  final PurchaseGoalSuggestionModel? goalSuggestion;
  final bool loadingGoalSuggestion;
  final Future<void> Function() onAddGoalSuggestion;
  final Future<void> Function() onOpenGoalSuggestion;
  final _DeliveryType deliveryType;
  final ValueChanged<_DeliveryType> onDeliveryTypeChange;
  final PublicCompanyAddressModel? companyAddress;
  const _CheckoutScreen({
    required this.cart,
    required this.customer,
    required this.company,
    required this.companyDescription,
    required this.avgPrepMinutes,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onSelectPaymentMethod,
    required this.brandColor,
    required this.isOpen,
    required this.openingHours,
    required this.useScheduling,
    required this.scheduledFor,
    required this.onScheduleToggle,
    required this.onScheduleChange,
    required this.onBack,
    required this.onEditCustomer,
    required this.onEditAddress,
    required this.onConfirm,
    required this.placing,
    required this.deliveryFee,
    required this.deliveryDistanceLabel,
    required this.deliveryDurationText,
    required this.isFreeDelivery,
    required this.loadingDeliveryFee,
    required this.deliveryRuleError,
    required this.onRetryDeliveryFee,
    required this.minOrderValue,
    this.error,
    required this.goalSuggestion,
    required this.loadingGoalSuggestion,
    required this.onAddGoalSuggestion,
    required this.onOpenGoalSuggestion,
    required this.deliveryType,
    required this.onDeliveryTypeChange,
    required this.companyAddress,
  });

  bool get _isPickup => deliveryType == _DeliveryType.pickup;
  double get _subtotal => cart.fold(0, (s, c) => s + c.subtotal);
  double get _total => _subtotal + (_isPickup ? 0 : deliveryFee);

  @override
  Widget build(BuildContext context) {
    final brand = brandColor;
    final activeMethods = <PublicPaymentMethodModel>[];
    final seenMethodIds = <int>{};
    for (final method in paymentMethods) {
      final id = method.id;
      if (id == null || method.active != true) continue;
      if (seenMethodIds.add(id)) {
        activeMethods.add(method);
      }
    }
    final selectedMethod =
        activeMethods.where((m) => m.id == selectedPaymentMethodId).cast<PublicPaymentMethodModel?>().isNotEmpty ? activeMethods.firstWhere((m) => m.id == selectedPaymentMethodId) : null;
    final minOrderBlocked = minOrderValue != null && _subtotal < minOrderValue!;
    final canFinish =
        !placing && !loadingDeliveryFee && !minOrderBlocked && deliveryRuleError == null && activeMethods.isNotEmpty && selectedPaymentMethodId != null && (isOpen || scheduledFor != null);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InlineBackArrow(onBack: onBack),
                const SizedBox(height: 4),
                // ── Company header (compacto, premium) ────────────────────
                _CheckoutCompanyHeader(
                  companyName: company.name ?? '',
                  logoUrl: company.logoUrl,
                  description: companyDescription,
                  avgPrepMinutes: avgPrepMinutes,
                  brandColor: brand,
                ),
                const SizedBox(height: 16),

                // ── Cliente (compacto, somente nome) ──────────────────────
                _CompactCustomerCard(
                  name: (customer.name ?? '').trim(),
                  brandColor: brand,
                  onEdit: onEditCustomer,
                ),
                const SizedBox(height: 10),

                // ── Seletor Entrega / Retirada (sincronizado com o carrinho) ──
                _DeliveryTypeSelector(
                  current: deliveryType,
                  brandColor: brand,
                  onChange: onDeliveryTypeChange,
                  allowDelivery: company.acceptsDelivery,
                  allowPickup: company.acceptsPickup,
                ),
                const SizedBox(height: 10),

                // ── Endereço de entrega / card de retirada ────────────────
                if (_isPickup)
                  _PickupInfoCard(
                    address: companyAddress,
                    companyName: company.name ?? '',
                    brandColor: brand,
                    avgPrepMinutes: avgPrepMinutes,
                  )
                else
                  _CompactDeliveryAddressCard(
                    customer: customer,
                    brandColor: brand,
                    loading: loadingDeliveryFee,
                    distanceLabel: deliveryDistanceLabel,
                    durationText: deliveryDurationText,
                    isFree: isFreeDelivery,
                    ruleError: deliveryRuleError,
                    deliveryFee: deliveryFee,
                    onEdit: onEditAddress,
                    onRetry: onRetryDeliveryFee,
                  ),
                const SizedBox(height: 10),

                // ── Forma de pagamento (container único clicável) ─────────
                _PaymentMethodSelectorCard(
                  selected: selectedMethod,
                  hasMethods: activeMethods.isNotEmpty,
                  brandColor: brand,
                  onTap: activeMethods.isEmpty ? null : () => _showPaymentPicker(context, activeMethods),
                ),

                // ── Agendamento — só quando fechado ───────────────────────
                if (!isOpen) ...[
                  const SizedBox(height: 10),
                  _ScheduleSection(
                    isOpen: isOpen,
                    openingHours: openingHours,
                    useScheduling: useScheduling,
                    scheduledFor: scheduledFor,
                    brandColor: brand,
                    onToggle: onScheduleToggle,
                    onChange: onScheduleChange,
                  ),
                ],

                const SizedBox(height: 16),

                // ── Resumo do pedido ──────────────────────────────────────
                _OrderSummaryCard(
                  cart: cart,
                  subtotal: _subtotal,
                  deliveryFee: _isPickup ? 0 : deliveryFee,
                  total: _total,
                  loadingDeliveryFee: _isPickup ? false : loadingDeliveryFee,
                  isFreeDelivery: _isPickup ? true : isFreeDelivery,
                  isPickup: _isPickup,
                  minOrderBlocked: minOrderBlocked,
                  minOrderValue: minOrderValue,
                  brandColor: brand,
                  goalSuggestion: goalSuggestion,
                  loadingGoalSuggestion: loadingGoalSuggestion,
                  onAddGoalSuggestion: onAddGoalSuggestion,
                  onOpenGoalSuggestion: onOpenGoalSuggestion,
                ),

                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEA),
                      borderRadius: BorderRadius.circular(_DS.rLg),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, size: 16, color: _DS.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!, style: const TextStyle(color: _DS.danger, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                _FinishOrderButton(
                  enabled: canFinish,
                  placing: placing,
                  total: _total,
                  brandColor: brand,
                  onTap: () {
                    if (selectedPaymentMethodId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione uma forma de pagamento para continuar.'),
                        ),
                      );
                      return;
                    }
                    onConfirm();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPaymentPicker(
    BuildContext context,
    List<PublicPaymentMethodModel> methods,
  ) {
    final activeOnly = <PublicPaymentMethodModel>[];
    final seenMethodIds = <int>{};
    for (final method in methods) {
      final id = method.id;
      if (id == null || method.active != true) continue;
      if (seenMethodIds.add(id)) {
        activeOnly.add(method);
      }
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.38,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _DS.hairline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Forma de pagamento',
                style: TextStyle(
                  fontSize: 17,
                  color: _DS.ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Selecione como você prefere pagar',
                style: TextStyle(fontSize: 12.5, color: _DS.steel),
              ),
              const SizedBox(height: 14),
              if (activeOnly.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma forma de pagamento ativa disponível.',
                    style: TextStyle(fontSize: 12, color: _DS.stone),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeOnly.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = activeOnly[i];
                      final isSel = selectedPaymentMethodId == m.id;
                      return _PaymentMethodRow(
                        method: m,
                        selected: isSel,
                        brandColor: brandColor,
                        onTap: () {
                          if (m.id != null) {
                            onSelectPaymentMethod(m.id!);
                          }
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header premium da empresa (compacto) ────────────────────────────────────
class _CheckoutCompanyHeader extends StatelessWidget {
  final String companyName;
  final String? logoUrl;
  final String? description;
  final int? avgPrepMinutes;
  final Color brandColor;
  const _CheckoutCompanyHeader({
    required this.companyName,
    required this.logoUrl,
    required this.description,
    required this.avgPrepMinutes,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final desc = (description ?? '').trim();
    final hasDesc = desc.isNotEmpty;
    final hasPrep = avgPrepMinutes != null && avgPrepMinutes! > 0;
    final initial = companyName.isEmpty ? '?' : companyName.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: brandColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _DS.canvas,
              border: Border.all(color: _DS.hairlineSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: (logoUrl ?? '').isNotEmpty
                ? CachedNetworkImage(
                    width: 42,
                    height: 42,
                    imageUrl: logoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: brandColor.withValues(alpha: 0.10)),
                    errorWidget: (_, __, ___) => _LogoInitialFallback(initial: initial, brandColor: brandColor),
                  )
                : _LogoInitialFallback(initial: initial, brandColor: brandColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: _DS.ink,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                if (hasDesc) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _DS.steel,
                      height: 1.2,
                    ),
                  ),
                ],
                if (hasPrep) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: brandColor),
                      const SizedBox(width: 4),
                      Text(
                        'Pronto em ~$avgPrepMinutes min',
                        style: TextStyle(
                          fontSize: 11,
                          color: brandColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
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
}

class _LogoInitialFallback extends StatelessWidget {
  final String initial;
  final Color brandColor;
  const _LogoInitialFallback({required this.initial, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: brandColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 16,
          color: brandColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Cliente compacto (somente nome) ─────────────────────────────────────────
class _CompactCustomerCard extends StatelessWidget {
  final String name;
  final Color brandColor;
  final VoidCallback onEdit;
  const _CompactCustomerCard({
    required this.name,
    required this.brandColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutShell(
      onTap: onEdit,
      child: Row(
        children: [
          _SectionIcon(icon: Icons.person_rounded, color: brandColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 11,
                    color: _DS.stone,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? 'Adicionar nome' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _DS.ink,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          _EditChevron(brandColor: brandColor),
        ],
      ),
    );
  }
}

// ─── Endereço de entrega compacto ────────────────────────────────────────────
class _CompactDeliveryAddressCard extends StatelessWidget {
  final PublicClientModel customer;
  final Color brandColor;
  final bool loading;
  final String? distanceLabel;
  final String? durationText;
  final bool isFree;
  final String? ruleError;
  final double deliveryFee;
  final VoidCallback onEdit;
  final VoidCallback onRetry;
  const _CompactDeliveryAddressCard({
    required this.customer,
    required this.brandColor,
    required this.loading,
    required this.distanceLabel,
    required this.durationText,
    required this.isFree,
    required this.ruleError,
    required this.deliveryFee,
    required this.onEdit,
    required this.onRetry,
  });

  String _shortAddress() {
    if (!customer.hasAddress) return 'Sem endereço cadastrado';
    final parts = <String>[];
    var line = (customer.street ?? '').trim();
    if ((customer.number ?? '').trim().isNotEmpty) line += ', ${customer.number!.trim()}';
    if (line.isNotEmpty) parts.add(line);
    if ((customer.neighborhood ?? '').trim().isNotEmpty) parts.add(customer.neighborhood!.trim());
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = ruleError != null;
    final isOutOfRange = hasError && ruleError!.toLowerCase().contains('área');
    return _CheckoutShell(
      borderColor: hasError ? const Color(0xFFFFCDD2) : null,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionIcon(icon: Icons.location_on_rounded, color: brandColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entregar em',
                      style: TextStyle(
                        fontSize: 11,
                        color: _DS.stone,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shortAddress(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DS.ink,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              _EditChevron(brandColor: brandColor),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _DeliveryErrorRow(
                      message: ruleError!,
                      isOutOfRange: isOutOfRange,
                      onRetry: onRetry,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _DeliveryMetaRow(
                      loading: loading,
                      distanceLabel: distanceLabel,
                      durationText: durationText,
                      deliveryFee: deliveryFee,
                      isFree: isFree,
                      brandColor: brandColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryMetaRow extends StatelessWidget {
  final bool loading;
  final String? distanceLabel;
  final String? durationText;
  final double deliveryFee;
  final bool isFree;
  final Color brandColor;
  const _DeliveryMetaRow({
    required this.loading,
    required this.distanceLabel,
    required this.durationText,
    required this.deliveryFee,
    required this.isFree,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _MetaSkeletonRow();
    }
    final chips = <Widget>[];
    if ((distanceLabel ?? '').isNotEmpty) {
      chips.add(_MetaChip(icon: Icons.straighten_rounded, label: distanceLabel!));
    }
    if ((durationText ?? '').isNotEmpty) {
      chips.add(_MetaChip(icon: Icons.schedule_rounded, label: durationText!));
    }
    final feeWidget = isFree
        ? const _FeePill(
            label: 'Frete grátis',
            bg: Color(0xFFE9FBF3),
            fg: _DS.successAccent,
          )
        : _FeePill(
            label: deliveryFee > 0 ? _currFmt.format(deliveryFee) : 'A combinar',
            bg: brandColor.withValues(alpha: 0.10),
            fg: brandColor,
          );

    return Row(
      children: [
        Expanded(
          child: chips.isEmpty
              ? const Text(
                  'Calculando entrega...',
                  style: TextStyle(fontSize: 11.5, color: _DS.stone),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: chips,
                ),
        ),
        const SizedBox(width: 8),
        feeWidget,
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.5, color: _DS.stone),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: _DS.steel,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

class _FeePill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _FeePill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _MetaSkeletonRow extends StatefulWidget {
  const _MetaSkeletonRow();
  @override
  State<_MetaSkeletonRow> createState() => _MetaSkeletonRowState();
}

class _MetaSkeletonRowState extends State<_MetaSkeletonRow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final o = 0.45 + 0.35 * _ctrl.value;
        return Row(
          children: [
            Opacity(
              opacity: o,
              child: Container(
                width: 90,
                height: 11,
                decoration: BoxDecoration(
                  color: _DS.hairlineSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const Spacer(),
            Opacity(
              opacity: o,
              child: Container(
                width: 70,
                height: 22,
                decoration: BoxDecoration(
                  color: _DS.hairlineSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Forma de pagamento (container único clicável) ───────────────────────────
class _PaymentMethodSelectorCard extends StatelessWidget {
  final PublicPaymentMethodModel? selected;
  final bool hasMethods;
  final Color brandColor;
  final VoidCallback? onTap;
  const _PaymentMethodSelectorCard({
    required this.selected,
    required this.hasMethods,
    required this.brandColor,
    required this.onTap,
  });

  IconData get _icon {
    if (selected == null) return Icons.payments_rounded;
    final label = (selected!.label ?? '').toLowerCase();
    if (label.contains('pix')) return Icons.qr_code_2_rounded;
    if (label.contains('cart') || label.contains('crédito') || label.contains('debito') || label.contains('débito')) {
      return Icons.credit_card_rounded;
    }
    if (label.contains('dinheiro') || label.contains('cash')) return Icons.payments_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = !hasMethods;
    final hasSelection = selected != null;
    final primaryText = isEmpty ? 'Nenhuma forma disponível' : (hasSelection ? (selected!.label ?? 'Método selecionado') : 'Selecionar forma de pagamento');
    final secondaryText = isEmpty
        ? 'Tente novamente em instantes'
        : (hasSelection ? ((selected!.description ?? '').trim().isEmpty ? 'Toque para trocar' : selected!.description!.trim()) : 'Toque para escolher como pagar');
    final primaryColor = isEmpty ? _DS.danger : _DS.ink;

    return _CheckoutShell(
      onTap: onTap,
      borderColor: isEmpty ? const Color(0xFFFFCDD2) : null,
      child: Row(
        children: [
          _SectionIcon(
            icon: _icon,
            color: hasSelection ? brandColor : _DS.steel,
            tintBackground: hasSelection,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forma de pagamento',
                  style: TextStyle(
                    fontSize: 11,
                    color: _DS.stone,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  primaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _DS.stone,
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 14, color: brandColor),
            )
          else
            const Icon(Icons.chevron_right_rounded, size: 22, color: _DS.muted),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final PublicPaymentMethodModel method;
  final bool selected;
  final Color brandColor;
  final VoidCallback onTap;
  const _PaymentMethodRow({
    required this.method,
    required this.selected,
    required this.brandColor,
    required this.onTap,
  });

  IconData get _icon {
    final label = (method.label ?? '').toLowerCase();
    if (label.contains('pix')) return Icons.qr_code_2_rounded;
    if (label.contains('cart')) return Icons.credit_card_rounded;
    if (label.contains('dinheiro')) return Icons.payments_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brandColor.withValues(alpha: 0.08) : _DS.canvas,
      borderRadius: BorderRadius.circular(_DS.rLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(_DS.rLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(
              color: selected ? brandColor.withValues(alpha: 0.45) : _DS.hairlineSoft,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (selected ? brandColor : _DS.steel).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, size: 18, color: selected ? brandColor : _DS.steel),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label ?? 'Método',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DS.ink,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if ((method.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        method.description!.trim(),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _DS.stone,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? brandColor : _DS.hairline,
                    width: 2,
                  ),
                  color: selected ? brandColor : Colors.transparent,
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shell base de cards do checkout (padding + bordas + hover/touch) ────────
class _CheckoutShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  const _CheckoutShell({
    required this.child,
    this.onTap,
    this.borderColor,
  });

  @override
  State<_CheckoutShell> createState() => _CheckoutShellState();
}

class _CheckoutShellState extends State<_CheckoutShell> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pressable = widget.onTap != null;
    return MouseRegion(
      cursor: pressable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hover = pressable && true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: pressable ? (_) => setState(() => _down = true) : null,
        onTapCancel: pressable ? () => setState(() => _down = false) : null,
        onTapUp: pressable ? (_) => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.992 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rXl),
              border: Border.all(
                color: widget.borderColor ?? (_hover ? _DS.hairline : _DS.hairlineSoft),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool tintBackground;
  const _SectionIcon({
    required this.icon,
    required this.color,
    this.tintBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tintBackground ? color.withValues(alpha: 0.10) : _DS.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _EditChevron extends StatelessWidget {
  final Color brandColor;
  const _EditChevron({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 11, color: brandColor),
          const SizedBox(width: 4),
          Text(
            'Editar',
            style: TextStyle(
              fontSize: 11,
              color: brandColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botão Finalizar (com microanimação) ─────────────────────────────────────
class _FinishOrderButton extends StatefulWidget {
  final bool enabled;
  final bool placing;
  final double total;
  final Color brandColor;
  final VoidCallback onTap;
  const _FinishOrderButton({
    required this.enabled,
    required this.placing,
    required this.total,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_FinishOrderButton> createState() => _FinishOrderButtonState();
}

class _FinishOrderButtonState extends State<_FinishOrderButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.placing;
    final brand = widget.brandColor;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brand,
                      Color.lerp(brand, Colors.black, 0.14) ?? brand,
                    ],
                  ),
            color: disabled ? _DS.hairlineSoft : null,
            borderRadius: BorderRadius.circular(99),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: brand.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.placing
              ? const SizedBox(
                  height: 22,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        disabled ? 'Verifique os dados' : 'Finalizar pedido',
                        style: TextStyle(
                          fontSize: 15,
                          color: disabled ? _DS.muted : Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currFmt.format(widget.total),
                      style: TextStyle(
                        fontSize: 14,
                        color: disabled ? _DS.muted : Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── (legado) Premium delivery info card — mantido para reuso futuro ─────────
// ignore: unused_element
class _DeliveryInfoCard extends StatelessWidget {
  final PublicClientModel customer;
  final Color brandColor;
  final bool loading;
  final String? distanceLabel;
  final String? durationText;
  final bool isFree;
  final String? ruleError;
  final double deliveryFee;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  const _DeliveryInfoCard({
    required this.customer,
    required this.brandColor,
    required this.loading,
    required this.distanceLabel,
    required this.durationText,
    required this.isFree,
    required this.ruleError,
    required this.deliveryFee,
    required this.onEdit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = distanceLabel != null || durationText != null;
    final isOutOfRange = ruleError != null && ruleError!.toLowerCase().contains('área');

    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(
          color: (ruleError != null) ? const Color(0xFFFFCDD2) : _DS.hairlineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              Icon(Icons.local_shipping_outlined, size: 14, color: brandColor),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Endereço de entrega',
                  style: TextStyle(
                    fontSize: 12,
                    color: _DS.slate,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_outlined, size: 11, color: brandColor),
                    const SizedBox(width: 4),
                    Text('Editar', style: TextStyle(fontSize: 11, color: brandColor)),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Address ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              customer.hasAddress ? customer.toAddressString() : 'Sem endereço cadastrado',
              style: const TextStyle(fontSize: 13, color: _DS.steel),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Divider(height: 1, color: _DS.hairlineSoft),
          ),

          // ── Estimate section ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: loading
                  ? const _DeliveryLoadingSkeleton()
                  : ruleError != null
                      ? _DeliveryErrorRow(
                          message: ruleError!,
                          isOutOfRange: isOutOfRange,
                          onRetry: onRetry,
                        )
                      : _DeliveryEstimateRow(
                          distanceLabel: distanceLabel,
                          durationText: durationText,
                          deliveryFee: deliveryFee,
                          isFree: isFree,
                          hasCoords: hasCoords,
                          brandColor: brandColor,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryLoadingSkeleton extends StatefulWidget {
  const _DeliveryLoadingSkeleton();

  @override
  State<_DeliveryLoadingSkeleton> createState() => _DeliveryLoadingSkeletonState();
}

class _DeliveryLoadingSkeletonState extends State<_DeliveryLoadingSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + 0.4 * _anim.value;
        return Row(children: [
          const Icon(Icons.calculate_outlined, size: 14, color: _DS.stone),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: opacity,
                  child: Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: _DS.hairlineSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Opacity(
                  opacity: opacity,
                  child: Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: _DS.hairlineSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: opacity,
            child: Container(
              height: 22,
              width: 60,
              decoration: BoxDecoration(
                color: _DS.hairlineSoft,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _DeliveryEstimateRow extends StatelessWidget {
  final String? distanceLabel;
  final String? durationText;
  final double deliveryFee;
  final bool isFree;
  final bool hasCoords;
  final Color brandColor;

  const _DeliveryEstimateRow({
    required this.distanceLabel,
    required this.durationText,
    required this.deliveryFee,
    required this.isFree,
    required this.hasCoords,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chips row (distance + ETA)
              if (hasCoords)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (distanceLabel != null)
                      _EstimateChip(
                        icon: Icons.near_me_outlined,
                        label: distanceLabel!,
                      ),
                    if (durationText != null)
                      _EstimateChip(
                        icon: Icons.schedule_rounded,
                        label: durationText!,
                      ),
                  ],
                )
              else
                const Text(
                  'Taxa calculada conforme configuração',
                  style: TextStyle(fontSize: 11, color: _DS.stone),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Fee badge
        if (isFree)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'GRÁTIS',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF065F46),
                letterSpacing: 0.5,
              ),
            ),
          )
        else
          Text(
            _currFmt.format(deliveryFee),
            style: const TextStyle(
              fontSize: 14,
              color: _DS.ink,
            ),
          ),
      ],
    );
  }
}

class _EstimateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EstimateChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: _DS.stone),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _DS.slate)),
      ]),
    );
  }
}

class _DeliveryErrorRow extends StatelessWidget {
  final String message;
  final bool isOutOfRange;
  final VoidCallback onRetry;
  const _DeliveryErrorRow({
    required this.message,
    required this.isOutOfRange,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isOutOfRange ? const Color(0xFFFFEBEA) : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isOutOfRange ? Icons.gps_off : Icons.warning_amber_rounded,
            size: 16,
            color: isOutOfRange ? _DS.danger : const Color(0xFF92400E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isOutOfRange ? _DS.danger : const Color(0xFF92400E),
              ),
            ),
          ),
          if (!isOutOfRange) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _DS.hairline),
                ),
                child: const Text(
                  'Tentar',
                  style: TextStyle(
                    fontSize: 11,
                    color: _DS.ink,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Premium order summary card ────────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final List<_PubCartItem> cart;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final bool loadingDeliveryFee;
  final bool isFreeDelivery;
  final bool isPickup;
  final bool minOrderBlocked;
  final double? minOrderValue;
  final Color brandColor;
  final PurchaseGoalSuggestionModel? goalSuggestion;
  final bool loadingGoalSuggestion;
  final Future<void> Function()? onAddGoalSuggestion;
  final Future<void> Function()? onOpenGoalSuggestion;

  const _OrderSummaryCard({
    required this.cart,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.loadingDeliveryFee,
    required this.isFreeDelivery,
    this.isPickup = false,
    required this.minOrderBlocked,
    required this.minOrderValue,
    required this.brandColor,
    this.goalSuggestion,
    this.loadingGoalSuggestion = false,
    this.onAddGoalSuggestion,
    this.onOpenGoalSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long_outlined, size: 14, color: brandColor),
              ),
              const SizedBox(width: 8),
              const Text(
                'Seu pedido',
                style: TextStyle(
                  fontSize: 13,
                  color: _DS.ink,
                ),
              ),
            ]),
          ),

          const Divider(height: 1, color: _DS.hairlineSoft),

          // ── Items ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: cart
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _DS.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${c.quantity}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _DS.slate,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontSize: 13, color: _DS.ink)),
                                  if ((c.notes ?? '').isNotEmpty) Text(c.notes!, style: const TextStyle(fontSize: 11, color: _DS.stone)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currFmt.format(c.subtotal),
                              style: const TextStyle(fontSize: 13, color: _DS.ink),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ── Upsell contextual (entre itens e totais) ──────────────────
          if (goalSuggestion != null && onAddGoalSuggestion != null && onOpenGoalSuggestion != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: brandColor),
                      const SizedBox(width: 5),
                      Text(
                        'Adicione ao pedido',
                        style: TextStyle(fontSize: 11, color: brandColor),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '· Sugestão opcional',
                        style: TextStyle(fontSize: 11, color: _DS.stone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _GoalSuggestionInlineCard(
                    suggestion: goalSuggestion!,
                    brandColor: brandColor,
                    onAdd: onAddGoalSuggestion!,
                    onTap: onOpenGoalSuggestion!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (loadingGoalSuggestion) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: _GoalSuggestionSkeleton(brandColor: brandColor),
            ),
          ],

          const Divider(height: 1, color: _DS.hairlineSoft),

          // ── Subtotal row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              const Expanded(
                child: Text('Subtotal', style: TextStyle(fontSize: 13, color: _DS.stone)),
              ),
              Text(_currFmt.format(subtotal), style: const TextStyle(fontSize: 13, color: _DS.slate)),
            ]),
          ),

          // ── Delivery fee row (oculta em retirada) ─────────────────────
          if (!isPickup)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(children: [
                const Expanded(
                  child: Text('Entrega', style: TextStyle(fontSize: 13, color: _DS.stone)),
                ),
                if (loadingDeliveryFee)
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _DS.muted),
                  )
                else if (isFreeDelivery)
                  const Text(
                    'Grátis',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF065F46),
                    ),
                  )
                else
                  Text(_currFmt.format(deliveryFee), style: const TextStyle(fontSize: 13, color: _DS.slate)),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(children: const [
                Expanded(
                  child: Text('Retirada no local', style: TextStyle(fontSize: 13, color: _DS.stone)),
                ),
                Text(
                  'Sem taxa 🚀',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),

          // ── Min order warning ─────────────────────────────────────────
          if (minOrderBlocked) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 13, color: _DS.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pedido mínimo: ${_currFmt.format(minOrderValue)} para entrega',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _DS.danger,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Divider(height: 1, color: _DS.hairlineSoft),
          ),

          // ── Total row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 15,
                    color: _DS.ink,
                  ),
                ),
              ),
              Text(
                _currFmt.format(total),
                style: const TextStyle(
                  fontSize: 17,
                  color: _DS.ink,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── InfoCard (kept for customer section) ─────────────────────────────────────
// ─── Schedule section ────────────────────────────────────────────────────────
class _ScheduleSection extends StatelessWidget {
  final bool isOpen;
  final List<PublicOpeningHourModel> openingHours;
  final bool useScheduling;
  final DateTime? scheduledFor;
  final Color brandColor;
  final void Function(bool) onToggle;
  final void Function(DateTime) onChange;

  const _ScheduleSection({
    required this.isOpen,
    required this.openingHours,
    required this.useScheduling,
    required this.scheduledFor,
    required this.brandColor,
    required this.onToggle,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final slots = _scheduleSlots(openingHours, DateTime.now());
    final hasSlots = slots.isNotEmpty;
    final canOrderNow = isOpen;
    final mustSchedule = !canOrderNow;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: brandColor),
              const SizedBox(width: 6),
              const Text('Quando entregar?', style: TextStyle(fontSize: 12, color: _DS.slate)),
            ],
          ),
          const SizedBox(height: 10),
          // Mode toggle
          Row(
            children: [
              Expanded(
                child: _ModePill(
                  label: 'Assim que possível',
                  icon: Icons.bolt_rounded,
                  selected: !useScheduling,
                  disabled: !canOrderNow,
                  brandColor: brandColor,
                  onTap: !canOrderNow
                      ? null
                      : () {
                          if (useScheduling) onToggle(false);
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModePill(
                  label: 'Agendar',
                  icon: Icons.event_rounded,
                  selected: useScheduling,
                  disabled: !hasSlots,
                  brandColor: brandColor,
                  onTap: !hasSlots
                      ? null
                      : () {
                          if (!useScheduling) onToggle(true);
                        },
                ),
              ),
            ],
          ),
          if (mustSchedule && hasSlots && !useScheduling) ...[
            const SizedBox(height: 10),
            Text(
              'Restaurante fechado — o pedido precisa ser agendado.',
              style: TextStyle(
                fontSize: 11,
                color: _DS.danger.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (mustSchedule && !hasSlots) ...[
            const SizedBox(height: 10),
            const Text(
              'Sem horários disponíveis nos próximos 7 dias.',
              style: TextStyle(
                fontSize: 11,
                color: _DS.danger,
              ),
            ),
          ],
          // Scheduling picker
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: useScheduling && hasSlots
                ? _SchedulePicker(
                    slots: slots,
                    selected: scheduledFor,
                    brandColor: brandColor,
                    onChange: onChange,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final Color brandColor;
  final VoidCallback? onTap;
  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    if (disabled) {
      bg = _DS.surface;
      fg = _DS.muted;
      border = _DS.hairlineSoft;
    } else if (selected) {
      bg = brandColor.withValues(alpha: 0.10);
      fg = brandColor;
      border = brandColor;
    } else {
      bg = _DS.canvas;
      fg = _DS.slate;
      border = _DS.hairline;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePicker extends StatelessWidget {
  final List<DateTime> slots;
  final DateTime? selected;
  final Color brandColor;
  final void Function(DateTime) onChange;
  const _SchedulePicker({
    required this.slots,
    required this.selected,
    required this.brandColor,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    // Group slots by day (year-month-day)
    final Map<String, List<DateTime>> byDay = {};
    for (final s in slots) {
      final key = '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
      byDay.putIfAbsent(key, () => []).add(s);
    }
    final dayKeys = byDay.keys.toList();

    // Resolve which day is selected
    String? selectedKey;
    if (selected != null) {
      selectedKey = '${selected!.year}-${selected!.month.toString().padLeft(2, '0')}-${selected!.day.toString().padLeft(2, '0')}';
    }
    selectedKey ??= dayKeys.isNotEmpty ? dayKeys.first : null;

    final daySlots = selectedKey != null ? (byDay[selectedKey] ?? []) : [];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: dayKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final key = dayKeys[i];
                final firstSlot = byDay[key]!.first;
                final isSel = key == selectedKey;
                return _SlotChip(
                  label: _dayChipLabel(firstSlot),
                  selected: isSel,
                  brandColor: brandColor,
                  onTap: () {
                    final list = byDay[key]!;
                    DateTime pick = list.first;
                    if (selected != null) {
                      for (final s in list) {
                        if (s.hour == selected!.hour && s.minute == selected!.minute) {
                          pick = s;
                          break;
                        }
                      }
                    }
                    onChange(pick);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Time chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: daySlots.map((s) {
              final isSel = selected != null && s.year == selected!.year && s.month == selected!.month && s.day == selected!.day && s.hour == selected!.hour && s.minute == selected!.minute;
              return _SlotChip(
                label: '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}',
                selected: isSel,
                brandColor: brandColor,
                onTap: () => onChange(s),
              );
            }).toList(),
          ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: brandColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Agendado para ${_scheduleLabel(selected!, full: true)}',
                      style: TextStyle(fontSize: 12, color: brandColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dayChipLabel(DateTime dt) {
    final today = DateTime.now();
    final isToday = dt.year == today.year && dt.month == today.month && dt.day == today.day;
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
    if (isToday) return 'Hoje';
    if (isTomorrow) return 'Amanhã';
    return '${_kDayShort[dt.weekday]} ${dt.day.toString().padLeft(2, '0')}';
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color brandColor;
  final VoidCallback onTap;
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.brandColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? brandColor : _DS.canvas,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? brandColor : _DS.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : _DS.slate,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

// ─── Shared field widgets ─────────────────────────────────────────────────────
class _PubLabel extends StatelessWidget {
  final String text;
  const _PubLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 12, color: _DS.slate));
}

class _PubField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final int maxLines;
  final Color focusColor;
  final List<TextInputFormatter>? inputFormatters;
  const _PubField({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.focusColor = _DS.brandBlue,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: _DS.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusColor, width: 2)),
        filled: true,
        fillColor: _DS.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ─── Card de sugestão de Objetivo de Compra (inline no checkout) ────────────

class _GoalSuggestionInlineCard extends StatefulWidget {
  final PurchaseGoalSuggestionModel suggestion;
  final Color brandColor;
  final Future<void> Function() onAdd;
  final Future<void> Function() onTap;

  const _GoalSuggestionInlineCard({
    required this.suggestion,
    required this.brandColor,
    required this.onAdd,
    required this.onTap,
  });

  @override
  State<_GoalSuggestionInlineCard> createState() => _GoalSuggestionInlineCardState();
}

class _GoalSuggestionInlineCardState extends State<_GoalSuggestionInlineCard> {
  bool _adding = false;

  Future<void> _handleAdd() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await widget.onAdd();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final hasImg = (s.productImageUrl ?? '').isNotEmpty;
    final hasSavings = s.discountAmount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _adding ? null : widget.onTap,
        borderRadius: BorderRadius.circular(_DS.rLg),
        child: Container(
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumb
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: hasImg
                      ? Image.network(
                          s.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbFallback(),
                        )
                      : _thumbFallback(),
                ),
              ),
              const SizedBox(width: 10),
              // Conteúdo + botão
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tag "Economize" acima do nome
                    if (hasSavings) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4C4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Economize ${_currFmt.format(s.discountAmount)}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF746019)),
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    // Nome + preços + botão na mesma linha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: _DS.ink, letterSpacing: -0.2),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    _currFmt.format(s.finalPrice),
                                    style: TextStyle(fontSize: 13, color: widget.brandColor),
                                  ),
                                  if (hasSavings) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      _currFmt.format(s.originalPrice),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _DS.muted,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // CTA
                        FilledButton(
                          onPressed: _adding ? null : _handleAdd,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.brandColor,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: _adding
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Adicionar', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: _DS.surface,
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 22, color: _DS.muted),
      ),
    );
  }
}

class _GoalSuggestionSkeleton extends StatelessWidget {
  final Color brandColor;
  const _GoalSuggestionSkeleton({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _DS.hairlineSoft,
      highlightColor: _DS.surface,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rLg),
          border: Border.all(color: _DS.hairlineSoft),
        ),
      ),
    );
  }
}
