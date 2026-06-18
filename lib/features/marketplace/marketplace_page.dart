import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/marketplace/marketplace_model.dart';
import 'package:portal_assoc/features/marketplace/marketplace_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:web/web.dart' as web;

// ─── Design tokens (padrão visual da plataforma) ─────────────────────────────
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const hairlineSoft = Color(0xFFEEF0F3);
  static const slate = Color(0xFF555A6A);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const muted = Color(0xFFA5A8B5);
  static const successAccent = Color(0xFF00B473);
  static const successSubtle = Color(0xFFF0FDF4);
  static const danger = Color(0xFFE53935);
  static const dangerSubtle = Color(0xFFFEF2F2);
  static const promoOrange = Color(0xFFFF5A36);

  static const double rXl = 16;
  static const double rLg = 12;
  static const double rFull = 9999;
}

// ─── SEO (rota pública) ───────────────────────────────────────────────────────
void _applyMarketplaceSeo() {
  try {
    web.document.title = 'Peça dos melhores restaurantes | AutomatizAI';
    void upsertMeta(String attr, String key, String content) {
      var el = web.document.querySelector('meta[$attr="$key"]') as web.HTMLMetaElement?;
      if (el == null) {
        el = web.document.createElement('meta') as web.HTMLMetaElement;
        el.setAttribute(attr, key);
        web.document.head?.appendChild(el);
      }
      el.content = content;
    }

    const desc = 'Descubra restaurantes, promoções e pratos incríveis perto de você. Peça online direto do cardápio.';
    upsertMeta('name', 'description', desc);
    upsertMeta('property', 'og:title', 'Peça dos melhores restaurantes');
    upsertMeta('property', 'og:description', desc);
    upsertMeta('property', 'og:type', 'website');
  } catch (_) {
    // Ambiente sem DOM — ignora.
  }
}

