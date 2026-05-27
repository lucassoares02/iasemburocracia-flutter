part of 'home_page.dart';

// ─── Smart insights ───────────────────────────────────────────────────────────
class _SmartInsights extends StatelessWidget {
  final List<InsightModel> insights;
  const _SmartInsights({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Insights inteligentes',
          subtitle: 'Sugestões automáticas com base nos dados',
          icon: LucideIcons.sparkles,
          iconColor: const Color(0xFF7C3AED),
        ),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final medium = c.maxWidth >= 720;
          int columns;
          if (wide) {
            columns = 3;
          } else if (medium) {
            columns = 2;
          } else {
            columns = 1;
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 128,
            ),
            itemCount: insights.length,
            itemBuilder: (_, i) => _InsightCard(insight: insights[i]),
          );
        }),
      ],
    );
  }
}

class _InsightCard extends StatefulWidget {
  final InsightModel insight;
  const _InsightCard({required this.insight});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.insight;
    final accent = _accentFor(i.type);
    final softBg = _softBgFor(i.type);
    final icon = _iconFor(i.icon);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _hover ? accent.withValues(alpha: 0.4) : _DS.hairlineSoft),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.title ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _DS.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      i.text ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _DS.steel,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentFor(String? type) {
    switch (type) {
      case 'positive':
        return _DS.successAccent;
      case 'negative':
        return _DS.danger;
      case 'info':
      default:
        return _DS.brandBlue;
    }
  }

  Color _softBgFor(String? type) {
    switch (type) {
      case 'positive':
        return _DS.successSoft;
      case 'negative':
        return _DS.dangerSoft;
      case 'info':
      default:
        return _DS.surfacePricing;
    }
  }

  IconData _iconFor(String? name) {
    switch (name) {
      case 'trending_up':
        return LucideIcons.trendingUp;
      case 'trending_down':
        return LucideIcons.trendingDown;
      case 'star':
        return LucideIcons.star;
      case 'person_premium':
      case 'person':
        return LucideIcons.userCheck;
      case 'group_add':
        return LucideIcons.userPlus;
      case 'warning':
        return LucideIcons.alertTriangle;
      case 'inventory':
        return LucideIcons.package;
      default:
        return LucideIcons.sparkles;
    }
  }
}
