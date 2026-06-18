part of 'public_order_page.dart';

// ─── Seletor "Entrega / Retirada" — segmented control premium ────────────────
class _DeliveryTypeSelector extends StatelessWidget {
  final _DeliveryType current;
  final Color brandColor;
  final ValueChanged<_DeliveryType> onChange;
  final bool dense;
  final bool allowDelivery;
  final bool allowPickup;

  const _DeliveryTypeSelector({
    required this.current,
    required this.brandColor,
    required this.onChange,
    this.dense = false,
    this.allowDelivery = true,
    this.allowPickup = true,
  });

  @override
  Widget build(BuildContext context) {
    // Quando a empresa aceita apenas um método, mostra somente aquele pill
    // (já ativo e travado) — não há o que alternar.
    final pills = <Widget>[
      if (allowDelivery)
        Expanded(
          child: _DeliveryTypePill(
            icon: Icons.delivery_dining_rounded,
            label: 'Entrega',
            active: current == _DeliveryType.delivery,
            brandColor: brandColor,
            dense: dense,
            onTap: () => onChange(_DeliveryType.delivery),
          ),
        ),
      if (allowDelivery && allowPickup) const SizedBox(width: 4),
      if (allowPickup)
        Expanded(
          child: _DeliveryTypePill(
            icon: Icons.shopping_bag_outlined,
            label: 'Retirar no local',
            active: current == _DeliveryType.pickup,
            brandColor: brandColor,
            dense: dense,
            onTap: () => onChange(_DeliveryType.pickup),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairline),
      ),
      child: Row(children: pills),
    );
  }
}

class _DeliveryTypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color brandColor;
  final bool dense;
  final VoidCallback onTap;

  const _DeliveryTypePill({
    required this.icon,
    required this.label,
    required this.active,
    required this.brandColor,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = dense ? 8.0 : 10.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: vPad),
        decoration: BoxDecoration(
          color: active ? brandColor : Colors.transparent,
          borderRadius: BorderRadius.circular(_DS.rFull),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: dense ? 14 : 16,
              color: active ? Colors.white : _DS.steel,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dense ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : _DS.steel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de informações da retirada ─────────────────────────────────────────
class _PickupInfoCard extends StatelessWidget {
  final PublicCompanyAddressModel? address;
  final String companyName;
  final Color brandColor;
  final int? avgPrepMinutes;
  final bool showFreeBadge;

  const _PickupInfoCard({
    required this.address,
    required this.companyName,
    required this.brandColor,
    this.avgPrepMinutes,
    this.showFreeBadge = true,
  });

  String get _formattedAddress {
    final a = address;
    if (a == null) return 'Endereço da loja indisponível';
    final fa = a.formattedAddress;
    if (fa != null && fa.isNotEmpty) return fa;
    final parts = <String>[];
    if ((a.street ?? '').isNotEmpty) {
      parts.add(a.number != null && (a.number ?? '').isNotEmpty
          ? '${a.street}, ${a.number}'
          : a.street!);
    }
    if ((a.neighborhood ?? '').isNotEmpty) parts.add(a.neighborhood!);
    if ((a.city ?? '').isNotEmpty) parts.add(a.city!);
    if ((a.state ?? '').isNotEmpty) parts.add(a.state!);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String? get _prepLabel {
    if (avgPrepMinutes == null || avgPrepMinutes! <= 0) return null;
    final low = (avgPrepMinutes! - 5).clamp(5, 999);
    final high = avgPrepMinutes! + 10;
    return 'Pronto em $low–$high min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(_DS.rLg),
                ),
                child: Icon(Icons.storefront_rounded, size: 18, color: brandColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retirar no local',
                      style: TextStyle(
                        fontSize: 11,
                        color: _DS.stone,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DS.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showFreeBadge) const _PickupFreeBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 14, color: _DS.stone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formattedAddress,
                  style: const TextStyle(fontSize: 12, color: _DS.slate, height: 1.4),
                ),
              ),
            ],
          ),
          if (_prepLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: _DS.stone),
                const SizedBox(width: 8),
                Text(
                  _prepLabel!,
                  style: const TextStyle(fontSize: 12, color: _DS.slate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupFreeBadge extends StatelessWidget {
  const _PickupFreeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FBF3),
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.successAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 11, color: _DS.successAccent),
          SizedBox(width: 3),
          Text(
            'Sem taxa',
            style: TextStyle(
              fontSize: 10,
              color: _DS.successAccent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge "Retirada" para mostrar nos detalhes do pedido ────────────────────
class _PickupOrderBadge extends StatelessWidget {
  final bool isPickup;
  const _PickupOrderBadge({required this.isPickup});

  @override
  Widget build(BuildContext context) {
    final fg = isPickup ? const Color(0xFFB45309) : const Color(0xFF4262FF);
    final bg = isPickup ? const Color(0xFFFEF3C7) : const Color(0xFFEEF3FF);
    final icon = isPickup ? Icons.shopping_bag_outlined : Icons.delivery_dining_rounded;
    final label = isPickup ? 'Retirada no local' : 'Entrega';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
