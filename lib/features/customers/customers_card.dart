part of 'customers_page.dart';

// ─── Customer Row (table-style) ───────────────────────────────────────────────
class _CustomerRow extends StatefulWidget {
  final CustomerModel customer;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _CustomerRow({
    required this.customer,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
  });

  @override
  State<_CustomerRow> createState() => _CustomerRowState();
}

class _CustomerRowState extends State<_CustomerRow> {
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
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered ? _DS.surface : _DS.canvas,
            border: Border(
              bottom: BorderSide(color: widget.isLast ? Colors.transparent : _DS.hairlineSoft),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _CustomerAvatar(name: c.name, size: 36),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      c.name ?? '—',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: _DS.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_anyBadge(c)) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (c.isRecurring)
                            const _CustomerBadge(
                              label: 'Recorrente',
                              fg: Color(0xFF4262FF),
                              bg: Color(0xFFEEF3FF),
                            ),
                          if (c.daysSinceCreated <= 30)
                            const _CustomerBadge(
                              label: 'Novo',
                              fg: Color(0xFF065F46),
                              bg: Color(0xFFD1FAE5),
                            ),
                          if ((c.totalSpent ?? 0) >= 500)
                            const _CustomerBadge(
                              label: 'Alto Valor',
                              fg: Color(0xFF946C0A),
                              bg: Color(0xFFFFF4C4),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  c.phone?.isNotEmpty == true ? c.phone! : '—',
                  style: const TextStyle(fontSize: 13, color: _DS.steel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${c.totalOrders ?? 0}',
                  style: const TextStyle(fontSize: 13, color: _DS.steel),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  c.totalSpent != null ? _currencyFmt.format(c.totalSpent) : 'R\$ 0,00',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovered ? 1 : 0,
                    child: _QuickAction(
                      icon: Icons.edit_outlined,
                      tooltip: 'Editar',
                      onTap: widget.onEdit,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _hovered ? _DS.slate : _DS.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _anyBadge(CustomerModel c) =>
      c.isRecurring || c.daysSinceCreated <= 30 || (c.totalSpent ?? 0) >= 500;
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
          fontWeight: FontWeight.w600,
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Quick action button ───────────────────────────────────────────────────────
class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hover ? _DS.canvas : _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rMd),
              border: Border.all(color: _DS.hairline),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14, color: _DS.slate),
          ),
        ),
      ),
    );
  }
}
