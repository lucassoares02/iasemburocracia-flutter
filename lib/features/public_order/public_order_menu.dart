part of 'public_order_page.dart';

class _MenuScreen extends StatefulWidget {
  final PublicCompanyPageModel data;
  final List<_PubCartItem> cart;
  final Color brandColor;
  final DateTime? scheduledFor;
  final void Function(
    PublicMenuItemModel,
    int,
    String?, {
    List<_PubCartOption> options,
  }) onAdd;
  final void Function(PublicMenuItemModel) onDecrement;
  final void Function(PublicPromotionModel, {int quantity, String? notes}) onAddPromotion;
  final VoidCallback onCartTap;
  final String? customerName;
  final VoidCallback? onViewHistory;
  final PublicOrderDetailModel? activeOrder;
  final VoidCallback? onViewActiveOrder;
  const _MenuScreen({
    required this.data,
    required this.cart,
    required this.brandColor,
    required this.scheduledFor,
    required this.onAdd,
    required this.onDecrement,
    required this.onAddPromotion,
    required this.onCartTap,
    this.customerName,
    this.onViewHistory,
    this.activeOrder,
    this.onViewActiveOrder,
  });

  @override
  State<_MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<_MenuScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  // _searchActive é controlado por ações explícitas do usuário (tap / cancelar),
  // nunca pelo estado interno do FocusNode.
  bool _searchActive = false;

