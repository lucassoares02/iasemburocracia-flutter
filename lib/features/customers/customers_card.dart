part of 'customers_page.dart';

// ─── Customer Card ─────────────────────────────────────────────────────────────
class _CustomerCard extends StatefulWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(
              color: _hovered ? _DS.hairline : _DS.hairlineSoft,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              _CustomerAvatar(name: c.name),
              const SizedBox(width: 12),
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
                              fontSize: 14,
                              color: _DS.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.isRecurring) ...[
                          const SizedBox(width: 6),
                          const _CustomerBadge(
                            label: 'Recorrente',
                            fg: Color(0xFF4262FF),
                            bg: Color(0xFFEEF3FF),
                          ),
                        ],
                        if (c.daysSinceCreated <= 30) ...[
                          const SizedBox(width: 4),
                          const _CustomerBadge(
                            label: 'Novo',
                            fg: Color(0xFF065F46),
                            bg: Color(0xFFD1FAE5),
                          ),
                        ],
                        if ((c.totalSpent ?? 0) >= 500) ...[
                          const SizedBox(width: 4),
                          const _CustomerBadge(
                            label: 'Alto Valor',
                            fg: Color(0xFF946C0A),
                            bg: Color(0xFFFFF4C4),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.phone?.isNotEmpty == true ? c.phone! : 'Sem telefone',
                      style: const TextStyle(fontSize: 12, color: _DS.stone),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    c.totalSpent != null ? _currencyFmt.format(c.totalSpent) : 'R\$ 0,00',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _DS.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.totalOrders ?? 0} pedido${(c.totalOrders ?? 0) == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 150),
                child: _hovered
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _QuickAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Editar',
                          onTap: widget.onEdit,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ────────────────────────────────────────────────────────────────────
class _CustomerAvatar extends StatelessWidget {
  final String? name;
  final double size;
  const _CustomerAvatar({this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _DS.avatarBg(name),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _DS.initials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Badge ─────────────────────────────────────────────────────────────────────
class _CustomerBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _CustomerBadge({
    required this.label,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Quick action button ───────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _DS.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: _DS.slate),
        ),
      ),
    );
  }
}
