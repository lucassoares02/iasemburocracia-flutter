part of 'home_page.dart';

// ─── Dashboard header ─────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final CompanyInfoModel? company;
  final Color brand;
  const _DashboardHeader({required this.company, required this.brand});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingFor(now);
    final logoUrl = company?.logoUrl ?? '';
    final isOpen = company?.isOpen ?? false;
    final dateLabel = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
    final dateCapitalized = dateLabel.isEmpty ? '' : '${dateLabel[0].toUpperCase()}${dateLabel.substring(1)}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_DS.rXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.withValues(alpha: 0.95),
            Color.lerp(brand, _DS.ink, 0.35) ?? brand,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.rXl),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: 80,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, c) {
                  final stack = c.maxWidth < 520;
                  return Flex(
                    direction: stack ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: stack ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      _logoAvatar(logoUrl),
                      SizedBox(width: stack ? 0 : 16, height: stack ? 14 : 0),
                      Expanded(
                        flex: stack ? 0 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              company?.name ?? '—',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateCapitalized,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: stack ? 0 : 12, height: stack ? 14 : 0),
                      _statusBadge(isOpen),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoAvatar(String url) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _logoFallback(),
            )
          : _logoFallback(),
    );
  }

  Widget _logoFallback() {
    final name = (company?.name ?? '').trim();
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _statusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOpen ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5)).withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOpen ? 'Aberto agora' : 'Fechado',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
