part of 'orders_page.dart';

// ─── Create order modal ───────────────────────────────────────────────────────
class _CreateOrderModal extends StatefulWidget {
  final OrdersController ctrl;
  const _CreateOrderModal({required this.ctrl});

  @override
  State<_CreateOrderModal> createState() => _CreateOrderModalState();
}

class _CreateOrderModalState extends State<_CreateOrderModal> {
  // ── Client search ──
  final _searchCtrl = TextEditingController();
  final _newNameCtrl = TextEditingController();
  final _newPhoneCtrl = TextEditingController();
  Timer? _debounce;

  List<ClientModel> _clientResults = [];
  bool _searchingClients = false;
  ClientModel? _selectedClient;
  bool _showNewClientForm = false;
  bool _creatingClient = false;

  // ── Client full details + address ──
  ClientModel? _clientFull;
  bool _loadingClientFull = false;
  bool _editingAddress = false;
  bool _savingAddress = false;
  String? _addressError;
  final _editAddrCtrls = _AddressControllers();
  final _newAddrCtrls = _AddressControllers();

  // ── Menu + cart ──
  final _notesCtrl = TextEditingController();
  List<MenuItemsModel> _menuItems = [];
  bool _loadingMenu = true;
  final List<_CartItem> _cart = [];

  // ── Submit ──
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _clientResults = [];
        _searchingClients = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _searchClients(q));
  }

  Future<void> _searchClients(String q) async {
    setState(() => _searchingClients = true);
    try {
      final res = await widget.ctrl.useCase.searchClients(q);
      if (mounted && res.success && res.data is List) {
        setState(() => _clientResults = (res.data as List).cast<ClientModel>());
      }
    } catch (_) {}
    if (mounted) setState(() => _searchingClients = false);
  }

  void _selectClient(ClientModel c) {
    setState(() {
      _selectedClient = c;
      _clientResults = [];
      _searchCtrl.text = c.name ?? '';
      _showNewClientForm = false;
      _error = null;
      _clientFull = null;
      _editingAddress = false;
      _addressError = null;
      _editAddrCtrls.clear();
    });
    _loadClientFull(c.id!);
  }

  void _clearClient() {
    setState(() {
      _selectedClient = null;
      _clientFull = null;
      _searchCtrl.clear();
      _clientResults = [];
      _showNewClientForm = false;
      _loadingClientFull = false;
      _editingAddress = false;
      _addressError = null;
      _editAddrCtrls.clear();
    });
  }

  Future<void> _loadClientFull(int id) async {
    setState(() => _loadingClientFull = true);
    try {
      final res = await widget.ctrl.useCase.getClient(id);
      if (mounted && res.success && res.data is ClientModel) {
        final full = res.data as ClientModel;
        setState(() {
          _clientFull = full;
          _editingAddress = !full.hasAddress;
          if (full.hasAddress) _editAddrCtrls.populate(full);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingClientFull = false);
  }

  Future<void> _saveAddress() async {
    if (_selectedClient == null || _clientFull == null) return;
    if (_editAddrCtrls.street.text.trim().isEmpty) {
      setState(() => _addressError = 'Informe a rua para salvar o endereço.');
      return;
    }
    setState(() {
      _savingAddress = true;
      _addressError = null;
    });
    try {
      final res = await widget.ctrl.useCase.updateClientAddress(
        _selectedClient!.id!,
        _clientFull!.name ?? '',
        _clientFull!.phone,
        _editAddrCtrls.toJson(),
      );
      if (mounted) {
        if (res.success && res.data is ClientModel) {
          setState(() {
            _clientFull = res.data as ClientModel;
            _editingAddress = false;
          });
        } else {
          setState(() => _addressError = 'Erro ao salvar endereço. Tente novamente.');
        }
      }
    } catch (_) {
      if (mounted) setState(() => _addressError = 'Erro ao salvar endereço. Tente novamente.');
    }
    if (mounted) setState(() => _savingAddress = false);
  }

  Future<void> _createNewClient() async {
    final name = _newNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do novo cliente.');
      return;
    }
    setState(() => _creatingClient = true);
    try {
      final addressData = _newAddrCtrls.hasAnyData ? _newAddrCtrls.toJson() : null;
      final res = await widget.ctrl.useCase.createClient(
        name,
        _newPhoneCtrl.text.trim().isEmpty ? null : _newPhoneCtrl.text.trim(),
        addressData: addressData,
      );
      if (res.success && res.data is ClientModel) {
        final newClient = res.data as ClientModel;
        setState(() {
          _selectedClient = newClient;
          _clientFull = newClient;
          _editingAddress = !newClient.hasAddress;
          _clientResults = [];
          _searchCtrl.text = newClient.name ?? '';
          _showNewClientForm = false;
          _error = null;
          _loadingClientFull = false;
          if (newClient.hasAddress) _editAddrCtrls.populate(newClient);
          _newNameCtrl.clear();
          _newPhoneCtrl.clear();
          _newAddrCtrls.clear();
        });
      } else {
        setState(() => _error = 'Erro ao cadastrar cliente.');
      }
    } catch (_) {
      setState(() => _error = 'Erro ao cadastrar cliente.');
    }
    if (mounted) setState(() => _creatingClient = false);
  }

  Future<void> _loadMenu() async {
    try {
      final response = await MenuItemsUseCase(MenuItemsRepository()).findAll();
      if (response.success && response.data is List) {
        setState(() {
          _menuItems = (response.data as List).cast<MenuItemsModel>().where((m) => m.available == true).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingMenu = false);
  }

  void _addItem(MenuItemsModel item) {
    final idx = _cart.indexWhere((c) => c.menuItemId == item.id);
    if (idx >= 0) {
      setState(() => _cart[idx].quantity++);
    } else {
      setState(() => _cart.add(_CartItem(menuItemId: item.id!, name: item.name ?? '', unitPrice: item.price ?? 0, quantity: 1)));
    }
  }

  void _removeItem(int menuItemId) => setState(() => _cart.removeWhere((c) => c.menuItemId == menuItemId));

  void _incrementItem(int menuItemId) {
    final idx = _cart.indexWhere((c) => c.menuItemId == menuItemId);
    if (idx >= 0) setState(() => _cart[idx].quantity++);
  }

  void _decrementItem(int menuItemId) {
    final idx = _cart.indexWhere((c) => c.menuItemId == menuItemId);
    if (idx >= 0) {
      if (_cart[idx].quantity <= 1) {
        _removeItem(menuItemId);
      } else {
        setState(() => _cart[idx].quantity--);
      }
    }
  }

  double get _total => _cart.fold(0, (sum, c) => sum + c.subtotal);

  String? _buildDeliveryAddress() {
    final c = _clientFull;
    if (c == null || !c.hasAddress) return null;
    final parts = <String>[];
    var line = c.street!;
    if ((c.number ?? '').isNotEmpty) line += ', ${c.number}';
    if ((c.complement ?? '').isNotEmpty) line += ' — ${c.complement}';
    parts.add(line);
    if ((c.neighborhood ?? '').isNotEmpty) parts.add(c.neighborhood!);
    if ((c.city ?? '').isNotEmpty) parts.add(c.city!);
    if ((c.zipCode ?? '').isNotEmpty) parts.add(c.zipCode!);
    return parts.join(' — ');
  }

  Future<void> _save() async {
    if (_selectedClient == null) {
      setState(() => _error = 'Selecione ou cadastre um cliente.');
      return;
    }
    if (_cart.isEmpty) {
      setState(() => _error = 'Adicione ao menos um item ao pedido.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final deliveryAddress = _buildDeliveryAddress();
      await widget.ctrl.create(
        {
          'client_id': _selectedClient!.id,
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'items': _cart.map((c) => c.toJson()).toList(),
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        },
        context,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _newNameCtrl.dispose();
    _newPhoneCtrl.dispose();
    _notesCtrl.dispose();
    _editAddrCtrls.dispose();
    _newAddrCtrls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _DS.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxxl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: _DS.surfacePricing, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.receipt_long_outlined, color: _DS.brandBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Novo pedido', style: TextStyle(fontSize: 18, color: _DS.ink))),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: _DS.stone), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('Cliente'),
                            const SizedBox(height: 8),
                            if (_selectedClient != null) ...[
                              _SelectedClientChip(client: _selectedClient!, onClear: _clearClient),
                              const SizedBox(height: 10),
                              if (_loadingClientFull)
                                _SkeletonAddressCard()
                              else if (_clientFull != null)
                                _editingAddress
                                    ? _ClientAddressForm(
                                        ctrls: _editAddrCtrls,
                                        saving: _savingAddress,
                                        error: _addressError,
                                        canCancel: _clientFull!.hasAddress,
                                        onSave: _saveAddress,
                                        onCancel: _clientFull!.hasAddress
                                            ? () => setState(() {
                                                  _editingAddress = false;
                                                  _addressError = null;
                                                })
                                            : null,
                                      )
                                    : _ClientAddressCard(
                                        client: _clientFull!,
                                        onEdit: () => setState(() {
                                          _editingAddress = true;
                                          _editAddrCtrls.populate(_clientFull!);
                                        }),
                                      ),
                            ] else ...[
                              _ClientSearchField(
                                controller: _searchCtrl,
                                loading: _searchingClients,
                                results: _clientResults,
                                onSelect: _selectClient,
                                onCreateNew: () => setState(() {
                                  _showNewClientForm = !_showNewClientForm;
                                  _newNameCtrl.text = _searchCtrl.text.trim();
                                }),
                              ),
                              if (_showNewClientForm) ...[
                                const SizedBox(height: 10),
                                _NewClientForm(
                                  nameCtrl: _newNameCtrl,
                                  phoneCtrl: _newPhoneCtrl,
                                  addressCtrls: _newAddrCtrls,
                                  loading: _creatingClient,
                                  onSave: _createNewClient,
                                  onCancel: () => setState(() => _showNewClientForm = false),
                                ),
                              ],
                            ],
                            const SizedBox(height: 16),
                            const _SectionLabel('Produtos do cardápio'),
                            const SizedBox(height: 8),
                            if (_loadingMenu)
                              ..._buildMenuSkeletons()
                            else if (_menuItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Nenhum produto disponível.', style: TextStyle(color: _DS.stone, fontSize: 13)),
                              )
                            else
                              ..._menuItems.map((item) => _MenuItemRow(
                                    item: item,
                                    cartQty: _cart.firstWhere((c) => c.menuItemId == item.id, orElse: () => _CartItem.empty()).quantity,
                                    onAdd: () => _addItem(item),
                                    onIncrement: () => _incrementItem(item.id!),
                                    onDecrement: () => _decrementItem(item.id!),
                                  )),
                            const SizedBox(height: 16),
                            const _SectionLabel('Observações'),
                            const SizedBox(height: 8),
                            _Field(controller: _notesCtrl, hint: 'Observações do pedido (opcional)', maxLines: 3),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 340,
                      child: _CartSummary(
                        cart: _cart,
                        total: _total,
                        onIncrement: _incrementItem,
                        onDecrement: _decrementItem,
                        onRemove: _removeItem,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: _DS.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _DS.ink, side: const BorderSide(color: _DS.hairline), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(backgroundColor: _DS.ink, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Confirmar pedido · ${_currencyFmt.format(_total)}'),
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

  List<Widget> _buildMenuSkeletons() => List.generate(
        4,
        (_) => Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _DS.hairlineSoft)),
        ),
      );
}

// ─── Client search widgets ────────────────────────────────────────────────────
class _ClientSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final List<ClientModel> results;
  final void Function(ClientModel) onSelect;
  final VoidCallback onCreateNew;
  const _ClientSearchField({required this.controller, required this.loading, required this.results, required this.onSelect, required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: _DS.ink),
          decoration: InputDecoration(
            hintText: 'Buscar por nome ou telefone...',
            hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 18, color: _DS.stone),
            suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue))) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: _DS.surface,
          ),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(10), border: Border.all(color: _DS.hairline)),
            child: Column(children: results.map((c) => _ClientResultRow(client: c, onTap: () => onSelect(c))).toList()),
          ),
        ],
        if (controller.text.trim().isNotEmpty && results.isEmpty && !loading) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onCreateNew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: _DS.surfacePricing, borderRadius: BorderRadius.circular(10), border: Border.all(color: _DS.brandBlue.withValues(alpha: 0.3))),
              child: Row(
                children: [
                  const Icon(Icons.person_add_outlined, size: 16, color: _DS.brandBlue),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Cadastrar "${controller.text.trim()}" como novo cliente',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _DS.brandBlue,
                          ))),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ClientResultRow extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;
  const _ClientResultRow({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _DS.hairlineSoft))),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person_outline, size: 14, color: _DS.stone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name ?? '', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                  if (client.phone != null && client.phone!.isNotEmpty) Text(client.phone!, style: const TextStyle(fontSize: 11, color: _DS.stone)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: _DS.muted),
          ],
        ),
      ),
    );
  }
}

