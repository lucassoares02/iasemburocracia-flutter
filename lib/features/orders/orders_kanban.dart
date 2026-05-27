part of 'orders_page.dart';

// ─── Column definition ────────────────────────────────────────────────────────
class _KCol {
  final int status;
  final Color accent;
  final Color colBg;
  final String label;
  const _KCol(this.status, this.accent, this.colBg, this.label);
}

const _kCols = [
  _KCol(1, Color(0xFF4262FF), Color(0xFFF0F3FF), 'Aguardando'),
  _KCol(2, Color(0xFF6D28D9), Color(0xFFEDE9FE), 'Confirmado'),
  _KCol(3, Color(0xFF946C0A), Color(0xFFFFF4C4), 'Em Preparo'),
  _KCol(4, Color(0xFFB45309), Color(0xFFFEF3C7), 'Em Entrega'),
  _KCol(8, Color(0xFF187574), Color(0xFFCCFBF1), 'Pronto p/ Retirada'),
];

// ─── Kanban Board ─────────────────────────────────────────────────────────────
class _KanbanBoard extends StatelessWidget {
  final List<OrderModel> orders;
  final OrdersController ctrl;
  final Future<void> Function(OrderModel, int) onStatusChange;

  const _KanbanBoard({
    required this.orders,
    required this.ctrl,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final byStatus = {for (final c in _kCols) c.status: <OrderModel>[]};
    for (final o in orders) {
      byStatus[o.status ?? 1]?.add(o);
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final colH = (constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0) - 8;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 8, right: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _kCols.map((col) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 272,
                  height: colH,
                  child: _KanbanColumn(
                    col: col,
                    orders: byStatus[col.status] ?? [],
                    onStatusChange: onStatusChange,
                    ctrl: ctrl,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Kanban Column ────────────────────────────────────────────────────────────
class _KanbanColumn extends StatefulWidget {
  final _KCol col;
  final List<OrderModel> orders;
  final Future<void> Function(OrderModel, int) onStatusChange;
  final OrdersController ctrl;

  const _KanbanColumn({
    required this.col,
    required this.orders,
    required this.onStatusChange,
    required this.ctrl,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  double get _total => widget.orders.fold(0.0, (s, o) => s + (o.total ?? 0));

  @override
  Widget build(BuildContext context) {
    return DragTarget<OrderModel>(
      onWillAcceptWithDetails: (d) => d.data.status != widget.col.status,
      onAcceptWithDetails: (d) => widget.onStatusChange(d.data, widget.col.status),
      builder: (ctx, candidates, _) {
        final isOver = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isOver ? widget.col.accent.withValues(alpha: 0.07) : const Color(0xFFF2F3F5),
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(
              color: isOver ? widget.col.accent.withValues(alpha: 0.55) : _DS.hairlineSoft,
              width: isOver ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              _KanbanColumnHeader(
                col: widget.col,
                count: widget.orders.length,
                total: _total,
                isOver: isOver,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Column(
                    children: [
                      if (widget.orders.isEmpty)
                        _KanbanEmptySlot(col: widget.col, isOver: isOver)
                      else ...[
                        ...widget.orders.map(
                          (o) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _KanbanCard(
                              key: ValueKey(o.id),
                              order: o,
                              col: widget.col,
                              ctrl: widget.ctrl,
                              onStatusChange: widget.onStatusChange,
                            ),
                          ),
                        ),
                        if (isOver) _DropIndicatorBar(accent: widget.col.accent),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Column header ────────────────────────────────────────────────────────────
class _KanbanColumnHeader extends StatelessWidget {
  final _KCol col;
  final int count;
  final double total;
  final bool isOver;

  const _KanbanColumnHeader({
    required this.col,
    required this.count,
    required this.total,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isOver ? 10 : 8,
            height: isOver ? 10 : 8,
            decoration: BoxDecoration(color: col.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  col.label,
                  style: const TextStyle(fontSize: 13, color: _DS.ink),
                ),
                if (total > 0)
                  Text(
                    _currencyFmt.format(total),
                    style: TextStyle(
                      fontSize: 10,
                      color: col.accent,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isOver ? col.accent : _DS.hairlineSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                color: isOver ? Colors.white : _DS.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kanban Card ──────────────────────────────────────────────────────────────
class _KanbanCard extends StatefulWidget {
  final OrderModel order;
  final _KCol col;
  final OrdersController ctrl;
  final Future<void> Function(OrderModel, int) onStatusChange;

  const _KanbanCard({
    super.key,
    required this.order,
    required this.col,
    required this.ctrl,
    required this.onStatusChange,
  });

  @override
  State<_KanbanCard> createState() => _KanbanCardState();
}

class _KanbanCardState extends State<_KanbanCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _actnAnim;
  late final Animation<double> _actnFade;

  OrderModel get o => widget.order;

  @override
  void initState() {
    super.initState();
    _actnAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _actnFade = CurvedAnimation(parent: _actnAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _actnAnim.dispose();
    super.dispose();
  }

  void _setHover(bool v) {
    if (!mounted || v == _hovered) return;
    setState(() => _hovered = v);
    if (v) {
      _actnAnim.forward();
    } else {
      _actnAnim.reverse();
    }
  }

  void _showDetails() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _OrderDetailsModal(order: o, ctrl: widget.ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = o.status == 1;
    final items = (o.items ?? []).cast<OrderItemModel>();
    final preview = items.take(3).toList();

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _hovered ? const Color(0xFFFAFAFD) : _DS.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? widget.col.accent.withValues(alpha: 0.45) : (_hovered ? _DS.hairline : _DS.hairlineSoft),
          width: isNew ? 1.5 : 1,
        ),
        boxShadow: _hovered ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top accent stripe for novo orders
          if (isNew)
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: widget.col.accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row: #ID + time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(4)),
                      child: Text('#${o.id}', style: const TextStyle(fontSize: 10, color: _DS.slate)),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.col.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Novo!', style: TextStyle(fontSize: 9, color: widget.col.accent)),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      o.createdAt != null ? DateFormat('HH:mm', 'pt_BR').format(o.createdAt!) : '—',
                      style: const TextStyle(fontSize: 10, color: _DS.stone),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Client name
                Row(children: [
                  const Icon(Icons.person_outline, size: 12, color: _DS.stone),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      o.clientName ?? '—',
                      style: const TextStyle(fontSize: 13, color: _DS.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                if ((o.clientPhone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.phone_outlined, size: 11, color: _DS.stone),
                    const SizedBox(width: 4),
                    Text(o.clientPhone!, style: const TextStyle(fontSize: 11, color: _DS.steel)),
                  ]),
                ],
                // Items preview
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: _DS.hairlineSoft, height: 1),
                  const SizedBox(height: 6),
                  ...preview.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(children: [
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(4)),
                          child: Center(child: Text('${item.quantity}', style: const TextStyle(fontSize: 9, color: _DS.slate))),
                        ),
                        const SizedBox(width: 5),
                        Expanded(child: Text(item.name ?? '—', style: const TextStyle(fontSize: 11, color: _DS.steel), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('+${items.length - 3} mais', style: const TextStyle(fontSize: 10, color: _DS.stone)),
                    ),
                ],
                const SizedBox(height: 8),
                // Footer: count + total
                Row(children: [
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                  ),
                  const Spacer(),
                  Text(
                    _currencyFmt.format(o.total ?? 0),
                    style: const TextStyle(fontSize: 13, color: _DS.ink),
                  ),
                ]),
                // Quick actions (fade in on hover)
                SizeTransition(
                  sizeFactor: _actnFade,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _actnFade,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Divider(color: _DS.hairlineSoft, height: 1),
                        const SizedBox(height: 8),
                        _KanbanQuickActions(
                          order: o,
                          col: widget.col,
                          onStatusChange: widget.onStatusChange,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Draggable<OrderModel>(
      data: o,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 248,
          child: _KanbanDragFeedback(order: o, col: widget.col),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          onTap: _showDetails,
          child: card,
        ),
      ),
    );
  }
}

// ─── Quick actions row ────────────────────────────────────────────────────────
class _KanbanQuickActions extends StatelessWidget {
  final OrderModel order;
  final _KCol col;
  final Future<void> Function(OrderModel, int) onStatusChange;

  const _KanbanQuickActions({
    required this.order,
    required this.col,
    required this.onStatusChange,
  });

  int? _nextStatus() {
    switch (order.status) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      case 8:
        return 9;
      default:
        return null;
    }
  }

  void _openWhatsApp() {
    final raw = order.clientPhone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (raw.isEmpty) return;
    final number = raw.startsWith('55') ? raw : '55$raw';
    _jsWindowOpen('https://wa.me/$number', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus();
    final hasPhone = (order.clientPhone ?? '').isNotEmpty;
    final canCancel = !const [6, 7, 5, 9].contains(order.status);

    return Row(
      children: [
        if (next != null)
          Expanded(
            child: _QkBtn(
              label: _DS.statusLabel(next),
              color: _DS.statusFg(next),
              onTap: () => onStatusChange(order, next),
            ),
          ),
        if (next != null && (hasPhone || canCancel)) const SizedBox(width: 6),
        if (hasPhone)
          _QkIconBtn(
            icon: Icons.chat_rounded,
            color: const Color(0xFF25D366),
            onTap: _openWhatsApp,
          ),
        if (hasPhone && canCancel) const SizedBox(width: 6),
        if (canCancel)
          _QkIconBtn(
            icon: Icons.cancel_outlined,
            color: _DS.danger,
            onTap: () => onStatusChange(order, 6),
          ),
      ],
    );
  }
}

class _QkBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QkBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward, size: 10),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label, style: TextStyle(fontSize: 11, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QkIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QkIconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

// ─── Drag feedback ────────────────────────────────────────────────────────────
class _KanbanDragFeedback extends StatelessWidget {
  final OrderModel order;
  final _KCol col;

  const _KanbanDragFeedback({required this.order, required this.col});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.accent.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
            BoxShadow(color: col.accent.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(4)),
                child: Text('#${order.id}', style: const TextStyle(fontSize: 10, color: _DS.slate)),
              ),
              const SizedBox(width: 6),
              _StatusBadge(status: order.status),
            ]),
            const SizedBox(height: 6),
            Text(
              order.clientName ?? '—',
              style: const TextStyle(fontSize: 13, color: _DS.ink),
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFmt.format(order.total ?? 0),
              style: const TextStyle(fontSize: 12, color: _DS.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty slot ───────────────────────────────────────────────────────────────
class _KanbanEmptySlot extends StatelessWidget {
  final _KCol col;
  final bool isOver;

  const _KanbanEmptySlot({required this.col, required this.isOver});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(top: 4),
      height: 72,
      decoration: BoxDecoration(
        color: isOver ? col.accent.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOver ? col.accent.withValues(alpha: 0.4) : _DS.hairlineSoft,
        ),
      ),
      child: Center(
        child: Text(
          isOver ? 'Soltar aqui' : 'Sem pedidos',
          style: TextStyle(
            fontSize: 12,
            color: isOver ? col.accent : _DS.muted,
            fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Drop indicator bar ────────────────────────────────────────────────────────
class _DropIndicatorBar extends StatelessWidget {
  final Color accent;
  const _DropIndicatorBar({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── View mode switcher ────────────────────────────────────────────────────────
class _ViewSwitcher extends StatelessWidget {
  final _ViewMode current;
  final ValueChanged<_ViewMode> onChange;

  const _ViewSwitcher({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchPill(
            icon: Icons.view_list_rounded,
            label: 'Lista',
            active: current == _ViewMode.list,
            onTap: () => onChange(_ViewMode.list),
          ),
          const SizedBox(width: 2),
          _SwitchPill(
            icon: Icons.view_kanban_outlined,
            label: 'Kanban',
            active: current == _ViewMode.kanban,
            onTap: () => onChange(_ViewMode.kanban),
          ),
          const SizedBox(width: 2),
          _SwitchPill(
            icon: Icons.map_outlined,
            label: 'Mapa',
            active: current == _ViewMode.map,
            onTap: () => onChange(_ViewMode.map),
          ),
        ],
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SwitchPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _DS.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(_DS.rFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : _DS.stone),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : _DS.steel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge "Entrega / Retirada" para cards admin ─────────────────────────────
class _OrderDeliveryTypeBadge extends StatelessWidget {
  final String? deliveryType;
  const _OrderDeliveryTypeBadge({required this.deliveryType});

  @override
  Widget build(BuildContext context) {
    final isPickup = deliveryType == 'pickup';
    final fg = isPickup ? const Color(0xFFB45309) : _DS.brandBlue;
    final bg = isPickup ? const Color(0xFFFEF3C7) : const Color(0xFFEEF3FF);
    final icon = isPickup ? Icons.shopping_bag_outlined : Icons.delivery_dining_rounded;
    final label = isPickup ? 'Retirada no local' : 'Entrega';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── JS interop helper ────────────────────────────────────────────────────────
@JS('window.open')
external void _jsWindowOpen(String url, String target);
