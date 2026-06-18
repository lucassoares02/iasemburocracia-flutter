part of 'public_order_page.dart';

// ─── History screen ──────────────────────────────────────────────────────────
class _HistoryScreen extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<PublicOrderDetailModel> orders;
  final Color brandColor;
  final String? customerName;
  final VoidCallback onBack;
  final void Function(PublicOrderDetailModel order) onOpenOrder;
  final Future<void> Function() onRetry;
  final Future<void> Function(int orderId)? onReorder;

  const _HistoryScreen({
    required this.loading,
    required this.error,
    required this.orders,
    required this.brandColor,
    required this.customerName,
    required this.onBack,
    required this.onOpenOrder,
    required this.onRetry,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HistoryHeader(
          customerName: customerName,
          brandColor: brandColor,
          onBack: onBack,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const _HistorySkeleton()
                : error != null
                    ? _HistoryError(message: error!, onRetry: onRetry)
                    : orders.isEmpty
                        ? const _HistoryEmpty()
                        : RefreshIndicator(
                            color: brandColor,
                            onRefresh: onRetry,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => _HistoryCard(
                                order: orders[i],
                                brandColor: brandColor,
                                onTap: () => onOpenOrder(orders[i]),
                                onReorder: onReorder,
                              ),
                            ),
                          ),
          ),
        ),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final String? customerName;
  final Color brandColor;
  final VoidCallback onBack;
  const _HistoryHeader({
    required this.customerName,
    required this.brandColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 28, 16, 18),
      decoration: const BoxDecoration(
        color: _DS.canvas,
        border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: _DS.ink),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName != null ? 'Olá, ${customerName!.split(' ').first}' : 'Histórico',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.steel,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Meus pedidos',
                  style: TextStyle(
                    fontSize: 18,
                    color: _DS.ink,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, size: 12, color: brandColor),
                const SizedBox(width: 4),
                Text(
                  'Histórico',
                  style: TextStyle(
                    fontSize: 11,
                    color: brandColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  final VoidCallback onTap;
  final Future<void> Function(int orderId)? onReorder;

  const _HistoryCard({
    required this.order,
    required this.brandColor,
    required this.onTap,
    this.onReorder,
  });

  String get _dateLabel {
    final dt = order.createdAt;
    if (dt == null) return '—';
    return _orderDateFmt.format(dt);
  }

  String get _itemsSummary {
    final count = order.items.length;
    final totalQty = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final label = count == 1 ? 'item' : 'itens';
    return '$count $label · $totalQty un.';
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(order.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_DS.rXl),
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
              Row(
                children: [
                  _CompanyAvatar(
                    logoUrl: order.logoUrl,
                    companyName: order.companyName,
                    brandColor: brandColor,
                    statusInfo: info,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pedido ${order.tag ?? '#${order.id}'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _DS.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: info.bg,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                info.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: info.fg,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.stone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currFmt.format(order.total),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _DS.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _itemsSummary,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _DS.stone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: _DS.hairlineSoft),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: order.items.take(3).map((it) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _DS.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _DS.hairlineSoft),
                      ),
                      child: Text(
                        '${it.quantity}× ${it.name}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _DS.slate,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(order.items.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: brandColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '+${order.items.length - 3}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: brandColor,
                                ),
                              ),
                            ),
                          ]
                        : []),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onReorder != null)
                    _ReorderButton(
                      orderId: order.id,
                      brandColor: brandColor,
                      onReorder: onReorder!,
                      style: _ReorderButtonStyle.compact,
                    ),
                  const Spacer(),
                  Text(
                    'Ver detalhes',
                    style: TextStyle(
                      fontSize: 11,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: brandColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
      ),
    );
  }
}

// ─── Empty ───────────────────────────────────────────────────────────────────
class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: _DS.stone,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum pedido por aqui',
              style: TextStyle(
                fontSize: 16,
                color: _DS.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Faça seu primeiro pedido e ele aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _DS.steel,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────────────
class _HistoryError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _HistoryError({required this.message, required this.onRetry});

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

// ─── Company avatar with status badge ────────────────────────────────────────
class _CompanyAvatar extends StatelessWidget {
  final String? logoUrl;
  final String? companyName;
  final Color brandColor;
  final _OrderStatusInfo statusInfo;

  const _CompanyAvatar({
    required this.logoUrl,
    required this.companyName,
    required this.brandColor,
    required this.statusInfo,
  });

  String get _initials {
    final name = (companyName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.hairlineSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? CachedNetworkImage(
                    imageUrl: logoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: brandColor.withValues(alpha: 0.08),
                    ),
                    errorWidget: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: statusInfo.bg,
                shape: BoxShape.circle,
                border: Border.all(color: _DS.canvas, width: 2),
              ),
              child: Icon(statusInfo.icon, size: 10, color: statusInfo.fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 14,
          color: brandColor,
        ),
      ),
    );
  }
}
