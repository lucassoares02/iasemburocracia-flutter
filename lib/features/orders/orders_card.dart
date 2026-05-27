part of 'orders_page.dart';

// ─── Order card ──────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  bool _updatingStatus = false;

  OrderModel get order => widget.order;

  OrdersController _findCtrl() {
    final state = context.findAncestorStateOfType<_OrdersPageState>();
    return state!._ctrl;
  }

  Future<void> _changeStatus(int newStatus) async {
    if (newStatus == 6 || newStatus == 7) {
      _showCancelDialog(newStatus);
      return;
    }
    setState(() => _updatingStatus = true);
    try {
      await _findCtrl().updateStatus(order.id!, newStatus);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _showCancelDialog(int targetStatus) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CancelOrderModal(orderId: order.id!, ctrl: _findCtrl(), targetStatus: targetStatus),
    );
  }

  void _showDetails() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _OrderDetailsModal(order: order, ctrl: _findCtrl()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = (order.items ?? []).cast<OrderItemModel>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_DS.rXl),
        onTap: _showDetails,
        child: Ink(
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(6)),
                              child: Text('#${order.id}', style: const TextStyle(fontSize: 12, color: _DS.slate)),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: order.status),
                          ]),
                        ),
                        Text(
                          order.createdAt != null ? _dateFmt.format(order.createdAt!) : '—',
                          style: const TextStyle(fontSize: 12, color: _DS.stone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.person_outline, size: 14, color: _DS.stone),
                                const SizedBox(width: 4),
                                Text(order.clientName ?? '—', style: const TextStyle(fontSize: 14, color: _DS.ink)),
                              ]),
                              if (order.clientPhone != null && order.clientPhone!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(children: [
                                  const Icon(Icons.phone_outlined, size: 13, color: _DS.stone),
                                  const SizedBox(width: 4),
                                  Text(order.clientPhone!, style: const TextStyle(fontSize: 13, color: _DS.steel)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currencyFmt.format(order.total ?? 0), style: const TextStyle(fontSize: 16, color: _DS.ink)),
                            Text('${items.length} ${items.length == 1 ? 'item' : 'itens'}', style: const TextStyle(fontSize: 12, color: _DS.stone)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_updatingStatus)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue))
                        else
                          _StatusSelector(current: order.status ?? 1, onChanged: _changeStatus),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Row(children: [
                            Text(
                              _expanded ? 'Ocultar itens' : 'Ver itens',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _DS.brandBlue,
                              ),
                            ),
                            Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: _DS.brandBlue),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _ItemsSection(items: items),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: _DS.statusBg(status), borderRadius: BorderRadius.circular(_DS.rFull)),
      child: Text(_DS.statusLabel(status), style: TextStyle(fontSize: 11, color: _DS.statusFg(status))),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final int current;
  final void Function(int) onChanged;
  const _StatusSelector({required this.current, required this.onChanged});

  static const _statuses = [
    1,
    2,
    3,
    4,
    5,
    8,
    9,
    6,
    7,
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      initialValue: current,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: _DS.canvas,
      offset: const Offset(0, 36),
      itemBuilder: (_) => _statuses.map((s) {
        final active = s == current;
        return PopupMenuItem(
          value: s,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: active ? _DS.surface : null,
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _DS.statusFg(s), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text(_DS.statusLabel(s), style: TextStyle(fontSize: 13, color: _DS.ink, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
              if (active) ...[const Spacer(), const Icon(Icons.check, size: 14, color: _DS.brandBlue)],
            ]),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: _DS.hairline), borderRadius: BorderRadius.circular(_DS.rFull)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: _DS.statusFg(current), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(_DS.statusLabel(current), style: const TextStyle(fontSize: 12, color: _DS.ink)),
            const SizedBox(width: 4),
            const Icon(Icons.unfold_more, size: 14, color: _DS.stone),
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final List<OrderItemModel> items;
  const _ItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _DS.hairlineSoft))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Itens do pedido', style: TextStyle(fontSize: 12, color: _DS.slate)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('${item.quantity}x', style: const TextStyle(fontSize: 10, color: _DS.slate))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.name ?? '—', style: const TextStyle(fontSize: 13, color: _DS.ink))),
                  Text(_currencyFmt.format(item.unitPrice ?? 0), style: const TextStyle(fontSize: 12, color: _DS.steel)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 72,
                    child: Text(_currencyFmt.format(item.subtotal ?? 0), style: const TextStyle(fontSize: 13, color: _DS.ink), textAlign: TextAlign.end),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}

// ─── Cancel modal ─────────────────────────────────────────────────────────────
class _CancelOrderModal extends StatefulWidget {
  final int orderId;
  final OrdersController ctrl;
  final int targetStatus;
  const _CancelOrderModal({
    required this.orderId,
    required this.ctrl,
    this.targetStatus = 6,
  });

  @override
  State<_CancelOrderModal> createState() => _CancelOrderModalState();
}

class _CancelOrderModalState extends State<_CancelOrderModal> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await widget.ctrl.updateStatus(
        widget.orderId,
        widget.targetStatus,
        cancelReason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _DS.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxxl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: _DS.dangerLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.cancel_outlined, color: _DS.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                  widget.targetStatus == 7 ? 'Rejeitar pedido' : 'Cancelar pedido',
                  style: const TextStyle(fontSize: 18, color: _DS.ink),
                )),
                IconButton(icon: const Icon(Icons.close, size: 18, color: _DS.stone), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 8),
              const Text('Esta ação não pode ser desfeita. Deseja continuar?', style: TextStyle(fontSize: 14, color: _DS.steel)),
              const SizedBox(height: 20),
              Text(
                widget.targetStatus == 7 ? 'Motivo da rejeição (opcional)' : 'Motivo do cancelamento (opcional)',
                style: const TextStyle(fontSize: 13, color: _DS.slate),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex: cliente desistiu, produto indisponível...',
                  hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: _DS.surface,
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _DS.ink, side: const BorderSide(color: _DS.hairline), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: const Text('Voltar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _confirm,
                    style: FilledButton.styleFrom(backgroundColor: _DS.danger, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Cancelar pedido'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsModal extends StatefulWidget {
  final OrderModel order;
  final OrdersController ctrl;
  const _OrderDetailsModal({required this.order, required this.ctrl});

  @override
  State<_OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<_OrderDetailsModal> {
  bool _updatingStatus = false;
  late int _unreadCount;

  @override
  void initState() {
    super.initState();
    _unreadCount = widget.order.unreadMessages;
  }

  Future<void> _changeStatus(int newStatus) async {
    if (newStatus == 6 || newStatus == 7) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (_) => _CancelOrderModal(
          orderId: widget.order.id!,
          ctrl: widget.ctrl,
          targetStatus: newStatus,
        ),
      );
      return;
    }

    setState(() => _updatingStatus = true);
    try {
      await widget.ctrl.updateStatus(widget.order.id!, newStatus);
      if (mounted) {
        setState(() => widget.order.status = newStatus);
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order.items ?? []).cast<OrderItemModel>();
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: _DS.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxxl)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text('#${order.id}', style: const TextStyle(fontSize: 20, color: _DS.ink)),
                          const SizedBox(width: 10),
                          _StatusBadge(status: order.status),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: _DS.stone),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  order.createdAt != null ? _dateFmt.format(order.createdAt!) : '—',
                  style: const TextStyle(fontSize: 12, color: _DS.stone),
                ),
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: _DS.stone),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    order.clientName ?? '—',
                                    style: const TextStyle(fontSize: 14, color: _DS.ink),
                                  ),
                                ),
                                Text(
                                  _currencyFmt.format(order.total ?? 0),
                                  style: const TextStyle(fontSize: 16, color: _DS.ink),
                                ),
                              ],
                            ),
                            if ((order.clientPhone ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 15, color: _DS.stone),
                                  const SizedBox(width: 6),
                                  Text(order.clientPhone!, style: const TextStyle(fontSize: 13, color: _DS.steel)),
                                ],
                              ),
                            ],
                            if ((order.notes ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _DS.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _DS.hairlineSoft),
                                ),
                                child: Text(order.notes!, style: const TextStyle(fontSize: 13, color: _DS.slate)),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(children: [
                              _OrderDeliveryTypeBadge(deliveryType: order.deliveryType),
                            ]),
                            if (order.deliveryType != 'pickup' && (order.deliveryAddress ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 15, color: _DS.stone),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      order.deliveryAddress!,
                                      style: const TextStyle(fontSize: 13, color: _DS.steel),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _DeliveryAddressMap(address: order.deliveryAddress!),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_updatingStatus)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue))
                    else
                      _StatusSelector(current: order.status ?? 1, onChanged: _changeStatus),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: _DS.ink,
                  unselectedLabelColor: _DS.stone,
                  indicatorColor: _DS.brandBlue,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: _DS.hairlineSoft,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                  ),
                  tabs: [
                    const Tab(text: 'Itens'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Mensagens'),
                          if (_unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: _DS.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _DS.hairlineSoft),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: items.isEmpty
                            ? const Center(
                                child: Text('Nenhum item', style: TextStyle(fontSize: 13, color: _DS.stone)),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const Divider(color: _DS.hairlineSoft, height: 14),
                                itemBuilder: (_, i) {
                                  final item = items[i];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(6)),
                                        child: Center(child: Text('${item.quantity}x', style: const TextStyle(fontSize: 10, color: _DS.slate))),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(item.name ?? '—', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                                      ),
                                      Text(_currencyFmt.format(item.subtotal ?? 0), style: const TextStyle(fontSize: 13, color: _DS.ink)),
                                    ],
                                  );
                                },
                              ),
                      ),
                      _AdminOrderChat(
                        orderId: order.id!,
                        clientName: order.clientName ?? 'Cliente',
                        onMessagesRead: () => setState(() => _unreadCount = 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressMap extends StatelessWidget {
  final String address;
  const _DeliveryAddressMap({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeliveryMapEmbed(address: address),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              address,
              style: const TextStyle(fontSize: 12, color: _DS.steel),
            ),
            GestureDetector(
              onTap: () => _jsWindowOpen(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                '_blank',
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 14, color: _DS.brandBlue),
                  SizedBox(width: 4),
                  Text(
                    'Abrir no Google Maps',
                    style: TextStyle(
                      fontSize: 12,
                      color: _DS.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryMapEmbed extends StatefulWidget {
  final String address;
  const _DeliveryMapEmbed({required this.address});

  @override
  State<_DeliveryMapEmbed> createState() => _DeliveryMapEmbedState();
}

class _DeliveryMapEmbedState extends State<_DeliveryMapEmbed> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'delivery-map-${DateTime.now().microsecondsSinceEpoch}';
    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      final encoded = Uri.encodeComponent(widget.address);
      iframe.src = 'https://www.google.com/maps?q=$encoded&output=embed';
      iframe.style.border = '0';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.setAttribute('loading', 'lazy');
      iframe.setAttribute('referrerpolicy', 'no-referrer-when-downgrade');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}