// ─── Categorias (emoji por palavra-chave da cozinha) ─────────────────────────
String _categoryEmoji(String category) {
  final c = category.toLowerCase();
  if (c.contains('hamb') || c.contains('burg') || c.contains('lanche')) return '🍔';
  if (c.contains('pizza')) return '🍕';
  if (c.contains('japon') || c.contains('sushi') || c.contains('orient')) return '🍣';
  if (c.contains('saud') || c.contains('salad') || c.contains('fit') || c.contains('natural')) return '🥗';
  if (c.contains('sobremesa') || c.contains('doce') || c.contains('confeit') || c.contains('bolo')) return '🍰';
  if (c.contains('bebida') || c.contains('suco') || c.contains('drink')) return '🥤';
  if (c.contains('marmita') || c.contains('caseira') || c.contains('brasileir') || c.contains('comida')) return '🍛';
  if (c.contains('açaí') || c.contains('acai') || c.contains('sorvete') || c.contains('gelado')) return '🍦';
  if (c.contains('churras') || c.contains('carne') || c.contains('grelha')) return '🥩';
  if (c.contains('café') || c.contains('cafe') || c.contains('padaria')) return '☕';
  if (c.contains('árabe') || c.contains('arabe') || c.contains('esfiha')) return '🥙';
  if (c.contains('mexic')) return '🌮';
  if (c.contains('frango') || c.contains('porç') || c.contains('porc')) return '🍗';
  if (c.contains('mar') || c.contains('peixe')) return '🦐';
  return '🍽️';
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _repo = MarketplaceRepository();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  MarketplaceData? _data;
  String _query = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _applyMarketplaceSeo();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) setState(() => _query = q);
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    final res = await _repo.fetch(force: force);
    if (!mounted) return;
    if (res.success && res.data is MarketplaceData) {
      setState(() {
        _data = res.data as MarketplaceData;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os restaurantes.';
      });
    }
  }

  void _openRestaurant(int companyId) => context.go('/order?company=$companyId');

  // ─── Derivações ─────────────────────────────────────────────────────────────
  List<String> get _categories {
    final set = <String>{};
    for (final r in _data?.restaurants ?? const <MarketplaceRestaurantModel>[]) {
      final c = (r.cuisineType ?? '').trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  bool get _filtering => _query.isNotEmpty || _selectedCategory != null;

  List<MarketplaceRestaurantModel> get _filtered {
    final all = _data?.restaurants ?? const <MarketplaceRestaurantModel>[];
    final q = _query.toLowerCase();
    return all.where((r) {
      final matchesCategory = _selectedCategory == null || (r.cuisineType ?? '').toLowerCase() == _selectedCategory!.toLowerCase();
      final matchesQuery = q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          (r.cuisineType ?? '').toLowerCase().contains(q) ||
          (r.description ?? '').toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Destaques: ranking da API (pedidos > faturamento > recentes).
  List<MarketplaceRestaurantModel> get _featured {
    final all = _data?.restaurants ?? const <MarketplaceRestaurantModel>[];
    final withOrders = all.where((r) => r.ordersCount > 0).take(6).toList();
    return withOrders.isNotEmpty ? withOrders : all.take(6).toList();
  }

  List<MarketplaceRestaurantModel> get _topOrdered =>
      (_data?.restaurants ?? const <MarketplaceRestaurantModel>[]).where((r) => r.ordersCount > 0).take(8).toList();

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Peça dos melhores restaurantes',
      color: _DS.ink,
      child: Scaffold(
        backgroundColor: _DS.surface,
        body: _loading
            ? const _MarketplaceSkeleton()
            : _error != null
                ? _ErrorView(message: _error!, onRetry: () => _load(force: true))
                : RefreshIndicator(
                    color: _DS.brandBlue,
                    onRefresh: () => _load(force: true),
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    if (data.restaurants.isEmpty) {
      return const _MarketplaceEmptyState();
    }

    final filtered = _filtered;
    final showSections = !_filtering;

    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      final isDesktop = width >= 1100;
      final cols = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);
      final hPad = width >= 700 ? 24.0 : 16.0;
      const maxContent = 1240.0;
      final extra = (width - maxContent) / 2;
      final sidePad = extra > hPad ? extra : hPad;

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sidePad, 24, sidePad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroSection(),
                    const SizedBox(height: 18),
                    _SearchBar(controller: _searchCtrl),
                    const SizedBox(height: 14),
                    if (_categories.isNotEmpty)
                      _CategoryFilter(
                        categories: _categories,
                        selected: _selectedCategory,
                        onSelect: (cat) => setState(() => _selectedCategory = _selectedCategory == cat ? null : cat),
                      ),
                  ],
                ),
              ),
            ),

            // ── Seções de descoberta (ocultas durante busca/filtro) ──────────
            if (showSections) ...[
              if (_featured.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePad, 26, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Section(
                      title: 'Restaurantes em destaque',
                      icon: LucideIcons.flame,
                      child: _FeaturedCarousel(
                        restaurants: _featured,
                        endPadding: sidePad,
                        onTap: _openRestaurant,
                      ),
                    ),
                  ),
                ),
              if (data.promotions.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePad, 26, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Section(
                      title: 'Promoções imperdíveis',
                      icon: LucideIcons.badgePercent,
                      child: _PromotionsCarousel(
                        promotions: data.promotions,
                        endPadding: sidePad,
                        onTap: _openRestaurant,
                      ),
                    ),
                  ),
                ),
              if (_topOrdered.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(sidePad, 26, 0, 0),
                  sliver: SliverToBoxAdapter(
                    child: _Section(
                      title: 'Mais pedidos da plataforma',
                      icon: LucideIcons.trophy,
                      child: _TopRestaurantsCarousel(
                        restaurants: _topOrdered,
                        endPadding: sidePad,
                        onTap: _openRestaurant,
                      ),
                    ),
                  ),
                ),
            ],

            // ── Lista principal ───────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(sidePad, 28, sidePad, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _filtering ? '${filtered.length} restaurante${filtered.length == 1 ? '' : 's'} encontrado${filtered.length == 1 ? '' : 's'}' : 'Todos os restaurantes',
                  style: const TextStyle(fontSize: 18, color: _DS.ink, letterSpacing: -0.4),
                ),
              ),
            ),
            if (filtered.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 40),
                sliver: SliverToBoxAdapter(child: _NoResults()),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(sidePad, 8, sidePad, 40),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 252,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RestaurantCard(
                      restaurant: filtered[i],
                      enableHover: isDesktop,
                      onTap: () => _openRestaurant(filtered[i].id),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peça dos melhores restaurantes',
          style: TextStyle(fontSize: 26, color: _DS.ink, letterSpacing: -0.8, height: 1.15),
        ),
        SizedBox(height: 6),
        Text(
          'Descubra restaurantes, promoções e pratos incríveis perto de você.',
          style: TextStyle(fontSize: 14, color: _DS.steel, height: 1.5),
        ),
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: _DS.ink),
      decoration: InputDecoration(
        hintText: 'Hambúrguer, Pizza, Açaiteria...',
        hintStyle: const TextStyle(fontSize: 14, color: _DS.muted),
        prefixIcon: const Icon(LucideIcons.search, size: 18, color: _DS.stone),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (_, __) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(LucideIcons.x, size: 16, color: _DS.stone),
                  onPressed: controller.clear,
                ),
        ),
        filled: true,
        fillColor: _DS.canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _DS.hairline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _DS.hairline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
      ),
    );
  }
}

