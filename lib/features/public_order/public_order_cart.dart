part of 'public_order_page.dart';

// ─── Cart screen ──────────────────────────────────────────────────────────────
class _CartScreen extends StatelessWidget {
  final List<_PubCartItem> cart;
  final Color brandColor;
  final VoidCallback onBack;
  final void Function(String cartKey, int qty) onUpdateQty;
  final void Function(String cartKey) onRemove;
  final VoidCallback onContinue;
  final double? minOrderValue;
  final List<Map<String, dynamic>> upsellItems;
  final String? upsellDescription;
  final void Function(Map<String, dynamic>, double, double) onAddUpsell;
  final _DeliveryType deliveryType;
  final ValueChanged<_DeliveryType> onDeliveryTypeChange;
  final bool allowDelivery;
  final bool allowPickup;
  final PublicCompanyAddressModel? companyAddress;
  final String companyName;
  final int? avgPrepMinutes;

  const _CartScreen({
    required this.cart,
    required this.brandColor,
    required this.onBack,
    required this.onUpdateQty,
    required this.onRemove,
    required this.onContinue,
    this.minOrderValue,
    this.upsellItems = const [],
    this.upsellDescription,
    required this.onAddUpsell,
    required this.deliveryType,
    required this.onDeliveryTypeChange,
    this.allowDelivery = true,
    this.allowPickup = true,
    required this.companyAddress,
    required this.companyName,
    required this.avgPrepMinutes,
  });

  double get _subtotal => cart.fold(0, (s, c) => s + c.subtotal);
  bool get _belowMinimum => minOrderValue != null && minOrderValue! > 0 && _subtotal < minOrderValue!;
  int get _totalItems => cart.fold<int>(0, (s, c) => s + c.quantity);

  /// Economia bruta = soma dos descontos vs preço original de cada linha.
  /// Cobre purchase goals (originalPrice) e upsell rules (originalPrice).
  double get _savings {
    var sum = 0.0;
    for (final c in cart) {
      final orig = c.originalPrice;
      if (orig != null && orig > c.unitPrice) {
        sum += (orig - c.unitPrice) * c.quantity;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final hasUpsell = upsellItems.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: cart.isEmpty
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _InlineBackArrow(onBack: onBack),
                    ),
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 48, color: _DS.muted),
                            SizedBox(height: 12),
                            Text('Carrinho vazio', style: TextStyle(fontSize: 15, color: _DS.slate)),
                            SizedBox(height: 4),
                            Text('Adicione produtos para continuar', style: TextStyle(fontSize: 13, color: _DS.stone)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Seta de voltar no nível das informações
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _InlineBackArrow(onBack: onBack),
                    ),
                    // ── Chips de destaque (itens · tempo · economia) ────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: _CartHighlightsRow(
                        totalItems: _totalItems,
                        avgPrepMinutes: avgPrepMinutes,
                        savings: _savings,
                        isPickup: deliveryType == _DeliveryType.pickup,
                        brandColor: brandColor,
                      ),
                    ),
                    // ── Seletor Entrega / Retirada ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: _DeliveryTypeSelector(
                        current: deliveryType,
                        brandColor: brandColor,
                        onChange: onDeliveryTypeChange,
                        allowDelivery: allowDelivery,
                        allowPickup: allowPickup,
                      ),
                    ),
                    if (deliveryType == _DeliveryType.pickup) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _PickupInfoCard(
                          address: companyAddress,
                          companyName: companyName,
                          brandColor: brandColor,
                          avgPrepMinutes: avgPrepMinutes,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // ── Cart items ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        children: [
                          for (var i = 0; i < cart.length; i++) ...[
                            _CartItemRow(
                              item: cart[i],
                              brandColor: brandColor,
                              onIncrement: () => onUpdateQty(cart[i].cartKey, cart[i].quantity + 1),
                              onDecrement: () => onUpdateQty(cart[i].cartKey, cart[i].quantity - 1),
                              onRemove: () => onRemove(cart[i].cartKey),
                            ),
                            if (i < cart.length - 1) const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        ),

        // ── Upsell section (fixo acima do footer) ─────────────────────────
        if (cart.isNotEmpty && hasUpsell)
          Container(
            decoration: const BoxDecoration(
              color: _DS.canvas,
              border: Border(top: BorderSide(color: _DS.hairlineSoft)),
            ),
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: _CartUpsellSection(
              items: upsellItems,
              description: upsellDescription,
              brandColor: brandColor,
              onAdd: onAddUpsell,
            ),
          ),

        // ── Footer: subtotal + continuar ──────────────────────────────────
        if (cart.isNotEmpty)
          _CartFooter(
            subtotal: _subtotal,
            brandColor: brandColor,
            belowMinimum: _belowMinimum,
            minOrderValue: minOrderValue,
            onContinue: onContinue,
          ),
      ],
    );
  }
}

