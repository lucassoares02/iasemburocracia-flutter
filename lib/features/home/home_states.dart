part of 'home_page.dart';

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _DS.hairlineSoft,
      highlightColor: const Color(0xFFF7F8FA),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 1100;
          final medium = c.maxWidth >= 720;
          final pad = wide ? 32.0 : (medium ? 24.0 : 16.0);
          return Center(
            child: Container(
              width: 1300,
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 20),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _shimmerBlock(height: 96, radius: _DS.rXl),
                  const SizedBox(height: 24),
                  _shimmerBlock(height: 16, width: 120, radius: 6),
                  const SizedBox(height: 12),
                  _shimmerGrid(count: 4, height: 96, columns: medium ? 4 : 2),
                  const SizedBox(height: 24),
                  _shimmerBlock(height: 16, width: 120, radius: 6),
                  const SizedBox(height: 12),
                  _shimmerGrid(count: 4, height: 96, columns: medium ? 4 : 2),
                  const SizedBox(height: 24),
                  _shimmerBlock(height: 220, radius: _DS.rXl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _shimmerBlock({double? width, required double height, double radius = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerGrid({required int count, required double height, required int columns}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: height,
      ),
      itemCount: count,
      itemBuilder: (_, __) => _shimmerBlock(height: height),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────
class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _DS.dangerSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline, size: 36, color: _DS.danger),
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar o dashboard',
                style: TextStyle(fontSize: 17, color: _DS.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 13, color: _DS.steel, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty placeholder (small, used in sections) ──────────────────────────────
class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  const _SectionEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _DS.muted),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _DS.stone),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
