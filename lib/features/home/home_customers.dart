part of 'home_page.dart';

// ─── Customer insights ────────────────────────────────────────────────────────
class _CustomerInsightsCard extends StatelessWidget {
  final ClientsSectionModel? clients;
  final Color brand;
  const _CustomerInsightsCard({required this.clients, required this.brand});

  @override
  Widget build(BuildContext context) {
    final c = clients;
    final top = c?.topSpender;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Clientes',
          subtitle: 'Visão geral da base',
          icon: LucideIcons.users,
          iconColor: const Color(0xFF7C3AED),
        ),
        _Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      icon: LucideIcons.users,
                      label: 'Cadastrados',
                      value: _intFmt.format(c?.total ?? 0),
                      color: brand,
                    ),
                  ),
                  Expanded(
                    child: _miniStat(
                      icon: LucideIcons.repeat,
                      label: 'Recorrentes',
                      value: _intFmt.format(c?.recurring ?? 0),
                      color: _DS.successAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      icon: LucideIcons.userPlus,
                      label: 'Novos no mês',
                      value: _intFmt.format(c?.newMonth ?? 0),
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  Expanded(
                    child: _miniStat(
                      icon: LucideIcons.percent,
                      label: 'Retenção',
                      value: _retentionPct(c),
                      color: _DS.warningAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _DS.hairlineSoft, height: 1),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(LucideIcons.crown, size: 14, color: _DS.warningAccent),
                  SizedBox(width: 6),
                  Text(
                    'Maior cliente',
                    style: TextStyle(
                      fontSize: 11,
                      color: _DS.slate,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (top == null)
                _SectionEmpty(
                  icon: LucideIcons.users,
                  message: 'Ainda não há dados suficientes',
                )
              else
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _DS.warningAccent.withValues(alpha: 0.18),
                            _DS.warningAccent.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.crown, size: 18, color: _DS.warningAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            top.name ?? '—',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _DS.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${top.ordersCount} pedidos · ${_currFmt.format(top.totalSpent)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _DS.steel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _retentionPct(ClientsSectionModel? c) {
    if (c == null || c.total == 0) return '0%';
    final pct = (c.recurring / c.total) * 100;
    return '${pct.toStringAsFixed(0)}%';
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: _DS.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _DS.stone,
          ),
        ),
      ],
    );
  }
}
