part of 'public_order_page.dart';

// ─── Bottom-sheet de sugestão de objetivo ────────────────────────────────────
//
// Mostrado entre a etapa de carrinho e o checkout (pagamento). Exibe 1 produto
// por vez, sugerido pelo backend, com preço original riscado, preço com
// desconto e CTA premium para adicionar ao pedido.
//
// Quando o cliente aceita, o produto entra no carrinho com purchaseGoalId e
// goalDiscountPercentage. Em seguida o controller recalcula categorias do
// carrinho e pede a próxima sugestão.

class _GoalSuggestionSheet extends StatefulWidget {
  final PurchaseGoalSuggestionModel suggestion;
  final Color brandColor;
  /// Retorna a quantidade aceita ou null se o cliente recusou.
  final Future<bool> Function(int quantity) onAccept;
  final VoidCallback onSkip;

  const _GoalSuggestionSheet({
    required this.suggestion,
    required this.brandColor,
    required this.onAccept,
    required this.onSkip,
  });

  @override
  State<_GoalSuggestionSheet> createState() => _GoalSuggestionSheetState();
}

class _GoalSuggestionSheetState extends State<_GoalSuggestionSheet> with TickerProviderStateMixin {
  int _qty = 1;
  bool _adding = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack),
    );
    _scaleCtrl.forward();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_adding) return;
    setState(() => _adding = true);
    final ok = await widget.onAccept(_qty);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _adding = false);
    }
  }

  void _skip() {
    if (_adding) return;
    widget.onSkip();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final hasImg = (s.productImageUrl ?? '').isNotEmpty;
    final pctLabel = s.discountPercentage.truncateToDouble() == s.discountPercentage
        ? s.discountPercentage.toStringAsFixed(0)
        : s.discountPercentage.toStringAsFixed(1).replaceAll('.', ',');

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: _DS.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (_, __) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.brandColor.withValues(alpha: 0.18 + 0.08 * _shimmerCtrl.value),
                                widget.brandColor.withValues(alpha: 0.30 + 0.10 * _shimmerCtrl.value),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 12, color: widget.brandColor),
                              const SizedBox(width: 4),
                              Text(
                                s.goalName.toUpperCase(),
                                style: TextStyle(fontSize: 10, color: widget.brandColor, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _skip,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _DS.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: _DS.steel),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Hero da sugestão
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: hasImg
                            ? Image.network(
                                s.productImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackImg(),
                              )
                            : _fallbackImg(),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.brandColor,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: widget.brandColor.withValues(alpha: 0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$pctLabel% OFF',
                          style: const TextStyle(fontSize: 12, color: Colors.white, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              s.missingCategoryName,
                              style: const TextStyle(fontSize: 10, color: Colors.white, letterSpacing: 0.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Falta só ${s.missingCategoryName.toLowerCase()} para completar seu pedido',
                      style: const TextStyle(fontSize: 13, color: _DS.steel, letterSpacing: -0.1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.productName,
                      style: const TextStyle(fontSize: 19, color: _DS.ink, letterSpacing: -0.3, height: 1.2),
                    ),
                    if ((s.productDescription ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.productDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: _DS.slate, height: 1.45),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (s.discountAmount > 0) ...[
                          Text(
                            _currFmt.format(s.originalPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              color: _DS.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _currFmt.format(s.finalPrice),
                          style: TextStyle(fontSize: 22, color: widget.brandColor, letterSpacing: -0.4),
                        ),
                        if (s.discountAmount > 0) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Você economiza ${_currFmt.format(s.discountAmount)}',
                              style: const TextStyle(fontSize: 11, color: _DS.successAccent),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Row(
                  children: [
                    _GoalQtyStepper(
                      value: _qty,
                      onChanged: _adding ? null : (v) => setState(() => _qty = v),
                      brandColor: widget.brandColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _adding ? null : _add,
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.brandColor,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _adding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Adicionar ao pedido • ${_currFmt.format(s.finalPrice * _qty)}',
                                    style: const TextStyle(fontSize: 14, letterSpacing: -0.1),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: GestureDetector(
                  onTap: _skip,
                  child: const Center(
                    child: Text(
                      'Continuar sem adicionar',
                      style: TextStyle(fontSize: 13, color: _DS.steel, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImg() {
    return Container(
      color: _DS.surface,
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 42, color: _DS.muted),
      ),
    );
  }
}

class _GoalQtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final Color brandColor;

  const _GoalQtyStepper({required this.value, required this.onChanged, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DS.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(
            icon: Icons.remove,
            onTap: enabled && value > 1 ? () => onChanged!(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  '$value',
                  key: ValueKey(value),
                  style: const TextStyle(fontSize: 15, color: _DS.ink),
                ),
              ),
            ),
          ),
          _qtyBtn(
            icon: Icons.add,
            onTap: enabled ? () => onChanged!(value + 1) : null,
            filled: true,
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback? onTap, bool filled = false}) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled && isEnabled ? brandColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled && isEnabled
              ? Colors.white
              : (isEnabled ? _DS.ink : _DS.muted),
        ),
      ),
    );
  }
}
