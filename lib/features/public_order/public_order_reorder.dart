part of 'public_order_page.dart';

/// Primary CTA used in the tracking screen and history cards to repeat a
/// previous order with one click. Owns its own loading state so the user gets
/// instant feedback while the backend validates against current menu state.
class _ReorderButton extends StatefulWidget {
  const _ReorderButton({
    required this.orderId,
    required this.brandColor,
    required this.onReorder,
    this.style = _ReorderButtonStyle.filled,
    this.label = 'Pedir novamente',
    this.icon = Icons.refresh_rounded,
  });

  final int orderId;
  final Color brandColor;
  final Future<void> Function(int orderId) onReorder;
  final _ReorderButtonStyle style;
  final String label;
  final IconData icon;

  @override
  State<_ReorderButton> createState() => _ReorderButtonState();
}

enum _ReorderButtonStyle { filled, soft, compact }

class _ReorderButtonState extends State<_ReorderButton> {
  bool _loading = false;

  Future<void> _trigger() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onReorder(widget.orderId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case _ReorderButtonStyle.filled:
        return _buildFilled();
      case _ReorderButtonStyle.soft:
        return _buildSoft();
      case _ReorderButtonStyle.compact:
        return _buildCompact();
    }
  }

  Widget _buildFilled() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : _trigger,
        style: FilledButton.styleFrom(
          backgroundColor: widget.brandColor,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _label(Colors.white),
      ),
    );
  }

  Widget _buildSoft() {
    return OutlinedButton(
      onPressed: _loading ? null : _trigger,
      style: OutlinedButton.styleFrom(
        foregroundColor: widget.brandColor,
        side: BorderSide(color: widget.brandColor.withValues(alpha: 0.4)),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: _label(widget.brandColor),
    );
  }

  Widget _buildCompact() {
    return Material(
      color: widget.brandColor.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: _loading ? null : _trigger,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniIcon(),
              const SizedBox(width: 6),
              Text(
                _loading ? 'Adicionando...' : widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: widget.brandColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _loading
          ? Row(
              key: const ValueKey('loading'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Validando itens...',
                  style: TextStyle(fontSize: 14, color: color),
                ),
              ],
            )
          : Row(
              key: const ValueKey('idle'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 14, color: color),
                ),
              ],
            ),
    );
  }

  Widget _miniIcon() {
    if (_loading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(widget.brandColor),
        ),
      );
    }
    return Icon(widget.icon, size: 13, color: widget.brandColor);
  }
}

/// Modal that explains exactly what was added to the cart and what was
/// skipped. Shown when the order has unavailable items or no valid items.
class _ReorderSummarySheet extends StatelessWidget {
  const _ReorderSummarySheet({
    required this.result,
    required this.brandColor,
    required this.onGoToCart,
  });

  final ReorderResultModel result;
  final Color brandColor;
  final VoidCallback onGoToCart;

  @override
  Widget build(BuildContext context) {
    final hasValid = result.validItems.isNotEmpty;
    final hasUnavailable = result.unavailable.isNotEmpty;
    final headlineColor = hasValid ? brandColor : _DS.danger;
    final headline = hasValid
        ? (hasUnavailable ? 'Adicionamos ${result.itemsCount} ${result.itemsCount == 1 ? 'item' : 'itens'} ao seu carrinho 🚀' : 'Pedido adicionado ao carrinho 🚀')
        : 'Não conseguimos repetir esse pedido';

    return Container(
      decoration: const BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _DS.hairline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: headlineColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasValid ? Icons.shopping_bag_rounded : Icons.error_outline_rounded,
                      color: headlineColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _DS.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasValid && hasUnavailable) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    'Alguns itens do pedido anterior não estão mais disponíveis.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _DS.steel,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasValid) _validList(),
                      if (hasValid && hasUnavailable) const SizedBox(height: 16),
                      if (hasUnavailable) _unavailableList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hasValid) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brandColor.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal estimado',
                          style: TextStyle(
                            fontSize: 12,
                            color: _DS.slate,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Text(
                        _currFmt.format(result.subtotalPreview),
                        style: TextStyle(
                          fontSize: 15,
                          color: brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onGoToCart,
                    style: FilledButton.styleFrom(
                      backgroundColor: brandColor,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                    label: const Text(
                      'Ir para o carrinho',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onGoToCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.ink,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _validList() {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: brandColor),
                const SizedBox(width: 6),
                Text(
                  'Adicionados ao carrinho',
                  style: TextStyle(fontSize: 11.5, color: brandColor),
                ),
              ],
            ),
          ),
          for (var i = 0; i < result.validItems.length; i++) _validRow(result.validItems[i], i == result.validItems.length - 1),
        ],
      ),
    );
  }

  Widget _validRow(ReorderValidItem item, bool isLast) {
    final hasDrops = item.droppedOptions.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(item.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}× ${item.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.ink,
                  ),
                ),
                if (item.options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.options.map((o) {
                        final qty = (o['quantity'] as num?)?.toInt() ?? 1;
                        final name = (o['option_name'] ?? '').toString();
                        return qty > 1 ? '$name ×$qty' : name;
                      }).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _DS.steel,
                        height: 1.35,
                      ),
                    ),
                  ),
                if (hasDrops)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFFEF3C7)),
                      ),
                      child: Text(
                        '${item.droppedOptions.length} complemento${item.droppedOptions.length == 1 ? '' : 's'} indisponível',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currFmt.format(item.subtotal),
            style: const TextStyle(
              fontSize: 13,
              color: _DS.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unavailableList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(Icons.report_problem_rounded, size: 14, color: _DS.danger),
                SizedBox(width: 6),
                Text(
                  'Não estão mais disponíveis',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _DS.danger,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < result.unavailable.length; i++) _unavailableRow(result.unavailable[i], i == result.unavailable.length - 1),
        ],
      ),
    );
  }

  Widget _unavailableRow(ReorderUnavailableItem item, bool isLast) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFFEE2E2))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(item.imageUrl, faded: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.quantity}× ${item.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.slate,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: _DS.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.message,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String? url, {bool faded = false}) {
    final placeholder = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood_outlined, size: 18, color: _DS.muted),
    );
    if (url == null || url.isEmpty) return placeholder;
    return Opacity(
      opacity: faded ? 0.5 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}
