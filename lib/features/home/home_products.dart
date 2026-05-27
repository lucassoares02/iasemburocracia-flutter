part of 'home_page.dart';

// ─── Products section ─────────────────────────────────────────────────────────
class _ProductsSection extends StatelessWidget {
  final ProductsSectionModel? products;
  final bool wide;
  final bool medium;
  const _ProductsSection({
    required this.products,
    required this.wide,
    required this.medium,
  });

  @override
  Widget build(BuildContext context) {
    final p = products;
    final hasTop = p?.topSeller != null;
    final hasWorst = p?.worstSeller != null;
    final withoutSales = p?.withoutSales ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Performance de produtos',
          subtitle: 'Análise dos últimos 30 dias',
          icon: LucideIcons.package,
          iconColor: _DS.brandBlue,
        ),
        if (!hasTop && !hasWorst && withoutSales.isEmpty)
          _Card(
            child: _SectionEmpty(
              icon: LucideIcons.package,
              message: 'Ainda não há dados suficientes para análise.',
            ),
          )
        else
          Flex(
            direction: medium ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: medium ? 1 : 0,
                child: _ProductCard(
                  badge: 'Mais vendido',
                  badgeColor: _DS.successAccent,
                  product: p?.topSeller,
                  fallbackMessage: 'Sem vendas no período',
                  showRevenue: true,
                ),
              ),
              SizedBox(width: medium ? 12 : 0, height: medium ? 0 : 12),
              Expanded(
                flex: medium ? 1 : 0,
                child: _ProductCard(
                  badge: 'Menos vendido',
                  badgeColor: _DS.warningAccent,
                  product: p?.worstSeller,
                  fallbackMessage: 'Sem dados',
                  showRevenue: false,
                ),
              ),
              SizedBox(width: medium ? 12 : 0, height: medium ? 0 : 12),
              Expanded(
                flex: medium ? 1 : 0,
                child: _WithoutSalesCard(items: withoutSales),
              ),
            ],
          ),
      ],
    );
  }
}

// ─── Single product card (top / worst) ────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final ProductSummaryEntity? product;
  final String fallbackMessage;
  final bool showRevenue;
  const _ProductCard({
    required this.badge,
    required this.badgeColor,
    required this.product,
    required this.fallbackMessage,
    required this.showRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                color: badgeColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (product == null) ...[
            _SectionEmpty(
              icon: LucideIcons.imageOff,
              message: fallbackMessage,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _productImage(product?.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? '—',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _DS.ink,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.package, size: 12, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${product?.quantitySold ?? 0} unidades',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _DS.slate,
                            ),
                          ),
                        ],
                      ),
                      if (showRevenue && (product?.revenue ?? 0) > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currFmt.format(product?.revenue ?? 0),
                          style: const TextStyle(
                            fontSize: 14,
                            color: _DS.ink,
                          ),
                        ),
                      ],
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

  Widget _productImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.fastfood_outlined, size: 28, color: _DS.muted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fastfood_outlined, size: 28, color: _DS.muted),
        ),
      ),
    );
  }
}

// ─── Without sales card ───────────────────────────────────────────────────────
class _WithoutSalesCard extends StatelessWidget {
  final List<ProductSummaryEntity> items;
  const _WithoutSalesCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _DS.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Sem vendas',
              style: TextStyle(
                fontSize: 11,
                color: _DS.danger,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            _SectionEmpty(
              icon: LucideIcons.checkCircle,
              message: 'Todos os produtos estão vendendo!',
            )
          else ...[
            Text(
              '${items.length} ${items.length == 1 ? "produto" : "produtos"} sem movimento',
              style: const TextStyle(
                fontSize: 12,
                color: _DS.steel,
              ),
            ),
            const SizedBox(height: 12),
            ...items.take(4).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      _mini(p.imageUrl),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name ?? '—',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _DS.slate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            if (items.length > 4)
              Text(
                '+${items.length - 4} outros',
                style: const TextStyle(
                  fontSize: 11,
                  color: _DS.stone,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _mini(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.fastfood_outlined, size: 14, color: _DS.muted),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 26,
        height: 26,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 26,
          height: 26,
          color: _DS.surface,
          child: const Icon(Icons.fastfood_outlined, size: 14, color: _DS.muted),
        ),
      ),
    );
  }
}
