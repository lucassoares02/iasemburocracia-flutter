part of 'public_order_page.dart';

// ─── Search Analytics Tracker ─────────────────────────────────────────────────
// Fire-and-forget: nunca bloqueia UI, erros são silenciados.
// Um tracker por sessão de menu (instanciado em _MenuScreenState.initState).
class _SearchTracker {
  final String companyId;
  // Identificador único por visita — gerado uma vez, sem persistência local.
  final String sessionId;

  bool _productClickedInSearch = false;
  Timer? _noResultsTimer;
  String? _lastNoResultsTerm; // evita duplicar eventos no_results para o mesmo termo

  _SearchTracker({required this.companyId}) : sessionId = _makeSessionId();

  static String _makeSessionId() {
    final ms = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final us = (DateTime.now().microsecondsSinceEpoch % 1000000).toRadixString(36);
    return '${ms}_$us';
  }

  // ── Chamado a cada mudança de resultados (via onChanged do TextField) ────────
  // Dispara no_results_search após 1,5s de estabilidade com 0 resultados.
  void onResultsChanged(String term, int count) {
    if (term.length < 2) return;
    _noResultsTimer?.cancel();
    if (count == 0 && term != _lastNoResultsTerm) {
      _noResultsTimer = Timer(const Duration(milliseconds: 1500), () {
        if (term == _lastNoResultsTerm) return;
        _lastNoResultsTerm = term;
        _send(
          event: 'no_results_search',
          term: term,
          resultsCount: 0,
          hadResults: false,
        );
      });
    }
  }

  // ── Chamado quando o usuário clica em um produto durante a busca ─────────────
  void onProductClicked({
    required String term,
    required int resultsCount,
    required int productId,
    required String productName,
    required String category,
  }) {
    if (term.length < 2) return;
    _productClickedInSearch = true;
    _noResultsTimer?.cancel();
    _send(
      event: 'product_clicked_from_search',
      term: term,
      resultsCount: resultsCount,
      hadResults: resultsCount > 0,
      extra: {
        'clicked_product_id': productId,
        'clicked_product_name': productName,
        'clicked_category': category,
      },
    );
  }

  // ── Chamado quando a busca é encerrada (Cancelar / Enter / foco perdido) ─────
  // search_completed → usuário clicou em produto após buscar.
  // search_closed    → usuário fechou sem ação.
  void onSearchClose(String term, int resultsCount) {
    _noResultsTimer?.cancel();
    if (term.length < 2) {
      _productClickedInSearch = false;
      return;
    }
    final event =
        _productClickedInSearch ? 'search_completed' : 'search_closed';
    _productClickedInSearch = false;
    _send(
      event: event,
      term: term,
      resultsCount: resultsCount,
      hadResults: resultsCount > 0,
    );
  }

  void _send({
    required String event,
    required String term,
    required int resultsCount,
    required bool hadResults,
    Map<String, dynamic>? extra,
  }) {
    final payload = <String, dynamic>{
      'company_id': companyId,
      'session_id': sessionId,
      'event_type': event,
      'search_term': term,
      'results_count': resultsCount,
      'had_results': hadResults,
      'device_type': 'web',
      if (extra != null) ...extra,
    };
    // Fire-and-forget — .ignore() descarta o Future sem warning de lint.
    PublicHttpService()
        .post('public/search-analytics', payload)
        .ignore();
  }

  void dispose() {
    _noResultsTimer?.cancel();
  }
}