class _SelectedClientChip extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onClear;
  const _SelectedClientChip({required this.client, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _DS.surfacePricing,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.brandBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: _DS.brandBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.person, size: 16, color: _DS.brandBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name ?? '', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                if (client.phone != null && client.phone!.isNotEmpty) Text(client.phone!, style: const TextStyle(fontSize: 11, color: _DS.steel)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.close, size: 13, color: _DS.stone),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New client form ──────────────────────────────────────────────────────────
class _NewClientForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final _AddressControllers addressCtrls;
  final bool loading;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  const _NewClientForm({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrls,
    required this.loading,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Novo cliente', style: TextStyle(fontSize: 12, color: _DS.slate)),
          const SizedBox(height: 8),
          _Field(controller: nameCtrl, hint: 'Nome *'),
          const SizedBox(height: 6),
          _Field(controller: phoneCtrl, hint: 'Telefone (opcional)', inputType: TextInputType.phone),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.location_on_outlined, size: 12, color: _DS.stone),
            SizedBox(width: 4),
            Text('Endereço (opcional)', style: TextStyle(fontSize: 11, color: _DS.stone)),
          ]),
          const SizedBox(height: 8),
          _AddressGoogleLookup(ctrls: addressCtrls),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(flex: 2, child: _Field(controller: addressCtrls.zip, hint: 'CEP', inputType: TextInputType.number)),
            const SizedBox(width: 6),
            Expanded(child: _Field(controller: addressCtrls.number, hint: 'Nº')),
          ]),
          const SizedBox(height: 6),
          _Field(controller: addressCtrls.street, hint: 'Rua'),
          const SizedBox(height: 6),
          _Field(controller: addressCtrls.complement, hint: 'Complemento'),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _Field(controller: addressCtrls.neighborhood, hint: 'Bairro')),
            const SizedBox(width: 6),
            Expanded(child: _Field(controller: addressCtrls.city, hint: 'Cidade')),
          ]),
          const SizedBox(height: 6),
          _Field(controller: addressCtrls.state, hint: 'Estado (UF)'),
          if (addressCtrls.lat != null && addressCtrls.lng != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GoogleMapWidget(lat: addressCtrls.lat!, lng: addressCtrls.lng!, height: 180),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: loading ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DS.steel,
                    side: const BorderSide(color: _DS.hairline),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: loading ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.brandBlue,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu item row ────────────────────────────────────────────────────────────
class _MenuItemRow extends StatelessWidget {
  final MenuItemsModel item;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  const _MenuItemRow({required this.item, required this.cartQty, required this.onAdd, required this.onIncrement, required this.onDecrement});

  @override
  Widget build(BuildContext context) {
    final inCart = cartQty > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: inCart ? _DS.surfacePricing : _DS.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: inCart ? _DS.brandBlue.withValues(alpha: 0.3) : _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          _ProductThumbnail(imageUrl: item.imageUrl, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.categoryName != null && item.categoryName!.isNotEmpty) ...[
                  _CategoryBadge(item.categoryName!),
                  const SizedBox(height: 3),
                ],
                Text(item.name ?? '', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                Text(_currencyFmt.format(item.price ?? 0), style: const TextStyle(fontSize: 12, color: _DS.steel)),
              ],
            ),
          ),
          if (!inCart)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: _DS.ink, borderRadius: BorderRadius.circular(_DS.rFull)),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            )
          else
            Row(
              children: [
                _QtyBtn(icon: Icons.remove, onTap: onDecrement),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('$cartQty', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                ),
                _QtyBtn(icon: Icons.add, onTap: onIncrement),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Cart summary ─────────────────────────────────────────────────────────────
class _CartSummary extends StatelessWidget {
  final List<_CartItem> cart;
  final double total;
  final void Function(int) onIncrement;
  final void Function(int) onDecrement;
  final void Function(int) onRemove;
  const _CartSummary({required this.cart, required this.total, required this.onIncrement, required this.onDecrement, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(_DS.rXl), border: Border.all(color: _DS.hairlineSoft)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo', style: TextStyle(fontSize: 12, color: _DS.slate)),
          const SizedBox(height: 10),
          if (cart.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Nenhum item', style: TextStyle(fontSize: 12, color: _DS.muted))))
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: cart
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 12, color: _DS.ink), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 4),
                              Text('${c.quantity}×', style: const TextStyle(fontSize: 11, color: _DS.stone)),
                              const SizedBox(width: 4),
                              Text(_currencyFmt.format(c.subtotal), style: const TextStyle(fontSize: 11, color: _DS.ink)),
                              const SizedBox(width: 4),
                              GestureDetector(onTap: () => onRemove(c.menuItemId), child: const Icon(Icons.close, size: 12, color: _DS.stone)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          if (cart.isNotEmpty) ...[
            const Divider(color: _DS.hairline, height: 16),
            Row(
              children: [
                const Expanded(child: Text('Total', style: TextStyle(fontSize: 13, color: _DS.ink))),
                Text(_currencyFmt.format(total), style: const TextStyle(fontSize: 14, color: _DS.ink)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