// ─── Cart footer (subtotal + continuar) ──────────────────────────────────────
class _CartFooter extends StatelessWidget {
  final double subtotal;
  final Color brandColor;
  final bool belowMinimum;
  final double? minOrderValue;
  final VoidCallback onContinue;

  const _CartFooter({
    required this.subtotal,
    required this.brandColor,
    required this.belowMinimum,
    required this.minOrderValue,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _DS.canvas,
        border: Border(top: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Subtotal', style: TextStyle(fontSize: 14, color: _DS.steel)),
              const Spacer(),
              Text(_currFmt.format(subtotal), style: const TextStyle(fontSize: 15, color: _DS.ink)),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            width: double.infinity,
            child: FilledButton(
              onPressed: belowMinimum ? null : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: brandColor,
                disabledBackgroundColor: _DS.hairline,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: belowMinimum
                    ? Text(
                        key: const ValueKey('blocked'),
                        'Adicione mais ${_currFmt.format((minOrderValue ?? 0) - subtotal)} para continuar',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _DS.slate,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        key: const ValueKey('ok'),
                        'Continuar',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de chips: itens · tempo · economia ────────────────────────────────
class _CartHighlightsRow extends StatelessWidget {
  final int totalItems;
  final int? avgPrepMinutes;
  final double savings;
  final bool isPickup;
  final Color brandColor;

  const _CartHighlightsRow({
    required this.totalItems,
    required this.avgPrepMinutes,
    required this.savings,
    required this.isPickup,
    required this.brandColor,
  });

  String? get _prepLabel {
    if (avgPrepMinutes == null || avgPrepMinutes! <= 0) return null;
    final low = (avgPrepMinutes! - 5).clamp(5, 999);
    final high = avgPrepMinutes! + 10;
    return '$low–$high min';
  }

  @override
  Widget build(BuildContext context) {
    final hasSavings = savings > 0.009;
    final prep = _prepLabel;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _CartChip(
          icon: Icons.shopping_bag_outlined,
          label: '$totalItems ${totalItems == 1 ? "item" : "itens"}',
          fg: _DS.slate,
          bg: _DS.surface,
        ),
        if (prep != null)
          _CartChip(
            icon: isPickup ? Icons.storefront_rounded : Icons.timer_outlined,
            label: isPickup ? 'Pronto em $prep' : 'Entrega em $prep',
            fg: brandColor,
            bg: brandColor.withValues(alpha: 0.08),
          ),
        if (hasSavings)
          _CartChip(
            icon: Icons.savings_outlined,
            label: 'Você economiza ${_currFmt.format(savings)}',
            fg: _DS.successAccent,
            bg: const Color(0xFFE9FBF3),
            bold: true,
          ),
      ],
    );
  }
}

class _CartChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final bool bold;

  const _CartChip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
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
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart upsell section ──────────────────────────────────────────────────────
class _CartUpsellSection extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? description;
  final Color brandColor;
  final void Function(Map<String, dynamic>, double, double) onAdd;

  const _CartUpsellSection({
    required this.items,
    required this.description,
    required this.brandColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: brandColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  description?.isNotEmpty == true ? description! : 'Complete seu pedido',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _DS.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 192,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final it = items[i];
              final origPrice = (it['item_price'] as num?)?.toDouble() ?? 0;
              final finalPrice = (it['final_price'] as num?)?.toDouble() ?? origPrice;
              final pct = (it['discount_percent'] as num?)?.toDouble() ?? 0;
              final name = it['item_name'] as String? ?? '';
              final imgUrl = it['item_image_url'] as String?;

              return _UpsellCard(
                name: name,
                imageUrl: imgUrl,
                originalPrice: origPrice,
                finalPrice: finalPrice,
                discountPercent: pct,
                brandColor: brandColor,
                onAdd: () => onAdd(it, finalPrice, origPrice),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Upsell card (premium, animated) ─────────────────────────────────────────
class _UpsellCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final double originalPrice;
  final double finalPrice;
  final double discountPercent;
  final Color brandColor;
  final VoidCallback onAdd;

  const _UpsellCard({
    required this.name,
    required this.imageUrl,
    required this.originalPrice,
    required this.finalPrice,
    required this.discountPercent,
    required this.brandColor,
    required this.onAdd,
  });

  @override
  State<_UpsellCard> createState() => _UpsellCardState();
}

class _UpsellCardState extends State<_UpsellCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    if (!mounted) return;
    widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.discountPercent > 0 && widget.originalPrice > widget.finalPrice;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleAdd,
        child: Container(
          width: 146,
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + discount badge
              Stack(
                children: [
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: (widget.imageUrl ?? '').isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: _DS.surface),
                            errorWidget: (_, __, ___) => Container(
                              color: _DS.surface,
                              child: const Icon(Icons.fastfood_outlined, color: _DS.muted, size: 26),
                            ),
                          )
                        : Container(
                            color: _DS.surface,
                            child: const Icon(Icons.fastfood_outlined, color: _DS.muted, size: 26),
                          ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4C4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(fontSize: 9, color: Color(0xFF746019)),
                        ),
                      ),
                    ),
                ],
              ),
              // Name + pricing + CTA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(fontSize: 11, color: _DS.ink, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (hasDiscount)
                        Text(
                          _currFmt.format(widget.originalPrice),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: _DS.stone,
                            decoration: TextDecoration.lineThrough,
                            height: 1.2,
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currFmt.format(widget.finalPrice),
                              style: const TextStyle(fontSize: 12, color: _DS.ink),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: widget.brandColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, size: 15, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cart item row ────────────────────────────────────────────────────────────
class _CartItemRow extends StatelessWidget {
  final _PubCartItem item;
  final Color brandColor;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  const _CartItemRow({
    required this.item,
    required this.brandColor,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(_DS.rXl), border: Border.all(color: _DS.hairlineSoft)),
      child: Row(
        children: [
          if ((item.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.imageUrl!, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()),
            )
          else
            _placeholder(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 13, color: _DS.ink)),
                if (item.purchaseGoalId != null && (item.goalDiscountPercentage ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 10, color: brandColor),
                          const SizedBox(width: 3),
                          Text(
                            'Objetivo • ${item.goalDiscountPercentage!.toStringAsFixed(item.goalDiscountPercentage!.truncateToDouble() == item.goalDiscountPercentage ? 0 : 1)}% OFF',
                            style: TextStyle(fontSize: 10, color: brandColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (item.options.isNotEmpty) _buildOptionsBreakdown(item),
                if ((item.notes ?? '').isNotEmpty) Text(item.notes!, style: const TextStyle(fontSize: 11, color: _DS.stone), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item.originalPrice != null && item.originalPrice! > item.unitPrice)
                  Text(
                    _currFmt.format(item.originalPrice!),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _DS.stone,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyControl(
                      qty: item.quantity,
                      brandColor: brandColor,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
                    ),
                    const Spacer(),
                    Text(_currFmt.format(item.subtotal), style: const TextStyle(fontSize: 13, color: _DS.ink)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 16, color: _DS.stone)),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.fastfood_outlined, size: 22, color: _DS.muted),
      );

  Widget _buildOptionsBreakdown(_PubCartItem item) {
    final byGroup = <String, List<_PubCartOption>>{};
    for (final o in item.options) {
      byGroup.putIfAbsent(o.groupName, () => []).add(o);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in byGroup.entries) ...[
            Text(
              '${entry.key}:',
              style: const TextStyle(
                fontSize: 10.5,
                color: _DS.slate,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            for (final o in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 1, left: 6),
                child: Text(
                  o.quantity > 1
                      ? '• ${o.optionName} ×${o.quantity}${o.additionalPrice > 0 ? '  (+${_currFmt.format(o.total)})' : ''}'
                      : '• ${o.optionName}${o.additionalPrice > 0 ? '  (+${_currFmt.format(o.additionalPrice)})' : ''}',
                  style: const TextStyle(fontSize: 11, color: _DS.steel, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final Color brandColor;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QtyControl({
    required this.qty,
    required this.brandColor,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(99), border: Border.all(color: _DS.hairline)),
            child: const Icon(Icons.remove, size: 13, color: _DS.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$qty', style: const TextStyle(fontSize: 13, color: _DS.ink)),
        ),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
