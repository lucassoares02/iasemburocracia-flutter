part of 'home_page.dart';

// ─── Local model helpers ───────────────────────────────────────────────────────
int _saInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class _SaTerm {
  final String term;
  final int total;
  final int clickCount;
  const _SaTerm({required this.term, required this.total, required this.clickCount});
  factory _SaTerm.fromJson(Map<String, dynamic> j) => _SaTerm(
        term: j['search_term'] as String? ?? '',
        total: _saInt(j['total']),
        clickCount: _saInt(j['click_count']),
      );
}

class _SaProduct {
  final String name;
  final int clickCount;
  final int uniqueSessions;
  const _SaProduct({required this.name, required this.clickCount, required this.uniqueSessions});
  factory _SaProduct.fromJson(Map<String, dynamic> j) => _SaProduct(
        name: j['clicked_product_name'] as String? ?? '—',
        clickCount: _saInt(j['click_count']),
        uniqueSessions: _saInt(j['unique_sessions']),
      );
}

class _SaNoResult {
  final String term;
  final int total;
  const _SaNoResult({required this.term, required this.total});
  factory _SaNoResult.fromJson(Map<String, dynamic> j) => _SaNoResult(
        term: j['search_term'] as String? ?? '',
        total: _saInt(j['total']),
      );
}

// ─── Section widget ───────────────────────────────────────────────────────────
class _SearchAnalyticsSection extends StatefulWidget {
  final int? companyId;
  final bool wide;
  final bool medium;
  const _SearchAnalyticsSection({
    required this.companyId,
    required this.wide,
    required this.medium,
  });

  @override
  State<_SearchAnalyticsSection> createState() => _SearchAnalyticsSectionState();
}

class _SearchAnalyticsSectionState extends State<_SearchAnalyticsSection> {
  final _http = HttpService();
  List<_SaTerm> _terms = const [];
  List<_SaProduct> _products = const [];
  List<_SaNoResult> _noResults = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SearchAnalyticsSection old) {
    super.didUpdateWidget(old);
    if (old.companyId != widget.companyId && widget.companyId != null) _load();
  }

  Future<void> _load() async {
    final id = widget.companyId;
    if (id == null || id <= 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        _http.get('search-analytics/top-terms/$id'),
        _http.get('search-analytics/top-products/$id'),
        _http.get('search-analytics/no-results/$id'),
      ]);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (results[0].success && results[0].data is List) {
          _terms = (results[0].data as List).whereType<Map<String, dynamic>>().map(_SaTerm.fromJson).toList();
        }
        if (results[1].success && results[1].data is List) {
          _products = (results[1].data as List).whereType<Map<String, dynamic>>().map(_SaProduct.fromJson).toList();
        }
        if (results[2].success && results[2].data is List) {
          _noResults = (results[2].data as List).whereType<Map<String, dynamic>>().map(_SaNoResult.fromJson).toList();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_terms.isEmpty && _products.isEmpty && _noResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Analytics de Busca',
          subtitle: 'Intenção de compra e oportunidades de produto',
          icon: LucideIcons.search,
          iconColor: Color(0xFF0EA5E9),
        ),
        if (widget.wide || widget.medium)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _SearchTermsCard(terms: _terms)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _SearchNoResultsCard(noResults: _noResults)),
            ],
          )
        else ...[
          _SearchTermsCard(terms: _terms),
          const SizedBox(height: 16),
          _SearchNoResultsCard(noResults: _noResults),
        ],
        if (_products.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SearchProductsCard(products: _products),
        ],
      ],
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: _DS.hairlineSoft,
      highlightColor: const Color(0xFFF7F8FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_DS.rXl),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Terms Card ───────────────────────────────────────────────────────────
class _SearchTermsCard extends StatelessWidget {
  final List<_SaTerm> terms;
  const _SearchTermsCard({required this.terms});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: LucideIcons.search,
            iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
            iconColor: const Color(0xFF0EA5E9),
            title: 'Termos Mais Buscados',
          ),
          const SizedBox(height: 10),
          const Divider(color: _DS.hairlineSoft, height: 1),
          const SizedBox(height: 6),
          if (terms.isEmpty)
            const _SectionEmpty(
              icon: LucideIcons.search,
              message: 'Nenhuma busca registrada ainda',
            )
          else
            ...terms.take(6).toList().asMap().entries.map((e) => _TermRow(
                  rank: e.key + 1,
                  term: e.value,
                )),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  final int rank;
  final _SaTerm term;
  const _TermRow({required this.rank, required this.term});

  @override
  Widget build(BuildContext context) {
    final convPct = term.total > 0 ? (term.clickCount / term.total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: rank <= 3 ? _DS.brandBlue : _DS.muted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              term.term,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _DS.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (convPct > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _DS.successSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$convPct% conv.',
                style: const TextStyle(
                  fontSize: 10,
                  color: _DS.successAccent,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _DS.hairline),
            ),
            child: Text(
              _intFmt.format(term.total),
              style: const TextStyle(
                fontSize: 11,
                color: _DS.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No Results Card ──────────────────────────────────────────────────────────
class _SearchNoResultsCard extends StatelessWidget {
  final List<_SaNoResult> noResults;
  const _SearchNoResultsCard({required this.noResults});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _DS.dangerSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(LucideIcons.alertCircle, size: 13, color: _DS.danger),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscas Sem Resultado',
                      style: TextStyle(
                        fontSize: 13,
                        color: _DS.ink,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Oportunidades de produto',
                      style: TextStyle(fontSize: 11, color: _DS.stone),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: _DS.hairlineSoft, height: 1),
          const SizedBox(height: 6),
          if (noResults.isEmpty)
            const _SectionEmpty(
              icon: LucideIcons.checkCircle,
              message: 'Nenhuma busca sem resultado!',
            )
          else
            ...noResults.take(6).map((nr) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 12, color: _DS.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nr.term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _DS.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _DS.dangerSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_intFmt.format(nr.total)}x',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ─── Products from Search Card ────────────────────────────────────────────────
class _SearchProductsCard extends StatelessWidget {
  final List<_SaProduct> products;
  const _SearchProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: LucideIcons.mousePointerClick,
            iconBg: _DS.successSoft,
            iconColor: _DS.successAccent,
            title: 'Produtos Encontrados via Busca',
          ),
          const SizedBox(height: 10),
          const Divider(color: _DS.hairlineSoft, height: 1),
          const SizedBox(height: 4),
          ...products.take(5).toList().asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: i < 3 ? _DS.brandBlue : _DS.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _DS.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_intFmt.format(p.uniqueSessions)} sess.',
                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _DS.successSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.mousePointerClick,
                          size: 10,
                          color: _DS.successAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _intFmt.format(p.clickCount),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.successAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Shared card header helper ────────────────────────────────────────────────
Widget _cardHeader({
  required IconData icon,
  required Color iconBg,
  required Color iconColor,
  required String title,
}) {
  return Row(
    children: [
      Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: iconColor),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: _DS.ink,
        ),
      ),
    ],
  );
}