// ─── Category filter ──────────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _CategoryFilter({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final cat = categories[i];
            final active = selected?.toLowerCase() == cat.toLowerCase();
            return Material(
              color: active ? _DS.ink : _DS.canvas,
              shape: StadiumBorder(side: BorderSide(color: active ? _DS.ink : _DS.hairline)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onSelect(cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    children: [
                      Text(_categoryEmoji(cat), style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 7),
                      Text(
                        cat,
                        style: TextStyle(fontSize: 13, color: active ? Colors.white : _DS.slate),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: _DS.brandBlue),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, color: _DS.ink, letterSpacing: -0.4)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ─── Destaques (carousel premium) ─────────────────────────────────────────────
class _FeaturedCarousel extends StatelessWidget {
  final List<MarketplaceRestaurantModel> restaurants;
  final double endPadding;
  final void Function(int companyId) onTap;
  const _FeaturedCarousel({required this.restaurants, required this.endPadding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.sizeOf(context).width < 480 ? 290.0 : 330.0;
    return SizedBox(
      height: 246,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(right: endPadding),
          itemCount: restaurants.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => SizedBox(
            width: cardWidth,
            child: _RestaurantCard(
              restaurant: restaurants[i],
              enableHover: true,
              onTap: () => onTap(restaurants[i].id),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mais pedidos (carousel compacto com ranking) ────────────────────────────
class _TopRestaurantsCarousel extends StatelessWidget {
  final List<MarketplaceRestaurantModel> restaurants;
  final double endPadding;
  final void Function(int companyId) onTap;
  const _TopRestaurantsCarousel({required this.restaurants, required this.endPadding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(right: endPadding),
          itemCount: restaurants.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final r = restaurants[i];
            return _HoverScale(
              enabled: true,
              child: Material(
                color: _DS.canvas,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rXl),
                  side: const BorderSide(color: _DS.hairlineSoft),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(_DS.rXl),
                  onTap: () => onTap(r.id),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          '#${i + 1}',
                          style: TextStyle(
                            fontSize: 17,
                            color: i == 0 ? const Color(0xFFF59E0B) : _DS.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _LogoBadge(url: r.logoUrl, name: r.name, size: 44),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13.5, color: _DS.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.ordersCount} pedido${r.ordersCount == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 11.5, color: _DS.stone),
                              ),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 16, color: _DS.stone),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Promoções (carousel) ─────────────────────────────────────────────────────
class _PromotionsCarousel extends StatelessWidget {
  final List<MarketplacePromotionModel> promotions;
  final double endPadding;
  final void Function(int companyId) onTap;
  const _PromotionsCarousel({required this.promotions, required this.endPadding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(right: endPadding),
          itemCount: promotions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            final p = promotions[i];
            final pct = p.effectiveDiscountPct;
            return _HoverScale(
              enabled: true,
              child: Material(
                color: _DS.canvas,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rXl),
                  side: const BorderSide(color: _DS.hairlineSoft),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onTap(p.companyId),
                  child: SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _NetImage(url: p.imageUrl, icon: LucideIcons.badgePercent),
                              if (pct > 0)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _DS.promoOrange,
                                      borderRadius: BorderRadius.circular(_DS.rFull),
                                    ),
                                    child: Text(
                                      '$pct% OFF',
                                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              _LogoBadge(url: p.companyLogo, name: p.companyName, size: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, color: _DS.ink),
                                    ),
                                    Text(
                                      p.companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: _DS.stone),
                                    ),
                                  ],
                                ),
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
          },
        ),
      ),
    );
  }
}

// ─── Restaurant card (lista + destaque) ───────────────────────────────────────
class _RestaurantCard extends StatelessWidget {
  final MarketplaceRestaurantModel restaurant;
  final bool enableHover;
  final VoidCallback onTap;
  const _RestaurantCard({required this.restaurant, required this.enableHover, required this.onTap});

  String? get _timeLabel {
    final avg = restaurant.avgPrepMinutes;
    if (avg == null || avg <= 0) return null;
    return '$avg-${avg + 15} min';
  }

  String? get _feeLabel {
    final fee = restaurant.minTaxDelivery;
    if (fee == null) return null;
    if (fee <= 0) return 'Entrega grátis';
    return 'Entrega R\$ ${fee.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String? get _minLabel {
    final min = restaurant.minPriceOrder;
    if (min == null || min <= 0) return null;
    return 'Mín. R\$ ${min.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return _HoverScale(
      enabled: enableHover,
      child: Material(
        color: _DS.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DS.rXl),
          side: const BorderSide(color: _DS.hairlineSoft),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner + logo + badges
              SizedBox(
                height: 118,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    _NetImage(url: r.bannerUrl, icon: LucideIcons.utensilsCrossed),
                    // Gradiente sutil para legibilidade dos badges
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.25)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _OpenBadge(isOpen: r.isOpen),
                    ),
                    if (r.hasPromotions)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _DS.promoOrange,
                            borderRadius: BorderRadius.circular(_DS.rFull),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.badgePercent, size: 11, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Promoção', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: -22,
                      left: 14,
                      child: _LogoBadge(url: r.logoUrl, name: r.name, size: 52, bordered: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15.5, color: _DS.ink, letterSpacing: -0.3),
                          ),
                        ),
                        if ((r.cuisineType ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${_categoryEmoji(r.cuisineType!)} ${r.cuisineType}',
                            style: const TextStyle(fontSize: 11.5, color: _DS.stone),
                          ),
                        ],
                      ],
                    ),
                    if ((r.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        r.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _DS.steel, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_timeLabel != null) _InfoChip(icon: LucideIcons.clock, label: _timeLabel!),
                        if (_feeLabel != null)
                          _InfoChip(
                            icon: LucideIcons.bike,
                            label: _feeLabel!,
                            highlight: (r.minTaxDelivery ?? 1) <= 0,
                          ),
                        if (_minLabel != null) _InfoChip(icon: LucideIcons.shoppingBag, label: _minLabel!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _HoverScale extends StatefulWidget {
  final bool enabled;
  final Widget child;
  const _HoverScale({required this.enabled, required this.child});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String? url;
  final IconData icon;
  const _NetImage({required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return Container(
        color: _DS.surface,
        child: Icon(icon, size: 26, color: _DS.muted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: _DS.surface),
      errorWidget: (_, __, ___) => Container(
        color: _DS.surface,
        child: Icon(icon, size: 26, color: _DS.muted),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final bool bordered;
  const _LogoBadge({required this.url, required this.name, required this.size, this.bordered = false});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: Colors.white, width: 2.5) : Border.all(color: _DS.hairlineSoft),
        boxShadow: bordered
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url ?? '').isEmpty
          ? Center(
              child: Text(
                initial,
                style: TextStyle(fontSize: size * 0.4, color: _DS.ink, fontWeight: FontWeight.w600),
              ),
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: TextStyle(fontSize: size * 0.4, color: _DS.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;
  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? _DS.successSubtle : _DS.dangerSubtle,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? _DS.successAccent : _DS.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Aberto' : 'Fechado',
            style: TextStyle(fontSize: 10.5, color: isOpen ? const Color(0xFF15803D) : _DS.danger, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  const _InfoChip({required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? _DS.successSubtle : _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: highlight ? _DS.successAccent : _DS.stone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: highlight ? const Color(0xFF15803D) : _DS.slate),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _MarketplaceSkeleton extends StatelessWidget {
  const _MarketplaceSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h, {double? w, double r = _DS.rLg}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r)),
        );

    return LayoutBuilder(builder: (context, c) {
      final hPad = c.maxWidth >= 700 ? 24.0 : 16.0;
      const maxContent = 1240.0;
      final extra = (c.maxWidth - maxContent) / 2;
      final sidePad = extra > hPad ? extra : hPad;
      return Shimmer.fromColors(
        baseColor: _DS.hairlineSoft,
        highlightColor: _DS.surface,
        child: ListView(
          padding: EdgeInsets.fromLTRB(sidePad, 24, sidePad, 24),
          children: [
            box(28, w: 320),
            const SizedBox(height: 10),
            box(16, w: 380),
            const SizedBox(height: 20),
            box(50, r: 14),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: Row(
                children: [for (var i = 0; i < 5; i++) ...[box(40, w: 110, r: _DS.rFull), const SizedBox(width: 8)]],
              ),
            ),
            const SizedBox(height: 28),
            box(20, w: 240),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: Row(
                children: [for (var i = 0; i < 3; i++) ...[Expanded(child: box(240, r: _DS.rXl)), const SizedBox(width: 14)]],
              ),
            ),
            const SizedBox(height: 28),
            box(20, w: 200),
            const SizedBox(height: 12),
            box(240, r: _DS.rXl),
            const SizedBox(height: 16),
            box(240, r: _DS.rXl),
          ],
        ),
      );
    });
  }
}

// ─── Empty / erro / sem resultados ───────────────────────────────────────────
class _MarketplaceEmptyState extends StatelessWidget {
  const _MarketplaceEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: _DS.canvas, shape: BoxShape.circle),
                child: const Icon(LucideIcons.store, size: 36, color: _DS.muted),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nenhum restaurante disponível no momento.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _DS.ink, letterSpacing: -0.2),
              ),
              const SizedBox(height: 6),
              const Text(
                'Volte em breve — novos restaurantes chegam todos os dias.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _DS.steel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Icon(LucideIcons.searchX, size: 34, color: _DS.muted),
          SizedBox(height: 12),
          Text(
            'Nenhum restaurante encontrado.',
            style: TextStyle(fontSize: 14.5, color: _DS.ink),
          ),
          SizedBox(height: 4),
          Text(
            'Tente outra busca ou remova os filtros.',
            style: TextStyle(fontSize: 12.5, color: _DS.steel),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.wifiOff, size: 34, color: _DS.muted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: _DS.steel)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Tentar novamente'),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.ink,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