  late final _SearchTracker _tracker;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _tracker = _SearchTracker(
      companyId: '${widget.data.company.id ?? 0}',
    );
  }

  void _enterSearchMode() {
    if (_searchActive) return;
    setState(() => _searchActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  /// Copia o link público do cardápio e confirma com uma snackbar.
  void _shareMenuLink() {
    final companyId = widget.data.company.id;
    if (companyId == null) return;
    final url = '${Uri.base.origin}/order?company=$companyId';
    Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _DS.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Link do cardápio copiado! 🔗',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _exitSearchMode() {
    final term = _query;
    final count = term.length >= 2 ? _allItems.where((e) => _matches(e.item, term)).length : 0;
    _tracker.onSearchClose(term, count);
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _searchActive = false);
  }

  void _onSearchChanged(String _) {
    setState(() {});
    final q = _query;
    if (q.length >= 2) {
      final count = _allItems.where((e) => _matches(e.item, q)).length;
      _tracker.onResultsChanged(q, count);
    }
  }

  bool get _inSearchMode => _searchActive || _isSearching;

  // ── Sticky category navigation
  final Map<String, GlobalKey> _categoryKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  String? _activeCategory;
  bool _isProgrammaticScroll = false;
  int _scrollGen = 0;

  GlobalKey _keyForCategory(String name) => _categoryKeys.putIfAbsent(name, () => GlobalKey());

  static const _kTabBarHeight = 56.0;

  // Offset absoluto no conteúdo rolável onde a seção da categoria começa.
  // precedingScrollExtent = soma dos scrollExtent de todos os slivers anteriores.
  // Válido sincronamente — não depende da posição atual do scroll.
  double? _categoryScrollOffset(String name) {
    final renderObj = _categoryKeys[name]?.currentContext?.findRenderObject();
    if (renderObj == null || !renderObj.attached) return null;
    // _CategorySection → findRenderObject() = RenderPadding
    // RenderPadding.parent = RenderSliverToBoxAdapter (RenderSliver)
    final sliver = renderObj.parent;
    if (sliver is! RenderSliver || !sliver.attached) return null;
    return sliver.constraints.precedingScrollExtent;
  }

  void _onScroll() {
    if (_inSearchMode || _isProgrammaticScroll || !_scrollCtrl.hasClients) return;
    final scrollPixels = _scrollCtrl.position.pixels;
    String? candidate;
    double bestOffset = double.negativeInfinity;
    for (final entry in _categoryKeys.entries) {
      final preceding = _categoryScrollOffset(entry.key);
      if (preceding == null) continue;
      final offset = preceding - _kTabBarHeight;
      if (offset <= scrollPixels + 4 && offset > bestOffset) {
        bestOffset = offset;
        candidate = entry.key;
      }
    }
    if (candidate != null && candidate != _activeCategory) {
      setState(() => _activeCategory = candidate);
    }
  }

  /// Navega até a categoria. Estratégia:
  /// 1. Mede o offset via `precedingScrollExtent`.
  /// 2. Se a categoria está fora do cache extent (não foi laid-out), avança
  ///    um viewport por vez para empurrá-la para dentro do cache e re-mede.
  /// 3. Repete até convergir ou esgotar 8 iterações.
  /// O contador `_scrollGen` cancela iterações pendentes caso o usuário
  /// clique em outra categoria no meio do processo.
  Future<void> _scrollToCategory(String name) async {
    if (!_scrollCtrl.hasClients) return;
    setState(() => _activeCategory = name);
    final gen = ++_scrollGen;
    _isProgrammaticScroll = true;
    try {
      for (var i = 0; i < 8; i++) {
        if (!mounted || _scrollGen != gen || !_scrollCtrl.hasClients) return;
        final offset = _categoryScrollOffset(name);
        if (offset != null) {
          final target = (offset - _kTabBarHeight).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
          final delta = (target - _scrollCtrl.position.pixels).abs();
          if (delta < 0.5) return;
          await _scrollCtrl.animateTo(
            target,
            duration: Duration(milliseconds: i == 0 ? 380 : 120),
            curve: i == 0 ? Curves.easeInOutCubic : Curves.easeOut,
          );
          // Próxima iteração re-mede: se outras seções foram laid-out
          // durante a animação, o precedingScrollExtent pode ter mudado.
        } else {
          // Categoria ainda não passou por layout. Avança ~1 viewport para
          // empurrá-la para dentro do cache extent e tenta de novo no
          // próximo frame.
          final current = _scrollCtrl.position.pixels;
          final next = (current + _scrollCtrl.position.viewportDimension).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
          if ((next - current).abs() < 0.5) return;
          _scrollCtrl.jumpTo(next);
          await WidgetsBinding.instance.endOfFrame;
        }
      }
    } finally {
      if (mounted && _scrollGen == gen) _isProgrammaticScroll = false;
    }
  }

  @override
  void dispose() {
    _tracker.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  int _cartQty(int menuItemId) {
    final match = widget.cart.where((c) => c.menuItemId == menuItemId);
    if (match.isEmpty) return 0;
    return match.fold<int>(0, (s, c) => s + c.quantity);
  }

  /// Quick add: if the product has option groups, opens the detail sheet so
  /// the user can configure them; otherwise adds directly with qty=1.
  void _quickAdd(BuildContext context, PublicMenuItemModel item) {
    if (item.hasOptions) {
      _showDetailSheet(context, item, _cartQty(item.id ?? -1));
    } else {
      widget.onAdd(item, 1, null);
    }
  }

  double get _cartTotal => widget.cart.fold(0, (s, c) => s + c.subtotal);
  int get _cartCount => widget.cart.fold(0, (s, c) => s + c.quantity);

  String get _query => _searchCtrl.text.trim().toLowerCase();
  bool get _isSearching => _query.isNotEmpty;

  /// Tempo médio de preparo (em minutos), arredondado, ou null se nenhum item tiver.
  int? get _avgPrepMinutes {
    final items = _allItems.map((e) => e.item).toList();
    final times = items.map((e) => e.prepTimeMinutes ?? 0).where((m) => m > 0).toList();
    if (times.isEmpty) return null;
    final avg = times.reduce((a, b) => a + b) / times.length;
    return avg.round();
  }

  /// Total de itens disponíveis no cardápio.
  int get _totalItemsCount => _allItems.length;

  /// Coleta todos os itens do cardápio (featured + categorias + uncategorized),
  /// preservando categoria de cada um.
  List<({PublicMenuItemModel item, String category})> get _allItems {
    final result = <({PublicMenuItemModel item, String category})>[];
    final seen = <int>{};
    for (final cat in widget.data.categories) {
      final name = cat.name ?? '—';
      for (final it in (cat.items ?? [])) {
        final id = it.id;
        if (id == null || seen.contains(id)) continue;
        seen.add(id);
        result.add((item: it as PublicMenuItemModel, category: name));
      }
    }
    for (final it in widget.data.uncategorized) {
      final id = it.id;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      result.add((item: it, category: 'Outros'));
    }
    for (final it in widget.data.featured) {
      final id = it.id;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      result.add((item: it, category: 'Destaques'));
    }
    return result;
  }

  bool _matches(PublicMenuItemModel e, String q) {
    final n = (e.name ?? '').toLowerCase();
    final d = (e.description ?? '').toLowerCase();
    return n.contains(q) || d.contains(q);
  }

  /// Sugere itens relacionados à busca. Estratégia:
  /// 1. Se há resultados: prioriza itens da mesma categoria que NÃO casaram com a busca.
  /// 2. Se NÃO há resultados: usa featured + itens populares (de qualquer categoria).
  /// 3. Limita a 10 itens.
  List<PublicMenuItemModel> _suggestions(List<PublicMenuItemModel> results, String q) {
    final all = _allItems;
    final resultIds = results.map((e) => e.id).whereType<int>().toSet();
    final out = <PublicMenuItemModel>[];
    final seen = <int>{};

    if (results.isNotEmpty) {
      final resultCategories = all.where((e) => resultIds.contains(e.item.id)).map((e) => e.category).toSet();
      for (final e in all) {
        if (resultIds.contains(e.item.id)) continue;
        if (!resultCategories.contains(e.category)) continue;
        if (seen.add(e.item.id ?? -1)) out.add(e.item);
        if (out.length >= 10) return out;
      }
    }

    // Complementa com featured se faltar
    for (final f in widget.data.featured) {
      if (out.length >= 10) break;
      final id = f.id;
      if (id == null || resultIds.contains(id) || !seen.add(id)) continue;
      out.add(f);
    }

    // Complementa com qualquer item restante
    for (final e in all) {
      if (out.length >= 10) break;
      final id = e.item.id;
      if (id == null || resultIds.contains(id) || !seen.add(id)) continue;
      out.add(e.item);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final q = _query;
    final searching = _isSearching;

    // Resultados com categoria preservada (para mostrar label no card)
    final List<({PublicMenuItemModel item, String category})> resultRecords;
    if (searching) {
      resultRecords = _allItems.where((e) => _matches(e.item, q)).toList();
    } else {
      resultRecords = const [];
    }
    final results = resultRecords.map((r) => r.item).toList();

    final featured = searching ? const <PublicMenuItemModel>[] : widget.data.featured;
    final categories = searching
        ? const <(String, List<PublicMenuItemModel>)>[]
        : widget.data.categories.map((cat) => (cat.name ?? '', (cat.items ?? []).cast<PublicMenuItemModel>())).where((e) => e.$2.isNotEmpty).toList();
    final uncategorized = searching ? const <PublicMenuItemModel>[] : widget.data.uncategorized;

    final suggestions = searching ? _suggestions(results, q) : const <PublicMenuItemModel>[];

    return Scaffold(
      backgroundColor: _DSx.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // Em modo busca: barra fixa no topo (hero some).
            if (_inSearchMode)
              _StickySearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                brandColor: widget.brandColor,
                showCancel: true,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
                onCancel: _exitSearchMode,
              ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollCtrl,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  // Idle: hero + trust row (com ícone de busca) rolam junto.
                  if (!_inSearchMode) ...[
                    SliverToBoxAdapter(
                      child: _HeroBanner(
                        bannerUrl: widget.data.company.bannerUrl,
                        logoUrl: widget.data.company.logoUrl,
                        companyName: widget.data.company.name ?? '',
                        description: widget.data.company.description,
                        brandColor: widget.brandColor,
                        isOpen: widget.data.isOpen,
                        avgPrepMinutes: _avgPrepMinutes,
                        productsCount: _totalItemsCount,
                        promotionsCount: widget.data.promotions.length,
                        onSearch: _enterSearchMode,
                        onShare: _shareMenuLink,
                        onTapInfo: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _CompanyDetailsPage(
                              data: widget.data,
                              cartQtyOf: _cartQty,
                              onTapProduct: (item) => _showDetailSheet(context, item, _cartQty(item.id ?? -1)),
                              onAddProduct: (item) => _quickAdd(context, item),
                              onRemoveProduct: (item) => widget.onDecrement(item),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Banner de pedido em andamento
                  if (!_inSearchMode && widget.activeOrder != null)
                    SliverToBoxAdapter(
                      child: _ActiveOrderBanner(
                        order: widget.activeOrder!,
                        brandColor: widget.brandColor,
                        onTap: widget.onViewActiveOrder,
                      ),
                    ),
                  // Banner "Estamos fechados" e o atalho "Já fez pedidos?"
                  // foram intencionalmente ocultados para reduzir poluição
                  // visual e liberar área para produtos. O status agora é
                  // sinalizado pelo `_StatusPill` no banner. Backend e fluxo
                  // de histórico continuam intactos para reutilização futura.
                  // ─── Resultados da busca ─────────────────────────────────────
                  if (searching) ...[
                    SliverToBoxAdapter(
                      child: _SearchResultsHeader(
                        query: q,
                        count: results.length,
                        brandColor: widget.brandColor,
                      ),
                    ),
                    if (resultRecords.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 4),
                        sliver: SliverList.builder(
                          itemCount: resultRecords.length,
                          itemBuilder: (_, i) {
                            final r = resultRecords[i];
                            final qty = _cartQty(r.item.id ?? -1);
                            return FoodCard(
                              item: r.item,
                              brandColor: widget.brandColor,
                              cartQty: qty,
                              categoryLabel: r.category,
                              onTap: () => _showDetailSheet(
                                context,
                                r.item,
                                qty,
                                searchCategory: r.category,
                              ),
                              onAdd: () => _quickAdd(context, r.item),
                              onRemove: qty > 0 ? () => widget.onDecrement(r.item) : null,
                            );
                          },
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _SearchEmptyState(query: q),
                      ),
                    if (suggestions.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _SuggestionsList(
                          title: results.isEmpty ? 'Que tal experimentar?' : 'Você também pode gostar',
                          items: suggestions,
                          brandColor: widget.brandColor,
                          cartQtyOf: _cartQty,
                          onTap: (item) => _showDetailSheet(context, item, _cartQty(item.id!)),
                          onAdd: (item) => _quickAdd(context, item),
                        ),
                      ),
                  ],
                  // ─── Cardápio normal (sem busca) ─────────────────────────────
                  if (!searching && featured.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _BestSellersCarousel(
                        items: featured.take(10).toList(),
                        brandColor: widget.brandColor,
                        cartQtyOf: _cartQty,
                        onTap: (item) => _showDetailSheet(context, item, _cartQty(item.id!)),
                        onAdd: (item) => _quickAdd(context, item),
                        onRemove: (item) => widget.onDecrement(item),
                      ),
                    ),
                  if (!searching && widget.data.promotions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PromotionsHorizontalList(
                        promotions: widget.data.promotions,
                        brandColor: widget.brandColor,
                        onTap: (promo) => _showPromotionSheet(context, promo),
                        onAdd: (promo) => widget.onAddPromotion(promo),
                      ),
                    ),

                  if (!searching && categories.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyCategoryTabs(
                        categories: [
                          ...categories.map((e) => e.$1),
                          if (uncategorized.isNotEmpty) 'Outros',
                        ],
                        activeCategory: _activeCategory,
                        brandColor: widget.brandColor,
                        onTap: _scrollToCategory,
                      ),
                    ),
                  if (!searching)
                    ...categories.map((entry) => SliverToBoxAdapter(
                          child: _CategorySection(
                            key: _keyForCategory(entry.$1),
                            title: entry.$1,
                            items: entry.$2,
                            brandColor: widget.brandColor,
                            cartQtyOf: _cartQty,
                            onTap: (item) => _showDetailSheet(context, item, _cartQty(item.id!)),
                            onAdd: (item) => _quickAdd(context, item),
                            onRemove: (item) => widget.onDecrement(item),
                          ),
                        )),
                  if (!searching && uncategorized.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _CategorySection(
                        key: _keyForCategory('Outros'),
                        title: 'Outros',
                        items: uncategorized,
                        brandColor: widget.brandColor,
                        cartQtyOf: _cartQty,
                        onTap: (item) => _showDetailSheet(context, item, _cartQty(item.id!)),
                        onAdd: (item) => _quickAdd(context, item),
                        onRemove: (item) => widget.onDecrement(item),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: widget.cart.isEmpty
            ? const SizedBox.shrink(key: ValueKey('empty-cart'))
            : _FloatingCartButton(
                key: const ValueKey('with-cart'),
                count: _cartCount,
                total: _cartTotal,
                brandColor: widget.brandColor,
                onTap: widget.onCartTap,
              ),
      ),
    );
  }

  void _showPromotionSheet(BuildContext context, PublicPromotionModel promo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => PromotionDetailsSheet(
        promo: promo,
        brandColor: widget.brandColor,
        onAdd: (qty, notes) {
          // Fecha este sheet ANTES de iniciar o fluxo de opções do combo, senão
          // o pop fecharia a folha de opções recém-aberta.
          Navigator.pop(context);
          widget.onAddPromotion(promo, quantity: qty, notes: notes);
        },
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    PublicMenuItemModel item,
    int currentQty, {
    String searchCategory = '',
  }) {
    if (_inSearchMode && _query.length >= 2) {
      final count = _allItems.where((e) => _matches(e.item, _query)).length;
      _tracker.onProductClicked(
        term: _query,
        resultsCount: count,
        productId: item.id ?? 0,
        productName: item.name ?? '',
        category: searchCategory,
      );
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        item: item,
        brandColor: widget.brandColor,
        initialQty: currentQty > 0 ? currentQty : 1,
        onAdd: (qty, notes, options) => widget.onAdd(item, qty, notes, options: options),
      ),
    );
  }
}

/// Carrossel premium de promoções. Cards quase full-width com PageView para
/// snap suave, hero image grande (≈55% da altura), overlay com gradiente e
/// preços hierarquizados como em apps modernos de delivery.
class PromotionsHorizontalList extends StatefulWidget {
  final List<PublicPromotionModel> promotions;
  final Color brandColor;
  final void Function(PublicPromotionModel) onTap;
  final void Function(PublicPromotionModel) onAdd;
  const PromotionsHorizontalList({
    super.key,
    required this.promotions,
    required this.brandColor,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<PromotionsHorizontalList> createState() => _PromotionsHorizontalListState();
}

class _PromotionsHorizontalListState extends State<PromotionsHorizontalList> {
  late final PageController _pageCtrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.promotions;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Container(
                //   width: 28,
                //   height: 28,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFFFFF1EC),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: const Icon(
                //     Icons.local_fire_department_rounded,
                //     size: 16,
                //     color: Color(0xFFFF5A36),
                //   ),
                // ),
                // const SizedBox(width: 10),
                const Text(
                  'Ofertas em destaque',
                  style: TextStyle(
                    fontSize: 18,
                    color: _DS.ink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (promos.length > 1)
                  Text(
                    '${_current + 1}/${promos.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: PageView.builder(
              controller: _pageCtrl,
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: promos.length,
              itemBuilder: (_, i) => _PremiumPromoCard(
                promo: promos[i],
                brandColor: widget.brandColor,
                onTap: () => widget.onTap(promos[i]),
                onAdd: () => widget.onAdd(promos[i]),
              ),
            ),
          ),
          if (promos.length > 1) ...[
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < promos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _current ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _current ? widget.brandColor : _DS.hairline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PremiumPromoCard extends StatefulWidget {
  final PublicPromotionModel promo;
  final Color brandColor;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _PremiumPromoCard({
    required this.promo,
    required this.brandColor,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<_PremiumPromoCard> createState() => _PremiumPromoCardState();
}

class _PremiumPromoCardState extends State<_PremiumPromoCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    final brand = widget.brandColor;
    final hasImage = (p.imageUrl ?? '').isNotEmpty;
    final discount = p.discountPercent?.toStringAsFixed(0) ?? '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _DSx.cardBg,
              borderRadius: BorderRadius.circular(_DSx.rCard),
              boxShadow: _DSx.shadowSoft,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero image bem grande
                Stack(
                  children: [
                    SizedBox(
                      height: 128,
                      width: double.infinity,
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: p.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: brand.withValues(alpha: 0.10)),
                              errorWidget: (_, __, ___) => Container(
                                color: brand.withValues(alpha: 0.10),
                                child: Icon(
                                  Icons.local_offer_rounded,
                                  size: 40,
                                  color: brand.withValues(alpha: 0.5),
                                ),
                              ),
                            )
                          : Container(
                              color: brand.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.local_offer_rounded,
                                size: 40,
                                color: brand.withValues(alpha: 0.55),
                              ),
                            ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Discount badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5A36), Color(0xFFFF8A65)],
                          ),
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5A36).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$discount% OFF',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Título sobreposto
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Text(
                        p.name ?? 'Promoção',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _DSx.text(
                          size: 18,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ).copyWith(
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Conteúdo inferior — preços + CTA
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if ((p.description ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    p.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _DSx.text(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: _DS.steel,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currFmt.format(p.finalPrice ?? 0),
                                    style: _DSx.text(
                                      size: 22,
                                      weight: FontWeight.w800,
                                      color: brand,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      _currFmt.format(p.originalPrice ?? 0),
                                      style: _DSx.text(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: const Color(0xFFB0142A),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: const Color(0xFFB0142A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onAdd,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: brand,
                              borderRadius: BorderRadius.circular(_DS.rFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Adicionar',
                                  style: _DSx.text(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet premium de detalhes da promoção — hero visual + price highlight,
/// itens inclusos em mini-cards, observações, quantidade e CTA fixo.
class PromotionDetailsSheet extends StatefulWidget {
  final PublicPromotionModel promo;
  final Color brandColor;
  final void Function(int quantity, String? notes) onAdd;
  const PromotionDetailsSheet({
    super.key,
    required this.promo,
    required this.brandColor,
    required this.onAdd,
  });

  @override
  State<PromotionDetailsSheet> createState() => _PromotionDetailsSheetState();
}

class _PromotionDetailsSheetState extends State<PromotionDetailsSheet> with SingleTickerProviderStateMixin {
  int _qty = 1;
  final _notesCtrl = TextEditingController();
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  static const _kAccentOrange = Color(0xFFFF5A36);
  static const _kAccentOrangeLight = Color(0xFFFF8A65);
  static const _kSavingsBg = Color(0xFFFFF1EC);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _entryCtrl.forward());
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _inc() => setState(() => _qty = (_qty + 1).clamp(1, 99));
  void _dec() => setState(() => _qty = (_qty - 1).clamp(1, 99));

  @override
  Widget build(BuildContext context) {
    final p = widget.promo;
    final brand = widget.brandColor;

    final originalUnit = p.originalPrice ?? 0;
    final finalUnit = p.finalPrice ?? 0;
    final savingsUnit = (originalUnit - finalUnit).clamp(0, double.infinity).toDouble();
    final discountPct = p.discountPercent?.toStringAsFixed(0) ?? '0';
    final totalNow = finalUnit * _qty;
    final totalSavings = savingsUnit * _qty;
    final items = p.items ?? const [];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(_DS.rXl + 12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              CustomScrollView(
                controller: scrollCtrl,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _PromotionHeroBanner(
                      imageUrl: p.imageUrl,
                      brandColor: brand,
                      discountLabel: '$discountPct% OFF',
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _entryAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(_entryAnim),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PromotionTagsRow(
                                discountPct: discountPct,
                                itemsCount: items.length,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p.name ?? 'Promoção',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: _DS.ink,
                                  height: 1.15,
                                ),
                              ),
                              if ((p.description ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  p.description!.trim(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: _DS.steel,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              _PromotionPriceHighlight(
                                originalPrice: originalUnit,
                                finalPrice: finalUnit,
                                savings: savingsUnit,
                                discountPct: discountPct,
                                brandColor: brand,
                              ),
                              if (items.isNotEmpty) ...[
                                const SizedBox(height: 22),
                                _PromotionIncludedItems(
                                  items: items,
                                  brandColor: brand,
                                ),
                              ],
                              const SizedBox(height: 22),
                              _PromotionNotesField(controller: _notesCtrl),
                              const SizedBox(height: 18),
                              _PromotionPerksRow(savingsLabel: _currFmt.format(savingsUnit)),
                              // Espaço para o CTA fixo no rodapé
                              const SizedBox(height: 160),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Handle de arraste no topo
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // CTA fixo
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PromotionCTASection(
                  qty: _qty,
                  onInc: _inc,
                  onDec: _dec,
                  totalPrice: totalNow,
                  totalSavings: totalSavings,
                  brandColor: brand,
                  onAdd: () => widget.onAdd(
                    _qty,
                    _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PromotionHeroBanner extends StatelessWidget {
  final String? imageUrl;
  final Color brandColor;
  final String discountLabel;
  final VoidCallback onClose;
  const _PromotionHeroBanner({
    required this.imageUrl,
    required this.brandColor,
    required this.discountLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').isNotEmpty;
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Hero(
              tag: 'promo_hero_$imageUrl',
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: brandColor.withValues(alpha: 0.10)),
                errorWidget: (_, __, ___) => _PromotionHeroFallback(brandColor: brandColor),
              ),
            )
          else
            _PromotionHeroFallback(brandColor: brandColor),
          // Gradient escurecendo a parte inferior para legibilidade
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x33000000),
                  Color(0x88000000),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Botão fechar (top-right)
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onClose,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(Icons.close_rounded, size: 18, color: _DS.ink),
                ),
              ),
            ),
          ),
          // Badge de desconto (top-left) com glow
          Positioned(
            top: 14,
            left: 16,
            child: _PromotionTagBadge(
              icon: Icons.local_fire_department_rounded,
              label: discountLabel,
              gradient: const LinearGradient(
                colors: [
                  _PromotionDetailsSheetState._kAccentOrange,
                  _PromotionDetailsSheetState._kAccentOrangeLight,
                ],
              ),
              glowColor: _PromotionDetailsSheetState._kAccentOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionHeroFallback extends StatelessWidget {
  final Color brandColor;
  const _PromotionHeroFallback({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandColor.withValues(alpha: 0.25),
            brandColor.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_offer_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _PromotionTagBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color glowColor;
  const _PromotionTagBadge({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionTagsRow extends StatelessWidget {
  final String discountPct;
  final int itemsCount;
  const _PromotionTagsRow({required this.discountPct, required this.itemsCount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _SoftChip(
          icon: Icons.bolt_rounded,
          label: 'Oferta limitada',
          fg: Color(0xFFB45309),
          bg: Color(0xFFFFF4C4),
        ),
        if (itemsCount > 0)
          _SoftChip(
            icon: Icons.shopping_bag_rounded,
            label: '$itemsCount ${itemsCount == 1 ? "item" : "itens"} no combo',
            fg: const Color(0xFF065F46),
            bg: const Color(0xFFD1FAE5),
          ),
        const _SoftChip(
          icon: Icons.trending_up_rounded,
          label: 'Mais pedido',
          fg: Color(0xFF6D28D9),
          bg: Color(0xFFEDE9FE),
        ),
      ],
    );
  }
}

class _SoftChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  const _SoftChip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionPriceHighlight extends StatelessWidget {
  final double originalPrice;
  final double finalPrice;
  final double savings;
  final String discountPct;
  final Color brandColor;
  const _PromotionPriceHighlight({
    required this.originalPrice,
    required this.finalPrice,
    required this.savings,
    required this.discountPct,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brandColor.withValues(alpha: 0.06),
            brandColor.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: brandColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (originalPrice > 0)
                  Text(
                    'De ${_currFmt.format(originalPrice)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _DS.stone,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: _DS.muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Por',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: brandColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _currFmt.format(finalPrice),
                  style: TextStyle(
                    fontSize: 30,
                    color: brandColor,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (savings > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: _PromotionDetailsSheetState._kAccentOrange,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Economize',
                      style: TextStyle(
                        fontSize: 11,
                        color: _PromotionDetailsSheetState._kAccentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _currFmt.format(savings),
                  style: const TextStyle(
                    fontSize: 15,
                    color: _PromotionDetailsSheetState._kAccentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$discountPct% OFF',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _PromotionDetailsSheetState._kAccentOrange.withValues(alpha: 0.85),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PromotionIncludedItems extends StatelessWidget {
  final List<PublicPromotionItemEntity> items;
  final Color brandColor;
  const _PromotionIncludedItems({required this.items, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 15,
                color: brandColor,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Inclui no combo',
              style: TextStyle(
                fontSize: 14.5,
                color: _DS.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${items.length} ${items.length == 1 ? "item" : "itens"}',
              style: const TextStyle(
                fontSize: 12.5,
                color: _DS.stone,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _PromotionMiniProductCard(
              item: items[i],
              brandColor: brandColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionMiniProductCard extends StatelessWidget {
  final PublicPromotionItemEntity item;
  final Color brandColor;
  const _PromotionMiniProductCard({required this.item, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    final hasImage = (item.imageUrl ?? '').isNotEmpty;
    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 76,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: brandColor.withValues(alpha: 0.08)),
                        errorWidget: (_, __, ___) => Container(
                          color: brandColor.withValues(alpha: 0.10),
                          child: Icon(
                            Icons.restaurant_rounded,
                            size: 24,
                            color: brandColor.withValues(alpha: 0.55),
                          ),
                        ),
                      )
                    : Container(
                        color: brandColor.withValues(alpha: 0.10),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 24,
                          color: brandColor.withValues(alpha: 0.55),
                        ),
                      ),
              ),
              if ((item.quantity) > 1)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Text(
              item.name ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _DS.ink,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionNotesField extends StatelessWidget {
  final TextEditingController controller;
  const _PromotionNotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: _DS.steel,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Observações',
              style: TextStyle(
                fontSize: 14.5,
                color: _DS.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '· opcional',
              style: TextStyle(
                fontSize: 12,
                color: _DS.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 13.5, color: _DS.ink, height: 1.35),
          decoration: InputDecoration(
            hintText: 'Ex: sem cebola, ponto da carne, troca de bebida...',
            hintStyle: const TextStyle(fontSize: 13, color: _DS.muted),
            filled: true,
            fillColor: _DS.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DS.rLg),
              borderSide: const BorderSide(color: _DS.hairline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DS.rLg),
              borderSide: const BorderSide(color: _DS.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DS.rLg),
              borderSide: const BorderSide(color: _DS.brandBlue, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromotionPerksRow extends StatelessWidget {
  final String savingsLabel;
  const _PromotionPerksRow({required this.savingsLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          _PerkItem(
            icon: Icons.savings_rounded,
            title: savingsLabel,
            subtitle: 'de economia',
            color: _PromotionDetailsSheetState._kAccentOrange,
          ),
          Container(
            width: 1,
            height: 32,
            color: _DS.hairlineSoft,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          const _PerkItem(
            icon: Icons.verified_rounded,
            title: 'Oferta verificada',
            subtitle: 'pelo restaurante',
            color: _DS.successAccent,
          ),
        ],
      ),
    );
  }
}

class _PerkItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _PerkItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _DS.ink,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _DS.stone,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionCTASection extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final double totalPrice;
  final double totalSavings;
  final Color brandColor;
  final VoidCallback onAdd;
  const _PromotionCTASection({
    required this.qty,
    required this.onInc,
    required this.onDec,
    required this.totalPrice,
    required this.totalSavings,
    required this.brandColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom * 0 + 8,
      ),
      decoration: BoxDecoration(
        color: _DS.canvas,
        border: const Border(top: BorderSide(color: _DS.hairlineSoft)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _QtyStepper(qty: qty, onInc: onInc, onDec: onDec),
            const SizedBox(width: 12),
            Expanded(
              child: _AddPromoButton(
                brandColor: brandColor,
                totalPrice: totalPrice,
                totalSavings: totalSavings,
                onTap: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyStepper({required this.qty, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            enabled: qty > 1,
            onTap: onDec,
          ),
          SizedBox(
            width: 26,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text(
                '$qty',
                key: ValueKey(qty),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: _DS.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            enabled: qty < 99,
            onTap: onInc,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _DS.canvas : _DS.hairlineSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _DS.ink : _DS.muted,
          ),
        ),
      ),
    );
  }
}

class _AddPromoButton extends StatefulWidget {
  final Color brandColor;
  final double totalPrice;
  final double totalSavings;
  final VoidCallback onTap;
  const _AddPromoButton({
    required this.brandColor,
    required this.totalPrice,
    required this.totalSavings,
    required this.onTap,
  });

  @override
  State<_AddPromoButton> createState() => _AddPromoButtonState();
}

class _AddPromoButtonState extends State<_AddPromoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final brand = widget.brandColor;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                brand,
                Color.lerp(brand, Colors.black, 0.12) ?? brand,
              ],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Adicionar',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _currFmt.format(widget.totalPrice),
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill premium com glow leve usado tanto no banner principal quanto inline
/// ao lado do nome do restaurante. Substitui o `_ClosedBanner` (removido).
class _StatusPill extends StatelessWidget {
  final bool isOpen;
  final bool dense;
  final bool onBanner;
  const _StatusPill({required this.isOpen, this.dense = false, this.onBanner = false});

  @override
  Widget build(BuildContext context) {
    final accent = isOpen ? const Color(0xFF00B473) : const Color(0xFFFF5A36);
    final dotColor = onBanner ? Colors.white : accent;
    final textColor = onBanner ? Colors.white : accent;
    final bg = onBanner ? Colors.white.withValues(alpha: 0.18) : (isOpen ? const Color(0xFFE9FBF3) : const Color(0xFFF1F2F5));
    final borderColor = onBanner ? Colors.white.withValues(alpha: 0.35) : accent.withValues(alpha: 0.20);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DSx.rCard),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dense ? 6 : 7,
            height: dense ? 6 : 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: isOpen && !onBanner
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          SizedBox(width: dense ? 6 : 7),
          Text(
            isOpen ? 'Aberto' : 'Fechado',
            style: _DSx.text(
              size: dense ? 11 : 12,
              weight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogoBadge extends StatelessWidget {
  final String? logoUrl;
  final String companyName;
  final Color brandColor;
  final double size;
  const _CompanyLogoBadge({
    required this.logoUrl,
    required this.companyName,
    required this.brandColor,
    this.size = 86,
  });

  @override
  Widget build(BuildContext context) {
    final initial = companyName.isEmpty ? '?' : companyName[0].toUpperCase();
    final initialFontSize = size * 0.36;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl ?? '').isEmpty
          ? Center(
              child: Text(
                initial,
                style: TextStyle(fontSize: initialFontSize, color: brandColor),
              ),
            )
          : CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: TextStyle(fontSize: initialFontSize, color: brandColor),
                ),
              ),
            ),
    );
  }
}

// ─── Hero banner with logo, company name and status ──────────────────────────
class _HeroBanner extends StatelessWidget {
  final String? bannerUrl;
  final String? logoUrl;
  final String companyName;
  final String? description;
  final Color brandColor;
  final bool isOpen;
  final int? avgPrepMinutes;
  final int productsCount;
  final int promotionsCount;
  final VoidCallback onSearch;
  final VoidCallback onTapInfo;
  final VoidCallback onShare;

  const _HeroBanner({
    required this.bannerUrl,
    required this.logoUrl,
    required this.companyName,
    required this.description,
    required this.brandColor,
    required this.isOpen,
    required this.avgPrepMinutes,
    required this.productsCount,
    required this.promotionsCount,
    required this.onSearch,
    required this.onTapInfo,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    const bannerHeight = 180.0;
    final hasBanner = (bannerUrl ?? '').isNotEmpty;
    final hasDesc = (description ?? '').isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner principal com info sobreposta ────────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: SizedBox(
            height: bannerHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasBanner
                    ? CachedNetworkImage(
                        imageUrl: bannerUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: brandColor.withValues(alpha: 0.85)),
                        errorWidget: (_, __, ___) => Container(color: brandColor),
                      )
                    : Container(color: brandColor),

                // Gradiente linear preto reforçado na base
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),

                if (promotionsCount > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _BannerBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: '$promotionsCount ${promotionsCount == 1 ? "promoção" : "promoções"}',
                      color: const Color(0xFFFF5A36),
                    ),
                  ),

                // Topo direito: tempo médio de preparo + compartilhar link
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (avgPrepMinutes != null && avgPrepMinutes! > 0) ...[
                        _PrepTimeBadge(minutes: avgPrepMinutes!),
                        const SizedBox(width: 8),
                      ],
                      _BannerShareButton(onTap: onShare),
                    ],
                  ),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        // Toque na logo/nome abre os detalhes do restaurante.
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onTapInfo,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _CompanyLogoBadge(
                                  logoUrl: logoUrl,
                                  companyName: companyName,
                                  brandColor: brandColor,
                                  size: 56,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              companyName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: _DSx.text(
                                                size: 20,
                                                weight: FontWeight.w700,
                                                color: Colors.white,
                                                height: 1.15,
                                                letterSpacing: -0.2,
                                              ).copyWith(
                                                shadows: const [
                                                  Shadow(blurRadius: 6, color: Colors.black38),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isOpen) ...[
                                            const SizedBox(width: 8),
                                            const _OpenPulseDot(),
                                          ],
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ],
                                      ),
                                      if (hasDesc) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _DSx.text(
                                            size: 12,
                                            weight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 0.88),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BannerSearchButton(onTap: onSearch),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Status de fechado + CTA de agendar (só quando fechado) ──────────
        if (!isOpen) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _ClosedSchedulePill(brandColor: brandColor),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BannerBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BannerBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.rFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _DS.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha compacta com trust pills + ícone de busca à direita.
/// Substitui o `_SearchBarPlaceholder` que ocupava uma faixa inteira do scroll.
/// Badge no canto superior direito do banner mostrando apenas o tempo médio
/// de preparo em minutos (ex.: "25 min"). Substitui o status pill.
class _PrepTimeBadge extends StatelessWidget {
  final int minutes;
  const _PrepTimeBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            '$minutes min',
            style: _DSx.text(
              size: 11,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bolinha pulsando ao lado do nome do estabelecimento quando aberto.
class _OpenPulseDot extends StatefulWidget {
  const _OpenPulseDot();

  @override
  State<_OpenPulseDot> createState() => _OpenPulseDotState();
}

class _OpenPulseDotState extends State<_OpenPulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E676);
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Container(
                width: 8 + 10 * t,
                height: 8 + 10 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: (1 - t) * 0.35),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ícone de busca circular inline na linha do banner.
class _BannerSearchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BannerSearchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Botão circular no topo do banner para compartilhar (copiar) o link do
/// cardápio. Mesmo estilo translúcido do botão de busca.
class _BannerShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BannerShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: 'Compartilhar link do cardápio',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Pill abaixo do banner mostrando "Fechado — agende seu pedido" quando a
/// loja está fora do horário de atendimento. Aparece somente nesse caso.
class _ClosedSchedulePill extends StatelessWidget {
  final Color brandColor;
  const _ClosedSchedulePill({required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              size: 14,
              color: Color(0xFFFF5A36),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fechado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF5A36),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Você pode agendar seu pedido pra mais tarde',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: brandColor,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão circular elegante que dispara o modo busca.
/// Substitui visualmente a barra fixa antiga, mantendo todo o comportamento
/// (animação, foco automático, teclado) intacto.
class _CompactSearchTrigger extends StatefulWidget {
  final Color brandColor;
  final VoidCallback onTap;
  const _CompactSearchTrigger({required this.brandColor, required this.onTap});

  @override
  State<_CompactSearchTrigger> createState() => _CompactSearchTriggerState();
}

class _CompactSearchTriggerState extends State<_CompactSearchTrigger> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final scale = _down ? 0.94 : (_hover ? 1.04 : 1.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _DS.canvas,
              shape: BoxShape.circle,
              border: Border.all(
                color: _hover ? widget.brandColor.withValues(alpha: 0.45) : _DS.hairlineSoft,
              ),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: widget.brandColor.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 18,
              color: widget.brandColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search bar placeholder (in-scroll, não é TextField) ─────────────────────
// Mantido para reuso futuro (substituído pelo `_CompactSearchTrigger` inline).
// ignore: unused_element
class _SearchBarPlaceholder extends StatelessWidget {
  final Color brandColor;
  final VoidCallback onTap;
  const _SearchBarPlaceholder({required this.brandColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: _DS.canvas,
          border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: brandColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Buscar pratos, bebidas, ingredientes...',
                  style: TextStyle(color: _DS.stone, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sticky search bar (appears at top when search mode is active) ────────────
class _StickySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color brandColor;
  final bool showCancel;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  const _StickySearchBar({
    required this.controller,
    required this.focusNode,
    required this.brandColor,
    required this.showCancel,
    required this.onChanged,
    required this.onClear,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _DS.canvas,
        border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: _DS.ink, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar pratos, bebidas, ingredientes...',
                hintStyle: const TextStyle(color: _DS.stone, fontSize: 13.5),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: Icon(Icons.search_rounded, color: brandColor, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                suffixIcon: hasText
                    ? IconButton(
                        iconSize: 16,
                        splashRadius: 18,
                        icon: const Icon(Icons.close_rounded, color: _DS.stone),
                        onPressed: onClear,
                      )
                    : null,
                filled: true,
                fillColor: _DS.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _DS.hairlineSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: brandColor, width: 1.5),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            child: showCancel
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: brandColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Search results header ───────────────────────────────────────────────────
class _SearchResultsHeader extends StatelessWidget {
  final String query;
  final int count;
  final Color brandColor;
  const _SearchResultsHeader({
    required this.query,
    required this.count,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: _DS.ink,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: count > 0 ? '$count ${count == 1 ? "resultado" : "resultados"} para ' : 'Nenhum resultado para ',
                  ),
                  TextSpan(
                    text: '"$query"',
                    style: TextStyle(color: brandColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Add button / quantity stepper ───────────────────────────────────────────
class _AddCircleButton extends StatelessWidget {
  final int qty;
  final Color brandColor;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  const _AddCircleButton({
    required this.qty,
    required this.brandColor,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
          child: child,
        ),
      ),
      child: inCart
          ? _QtyStepperInline(
              key: const ValueKey('stepper'),
              qty: qty,
              brandColor: brandColor,
              onAdd: onAdd,
              onRemove: onRemove,
            )
          : _PlusBubble(
              key: const ValueKey('plus'),
              brandColor: brandColor,
              onTap: onAdd,
            ),
    );
  }
}

class _PlusBubble extends StatelessWidget {
  final Color brandColor;
  final VoidCallback onTap;
  const _PlusBubble({super.key, required this.brandColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: brandColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: brandColor.withValues(alpha: 0.24),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _QtyStepperInline extends StatelessWidget {
  final int qty;
  final Color brandColor;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  const _QtyStepperInline({
    super.key,
    required this.qty,
    required this.brandColor,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: brandColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperIcon(
            icon: Icons.remove,
            onTap: onRemove,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                sizeFactor: anim,
                axis: Axis.vertical,
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey(qty),
              width: 22,
              child: Center(
                child: Text(
                  '$qty',
                  style: _DSx.text(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          _StepperIcon(
            icon: Icons.add,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepperIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 32,
          height: 36,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

// ─── Empty results state ─────────────────────────────────────────────────────
class _SearchEmptyState extends StatelessWidget {
  final String query;
  const _SearchEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_off_rounded, color: _DS.stone, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Não encontramos "$query"',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _DS.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Veja algumas sugestões abaixo.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _DS.steel,
                      height: 1.35,
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
}

// ─── Horizontal suggestions list ─────────────────────────────────────────────
class _SuggestionsList extends StatelessWidget {
  final String title;
  final List<PublicMenuItemModel> items;
  final Color brandColor;
  final int Function(int) cartQtyOf;
  final void Function(PublicMenuItemModel) onTap;
  final void Function(PublicMenuItemModel) onAdd;

  const _SuggestionsList({
    required this.title,
    required this.items,
    required this.brandColor,
    required this.cartQtyOf,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: brandColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.ink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = items[i];
                final qty = cartQtyOf(item.id ?? -1);
                return _SuggestionCard(
                  item: item,
                  brandColor: brandColor,
                  qty: qty,
                  onTap: () => onTap(item),
                  onAdd: () => onAdd(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final PublicMenuItemModel item;
  final Color brandColor;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _SuggestionCard({
    required this.item,
    required this.brandColor,
    required this.qty,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (item.imageUrl ?? '').isNotEmpty;
    return SizedBox(
      width: 144,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_DS.rXl),
          child: Container(
            decoration: BoxDecoration(
              color: _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rXl),
              border: Border.all(
                color: qty > 0 ? brandColor.withValues(alpha: 0.3) : _DS.hairlineSoft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(_DS.rXl)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: _DS.surface),
                            errorWidget: (_, __, ___) => Container(
                              color: _DS.surface,
                              alignment: Alignment.center,
                              child: const Icon(Icons.fastfood_outlined, color: _DS.muted, size: 22),
                            ),
                          )
                        : Container(
                            color: _DS.surface,
                            alignment: Alignment.center,
                            child: const Icon(Icons.fastfood_outlined, color: _DS.muted, size: 22),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? '—',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _DS.ink,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _currFmt.format(item.price ?? 0),
                              style: const TextStyle(
                                fontSize: 13,
                                color: _DS.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _AddCircleButton(
                            qty: qty,
                            brandColor: brandColor,
                            onAdd: onAdd,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedCard extends StatelessWidget {
  final PublicMenuItemModel item;
  final Color brandColor;
  final bool inCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const FeaturedCard({
    super.key,
    required this.item,
    required this.brandColor,
    required this.inCart,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: inCart ? brandColor.withValues(alpha: 0.35) : _DS.hairlineSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: (item.imageUrl ?? '').isEmpty
                    ? Container(color: _DS.surface, child: const Center(child: Icon(Icons.fastfood_outlined, color: _DS.muted)))
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(color: _DS.hairlineSoft),
                        errorWidget: (_, __, ___) => Container(color: _DS.surface, child: const Center(child: Icon(Icons.fastfood_outlined, color: _DS.muted))),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 52, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: _DS.ink)),
                  if ((item.description ?? '').isNotEmpty) Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _DS.stone)),
                  const SizedBox(height: 4),
                  Text(_currFmt.format(item.price ?? 0), style: const TextStyle(fontSize: 14, color: _DS.ink)),
                ]),
              ),
            ]),
            Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle),
                  child: const Icon(Icons.add, size: 19, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<PublicMenuItemModel> items;
  final Color brandColor;
  final int Function(int menuItemId) cartQtyOf;
  final void Function(PublicMenuItemModel) onTap;
  final void Function(PublicMenuItemModel) onAdd;
  final void Function(PublicMenuItemModel) onRemove;
  const _CategorySection({super.key, required this.title, required this.items, required this.brandColor, required this.cartQtyOf, required this.onTap, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            title,
            style: _DSx.text(
              size: 18,
              weight: FontWeight.w700,
              color: _DS.ink,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ...items.map((item) {
          final qty = cartQtyOf(item.id!);
          return FoodCard(
            item: item,
            brandColor: brandColor,
            cartQty: qty,
            onTap: () => onTap(item),
            onAdd: () => onAdd(item),
            onRemove: qty > 0 ? () => onRemove(item) : null,
          );
        }),
      ]),
    );
  }
}

class FoodCard extends StatelessWidget {
  final PublicMenuItemModel item;
  final Color brandColor;
  final int cartQty;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final String? categoryLabel;
  const FoodCard({
    super.key,
    required this.item,
    required this.brandColor,
    required this.cartQty,
    required this.onTap,
    required this.onAdd,
    this.onRemove,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoryLabel != null) ...[
                        Text(
                          categoryLabel!.toUpperCase(),
                          style: _DSx.text(
                            size: 10,
                            weight: FontWeight.w700,
                            color: _DS.stone,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (item.featured) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _DSx.yellowSoftBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('★', style: TextStyle(fontSize: 11, color: _DSx.yellowSoftFg)),
                              const SizedBox(width: 4),
                              Text(
                                'DESTAQUE',
                                style: _DSx.text(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: _DSx.yellowSoftFg,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        item.name ?? '',
                        style: _DSx.text(
                          size: 16,
                          weight: FontWeight.w700,
                          color: _DS.ink,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if ((item.description ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _DSx.text(
                              size: 13,
                              weight: FontWeight.w500,
                              color: _DS.steel,
                              height: 1.4,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            _currFmt.format(item.price ?? 0),
                            style: _DSx.text(
                              size: 17,
                              weight: FontWeight.w800,
                              color: _DS.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if ((item.prepTimeMinutes ?? 0) > 0) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.access_time_rounded, size: 12, color: _DS.stone),
                            const SizedBox(width: 4),
                            Text(
                              '~${item.prepTimeMinutes} min',
                              style: _DSx.text(
                                size: 12,
                                weight: FontWeight.w500,
                                color: _DS.stone,
                              ),
                            ),
                          ],
                          const Spacer(),
                          _AddCircleButton(
                            qty: cartQty,
                            brandColor: brandColor,
                            onAdd: onAdd,
                            onRemove: onRemove,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (item.imageUrl ?? '').isEmpty
                      ? Container(width: 96, height: 96, color: _DS.surface, child: const Icon(Icons.fastfood_outlined, color: _DS.muted))
                      : CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(width: 96, height: 96, color: _DS.hairlineSoft),
                          errorWidget: (_, __, ___) => Container(width: 96, height: 96, color: _DS.surface, child: const Icon(Icons.fastfood_outlined, color: _DS.muted)),
                        ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: _DS.hairlineSoft),
      ],
    );
  }
}

class _FloatingCartButton extends StatefulWidget {
  final int count;
  final double total;
  final Color brandColor;
  final VoidCallback onTap;
  const _FloatingCartButton({
    super.key,
    required this.count,
    required this.total,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends State<_FloatingCartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant _FloatingCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _bounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final itemsLabel = count == 1 ? 'item' : 'itens';
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) {
        final v = Curves.elasticOut.transform(_bounce.value);
        final scale = 1.0 + (0.06 * (1 - (v - 1).abs()).clamp(0.0, 1.0));
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  color: widget.brandColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _DSx.shadowFloating,
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ver sacola',
                                style: _DSx.text(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '•',
                                  style: _DSx.text(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                              Text(
                                '$count $itemsLabel',
                                style: _DSx.text(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '•',
                                  style: _DSx.text(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                              Text(
                                _currFmt.format(widget.total),
                                style: _DSx.text(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product detail sheet (premium) ───────────────────────────────────────────
class _ProductDetailSheet extends StatefulWidget {
  final PublicMenuItemModel item;
  final Color brandColor;
  final int initialQty;
  final void Function(int qty, String? notes, List<_PubCartOption> options) onAdd;
  // Modo "somente opções": usado para coletar as opções de um item dentro de um
  // combo. Esconde o seletor de quantidade e o botão confirma sem preço.
  final bool optionsOnly;
  final String? confirmLabel;
  const _ProductDetailSheet({
    required this.item,
    required this.brandColor,
    required this.initialQty,
    required this.onAdd,
    this.optionsOnly = false,
    this.confirmLabel,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  late int _qty;
  final _notesCtrl = TextEditingController();

  // Options selection state
  final _repo = ProductOptionsRepository();
  bool _loadingOptions = false;
  String? _optionsError;
  List<ProductOptionGroupModel> _groups = [];

  /// Map<groupId, Map<optionId, qty>>
  final Map<int, Map<int, int>> _selection = {};

  @override
  void initState() {
    super.initState();
    _qty = widget.initialQty;
    if (widget.item.hasOptions && widget.item.id != null) {
      _loadOptions(widget.item.id!);
    }
  }

  Future<void> _loadOptions(int productId) async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    final res = await _repo.findPublicByProduct(productId);
    if (!mounted) return;
    if (res.success && res.data is List<ProductOptionGroupModel>) {
      setState(() {
        _groups = res.data as List<ProductOptionGroupModel>;
        _loadingOptions = false;
      });
    } else {
      setState(() {
        _loadingOptions = false;
        _optionsError = res.message;
      });
    }
  }

  int _qtyOf(int groupId, int optionId) => _selection[groupId]?[optionId] ?? 0;

  int _totalSelected(ProductOptionGroupModel g) {
    final map = _selection[g.id ?? 0];
    if (map == null) return 0;
    return map.values.fold<int>(0, (s, v) => s + v);
  }

  double get _extraPerUnit {
    var total = 0.0;
    for (final g in _groups) {
      final map = _selection[g.id ?? 0];
      if (map == null) continue;
      for (final entry in map.entries) {
        final item = g.items.firstWhere(
          (it) => it.id == entry.key,
          orElse: () => ProductOptionItemModel(),
        );
        total += item.additionalPrice * entry.value;
      }
    }
    return total;
  }

  void _setSingle(ProductOptionGroupModel g, int optionId) {
    setState(() {
      _selection[g.id ?? 0] = {optionId: 1};
    });
  }

  void _toggleMultiple(ProductOptionGroupModel g, int optionId) {
    setState(() {
      final map = _selection.putIfAbsent(g.id ?? 0, () => {});
      if (map.containsKey(optionId)) {
        map.remove(optionId);
      } else {
        if (g.maxSelection > 0 && _totalSelected(g) >= g.maxSelection) return;
        map[optionId] = 1;
      }
    });
  }

  void _setQuantity(ProductOptionGroupModel g, int optionId, int qty) {
    setState(() {
      final map = _selection.putIfAbsent(g.id ?? 0, () => {});
      if (qty <= 0) {
        map.remove(optionId);
      } else {
        if (g.maxSelection > 0) {
          final others = map.entries.where((e) => e.key != optionId).fold<int>(0, (s, e) => s + e.value);
          final maxForThis = g.maxSelection - others;
          if (maxForThis <= 0) return;
          map[optionId] = qty.clamp(0, maxForThis);
        } else {
          map[optionId] = qty;
        }
      }
    });
  }

  String? _validateRequired() {
    for (final g in _groups) {
      final total = _totalSelected(g);
      if (g.isRequired) {
        final min = g.minSelection < 1 ? 1 : g.minSelection;
        if (total < min) {
          return min == 1 ? 'Selecione uma opção em "${g.name}"' : 'Escolha pelo menos $min em "${g.name}"';
        }
      }
    }
    return null;
  }

  List<_PubCartOption> _buildSelectionSnapshot() {
    final out = <_PubCartOption>[];
    for (final g in _groups) {
      final map = _selection[g.id ?? 0];
      if (map == null) continue;
      for (final entry in map.entries) {
        final item = g.items.firstWhere(
          (it) => it.id == entry.key,
          orElse: () => ProductOptionItemModel(),
        );
        if (item.id == null) continue;
        out.add(_PubCartOption(
          groupId: g.id,
          groupName: g.name,
          optionId: item.id,
          optionName: item.name,
          additionalPrice: item.additionalPrice,
          quantity: entry.value,
        ));
      }
    }
    return out;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final brand = widget.brandColor;
    final hasImg = (item.imageUrl ?? '').isNotEmpty;
    return Container(
      decoration: const BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _DS.hairline,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 0,
                right: 0,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image with gradient overlay
                  Stack(
                    children: [
                      SizedBox(
                        height: hasImg ? 220 : 140,
                        width: double.infinity,
                        child: hasImg
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(brand),
                              )
                            : _imageFallback(brand),
                      ),
                      if (hasImg)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                _currFmt.format(item.price ?? 0),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: brand,
                                ),
                              ),
                            ),
                            if ((item.prepTimeMinutes ?? 0) > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 12, color: _DS.slate),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.prepTimeMinutes} min',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _DS.slate,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            color: _DS.ink,
                            height: 1.15,
                          ),
                        ),
                        if ((item.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _DS.steel,
                              height: 1.5,
                            ),
                          ),
                        ],
                        if (item.hasOptions) ...[
                          const SizedBox(height: 18),
                          _buildOptionsSection(brand),
                        ],
                        const SizedBox(height: 22),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14, color: _DS.ink),
                          decoration: InputDecoration(
                            hintText: 'Ex: sem cebola, molho separado...',
                            hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _DS.hairline)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _DS.hairline)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: brand, width: 2)),
                            filled: true,
                            fillColor: _DS.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Rodapé fixo: stepper de quantidade + botão Adicionar ──────────
          _buildStickyAddBar(brand),
        ],
      ),
    );
  }

  /// Rodapé fixo do sheet — não scrolla com o conteúdo. Garante que o botão
  /// "Adicionar" esteja sempre visível, independentemente da quantidade de
  /// adicionais que o produto possua.
  Widget _buildStickyAddBar(Color brand) {
    final item = widget.item;
    final hasBlockingError = _loadingOptions;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: _DS.canvas,
        border: Border(top: BorderSide(color: _DS.hairlineSoft)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!widget.optionsOnly) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _DS.hairline),
                ),
                child: Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove,
                      onTap: () {
                        if (_qty > 1) setState(() => _qty--);
                      },
                      enabled: _qty > 1,
                    ),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            '$_qty',
                            key: ValueKey(_qty),
                            style: const TextStyle(
                              fontSize: 16,
                              color: _DS.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add,
                      onTap: () => setState(() => _qty++),
                      brand: brand,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: hasBlockingError
                      ? null
                      : () {
                          final err = _validateRequired();
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err), backgroundColor: _DS.danger),
                            );
                            return;
                          }
                          widget.onAdd(
                            _qty,
                            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                            _buildSelectionSnapshot(),
                          );
                          Navigator.pop(context);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: brand,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    widget.optionsOnly
                        ? (widget.confirmLabel ?? 'Confirmar opções')
                        : 'Adicionar · ${_currFmt.format(((item.price ?? 0) + _extraPerUnit) * _qty)}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Options UI ────────────────────────────────────────────────────────────
  Widget _buildOptionsSection(Color brand) {
    if (_loadingOptions) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.rXl),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_optionsError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(
          'Não foi possível carregar as opções. ($_optionsError)',
          style: const TextStyle(fontSize: 12, color: _DS.danger),
        ),
      );
    }
    if (_groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _groups.length; i++) ...[
          _buildGroup(_groups[i], brand),
          if (i < _groups.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildGroup(ProductOptionGroupModel g, Color brand) {
    final subtitle = _groupSubtitle(g);
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: _DS.surface,
              border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              g.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _DS.ink,
                              ),
                            ),
                          ),
                          if (g.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Obrigatório',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _DS.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.steel,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < g.items.length; i++) _buildOptionRow(g, g.items[i] as ProductOptionItemModel, brand, isLast: i == g.items.length - 1),
        ],
      ),
    );
  }

  String _groupSubtitle(ProductOptionGroupModel g) {
    switch (g.type) {
      case ProductOptionGroupType.single:
        return 'Escolha 1 opção';
      case ProductOptionGroupType.multiple:
        if (g.maxSelection == 0) return 'Escolha quantos quiser';
        return 'Escolha até ${g.maxSelection}';
      case ProductOptionGroupType.quantity:
        if (g.maxSelection == 0) return 'Adicione quantos quiser';
        return 'Até ${g.maxSelection} unidades no total';
    }
  }

  Widget _buildOptionRow(
    ProductOptionGroupModel g,
    ProductOptionItemModel item,
    Color brand, {
    required bool isLast,
  }) {
    final qty = _qtyOf(g.id ?? 0, item.id ?? 0);
    final selected = qty > 0;

    Widget control;
    switch (g.type) {
      case ProductOptionGroupType.single:
        control = _radioCircle(selected, brand);
        break;
      case ProductOptionGroupType.multiple:
        final limitReached = !selected && g.maxSelection > 0 && _totalSelected(g) >= g.maxSelection;
        control = _checkboxBox(selected, brand, disabled: limitReached);
        break;
      case ProductOptionGroupType.quantity:
        control = _qtyStepper(g, item, qty, brand);
        break;
    }

    final tappable = g.type != ProductOptionGroupType.quantity;

    return InkWell(
      onTap: !tappable
          ? null
          : () {
              if (g.type == ProductOptionGroupType.single) {
                _setSingle(g, item.id ?? 0);
              } else if (g.type == ProductOptionGroupType.multiple) {
                _toggleMultiple(g, item.id ?? 0);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected ? brand.withValues(alpha: 0.04) : Colors.transparent,
          border: isLast ? null : const Border(bottom: BorderSide(color: _DS.hairlineSoft)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: _DS.ink,
                      height: 1.25,
                    ),
                  ),
                  if (item.additionalPrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '+ ${_currFmt.format(item.additionalPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: brand,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            control,
          ],
        ),
      ),
    );
  }

  Widget _radioCircle(bool selected, Color brand) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? brand : Colors.transparent,
        border: Border.all(
          color: selected ? brand : _DS.hairline,
          width: selected ? 0 : 1.5,
        ),
      ),
      child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
    );
  }

  Widget _checkboxBox(bool selected, Color brand, {bool disabled = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: selected ? brand : Colors.transparent,
        border: Border.all(
          color: disabled
              ? _DS.hairline
              : selected
                  ? brand
                  : _DS.hairline,
          width: selected ? 0 : 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : disabled
              ? const Icon(Icons.block_rounded, size: 12, color: _DS.muted)
              : null,
    );
  }

  Widget _qtyStepper(
    ProductOptionGroupModel g,
    ProductOptionItemModel item,
    int qty,
    Color brand,
  ) {
    final canIncrement = g.maxSelection == 0 || _totalSelected(g) < g.maxSelection;
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _DS.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _miniBtn(
            icon: Icons.remove,
            onTap: qty > 0 ? () => _setQuantity(g, item.id ?? 0, qty - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: Text(
                  '$qty',
                  key: ValueKey('${item.id}-$qty'),
                  style: TextStyle(
                    fontSize: 14,
                    color: qty > 0 ? brand : _DS.ink,
                  ),
                ),
              ),
            ),
          ),
          _miniBtn(
            icon: Icons.add,
            onTap: canIncrement ? () => _setQuantity(g, item.id ?? 0, qty + 1) : null,
            brand: brand,
          ),
        ],
      ),
    );
  }

  Widget _miniBtn({
    required IconData icon,
    VoidCallback? onTap,
    Color? brand,
  }) {
    final filled = brand != null;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled && enabled ? brand : (enabled ? _DS.canvas : _DS.surface),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: _DS.hairline),
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled && enabled ? Colors.white : (enabled ? _DS.ink : _DS.muted),
        ),
      ),
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    Color? brand,
  }) {
    final filled = brand != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? brand : (enabled ? _DS.canvas : _DS.surface),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: _DS.hairline),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : (enabled ? _DS.ink : _DS.muted),
        ),
      ),
    );
  }

  Widget _imageFallback(Color brand) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.withValues(alpha: 0.15),
            brand.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.fastfood_outlined, size: 52, color: _DS.muted),
      ),
    );
  }
}

// ─── Closed banner with next-available hint ──────────────────────────────────
// Mantido para reuso futuro (substituído pelo `_StatusPill` inline).
// ignore: unused_element
class _ClosedBanner extends StatelessWidget {
  final DateTime? nextSlot;
  final Color brandColor;
  const _ClosedBanner({required this.nextSlot, required this.brandColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF92400E)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estamos fechados no momento',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF92400E),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextSlot == null ? 'Sem horários disponíveis nos próximos dias.' : 'Você pode fazer seu pedido para ${_scheduleLabel(nextSlot!, full: true)} no checkout.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF92400E),
                      height: 1.45,
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
}

// ─── Returning customer banner ───────────────────────────────────────────────
// Ocultado da UI por enquanto. Mantido para reuso futuro — toda a lógica de
// histórico no `PublicOrderPageState._openHistory` continua intacta.
// ignore: unused_element
class _ReturningCustomerBanner extends StatelessWidget {
  final String customerName;
  final Color brandColor;
  final VoidCallback onViewHistory;

  const _ReturningCustomerBanner({
    required this.customerName,
    required this.brandColor,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = customerName.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewHistory,
          borderRadius: BorderRadius.circular(_DS.rXl),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  brandColor.withValues(alpha: 0.10),
                  brandColor.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(_DS.rXl),
              border: Border.all(color: brandColor.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, size: 20, color: brandColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $firstName 👋',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DS.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Toque para ver seus pedidos anteriores.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _DS.steel,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: brandColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Meus pedidos',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Best sellers carousel (alta conversão, topo da página) ──────────────────
class _BestSellersCarousel extends StatelessWidget {
  final List<PublicMenuItemModel> items;
  final Color brandColor;
  final int Function(int) cartQtyOf;
  final void Function(PublicMenuItemModel) onTap;
  final void Function(PublicMenuItemModel) onAdd;
  final void Function(PublicMenuItemModel)? onRemove;
  const _BestSellersCarousel({
    required this.items,
    required this.brandColor,
    required this.cartQtyOf,
    required this.onTap,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                const Text('🔥 ', style: TextStyle(fontSize: 18)),
                Text(
                  'Mais pedidos',
                  style: _DSx.text(
                    size: 18,
                    weight: FontWeight.bold,
                    color: _DS.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(_DS.rFull),
                  ),
                  child: Text(
                    '${items.length}',
                    style: _DSx.text(
                      size: 11,
                      weight: FontWeight.w600,
                      color: brandColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) {
                final item = items[i];
                final qty = cartQtyOf(item.id ?? -1);
                return _BestSellerCard(
                  item: item,
                  brandColor: brandColor,
                  qty: qty,
                  rank: i + 1,
                  onTap: () => onTap(item),
                  onAdd: () => onAdd(item),
                  onRemove: (qty > 0 && onRemove != null) ? () => onRemove!(item) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BestSellerCard extends StatelessWidget {
  final PublicMenuItemModel item;
  final Color brandColor;
  final int qty;
  final int rank;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  const _BestSellerCard({
    required this.item,
    required this.brandColor,
    required this.qty,
    required this.rank,
    required this.onTap,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImg = (item.imageUrl ?? '').isNotEmpty;
    final desc = (item.description ?? '').trim();
    return SizedBox(
      width: 188,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: _DSx.cardBg,
            borderRadius: BorderRadius.circular(_DSx.rCard),
            boxShadow: _DSx.shadowSoft,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_DSx.rCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(_DSx.rCard)),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: hasImg
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: _DS.surface),
                                errorWidget: (_, __, ___) => Container(
                                  color: _DS.surface,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.fastfood_outlined, color: _DS.muted),
                                ),
                              )
                            : Container(
                                color: _DS.surface,
                                alignment: Alignment.center,
                                child: const Icon(Icons.fastfood_outlined, color: _DS.muted),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(_DS.rFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              '$rank',
                              style: _DSx.text(
                                size: 10,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (item.featured)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD02F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.star_rounded, size: 12, color: Color(0xFF746019)),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name ?? '—',
                        style: _DSx.text(
                          size: 14,
                          weight: FontWeight.w700,
                          color: _DS.ink,
                          height: 1.25,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc.isNotEmpty ? desc : '—',
                        style: _DSx.text(
                          size: 11.5,
                          weight: FontWeight.w500,
                          color: _DS.steel,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _currFmt.format(item.price ?? 0),
                              style: _DSx.text(
                                size: 16,
                                weight: FontWeight.w800,
                                color: _DS.ink,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AddCircleButton(
                            qty: qty,
                            brandColor: brandColor,
                            onAdd: onAdd,
                            onRemove: onRemove,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sticky category tabs (premium pills com auto-scroll) ───────────────────
class _StickyCategoryTabs extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String? activeCategory;
  final Color brandColor;
  final void Function(String) onTap;

  _StickyCategoryTabs({
    required this.categories,
    required this.activeCategory,
    required this.brandColor,
    required this.onTap,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _ModernCategoryTabsBar(
      categories: categories,
      activeCategory: activeCategory,
      brandColor: brandColor,
      onTap: onTap,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCategoryTabs oldDelegate) {
    return oldDelegate.categories.length != categories.length || oldDelegate.activeCategory != activeCategory || oldDelegate.brandColor != brandColor;
  }
}

/// Barra horizontal premium com pills. Faz auto-scroll para centralizar a
/// categoria ativa, transição suave do active state e ripple sutil ao tocar.
class _ModernCategoryTabsBar extends StatefulWidget {
  final List<String> categories;
  final String? activeCategory;
  final Color brandColor;
  final void Function(String) onTap;

  const _ModernCategoryTabsBar({
    required this.categories,
    required this.activeCategory,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_ModernCategoryTabsBar> createState() => _ModernCategoryTabsBarState();
}

class _ModernCategoryTabsBarState extends State<_ModernCategoryTabsBar> {
  final _ctrl = ScrollController();
  final Map<String, GlobalKey> _keys = {};
  String? _lastActive;

  GlobalKey _keyFor(String c) => _keys.putIfAbsent(c, () => GlobalKey());

  @override
  void didUpdateWidget(covariant _ModernCategoryTabsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeCategory != _lastActive) {
      _lastActive = widget.activeCategory;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  /// Centraliza o pill ativo dentro do ListView horizontal SEM disparar
  /// `Scrollable.ensureVisible`. Aquele helper sobe na árvore e tenta também
  /// "revelar" o pill verticalmente, o que mexia no scroll vertical do
  /// CustomScrollView pai (= forçava a tela de volta para o topo a cada tick
  /// de scroll que mudava a categoria ativa).
  void _scrollToActive() {
    final active = widget.activeCategory;
    if (active == null || !_ctrl.hasClients) return;
    final keyCtx = _keys[active]?.currentContext;
    if (keyCtx == null) return;
    final pillRO = keyCtx.findRenderObject();
    if (pillRO is! RenderBox || !pillRO.attached) return;
    // RenderAbstractViewport.of caminha para cima até achar o PRIMEIRO viewport
    // — que é o horizontal do ListView. Por isso a operação só afeta o eixo X.
    final viewport = RenderAbstractViewport.of(pillRO);
    final reveal = viewport.getOffsetToReveal(pillRO, 0.5); // 0.5 = centraliza
    final target = reveal.offset.clamp(
      _ctrl.position.minScrollExtent,
      _ctrl.position.maxScrollExtent,
    );
    if ((target - _ctrl.position.pixels).abs() < 0.5) return;
    _ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: _DSx.pageBg,
      child: ListView.separated(
        controller: _ctrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = widget.categories[i];
          final selected = cat == widget.activeCategory;
          return _CategoryPillButton(
            key: _keyFor(cat),
            label: cat,
            selected: selected,
            brandColor: widget.brandColor,
            onTap: () => widget.onTap(cat),
          );
        },
      ),
    );
  }
}

class _CategoryPillButton extends StatefulWidget {
  final String label;
  final bool selected;
  final Color brandColor;
  final VoidCallback onTap;
  const _CategoryPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.brandColor,
    required this.onTap,
  });

  @override
  State<_CategoryPillButton> createState() => _CategoryPillButtonState();
}

class _CategoryPillButtonState extends State<_CategoryPillButton> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected ? _DS.ink : Colors.transparent;
    final fg = selected ? Colors.white : _DS.steel;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_DS.rFull),
          splashColor: _DS.ink.withValues(alpha: 0.06),
          highlightColor: _DS.ink.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(_DS.rFull),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: _DSx.text(
                size: 15,
                weight: FontWeight.bold,
                color: fg,
              ),
              child: Text(widget.label, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}

// (upsell suggestions are now rendered inside _CartScreen via _CartUpsellSection)

// ─── Banner: pedido em andamento ─────────────────────────────────────────────
class _ActiveOrderBanner extends StatefulWidget {
  final PublicOrderDetailModel order;
  final Color brandColor;
  final VoidCallback? onTap;
  const _ActiveOrderBanner({required this.order, required this.brandColor, this.onTap});

  @override
  State<_ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<_ActiveOrderBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = _statusInfo(order.status);
    final itemCount = order.items.length;
    final total = order.total;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: widget.brandColor.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: widget.brandColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Pulse dot
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.brandColor.withValues(alpha: 0.4 + 0.6 * _pulse.value),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Order info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pedido em andamento',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _DS.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.tag ?? '#${order.id}',
                        style: const TextStyle(fontSize: 12, color: _DS.stone),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: status.fg,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (itemCount > 0)
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'itens'} · ${_currFmt.format(total)}',
                          style: const TextStyle(fontSize: 11, color: _DS.stone),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: widget.brandColor, size: 20),
          ],
        ),
      ),
    );
  }
}
