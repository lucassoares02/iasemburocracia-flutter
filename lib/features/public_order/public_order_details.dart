part of 'public_order_page.dart';

// Abre uma URL em uma nova aba (WhatsApp, Google Maps).
@JS('window.open')
external void _jsOpenTab(String url, String target);

// ─── Tela de detalhes do restaurante ────────────────────────────────────────
// Aberta ao tocar na logo ou no nome no cabeçalho do cardápio. Mantém o padrão
// visual premium e usa a cor de marca selecionada pela empresa.
class _CompanyDetailsPage extends StatefulWidget {
  final PublicCompanyPageModel data;
  final int Function(int menuItemId) cartQtyOf;
  final void Function(PublicMenuItemModel) onTapProduct;
  final void Function(PublicMenuItemModel) onAddProduct;
  final void Function(PublicMenuItemModel) onRemoveProduct;

  const _CompanyDetailsPage({
    required this.data,
    required this.cartQtyOf,
    required this.onTapProduct,
    required this.onAddProduct,
    required this.onRemoveProduct,
  });

  @override
  State<_CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<_CompanyDetailsPage> {
  PublicCompanyPageModel get data => widget.data;
  Color get _brand => _parseBrandColor(data.company.brandColor);

  void _openWhatsApp() {
    final raw = (data.company.phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) return;
    final number = raw.startsWith('55') ? raw : '55$raw';
    final name = (data.company.name ?? '').trim();
    final msg = Uri.encodeComponent(
      name.isEmpty ? 'Olá! Vim pelo cardápio digital.' : 'Olá, $name! Vim pelo cardápio digital.',
    );
    _jsOpenTab('https://wa.me/$number?text=$msg', '_blank');
  }

  void _openMaps(double lat, double lng) {
    _jsOpenTab('https://www.google.com/maps/search/?api=1&query=$lat,$lng', '_blank');
  }

  // Todos os produtos ordenados do mais vendido para o menos vendido.
  List<PublicMenuItemModel> get _bestSellers {
    final all = <PublicMenuItemModel>[];
    for (final cat in data.categories) {
      all.addAll((cat.items ?? const []).cast<PublicMenuItemModel>());
    }
    all.addAll(data.uncategorized);
    final seen = <int>{};
    final unique = <PublicMenuItemModel>[];
    for (final it in all) {
      if (seen.add(it.id ?? -1)) unique.add(it);
    }
    unique.sort((a, b) {
      final c = b.salesCount.compareTo(a.salesCount);
      if (c != 0) return c;
      return (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase());
    });
    return unique.take(15).toList();
  }

  Widget _padH(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  @override
  Widget build(BuildContext context) {
    final hasDesc = (data.company.description ?? '').trim().isNotEmpty;
    final hasPhone = (data.company.phone ?? '').trim().isNotEmpty;
    final hasAddr = data.companyAddress != null && _hasAddress(data.companyAddress!);
    final bestSellers = _bestSellers;

    return Scaffold(
      backgroundColor: _DSx.pageBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 64),
                    _padH(_titleBlock()),
                    const SizedBox(height: 20),
                    if (hasDesc) ...[_padH(_aboutCard()), const SizedBox(height: 14)],
                    _padH(_hoursCard()),
                    const SizedBox(height: 14),
                    if (bestSellers.isNotEmpty) _bestSellersSection(bestSellers),
                    if (hasPhone) ...[_padH(_contactCard()), const SizedBox(height: 14)],
                    if (hasAddr) ...[_padH(_addressCard()), const SizedBox(height: 14)],
                    if (hasPhone) _padH(_whatsappButton()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista horizontal "Mais pedidos" (card padrão de destaque) ────────────
  Widget _bestSellersSection(List<PublicMenuItemModel> items) {
    return _BestSellersCarousel(
      items: items,
      brandColor: _brand,
      cartQtyOf: widget.cartQtyOf,
      onTap: widget.onTapProduct,
      onAdd: (item) {
        widget.onAddProduct(item);
        if (mounted) setState(() {});
      },
      onRemove: (item) {
        widget.onRemoveProduct(item);
        if (mounted) setState(() {});
      },
    );
  }

  // ── Cabeçalho: banner cheio ao fundo + logo em destaque ──────────────────
  Widget _header(BuildContext context) {
    final bannerUrl = data.company.bannerUrl ?? '';
    final logoUrl = data.company.logoUrl ?? '';
    final hasBanner = bannerUrl.isNotEmpty;
    const headerHeight = 230.0;
    const logoSize = 104.0;

    return SizedBox(
      height: headerHeight + logoSize / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasBanner
                    ? CachedNetworkImage(
                        imageUrl: bannerUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: _brand.withValues(alpha: 0.85)),
                        errorWidget: (_, __, ___) => Container(color: _brand),
                      )
                    : Container(color: _brand),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _DSx.cardBg,
                  border: Border.all(color: _DSx.cardBg, width: 4),
                  boxShadow: _DSx.shadowFloating,
                ),
                clipBehavior: Clip.antiAlias,
                child: logoUrl.isEmpty
                    ? Container(
                        color: _brand.withValues(alpha: 0.12),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(data.company.name ?? ''),
                          style: _DSx.text(size: 30, weight: FontWeight.w700, color: _brand),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: _brand.withValues(alpha: 0.12)),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        Text(
          data.company.name ?? 'Restaurante',
          textAlign: TextAlign.center,
          style: _DSx.text(size: 24, weight: FontWeight.w700, color: _DS.ink, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        _statusPill(),
      ],
    );
  }

  Widget _statusPill() {
    final open = data.isOpen;
    final color = open ? _DS.successAccent : _DS.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(open ? 'Aberto agora' : 'Fechado agora', style: _DSx.text(size: 12.5, weight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return _card(
      icon: Icons.info_outline_rounded,
      title: 'Sobre',
      child: Text(
        data.company.description!.trim(),
        style: _DSx.text(size: 14, weight: FontWeight.w400, color: _DS.slate, height: 1.5),
      ),
    );
  }

  Widget _hoursCard() {
    final byDay = <int, List<PublicOpeningHourModel>>{};
    for (final h in data.openingHours) {
      final wd = h.weekday;
      if (wd == null) continue;
      (byDay[wd] ??= []).add(h);
    }
    final todayWd = DateTime.now().weekday;

    return _card(
      icon: Icons.access_time_rounded,
      title: 'Horário de funcionamento',
      child: Column(
        children: [
          for (var wd = 1; wd <= 7; wd++) _hoursRow(wd, byDay[wd] ?? const [], wd == todayWd),
        ],
      ),
    );
  }

  Widget _hoursRow(int weekday, List<PublicOpeningHourModel> slots, bool isToday) {
    final open = slots.where((s) => !s.isClosed && (s.opensAt ?? '').isNotEmpty && (s.closesAt ?? '').isNotEmpty).toList();
    final label = open.isEmpty ? 'Fechado' : open.map((s) => '${_hm(s.opensAt)} – ${_hm(s.closesAt)}').join('  ·  ');
    final closed = open.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isToday ? _brand.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: isToday ? Border.all(color: _brand.withValues(alpha: 0.25)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              _kDayFull[weekday] ?? '',
              style: _DSx.text(size: 13.5, weight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? _brand : _DS.ink),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: _DSx.text(size: 13.5, weight: FontWeight.w500, color: closed ? _DS.muted : _DS.slate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return _card(
      icon: Icons.phone_outlined,
      title: 'Contato',
      child: Row(
        children: [
          Icon(Icons.phone_rounded, size: 18, color: _brand),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.company.phone!.trim(),
              style: _DSx.text(size: 14.5, weight: FontWeight.w600, color: _DS.ink),
            ),
          ),
          TextButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat_rounded, size: 16),
            label: const Text('WhatsApp'),
            style: TextButton.styleFrom(foregroundColor: _brand),
          ),
        ],
      ),
    );
  }

  Widget _addressCard() {
    final addr = data.companyAddress!;
    final hasPin = addr.latitude != null && addr.longitude != null;
    return _card(
      icon: Icons.place_outlined,
      title: 'Endereço',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatAddress(addr),
            style: _DSx.text(size: 14, weight: FontWeight.w500, color: _DS.slate, height: 1.45),
          ),
          if (hasPin) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(_DS.rLg),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: GoogleMapWidget(lat: addr.latitude!, lng: addr.longitude!, height: 200),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openMaps(addr.latitude!, addr.longitude!),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Como chegar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brand,
                  side: BorderSide(color: _brand.withValues(alpha: 0.4)),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _whatsappButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _openWhatsApp,
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: const Text('Enviar mensagem no WhatsApp'),
        style: FilledButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: _DSx.text(size: 15, weight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _card({required IconData icon, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DSx.cardBg,
        borderRadius: BorderRadius.circular(_DSx.rCard),
        boxShadow: _DSx.shadowSoft,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(_DS.rLg),
                ),
                child: Icon(icon, size: 17, color: _brand),
              ),
              const SizedBox(width: 10),
              Text(title, style: _DSx.text(size: 15, weight: FontWeight.w700, color: _DS.ink)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _hm(String? raw) {
    final s = (raw ?? '').trim();
    if (s.length >= 5) return s.substring(0, 5);
    return s;
  }

  bool _hasAddress(PublicCompanyAddressModel a) {
    return (a.formattedAddress ?? '').trim().isNotEmpty || (a.street ?? '').trim().isNotEmpty;
  }

  String _formatAddress(PublicCompanyAddressModel a) {
    if ((a.formattedAddress ?? '').trim().isNotEmpty) return a.formattedAddress!.trim();
    final parts = <String>[];
    var line = (a.street ?? '').trim();
    if ((a.number ?? '').trim().isNotEmpty) line += ', ${a.number!.trim()}';
    if (line.isNotEmpty) parts.add(line);
    if ((a.neighborhood ?? '').trim().isNotEmpty) parts.add(a.neighborhood!.trim());
    final cs = [a.city, a.state].where((s) => (s ?? '').trim().isNotEmpty).map((s) => s!.trim()).join(' / ');
    if (cs.isNotEmpty) parts.add(cs);
    if ((a.zipCode ?? '').trim().isNotEmpty) parts.add('CEP ${a.zipCode!.trim()}');
    return parts.join('\n');
  }

  String _initials(String name) {
    final n = name.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}
