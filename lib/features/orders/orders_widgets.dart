part of 'orders_page.dart';

// ─── Shared form widgets ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, color: _DS.slate, letterSpacing: 0.3));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final int maxLines;
  const _Field({required this.controller, required this.hint, this.inputType = TextInputType.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _DS.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: _DS.surface,
      ),
    );
  }
}

// ─── Address widgets ──────────────────────────────────────────────────────────
class _SkeletonAddressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 130, height: 11, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Container(width: 220, height: 10, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 5),
          Container(width: 160, height: 10, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

class _ClientAddressCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onEdit;
  const _ClientAddressCard({required this.client, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    var mainLine = client.street ?? '';
    if ((client.number ?? '').isNotEmpty) mainLine += ', ${client.number}';
    if ((client.complement ?? '').isNotEmpty) mainLine += ' — ${client.complement}';
    if (mainLine.isNotEmpty) lines.add(mainLine);
    if ((client.neighborhood ?? '').isNotEmpty) lines.add(client.neighborhood!);
    final cityState = [client.city, client.state].where((s) => s != null && s.isNotEmpty).cast<String>().join(' / ');
    if (cityState.isNotEmpty) lines.add(cityState);
    if ((client.zipCode ?? '').isNotEmpty) lines.add('CEP ${client.zipCode}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: _DS.brandBlue),
            const SizedBox(width: 6),
            const Expanded(child: Text('Endereço de entrega', style: TextStyle(fontSize: 12, color: _DS.slate))),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _DS.surfacePricing, borderRadius: BorderRadius.circular(_DS.rFull)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 11, color: _DS.brandBlue),
                    SizedBox(width: 4),
                    Text('Editar', style: TextStyle(fontSize: 11, color: _DS.brandBlue)),
                  ],
                ),
              ),
            ),
          ]),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(l, style: const TextStyle(fontSize: 12, color: _DS.steel)),
                )),
          ],
        ],
      ),
    );
  }
}

class _ClientAddressForm extends StatelessWidget {
  final _AddressControllers ctrls;
  final bool saving;
  final String? error;
  final bool canCancel;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  const _ClientAddressForm({
    required this.ctrls,
    required this.saving,
    this.error,
    required this.canCancel,
    required this.onSave,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 14, color: _DS.brandBlue),
            const SizedBox(width: 6),
            Text(
              canCancel ? 'Editar endereço' : 'Cadastrar endereço',
              style: const TextStyle(fontSize: 12, color: _DS.slate),
            ),
          ]),
          const SizedBox(height: 10),
          _AddressGoogleLookup(ctrls: ctrls),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(flex: 2, child: _Field(controller: ctrls.zip, hint: 'CEP', inputType: TextInputType.number)),
            const SizedBox(width: 6),
            Expanded(child: _Field(controller: ctrls.number, hint: 'Número')),
          ]),
          const SizedBox(height: 6),
          _Field(controller: ctrls.street, hint: 'Rua *'),
          const SizedBox(height: 6),
          _Field(controller: ctrls.complement, hint: 'Complemento (opcional)'),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _Field(controller: ctrls.neighborhood, hint: 'Bairro')),
            const SizedBox(width: 6),
            Expanded(child: _Field(controller: ctrls.city, hint: 'Cidade')),
          ]),
          const SizedBox(height: 6),
          _Field(controller: ctrls.state, hint: 'Estado (UF)'),
          if (ctrls.lat != null && ctrls.lng != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GoogleMapWidget(lat: ctrls.lat!, lng: ctrls.lng!, height: 180),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(error!, style: const TextStyle(color: _DS.danger, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (canCancel && onCancel != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.steel,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12)),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(backgroundColor: _DS.brandBlue, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 8), textStyle: const TextStyle(fontSize: 12)),
                child: saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar endereço'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AddressGoogleLookup extends StatefulWidget {
  final _AddressControllers ctrls;
  const _AddressGoogleLookup({required this.ctrls});

  @override
  State<_AddressGoogleLookup> createState() => _AddressGoogleLookupState();
}

