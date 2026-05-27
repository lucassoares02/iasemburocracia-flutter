part of 'public_order_page.dart';

final _timeOnlyFmt = DateFormat('HH:mm', 'pt_BR');

// ─── Tracking screen ─────────────────────────────────────────────────────────
class _TrackingScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final PublicOrderDetailModel? order;
  final Color brandColor;
  final String companyName;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;
  final VoidCallback onViewHistory;
  final VoidCallback onNewOrder;
  final VoidCallback? onOpenChat;
  final Future<void> Function(int orderId)? onReorder;

  const _TrackingScreen({
    required this.loading,
    required this.error,
    required this.order,
    required this.brandColor,
    required this.companyName,
    required this.onRefresh,
    required this.onBack,
    required this.onViewHistory,
    required this.onNewOrder,
    this.onOpenChat,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: loading && order == null
          ? const _TrackingSkeleton()
          : error != null && order == null
              ? _TrackingError(message: error!, onRetry: onRefresh)
              : order == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: brandColor,
                      onRefresh: onRefresh,
                      child: _TrackingContent(
                        order: order!,
                        brandColor: brandColor,
                        companyName: companyName,
                        onNewOrder: onNewOrder,
                        onReorder: onReorder,
                        onBack: onBack,
                        onViewHistory: onViewHistory,
                        onOpenChat: onOpenChat,
                      ),
                    ),
    );
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────
class _TrackingContent extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  final String companyName;
  final VoidCallback onNewOrder;
  final VoidCallback onBack;
  final VoidCallback onViewHistory;
  final VoidCallback? onOpenChat;
  final Future<void> Function(int orderId)? onReorder;

  const _TrackingContent({
    required this.order,
    required this.brandColor,
    required this.companyName,
    required this.onNewOrder,
    required this.onBack,
    required this.onViewHistory,
    this.onOpenChat,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType == 'pickup';
    final showDeliveryMap = !isPickup && order.status == 4 && order.deliveryLat != null && order.deliveryLng != null;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _InlineBackArrow(onBack: onBack),
        const SizedBox(height: 4),
        _HeroStatusCard(order: order, brandColor: brandColor),
        const SizedBox(height: 16),
        if (showDeliveryMap) ...[
          _DeliveryMapCard(
            destinationLat: order.deliveryLat!,
            destinationLng: order.deliveryLng!,
            originLat: order.companyLat,
            originLng: order.companyLng,
            brandColor: brandColor,
          ),
          const SizedBox(height: 16),
        ],
        _OrderItemsCard(order: order, brandColor: brandColor),
        const SizedBox(height: 12),
        _TrackingSummaryCard(order: order),
        const SizedBox(height: 12),
        _DeliveryDetailsCard(order: order, brandColor: brandColor),
        const SizedBox(height: 12),
        _PaymentDetailsCard(order: order, brandColor: brandColor),
        const SizedBox(height: 20),
        if (onReorder != null) ...[
          _ReorderButton(
            orderId: order.id,
            brandColor: brandColor,
            onReorder: onReorder!,
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: onNewOrder,
          style: OutlinedButton.styleFrom(
            foregroundColor: _DS.ink,
            side: const BorderSide(color: _DS.hairline),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Fazer novo pedido', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(height: 20),
        _BottomTrackingActions(
          brandColor: brandColor,
          onOpenChat: onOpenChat,
          onViewHistory: onViewHistory,
        ),
      ],
    );
  }
}

// ─── Ações ao final da tela (mensagem + meus pedidos) ────────────────────────
class _BottomTrackingActions extends StatelessWidget {
  final Color brandColor;
  final VoidCallback? onOpenChat;
  final VoidCallback onViewHistory;

  const _BottomTrackingActions({
    required this.brandColor,
    required this.onOpenChat,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onOpenChat != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onOpenChat,
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: brandColor),
              label: Text(
                'Mensagem',
                style: TextStyle(color: brandColor, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: brandColor.withValues(alpha: 0.4)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onViewHistory,
            icon: Icon(Icons.receipt_long_rounded, size: 16, color: brandColor),
            label: Text(
              'Meus pedidos',
              style: TextStyle(color: brandColor, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: brandColor.withValues(alpha: 0.4)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero status card (with integrated horizontal stepper) ───────────────────
class _HeroStatusCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  const _HeroStatusCard({required this.order, required this.brandColor});

  bool get _isActive => !_kTerminalStatuses.contains(order.status);

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(order.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status section ────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _PulsingStatusIcon(info: info, active: _isActive),
            // const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'STATUS ATUAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: info.fg.withValues(alpha: 0.7),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (_isActive) _LiveBadge(color: info.fg),
                    ],
                  ),
                  Text(
                    info.label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: info.fg, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _heroSubtitle(order),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _DS.steel,
                      height: 1.4,
                    ),
                  ),
                  if (order.scheduledFor != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_rounded, size: 12, color: brandColor),
                          const SizedBox(width: 6),
                          Text(
                            'Agendado: ${_scheduleLabel(order.scheduledFor!, full: true)}',
                            style: TextStyle(fontSize: 11, color: brandColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        // ── Divider ───────────────────────────────────────────────────────
        const SizedBox(height: 18),
        // ── Horizontal timeline ───────────────────────────────────────────
        _HorizontalOrderStepper(order: order, brandColor: brandColor),
      ],
    );
  }

  String _heroSubtitle(PublicOrderDetailModel o) {
    if (o.status == 1) return 'Aguardando confirmação do estabelecimento.';
    if (o.status == 2) return 'Pedido confirmado! Em breve começamos a preparar.';
    if (o.status == 3) return 'Seu pedido está sendo preparado.';
    if (o.status == 4) return 'Saiu para entrega.';
    if (o.status == 5) return 'Pedido entregue. Bom apetite!';
    if (o.status == 6) return 'Este pedido foi cancelado.';
    if (o.status == 7) return 'Este pedido foi rejeitado.';
    if (o.status == 8) return 'Seu pedido está pronto para retirada.';
    if (o.status == 9) return 'Pedido retirado. Bom apetite!';
    return 'Acompanhe a evolução do seu pedido.';
  }
}

// ─── Horizontal order stepper (3 bars) ───────────────────────────────────────
class _HorizontalOrderStepper extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;

  const _HorizontalOrderStepper({
    required this.order,
    required this.brandColor,
  });

  bool get _isTakeaway => order.status == 8 || order.status == 9 || order.statusHistory.any((s) => s.status == 8 || s.status == 9);

  bool get _isCancelled => order.status == 6 || order.status == 7;

  int get _currentIdx {
    final s = order.status;
    if (s == 1) return 0;
    if (s == 2 || s == 3) return 1;
    if (s == 4 || s == 8) return 2;
    if (s == 5 || s == 9) return 3; // all bars filled when delivered/picked up
    if (_isCancelled) {
      final codes = order.statusHistory.map((h) => h.status).toSet();
      if (codes.any((c) => [4, 5, 8, 9].contains(c))) return 2;
      if (codes.any((c) => [2, 3].contains(c))) return 1;
      return 0;
    }
    return 0;
  }

  Map<int, DateTime?> get _historyMap {
    final map = <int, DateTime?>{};
    for (final h in order.statusHistory) {
      if (!map.containsKey(h.status)) map[h.status] = h.createdAt;
    }
    return map;
  }

  DateTime? _timeForStep(int idx, bool isTakeaway, Map<int, DateTime?> h) {
    switch (idx) {
      case 0:
        return h[1];
      case 1:
        return h[2] ?? h[3];
      case 2:
        return isTakeaway ? (h[8] ?? h[9]) : (h[4] ?? h[5]);
      default:
        return null;
    }
  }

  String _labelForStep(int idx, bool isTakeaway) {
    switch (idx) {
      case 0:
        return 'Pedido realizado';
      case 1:
        return 'Confirmado';
      case 2:
        if (isTakeaway) return order.status == 9 ? 'Retirado' : 'Pronto';
        return order.status == 5 ? 'Entregue' : 'Em entrega';
      default:
        return '';
    }
  }

  Color _colorForStep(int idx, bool isTakeaway) {
    if (_isCancelled) return _DS.danger;
    switch (idx) {
      case 0:
        return _DS.successAccent;
      case 1:
        return const Color(0xFF6D28D9);
      case 2:
        if (isTakeaway) return const Color(0xFF187574);
        return order.status == 5 ? const Color(0xFF065F46) : const Color(0xFFB45309);
      default:
        return _DS.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTakeaway = _isTakeaway;
    final currentIdx = _currentIdx;
    final historyMap = _historyMap;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildBarStep(
            idx: 0,
            currentIdx: currentIdx,
            isTakeaway: isTakeaway,
            historyMap: historyMap,
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildBarStep(
            idx: 1,
            currentIdx: currentIdx,
            isTakeaway: isTakeaway,
            historyMap: historyMap,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildBarStep(
            idx: 2,
            currentIdx: currentIdx,
            isTakeaway: isTakeaway,
            historyMap: historyMap,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBarStep({
    required int idx,
    required int currentIdx,
    required bool isTakeaway,
    required Map<int, DateTime?> historyMap,
    required TextAlign textAlign,
  }) {
    final isPast = currentIdx > idx;
    final isCurrent = currentIdx == idx;
    final dt = _timeForStep(idx, isTakeaway, historyMap);
    final label = _labelForStep(idx, isTakeaway);
    final color = _colorForStep(idx, isTakeaway);

    final CrossAxisAlignment colAlign = idx == 0
        ? CrossAxisAlignment.start
        : idx == 2
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: colAlign,
      children: [
        _buildBar(isPast: isPast, isCurrent: isCurrent, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 11,
            color: (isPast || isCurrent) ? _DS.ink : _DS.muted,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dt != null ? _timeOnlyFmt.format(dt) : '—',
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 10,
            color: dt != null ? _DS.stone : _DS.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildBar({
    required bool isPast,
    required bool isCurrent,
    required Color color,
  }) {
    const h = 6.0;
    if (isCurrent) {
      return _ActiveStepBar(color: color, height: h);
    }
    final bg = _isCancelled
        ? _DS.danger.withValues(alpha: 0.35)
        : isPast
            ? _DS.successAccent
            : _DS.hairlineSoft;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
  }
}

// ─── Active step bar (shimmer sweep) ─────────────────────────────────────────
class _ActiveStepBar extends StatelessWidget {
  final Color color;
  final double height;
  const _ActiveStepBar({required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: color.withValues(alpha: 0.22),
      highlightColor: color.withValues(alpha: 0.88),
      period: const Duration(milliseconds: 2800),
      direction: ShimmerDirection.ltr,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

// ─── Items card ──────────────────────────────────────────────────────────────
class _OrderItemsCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  const _OrderItemsCard({required this.order, required this.brandColor});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 16, color: brandColor),
              const SizedBox(width: 8),
              Text(
                'Itens do pedido (${order.items.length})',
                style: const TextStyle(fontSize: 13, color: _DS.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: TextStyle(fontSize: 11, color: brandColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 13, color: _DS.ink),
                        ),
                        if ((item.notes ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.notes!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _DS.stone,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _currFmt.format(item.subtotal),
                    style: const TextStyle(fontSize: 12, color: _DS.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary card ────────────────────────────────────────────────────────────
class _TrackingSummaryCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  const _TrackingSummaryCard({required this.order});

  Widget _row(String label, String value, {bool emphasis = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasis ? 14 : 12,
                color: emphasis ? _DS.ink : _DS.slate,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 16 : 13,
              fontWeight: emphasis ? FontWeight.bold : FontWeight.normal,
              color: emphasis ? _DS.ink : _DS.steel,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        children: [
          _row('Subtotal', _currFmt.format(order.subtotal)),
          _row(
            'Taxa de entrega',
            order.deliveryFee == 0 ? 'Grátis' : _currFmt.format(order.deliveryFee),
          ),
          if (order.discount > 0) _row('Desconto', '- ${_currFmt.format(order.discount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: _DS.hairlineSoft),
          ),
          _row('Total', _currFmt.format(order.total), emphasis: true),
        ],
      ),
    );
  }
}

// ─── Delivery details ────────────────────────────────────────────────────────
class _DeliveryDetailsCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  const _DeliveryDetailsCard({required this.order, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final isPickup = order.deliveryType == 'pickup';
    final hasAddress = (order.deliveryAddress ?? '').isNotEmpty;
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
          Row(
            children: [
              Icon(
                isPickup ? Icons.shopping_bag_outlined : Icons.local_shipping_outlined,
                size: 16,
                color: brandColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPickup ? 'Retirada no local' : 'Entrega',
                  style: const TextStyle(fontSize: 13, color: _DS.ink),
                ),
              ),
              _PickupOrderBadge(isPickup: isPickup),
            ],
          ),
          const SizedBox(height: 8),
          if (isPickup)
            const Text(
              'Você vai retirar este pedido no estabelecimento.',
              style: TextStyle(fontSize: 12, color: _DS.steel, height: 1.4),
            )
          else if (hasAddress)
            Text(
              order.deliveryAddress!,
              style: const TextStyle(fontSize: 12, color: _DS.steel, height: 1.4),
            )
          else
            const Text(
              'Endereço de entrega não informado',
              style: TextStyle(fontSize: 12, color: _DS.steel),
            ),
          if ((order.clientName ?? '').isNotEmpty || (order.clientPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: _DS.hairlineSoft),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline, size: 14, color: _DS.stone),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((order.clientName ?? '').isNotEmpty)
                        Text(
                          order.clientName!,
                          style: const TextStyle(fontSize: 12, color: _DS.ink),
                        ),
                      if ((order.clientPhone ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            order.clientPhone!,
                            style: const TextStyle(fontSize: 11, color: _DS.stone),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Payment details ─────────────────────────────────────────────────────────
class _PaymentDetailsCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  const _PaymentDetailsCard({required this.order, required this.brandColor});

  IconData _iconFor(int? type) {
    switch (type) {
      case 1:
        return Icons.attach_money_rounded;
      case 2:
        return Icons.credit_card_rounded;
      case 3:
        return Icons.account_balance_wallet_rounded;
      case 4:
        return Icons.qr_code_2_rounded;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = order.paymentMethodLabel ?? 'Forma de pagamento';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(order.paymentMethodType), size: 18, color: brandColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forma de pagamento',
                  style: TextStyle(fontSize: 11, color: _DS.stone),
                ),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 13, color: _DS.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────
class _TrackingSkeleton extends StatelessWidget {
  const _TrackingSkeleton();

  static Widget _box({
    double? width,
    required double height,
    double radius = 6,
    BoxShape shape = BoxShape.rectangle,
  }) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
          shape: shape,
        ),
      );

  static Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_DS.rXl),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _DS.hairlineSoft,
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 2600),
      direction: ShimmerDirection.ltr,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Hero card with integrated stepper ─────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(height: 56, width: 56, shape: BoxShape.circle),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(width: 64, height: 10),
                          const SizedBox(height: 10),
                          _box(width: 150, height: 20, radius: 8),
                          const SizedBox(height: 8),
                          _box(height: 11),
                          const SizedBox(height: 4),
                          _box(width: 160, height: 11),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _box(height: 1, radius: 0),
                const SizedBox(height: 18),
                // ── Horizontal stepper skeleton (3 bars) ────────────────────
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _SkeletonBarStep(align: CrossAxisAlignment.start)),
                    SizedBox(width: 2),
                    Expanded(child: _SkeletonBarStep(align: CrossAxisAlignment.center)),
                    SizedBox(width: 2),
                    Expanded(child: _SkeletonBarStep(align: CrossAxisAlignment.end)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Items card ────────────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(height: 16, width: 16, shape: BoxShape.circle),
                    const SizedBox(width: 8),
                    _box(width: 130, height: 13),
                  ],
                ),
                const SizedBox(height: 12),
                _box(height: 12),
                const SizedBox(height: 8),
                _box(height: 12),
                const SizedBox(height: 8),
                _box(width: 200, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Summary ───────────────────────────────────────────────────────
          _card(
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _box(width: 80, height: 11),
                      _box(width: 60, height: 11),
                    ],
                  ),
                  if (i < 2) const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                _box(height: 1, radius: 0),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 60, height: 14),
                    _box(width: 80, height: 14),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Delivery ──────────────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(height: 16, width: 16, shape: BoxShape.circle),
                    const SizedBox(width: 8),
                    _box(width: 70, height: 13),
                  ],
                ),
                const SizedBox(height: 10),
                _box(height: 11),
                const SizedBox(height: 5),
                _box(width: 220, height: 11),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Payment ───────────────────────────────────────────────────────
          _card(
            child: Row(
              children: [
                _box(height: 36, width: 36, radius: 10),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 100, height: 11),
                    const SizedBox(height: 6),
                    _box(width: 140, height: 13),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBarStep extends StatelessWidget {
  final CrossAxisAlignment align;
  const _SkeletonBarStep({required this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 54,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────
class _TrackingError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _TrackingError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 32, color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: _DS.slate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.ink,
                side: const BorderSide(color: _DS.hairline),
                shape: const StadiumBorder(),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing status icon ─────────────────────────────────────────────────────
class _PulsingStatusIcon extends StatefulWidget {
  final _OrderStatusInfo info;
  final bool active;
  const _PulsingStatusIcon({required this.info, required this.active});

  @override
  State<_PulsingStatusIcon> createState() => _PulsingStatusIconState();
}

class _PulsingStatusIconState extends State<_PulsingStatusIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _PulsingStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final core = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: info.bg,
        shape: BoxShape.circle,
        border: Border.all(color: info.fg.withValues(alpha: 0.2)),
      ),
      child: Icon(info.icon, color: info.fg, size: 28),
    );
    if (!widget.active) {
      return SizedBox(width: 56, height: 56, child: core);
    }
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Opacity(
                opacity: (1 - t).clamp(0.0, 0.55),
                child: Container(
                  width: 56 + (28 * t),
                  height: 56 + (28 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: info.fg.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = (_ctrl.value + 0.5) % 1.0;
              return Opacity(
                opacity: (1 - t).clamp(0.0, 0.45),
                child: Container(
                  width: 56 + (28 * t),
                  height: 56 + (28 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: info.fg.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
          core,
        ],
      ),
    );
  }
}

// ─── Live badge with pulsing dot ─────────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  final Color color;
  const _LiveBadge({required this.color});

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: widget.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.4 + 0.6 * _anim.value),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.5 * _anim.value),
                      blurRadius: 4 * _anim.value,
                      spreadRadius: 1 * _anim.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 9,
                  color: widget.color,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Delivery map card (status = 4) ──────────────────────────────────────────
class _DeliveryMapCard extends StatelessWidget {
  final double destinationLat;
  final double destinationLng;
  final double? originLat;
  final double? originLng;
  final Color brandColor;

  const _DeliveryMapCard({
    required this.destinationLat,
    required this.destinationLng,
    required this.originLat,
    required this.originLng,
    required this.brandColor,
  });

  static const _kStaticMapsKey = 'AIzaSyBUxNIZ4yXZZA752jhoEXLI0vBbXZwaaw0';

  String _staticMapUrl() {
    final hasOrigin = originLat != null && originLng != null;
    final markers = hasOrigin
        ? 'markers=color:0x4262FF%7Clabel:R%7C$originLat,$originLng'
            '&markers=color:0xE53935%7Clabel:E%7C$destinationLat,$destinationLng'
            '&path=color:0x4262FF%7Cweight:4%7C$originLat,$originLng%7C$destinationLat,$destinationLng'
        : 'markers=color:0xE53935%7Clabel:E%7C$destinationLat,$destinationLng';
    final center = hasOrigin ? '' : '&center=$destinationLat,$destinationLng&zoom=15';
    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?size=720x320&scale=2$center&$markers&key=$_kStaticMapsKey';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.two_wheeler_rounded, size: 16, color: brandColor),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A caminho até você',
                        style: TextStyle(fontSize: 13, color: _DS.ink),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seu pedido saiu para entrega.',
                        style: TextStyle(fontSize: 11, color: _DS.steel),
                      ),
                    ],
                  ),
                ),
                _LiveBadge(color: brandColor),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _staticMapUrl(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: _DS.surface,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 36, color: _DS.stone),
                    SizedBox(height: 6),
                    Text(
                      'Mapa indisponível no momento',
                      style: TextStyle(fontSize: 11, color: _DS.stone),
                    ),
                  ],
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: _DS.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _DS.stone,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
