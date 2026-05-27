part of 'home_page.dart';

// ─── Today KPIs ───────────────────────────────────────────────────────────────
class _KpiTodaySection extends StatelessWidget {
  final PeriodStatsModel? today;
  final Color brand;
  const _KpiTodaySection({required this.today, required this.brand});

  @override
  Widget build(BuildContext context) {
    final t = today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Hoje',
          subtitle: 'Performance do dia em tempo real',
          icon: LucideIcons.sun,
          iconColor: _DS.warningAccent,
        ),
        _KpiGrid(
          cards: [
            _KpiCardData(
              label: 'Vendas hoje',
              value: _currFmt.format(t?.revenue ?? 0),
              icon: LucideIcons.dollarSign,
              accent: brand,
            ),
            _KpiCardData(
              label: 'Pedidos hoje',
              value: _intFmt.format(t?.orders ?? 0),
              icon: LucideIcons.shoppingBag,
              accent: _DS.brandBlue,
            ),
            _KpiCardData(
              label: 'Ticket médio',
              value: _currFmt.format(t?.avgTicket ?? 0),
              icon: LucideIcons.receipt,
              accent: const Color(0xFF7C3AED),
            ),
            _KpiCardData(
              label: 'Novos clientes',
              value: _intFmt.format(t?.newClients ?? 0),
              icon: LucideIcons.userPlus,
              accent: _DS.successAccent,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Month KPIs ───────────────────────────────────────────────────────────────
class _KpiMonthSection extends StatelessWidget {
  final MonthStatsModel? month;
  final Color brand;
  const _KpiMonthSection({required this.month, required this.brand});

  @override
  Widget build(BuildContext context) {
    final m = month;
    final growth = m?.growthPct ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Mês',
          subtitle: 'Acumulado do mês corrente',
          icon: LucideIcons.calendar,
          iconColor: _DS.brandBlue,
        ),
        _KpiGrid(
          cards: [
            _KpiCardData(
              label: 'Vendas no mês',
              value: _currFmt.format(m?.revenue ?? 0),
              icon: LucideIcons.trendingUp,
              accent: brand,
            ),
            _KpiCardData(
              label: 'Pedidos no mês',
              value: _intFmt.format(m?.orders ?? 0),
              icon: LucideIcons.shoppingBag,
              accent: _DS.brandBlue,
            ),
            _KpiCardData(
              label: 'Ticket médio',
              value: _currFmt.format(m?.avgTicket ?? 0),
              icon: LucideIcons.receipt,
              accent: const Color(0xFF7C3AED),
            ),
            _KpiCardData(
              label: 'Crescimento',
              value: '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
              icon: growth >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              accent: growth >= 0 ? _DS.successAccent : _DS.danger,
              trendBadge: growth >= 0 ? 'vs mês anterior' : 'vs mês anterior',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Operation KPIs ───────────────────────────────────────────────────────────
class _KpiOperationSection extends StatelessWidget {
  final OperationStatsModel? op;
  const _KpiOperationSection({required this.op});

  @override
  Widget build(BuildContext context) {
    final o = op;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Operação',
          subtitle: 'Visão completa dos pedidos',
          icon: LucideIcons.activity,
          iconColor: const Color(0xFF7C3AED),
        ),
        _KpiGrid(
          cards: [
            _KpiCardData(
              label: 'Em andamento',
              value: _intFmt.format(o?.inProgress ?? 0),
              icon: LucideIcons.clock,
              accent: _DS.warningAccent,
            ),
            _KpiCardData(
              label: 'Concluídos',
              value: _intFmt.format(o?.completed ?? 0),
              icon: LucideIcons.checkCircle,
              accent: _DS.successAccent,
            ),
            _KpiCardData(
              label: 'Cancelados',
              value: _intFmt.format(o?.cancelled ?? 0),
              icon: LucideIcons.xCircle,
              accent: _DS.danger,
            ),
            _KpiCardData(
              label: 'Taxa de cancelamento',
              value: '${(o?.cancellationRate ?? 0).toStringAsFixed(1)}%',
              icon: LucideIcons.percent,
              accent: (o?.cancellationRate ?? 0) > 10 ? _DS.danger : _DS.steel,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Card data ────────────────────────────────────────────────────────────────
class _KpiCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? trendBadge;
  const _KpiCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.trendBadge,
  });
}

// ─── Grid layout ──────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final List<_KpiCardData> cards;
  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        int columns;
        if (width >= 1100) {
          columns = 4;
        } else if (width >= 720) {
          columns = 4;
        } else if (width >= 480) {
          columns = 2;
        } else {
          columns = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 116,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _KpiCard(data: cards[i]),
        );
      },
    );
  }
}

// ─── Single KPI card ──────────────────────────────────────────────────────────
class _KpiCard extends StatefulWidget {
  final _KpiCardData data;
  const _KpiCard({required this.data});

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _hover ? d.accent.withValues(alpha: 0.35) : _DS.hairlineSoft),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: d.accent.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: d.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(d.icon, size: 16, color: d.accent),
                ),
                const Spacer(),
                if (d.trendBadge != null)
                  Text(
                    d.trendBadge!,
                    style: const TextStyle(fontSize: 10, color: _DS.stone),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.value,
                  style: const TextStyle(
                    fontSize: 19,
                    color: _DS.ink,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  d.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _DS.steel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