class _AddressGoogleLookupState extends State<_AddressGoogleLookup> {
  final _searchCtrl = TextEditingController();
  final _repo = AddressRepository();
  final _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
  Timer? _debounce;
  bool _loading = false;
  List<PlaceSuggestion> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final input = value.trim();
    if (input.length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(input));
  }

  Future<void> _fetch(String input) async {
    setState(() => _loading = true);
    try {
      final res = await _repo.autocomplete(input, sessionToken: _sessionToken);
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() => _suggestions = (res.data as List).cast<PlaceSuggestion>());
      } else {
        setState(() => _suggestions = []);
      }
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    _searchCtrl.text = suggestion.description;
    setState(() {
      _loading = true;
      _suggestions = [];
    });
    try {
      final res = await _repo.details(suggestion.placeId, sessionToken: _sessionToken);
      if (!mounted) return;
      if (res.success && res.data is PlaceDetails) {
        final d = res.data as PlaceDetails;
        if (d.street != null) widget.ctrls.street.text = d.street!;
        if (d.number != null) widget.ctrls.number.text = d.number!;
        if (d.neighborhood != null) widget.ctrls.neighborhood.text = d.neighborhood!;
        if (d.city != null) widget.ctrls.city.text = d.city!;
        if (d.state != null) widget.ctrls.state.text = d.state!;
        if (d.zipCode != null) widget.ctrls.zip.text = d.zipCode!;
        widget.ctrls.lat = d.lat;
        widget.ctrls.lng = d.lng;
        widget.ctrls.placeId = d.placeId;
        widget.ctrls.formattedAddress = d.formattedAddress;
        setState(() {});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onChanged,
          style: const TextStyle(fontSize: 14, color: _DS.ink),
          decoration: InputDecoration(
            hintText: 'Buscar endereço no Google',
            hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 18, color: _DS.stone),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue)),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: _DS.surface,
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _DS.canvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _DS.hairline),
            ),
            child: Column(
              children: _suggestions.map((s) {
                return InkWell(
                  onTap: () => _select(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: _DS.stone),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.mainText ?? s.description, style: const TextStyle(fontSize: 12, color: _DS.ink)),
                              if (s.secondaryText != null && s.secondaryText!.isNotEmpty) Text(s.secondaryText!, style: const TextStyle(fontSize: 11, color: _DS.stone)),
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
        ],
      ],
    );
  }
}

// ─── Product widgets ──────────────────────────────────────────────────────────
class _ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  const _ProductThumbnail({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : Container(width: size, height: size, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(8))),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.fastfood_outlined, size: size * 0.45, color: _DS.muted),
      );
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _DS.yellowLight, borderRadius: BorderRadius.circular(_DS.rFull)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: _DS.yellowDark)),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(_DS.rFull), border: Border.all(color: _DS.hairline)),
        child: Icon(icon, size: 14, color: _DS.ink),
      ),
    );
  }
}

// ─── Cart item (local model) ──────────────────────────────────────────────────
class _CartItem {
  final int menuItemId;
  final String name;
  final double unitPrice;
  int quantity;

  _CartItem({required this.menuItemId, required this.name, required this.unitPrice, required this.quantity});

  factory _CartItem.empty() => _CartItem(menuItemId: -1, name: '', unitPrice: 0, quantity: 0);

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'menu_item_id': menuItemId,
        'name': name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}

// ─── Address controllers helper ───────────────────────────────────────────────
class _AddressControllers {
  final zip = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final complement = TextEditingController();
  final neighborhood = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  double? lat;
  double? lng;
  String? placeId;
  String? formattedAddress;

  void dispose() {
    zip.dispose();
    street.dispose();
    number.dispose();
    complement.dispose();
    neighborhood.dispose();
    city.dispose();
    state.dispose();
  }

  void clear() {
    zip.clear();
    street.clear();
    number.clear();
    complement.clear();
    neighborhood.clear();
    city.clear();
    state.clear();
    lat = null;
    lng = null;
    placeId = null;
    formattedAddress = null;
  }

  void populate(ClientModel c) {
    zip.text = c.zipCode ?? '';
    street.text = c.street ?? '';
    number.text = c.number ?? '';
    complement.text = c.complement ?? '';
    neighborhood.text = c.neighborhood ?? '';
    city.text = c.city ?? '';
    state.text = c.state ?? '';
    lat = null;
    lng = null;
    placeId = null;
    formattedAddress = null;
  }

  bool get hasAnyData => street.text.trim().isNotEmpty || zip.text.trim().isNotEmpty || city.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'zip_code': zip.text.trim().isEmpty ? null : zip.text.trim(),
        'street': street.text.trim().isEmpty ? null : street.text.trim(),
        'number': number.text.trim().isEmpty ? null : number.text.trim(),
        'complement': complement.text.trim().isEmpty ? null : complement.text.trim(),
        'neighborhood': neighborhood.text.trim().isEmpty ? null : neighborhood.text.trim(),
        'city': city.text.trim().isEmpty ? null : city.text.trim(),
        'state': state.text.trim().isEmpty ? null : state.text.trim(),
      };
}
