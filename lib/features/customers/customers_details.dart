part of 'customers_page.dart';

// ─── Detail Page ───────────────────────────────────────────────────────────────
class _CustomerDetailPage extends StatefulWidget {
  final int customerId;
  final CustomersController ctrl;
  const _CustomerDetailPage({required this.customerId, required this.ctrl});

  @override
  State<_CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<_CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.fetchDetails(widget.customerId);
  }

  void _openEdit(CustomerModel c) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomerFormModal(ctrl: widget.ctrl, customer: c),
    );
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _DeleteConfirmDialog(name: c.name),
    );
    if (confirmed != true || !mounted) return;
    final res = await widget.ctrl.deleteCustomer(widget.customerId);
    if (res.success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      appBar: AppBar(
        backgroundColor: _DS.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _DS.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalhes do cliente',
          style: TextStyle(fontSize: 16, color: _DS.ink),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _DS.hairlineSoft),
        ),
      ),
      body: ValueListenableBuilder<StateApp>(
        valueListenable: widget.ctrl.stateDetails,
        builder: (_, state, __) {
          if (state is LoadingState || state is StartState) {
            return const _DetailSkeleton();
          }
          if (state is ErrorState) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 36, color: _DS.danger),
                const SizedBox(height: 10),
                Text(state.message, style: const TextStyle(fontSize: 13, color: _DS.stone)),
              ]),
            );
          }
          if (state is SuccessState && state.data is CustomerModel) {
            final c = state.data as CustomerModel;
            return _DetailContent(
              customer: c,
              onEdit: () => _openEdit(c),
              onDelete: () => _confirmDelete(c),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Detail Content ────────────────────────────────────────────────────────────
class _DetailContent extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DetailContent({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _DetailHeader(customer: c, onEdit: onEdit, onDelete: onDelete),
            const SizedBox(height: 16),
            _InsightsSection(customer: c),
            const SizedBox(height: 16),
            _MetricsGrid(customer: c),
            if (c.hasAddress) ...[
              const SizedBox(height: 16),
              _AddressCard(customer: c),
            ],
            if (c.hasOrders) ...[
              const SizedBox(height: 16),
              _OrdersHistoryCard(customer: c),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Detail Header ─────────────────────────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DetailHeader({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomerAvatar(name: c.name, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name ?? '—',
                        style: const TextStyle(
                          fontSize: 18,
                          color: _DS.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (c.phone?.isNotEmpty == true)
                  Text(
                    c.phone!,
                    style: const TextStyle(fontSize: 13, color: _DS.stone),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (c.isRecurring)
                      const _CustomerBadge(
                        label: 'Recorrente',
                        fg: Color(0xFF4262FF),
                        bg: Color(0xFFEEF3FF),
                      ),
                    if (c.daysSinceCreated <= 30)
                      const _CustomerBadge(
                        label: 'Novo',
                        fg: Color(0xFF065F46),
                        bg: Color(0xFFD1FAE5),
                      ),
                    if ((c.totalSpent ?? 0) >= 500)
                      const _CustomerBadge(
                        label: 'Alto Valor',
                        fg: Color(0xFF946C0A),
                        bg: Color(0xFFFFF4C4),
                      ),
                    if (c.daysSinceLastOrder <= 30 && c.hasOrders)
                      const _CustomerBadge(
                        label: 'Ativo',
                        fg: Color(0xFF187574),
                        bg: Color(0xFFCCFBF1),
                      ),
                    if (c.daysSinceLastOrder > 60 && c.hasOrders)
                      const _CustomerBadge(
                        label: 'Inativo',
                        fg: Color(0xFF6B6F7E),
                        bg: Color(0xFFEEF0F3),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.ink,
                  side: const BorderSide(color: _DS.hairline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Editar',
                    style: TextStyle(
                      fontSize: 13,
                    )),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.danger,
                  side: const BorderSide(color: _DS.dangerLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.delete_outline, size: 15),
                label: const Text('Excluir',
                    style: TextStyle(
                      fontSize: 13,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Insights Section ──────────────────────────────────────────────────────────
class _InsightsSection extends StatelessWidget {
  final CustomerModel customer;
  const _InsightsSection({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final insights = <String>[];

    if (c.isRecurring) {
      insights.add('${c.totalOrders} pedidos no total');
    }
    if (c.lastOrderAt != null) {
      final days = c.daysSinceLastOrder;
      if (days == 0) {
        insights.add('Pedido hoje');
      } else if (days == 1) {
        insights.add('Pedido ontem');
      } else {
        insights.add('Último pedido há $days dias');
      }
    }
    if (c.avgTicket != null && c.avgTicket! > 0) {
      insights.add('Ticket médio: ${_currencyFmt.format(c.avgTicket)}');
    }
    if (c.maxOrder != null && c.maxOrder! > 0) {
      insights.add('Maior pedido: ${_currencyFmt.format(c.maxOrder)}');
    }
    if ((c.cancelledOrders ?? 0) > 0) {
      insights.add('${c.cancelledOrders} cancelamento${c.cancelledOrders! > 1 ? 's' : ''}');
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: insights
          .map((text) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _DS.canvas,
                  borderRadius: BorderRadius.circular(_DS.rFull),
                  border: Border.all(color: _DS.hairlineSoft),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _DS.slate,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ─── Metrics Grid ──────────────────────────────────────────────────────────────
class _MetricsGrid extends StatelessWidget {
  final CustomerModel customer;
  const _MetricsGrid({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return LayoutBuilder(builder: (_, box) {
      final narrow = box.maxWidth < 480;
      final cols = narrow ? 2 : 4;
      const spacing = 10.0;
      final w = (box.maxWidth - (cols - 1) * spacing) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _MetricTile(
            icon: Icons.receipt_long_outlined,
            iconColor: _DS.brandBlue,
            iconBg: const Color(0xFFEEF3FF),
            label: 'Total pedidos',
            value: '${c.totalOrders ?? 0}',
            width: w,
          ),
          _MetricTile(
            icon: Icons.payments_outlined,
            iconColor: _DS.successAccent,
            iconBg: const Color(0xFFE6FAF3),
            label: 'Total gasto',
            value: _currencyFmt.format(c.totalSpent ?? 0),
            width: w,
          ),
          _MetricTile(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF6D28D9),
            iconBg: const Color(0xFFEDE9FE),
            label: 'Ticket médio',
            value: c.avgTicket != null ? _currencyFmt.format(c.avgTicket) : '—',
            width: w,
          ),
          _MetricTile(
            icon: Icons.workspace_premium_outlined,
            iconColor: const Color(0xFFB45309),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Maior pedido',
            value: c.maxOrder != null ? _currencyFmt.format(c.maxOrder) : '—',
            width: w,
          ),
        ],
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String label, value;
  final double width;
  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 11, color: _DS.stone)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, color: _DS.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Address Card ──────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final CustomerModel customer;
  const _AddressCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final line1 = [c.street, c.number].where((v) => v?.isNotEmpty == true).join(', ');
    final line2 = [c.complement, c.neighborhood].where((v) => v?.isNotEmpty == true).join(' — ');
    final line3 = [
      if (c.city?.isNotEmpty == true) c.city,
      if (c.state?.isNotEmpty == true) c.state,
      if (c.zipCode?.isNotEmpty == true) c.zipCode,
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFEEF3FF), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.location_on_outlined, size: 16, color: _DS.brandBlue),
            ),
            const SizedBox(width: 10),
            const Text('Endereço', style: TextStyle(fontSize: 14, color: _DS.ink)),
          ]),
          const SizedBox(height: 12),
          if (line1.isNotEmpty) _AddrLine(text: line1),
          if (line2.isNotEmpty) _AddrLine(text: line2),
          if (line3.isNotEmpty) _AddrLine(text: line3),
        ],
      ),
    );
  }
}

class _AddrLine extends StatelessWidget {
  final String text;
  const _AddrLine({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(text, style: const TextStyle(fontSize: 13, color: _DS.steel)),
    );
  }
}

// ─── Orders History Card ───────────────────────────────────────────────────────
class _OrdersHistoryCard extends StatelessWidget {
  final CustomerModel customer;
  const _OrdersHistoryCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final orders = customer.orders ?? [];
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFF6D28D9)),
              ),
              const SizedBox(width: 10),
              const Text('Histórico de pedidos', style: TextStyle(fontSize: 14, color: _DS.ink)),
              const Spacer(),
              Text('${orders.length} pedido${orders.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: _DS.stone)),
            ]),
          ),
          const Divider(height: 1, color: _DS.hairlineSoft),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhum pedido registrado.', style: TextStyle(fontSize: 13, color: _DS.stone)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _DS.hairlineSoft),
              itemBuilder: (_, i) => _OrderHistoryItem(order: orders[i] as CustomerOrderModel),
            ),
        ],
      ),
    );
  }
}

class _OrderHistoryItem extends StatelessWidget {
  final CustomerOrderModel order;
  const _OrderHistoryItem({required this.order});

  @override
  Widget build(BuildContext context) {
    final itemNames = (order.items ?? []).map((i) => i.name ?? '').where((n) => n.isNotEmpty).take(3).join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _DS.statusBg(order.status),
              shape: BoxShape.circle,
              border: Border.all(color: _DS.statusFg(order.status), width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _DS.statusBg(order.status),
                      borderRadius: BorderRadius.circular(_DS.rFull),
                    ),
                    child: Text(
                      _DS.statusLabel(order.status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _DS.statusFg(order.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.total != null ? _currencyFmt.format(order.total) : '—',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _DS.ink,
                    ),
                  ),
                ]),
                if (itemNames.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    itemNames,
                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (order.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _datetimeFmt.format(order.createdAt!),
                    style: const TextStyle(fontSize: 11, color: _DS.muted),
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

// ─── Detail Skeleton ───────────────────────────────────────────────────────────
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  Widget _box(double w, double h, {double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _DS.hairlineSoft,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DS.canvas,
                borderRadius: BorderRadius.circular(_DS.rXl),
                border: Border.all(color: _DS.hairlineSoft),
              ),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: const BoxDecoration(color: _DS.hairlineSoft, shape: BoxShape.circle)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _box(140, 14),
                  const SizedBox(height: 8),
                  _box(90, 11),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _box(90, 28, r: 99),
              _box(70, 28, r: 99),
              _box(80, 28, r: 99),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < 4; i++)
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 80) / 4,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: _DS.canvas,
                      borderRadius: BorderRadius.circular(_DS.rXl),
                      border: Border.all(color: _DS.hairlineSoft),
                    ),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Confirm Dialog ─────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final String? name;
  const _DeleteConfirmDialog({this.name});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _DS.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxxl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
                  child: const Icon(Icons.delete_outline, color: _DS.danger, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Excluir cliente', style: TextStyle(fontSize: 17, color: _DS.ink)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _DS.stone),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ]),
              const SizedBox(height: 12),
              Text(
                'Deseja excluir "${name ?? 'este cliente'}"? Esta ação não pode ser desfeita.',
                style: const TextStyle(fontSize: 14, color: _DS.steel),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.ink,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.danger,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Excluir'),
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

// ─── Customer Form Modal ───────────────────────────────────────────────────────
class _CustomerFormModal extends StatefulWidget {
  final CustomersController ctrl;
  final CustomerModel? customer;
  const _CustomerFormModal({required this.ctrl, this.customer});

  @override
  State<_CustomerFormModal> createState() => _CustomerFormModalState();
}

class _CustomerFormModalState extends State<_CustomerFormModal> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (c != null) {
      _nameCtrl.text = c.name ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _streetCtrl.text = c.street ?? '';
      _numberCtrl.text = c.number ?? '';
      _complementCtrl.text = c.complement ?? '';
      _neighborhoodCtrl.text = c.neighborhood ?? '';
      _cityCtrl.text = c.city ?? '';
      _stateCtrl.text = c.state ?? '';
      _zipCtrl.text = c.zipCode ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _complementCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'O nome é obrigatório.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = {
      'name': name,
      'phone': _phoneCtrl.text.trim(),
      'street': _streetCtrl.text.trim(),
      'number': _numberCtrl.text.trim(),
      'complement': _complementCtrl.text.trim(),
      'neighborhood': _neighborhoodCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'zip_code': _zipCtrl.text.trim(),
    };

    final ResponseModel res = _isEdit ? await widget.ctrl.updateCustomer(widget.customer!.id!, data) : await widget.ctrl.createCustomer(data);

    if (!mounted) return;

    if (res.success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _DS.canvas,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxxl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, color: _DS.brandBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEdit ? 'Editar cliente' : 'Novo cliente',
                    style: const TextStyle(fontSize: 18, color: _DS.ink),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _DS.stone),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                _isEdit ? 'Atualize as informações do cliente.' : 'Preencha os dados para cadastrar um novo cliente.',
                style: const TextStyle(fontSize: 13, color: _DS.steel),
              ),
              const SizedBox(height: 20),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Informações pessoais'),
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'Nome *',
                        controller: _nameCtrl,
                        hint: 'Nome completo',
                      ),
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'Telefone',
                        controller: _phoneCtrl,
                        hint: '(11) 99999-9999',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      const _SectionLabel('Endereço'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: _LabeledField(
                            label: 'Rua / Avenida',
                            controller: _streetCtrl,
                            hint: 'Rua das Flores',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LabeledField(
                            label: 'Número',
                            controller: _numberCtrl,
                            hint: '123',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'Complemento',
                        controller: _complementCtrl,
                        hint: 'Apto 42',
                      ),
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'Bairro',
                        controller: _neighborhoodCtrl,
                        hint: 'Centro',
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          flex: 3,
                          child: _LabeledField(
                            label: 'Cidade',
                            controller: _cityCtrl,
                            hint: 'São Paulo',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LabeledField(
                            label: 'UF',
                            controller: _stateCtrl,
                            hint: 'SP',
                            maxLength: 2,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _LabeledField(
                        label: 'CEP',
                        controller: _zipCtrl,
                        hint: '01310-100',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _DS.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 15, color: _DS.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(fontSize: 12, color: _DS.danger)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.ink,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.ink,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEdit ? 'Salvar' : 'Cadastrar'),
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

// ─── Form helpers ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: _DS.stone, letterSpacing: 0.4),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _DS.slate)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 13, color: _DS.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
            filled: true,
            fillColor: _DS.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
