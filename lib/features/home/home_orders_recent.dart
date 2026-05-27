part of 'home_page.dart';

// ─── Bottom row: recent orders + customer insights ────────────────────────────
class _BottomRow extends StatelessWidget {
  final List<RecentOrderModel> recentOrders;
  final ClientsSectionModel? clients;
  final Color brand;
  final bool wide;
  final bool medium;
  const _BottomRow({
    required this.recentOrders,
    required this.clients,
    required this.brand,
    required this.wide,
    required this.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (medium) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _RecentOrdersCard(orders: recentOrders, brand: brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _CustomerInsightsCard(clients: clients, brand: brand),
          ),
        ],
      );
    }
    return Column(
      children: [
        _RecentOrdersCard(orders: recentOrders, brand: brand),
        const SizedBox(height: 12),
        _CustomerInsightsCard(clients: clients, brand: brand),
      ],
    );
  }
}

// ─── Recent orders card ───────────────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  final List<RecentOrderModel> orders;
  final Color brand;
  const _RecentOrdersCard({required this.orders, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Últimas vendas',
          subtitle: 'Pedidos mais recentes',
          icon: LucideIcons.history,
          iconColor: _DS.brandBlue,
        ),
        _Card(
          padding: EdgeInsets.zero,
          child: orders.isEmpty
              ? _SectionEmpty(
                  icon: LucideIcons.shoppingBag,
                  message: 'Nenhum pedido ainda',
                )
              : Column(
                  children: List.generate(orders.length, (i) {
                    final o = orders[i];
                    return _OrderRow(
                      order: o,
                      brand: brand,
                      showDivider: i < orders.length - 1,
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

class _OrderRow extends StatefulWidget {
  final RecentOrderModel order;
  final Color brand;
  final bool showDivider;
  const _OrderRow({
    required this.order,
    required this.brand,
    required this.showDivider,
  });

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final color = _statusColor(o.status);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hover ? _DS.surface : Colors.transparent,
          border: widget.showDivider ? const Border(bottom: BorderSide(color: _DS.hairlineSoft)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.brand.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _initials(o.clientName),
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.brand,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.clientName ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _DS.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currFmt.format(o.total ?? 0),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DS.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusChip(o.status, color),
                      const SizedBox(width: 8),
                      Text(
                        '#${o.id ?? '—'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _DS.stone,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.package, size: 11, color: _DS.muted),
                      const SizedBox(width: 3),
                      Text(
                        '${o.itemsCount} itens',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _DS.stone,
                        ),
                      ),
                      const Spacer(),
                      if (o.createdAt != null)
                        Text(
                          _timeFmt.format(o.createdAt!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.stone,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String? status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
