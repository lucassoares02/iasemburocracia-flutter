import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portal_assoc/features/customer_tracking/customer_tracking_model.dart';
import 'package:portal_assoc/features/customer_tracking/customer_tracking_repository.dart';

// ─── Design tokens (mirror dos tokens de orders_page) ──────────────────────────
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
  static const danger = Color(0xFFE53935);
  static const warning = Color(0xFFB45309);
  static const warningLight = Color(0xFFFEF3C7);
  static const successLight = Color(0xFFD1FAE5);
  static const blueLight = Color(0xFFEEF3FF);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
  static const rFull = 9999.0;
}

const _kPollInterval = Duration(seconds: 8);
const _kTileSize = 256.0;
// Sub-domínios oficiais da OSM tile API — não exige chave.
const _kTileSubdomains = ['a', 'b', 'c'];
String _tileUrl(int z, int x, int y) {
  final sd = _kTileSubdomains[(x + y) % _kTileSubdomains.length];
  return 'https://$sd.tile.openstreetmap.org/$z/$x/$y.png';
}

// ─── Status helpers ──────────────────────────────────────────────────────────
class _StatusInfo {
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;
  const _StatusInfo(this.label, this.fg, this.bg, this.icon);
}

const Map<String, _StatusInfo> _kStatusInfo = {
  'browsing': _StatusInfo('Navegando', _DS.brandBlue, _DS.blueLight, Icons.explore_outlined),
  'selecting_products': _StatusInfo('Escolhendo', Color(0xFF6D28D9), Color(0xFFEDE9FE), Icons.restaurant_menu_outlined),
  'cart': _StatusInfo('No carrinho', Color(0xFF0F766E), Color(0xFFCCFBF1), Icons.shopping_bag_outlined),
  'checkout': _StatusInfo('Checkout', _DS.warning, _DS.warningLight, Icons.receipt_outlined),
  'address_filled': _StatusInfo('Endereço ok', Color(0xFF1D4ED8), Color(0xFFDBEAFE), Icons.location_on_outlined),
  'payment_selection': _StatusInfo('Pagamento', _DS.warning, _DS.warningLight, Icons.payments_outlined),
  'order_created': _StatusInfo('Pedido criado', Color(0xFF065F46), _DS.successLight, Icons.check_circle_outline),
  'abandoned': _StatusInfo('Abandonado', _DS.danger, Color(0xFFFFEBEA), Icons.report_outlined),
};

_StatusInfo _statusInfoFor(String s) =>
    _kStatusInfo[s] ?? const _StatusInfo('—', _DS.slate, _DS.surface, Icons.help_outline);

// ─── Página: Mapa Operacional ────────────────────────────────────────────────
class CustomerTrackingMapPage extends StatefulWidget {
  final void Function(int orderId)? onOpenOrder;
  const CustomerTrackingMapPage({super.key, this.onOpenOrder});

  @override
  State<CustomerTrackingMapPage> createState() => _CustomerTrackingMapPageState();
}

class _CustomerTrackingMapPageState extends State<CustomerTrackingMapPage> {
  final _repo = CustomerTrackingRepository();

  List<TrackingSessionModel> _sessions = const [];
  TrackingMetricsModel _metrics = TrackingMetricsModel.empty;

  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  TrackingSessionModel? _selected;

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.listSessions(),
        _repo.getMetrics(),
      ]);
      if (!mounted) return;
      final sessionsRes = results[0];
      final metricsRes = results[1];

      setState(() {
        _loading = false;
        if (sessionsRes.success && sessionsRes.data is List) {
          _sessions = (sessionsRes.data as List).cast<TrackingSessionModel>();
          // Keep selection in sync (or drop if it's gone).
          if (_selected != null) {
            final fresh = _sessions.firstWhere(
              (s) => s.sessionId == _selected!.sessionId,
              orElse: () => _selected!,
            );
            _selected = fresh;
          }
        }
        if (metricsRes.success && metricsRes.data is TrackingMetricsModel) {
          _metrics = metricsRes.data as TrackingMetricsModel;
        }
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Falha ao atualizar o painel.';
      });
    }
  }

  List<TrackingSessionModel> get _mapSessions =>
      _sessions.where((s) => s.hasLocation).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsHeader(metrics: _metrics, loading: _loading && _sessions.isEmpty),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _MapPanel(
                        sessions: _mapSessions,
                        selected: _selected,
                        onSelect: (s) => setState(() => _selected = s),
                        loading: _loading && _sessions.isEmpty,
                        error: _error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _SidePanel(
                        sessions: _sessions,
                        selected: _selected,
                        onSelect: (s) => setState(() => _selected = s),
                        onOpenOrder: widget.onOpenOrder,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  SizedBox(
                    height: 380,
                    child: _MapPanel(
                      sessions: _mapSessions,
                      selected: _selected,
                      onSelect: (s) => setState(() => _selected = s),
                      loading: _loading && _sessions.isEmpty,
                      error: _error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _SidePanel(
                      sessions: _sessions,
                      selected: _selected,
                      onSelect: (s) => setState(() => _selected = s),
                      onOpenOrder: widget.onOpenOrder,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Métricas do topo ────────────────────────────────────────────────────────
class _MetricsHeader extends StatelessWidget {
  final TrackingMetricsModel metrics;
  final bool loading;
  const _MetricsHeader({required this.metrics, required this.loading});

  static final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final items = <_MetricCardData>[
      _MetricCardData(
        label: 'Navegando agora',
        value: '${metrics.browsing}',
        description: 'Cardápio em aberto',
        fg: _DS.brandBlue,
        bg: _DS.blueLight,
        icon: Icons.explore_outlined,
      ),
      _MetricCardData(
        label: 'Em checkout',
        value: '${metrics.inCheckout}',
        description: 'Endereço/pagamento',
        fg: _DS.warning,
        bg: _DS.warningLight,
        icon: Icons.receipt_long_outlined,
      ),
      _MetricCardData(
        label: 'Pedidos hoje',
        value: '${metrics.completedToday}',
        description: 'Convertidos em 24h',
        fg: _DS.successAccent,
        bg: _DS.successLight,
        icon: Icons.check_circle_outline,
      ),
      _MetricCardData(
        label: 'Carrinhos abandonados',
        value: '${metrics.abandonedCarts}',
        description: 'Últimas 24h',
        fg: _DS.danger,
        bg: const Color(0xFFFFEBEA),
        icon: Icons.remove_shopping_cart_outlined,
      ),
      _MetricCardData(
        label: 'Pipeline ativo',
        value: _currFmt.format(metrics.pipelineValue),
        description: 'Valor em jogo agora',
        fg: _DS.ink,
        bg: _DS.surface,
        icon: Icons.savings_outlined,
      ),
    ];
    return SizedBox(
      height: 92,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 10),
                child: _MetricCard(data: items[i], loading: loading),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final String description;
  final Color fg;
  final Color bg;
  final IconData icon;
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.description,
    required this.fg,
    required this.bg,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  final bool loading;
  const _MetricCard({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(_DS.rMd),
            ),
            child: Icon(data.icon, size: 18, color: data.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loading ? '—' : data.value,
                  style: TextStyle(fontSize: 18, color: data.fg),
                ),
                Text(
                  data.label,
                  style: const TextStyle(fontSize: 11, color: _DS.stone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.description,
                  style: const TextStyle(fontSize: 10, color: _DS.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Painel central com mapa e marcadores clicáveis ─────────────────────────
class _MapPanel extends StatelessWidget {
  final List<TrackingSessionModel> sessions;
  final TrackingSessionModel? selected;
  final ValueChanged<TrackingSessionModel> onSelect;
  final bool loading;
  final String? error;

  const _MapPanel({
    required this.sessions,
    required this.selected,
    required this.onSelect,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: _MapCanvas(sessions: sessions, onSelect: onSelect)),
          if (loading)
            const Positioned(
              top: 12,
              right: 12,
              child: _SmallChip(
                label: 'Atualizando…',
                icon: Icons.sync_rounded,
                color: _DS.steel,
              ),
            )
          else
            const Positioned(
              top: 12,
              right: 12,
              child: _LiveChip(),
            ),
          if (error != null)
            Positioned(
              top: 12,
              left: 12,
              child: _SmallChip(
                label: error!,
                icon: Icons.warning_amber_rounded,
                color: _DS.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapCanvas extends StatelessWidget {
  final List<TrackingSessionModel> sessions;
  final ValueChanged<TrackingSessionModel> onSelect;
  const _MapCanvas({required this.sessions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (sessions.isEmpty) {
          return _EmptyMap(constraints: constraints);
        }
        final w = constraints.maxWidth.clamp(320.0, 4096.0).toDouble();
        final h = constraints.maxHeight.clamp(240.0, 4096.0).toDouble();

        // Bounding box + centro do conjunto de sessões com localização.
        final lats = sessions.map((s) => s.latitude!).toList();
        final lngs = sessions.map((s) => s.longitude!).toList();
        final minLat = lats.reduce(math.min);
        final maxLat = lats.reduce(math.max);
        final minLng = lngs.reduce(math.min);
        final maxLng = lngs.reduce(math.max);
        final centerLat = (minLat + maxLat) / 2;
        final centerLng = (minLng + maxLng) / 2;

        final zoom = _fitZoom(
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
          widthPx: w,
          heightPx: h,
        );

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _OsmTileLayer(
                centerLat: centerLat,
                centerLng: centerLng,
                zoom: zoom,
                width: w,
                height: h,
              ),
              // Atribuição obrigatória OSM.
              const Positioned(
                bottom: 4,
                right: 8,
                child: Text(
                  '© OpenStreetMap',
                  style: TextStyle(
                    fontSize: 9,
                    color: _DS.steel,
                  ),
                ),
              ),
              for (final s in sessions)
                _PositionedMarker(
                  session: s,
                  centerLat: centerLat,
                  centerLng: centerLng,
                  zoom: zoom,
                  width: w,
                  height: h,
                  onTap: () => onSelect(s),
                ),
            ],
          ),
        );
      },
    );
  }

  // Zoom inteiro mais alto cujo bbox ainda cabe em ~90% do viewport.
  int _fitZoom({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required double widthPx,
    required double heightPx,
  }) {
    for (int z = 18; z >= 2; z--) {
      final worldSize = _kTileSize * math.pow(2, z);
      final tl = _project(maxLat, minLng, worldSize);
      final br = _project(minLat, maxLng, worldSize);
      final dx = (br.dx - tl.dx).abs();
      final dy = (br.dy - tl.dy).abs();
      if (dx <= widthPx * 0.9 && dy <= heightPx * 0.9) return z;
    }
    return 14;
  }

  // Projeção Web Mercator (lat/lng → pixel global, com worldSize = 256·2^z).
  static Offset _project(double lat, double lng, double worldSize) {
    final x = (lng + 180.0) / 360.0 * worldSize;
    final sinLat = math.sin(lat * math.pi / 180.0);
    final y = (0.5 -
            math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) *
        worldSize;
    return Offset(x, y);
  }
}

// ─── Renderiza tiles do OpenStreetMap como camada de fundo ───────────────────
class _OsmTileLayer extends StatelessWidget {
  final double centerLat;
  final double centerLng;
  final int zoom;
  final double width;
  final double height;

  const _OsmTileLayer({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final worldSize = _kTileSize * math.pow(2, zoom);
    final centerWorld = _MapCanvas._project(centerLat, centerLng, worldSize);

    // Origem do viewport em coordenadas globais de pixel.
    final viewLeft = centerWorld.dx - width / 2;
    final viewTop = centerWorld.dy - height / 2;

    // Range de tiles necessárias para cobrir o viewport.
    final firstX = (viewLeft / _kTileSize).floor();
    final lastX = ((viewLeft + width) / _kTileSize).floor();
    final firstY = (viewTop / _kTileSize).floor();
    final lastY = ((viewTop + height) / _kTileSize).floor();

    final maxTile = (1 << zoom) - 1; // (2^z - 1)
    final tiles = <Widget>[];

    for (int tx = firstX; tx <= lastX; tx++) {
      for (int ty = firstY; ty <= lastY; ty++) {
        // Esconde tiles fora dos limites verticais (poles); horizontal pode
        // ser tratado por wrap, mas no nosso caso de operação local é raro.
        if (ty < 0 || ty > maxTile) continue;
        // Wrap horizontal para limites do mundo.
        final wrappedX = ((tx % (maxTile + 1)) + (maxTile + 1)) % (maxTile + 1);
        final left = tx * _kTileSize - viewLeft;
        final top = ty * _kTileSize - viewTop;
        tiles.add(Positioned(
          left: left,
          top: top,
          width: _kTileSize,
          height: _kTileSize,
          child: Image.network(
            _tileUrl(zoom, wrappedX, ty),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(color: _DS.surface),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(color: _DS.surface);
            },
          ),
        ));
      }
    }

    return ClipRect(child: Stack(children: tiles));
  }
}

class _PositionedMarker extends StatelessWidget {
  final TrackingSessionModel session;
  final double centerLat;
  final double centerLng;
  final int zoom;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _PositionedMarker({
    required this.session,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final worldSize = 256.0 * math.pow(2, zoom);
    final centerPx = _MapCanvas._project(centerLat, centerLng, worldSize);
    final pointPx = _MapCanvas._project(session.latitude!, session.longitude!, worldSize);
    final dx = pointPx.dx - centerPx.dx + width / 2;
    final dy = pointPx.dy - centerPx.dy + height / 2;

    if (dx < 0 || dy < 0 || dx > width || dy > height) {
      return const SizedBox.shrink();
    }

    const dotSize = 22.0;
    const hitArea = dotSize + 24;
    return Positioned(
      left: dx - hitArea / 2,
      top: dy - hitArea / 2,
      child: _PulsingMarker(
        color: session.isOrderCreated ? _DS.successAccent : _DS.brandBlue,
        size: dotSize,
        onTap: onTap,
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback onTap;
  const _PulsingMarker({required this.color, required this.size, required this.onTap});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.size + 24,
          height: widget.size + 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final t = _ctrl.value;
                  return Container(
                    width: widget.size + 18 * t,
                    height: widget.size + 18 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.20 * (1 - t)),
                    ),
                  );
                },
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
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

// ─── Side panel: lista + detalhes ─────────────────────────────────────────────
class _SidePanel extends StatelessWidget {
  final List<TrackingSessionModel> sessions;
  final TrackingSessionModel? selected;
  final ValueChanged<TrackingSessionModel?> onSelect;
  final void Function(int orderId)? onOpenOrder;

  const _SidePanel({
    required this.sessions,
    required this.selected,
    required this.onSelect,
    required this.onOpenOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        children: [
          if (selected != null)
            _SelectedSessionCard(
              session: selected!,
              onClose: () => onSelect(null),
              onOpenOrder: onOpenOrder,
            )
          else
            const _SidePanelEmptyHeader(),
          const Divider(height: 1, color: _DS.hairlineSoft),
          Expanded(
            child: _SessionsList(
              sessions: sessions,
              selected: selected,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanelEmptyHeader extends StatelessWidget {
  const _SidePanelEmptyHeader();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rMd),
            ),
            child: const Icon(Icons.people_alt_outlined, size: 16, color: _DS.steel),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clientes ao vivo',
                    style: TextStyle(fontSize: 14, color: _DS.ink)),
                Text('Clique em um marcador no mapa ou em um cliente abaixo.',
                    style: TextStyle(fontSize: 11, color: _DS.stone)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedSessionCard extends StatelessWidget {
  final TrackingSessionModel session;
  final VoidCallback onClose;
  final void Function(int orderId)? onOpenOrder;
  const _SelectedSessionCard({
    required this.session,
    required this.onClose,
    required this.onOpenOrder,
  });

  static final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _hmFmt = DateFormat('HH:mm', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final info = _statusInfoFor(session.status);
    final name = (session.customerName ?? '').isNotEmpty
        ? session.customerName!
        : 'Cliente anônimo';
    final addrShort = (session.address ?? '').isNotEmpty
        ? _shortAddress(session.address!)
        : 'Sem endereço informado';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TrackingStatusBadge(status: session.status),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 18, color: _DS.stone),
                tooltip: 'Fechar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 16, color: _DS.ink)),
          if ((session.customerPhone ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                session.customerPhone!,
                style: const TextStyle(fontSize: 12, color: _DS.steel),
              ),
            ),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.timelapse_outlined, label: 'Início', value: _hmFmt.format(session.createdAt)),
          _InfoRow(icon: Icons.bolt_outlined, label: 'Última atividade', value: _hmFmt.format(session.lastActivityAt)),
          _InfoRow(icon: Icons.shopping_bag_outlined, label: 'Itens', value: '${session.cartItemsCount}'),
          _InfoRow(icon: Icons.attach_money_rounded, label: 'Subtotal', value: _currFmt.format(session.subtotal)),
          _InfoRow(icon: info.icon, label: 'Etapa', value: info.label, valueColor: info.fg),
          _InfoRow(icon: Icons.place_outlined, label: 'Endereço', value: addrShort, maxLines: 2),
          const SizedBox(height: 12),
          if (session.isOrderCreated && session.orderId != null)
            FilledButton.icon(
              onPressed: onOpenOrder == null ? null : () => onOpenOrder!(session.orderId!),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text('Abrir pedido #${session.orderId}'),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.successAccent,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_top_rounded, size: 16, color: _DS.stone),
              label: const Text('Aguardando finalização',
                  style: TextStyle(color: _DS.stone, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _DS.hairline),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }

  String _shortAddress(String a) {
    if (a.length <= 80) return a;
    return '${a.substring(0, 77)}…';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final int maxLines;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _DS.stone),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: _DS.stone)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: valueColor ?? _DS.ink),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsList extends StatelessWidget {
  final List<TrackingSessionModel> sessions;
  final TrackingSessionModel? selected;
  final ValueChanged<TrackingSessionModel> onSelect;
  const _SessionsList({
    required this.sessions,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sensors_off_outlined, size: 32, color: _DS.muted),
              SizedBox(height: 8),
              Text('Nenhum cliente ativo no momento',
                  style: TextStyle(fontSize: 12, color: _DS.stone)),
            ],
          ),
        ),
      );
    }
    final active = sessions.where((s) => s.isActive && !s.isOrderCreated).toList();
    final finished = sessions.where((s) => s.isOrderCreated).toList();
    final abandoned = sessions.where((s) => s.isAbandoned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      children: [
        if (active.isNotEmpty) ...[
          const _SectionLabel(label: 'Em fluxo', count: null),
          for (final s in active)
            _SessionTile(
              session: s,
              selected: selected?.sessionId == s.sessionId,
              onTap: () => onSelect(s),
            ),
        ],
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionLabel(label: 'Pedidos criados', count: finished.length),
          for (final s in finished)
            _SessionTile(
              session: s,
              selected: selected?.sessionId == s.sessionId,
              onTap: () => onSelect(s),
            ),
        ],
        if (abandoned.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionLabel(label: 'Abandonados (24h)', count: abandoned.length),
          for (final s in abandoned)
            _SessionTile(
              session: s,
              selected: selected?.sessionId == s.sessionId,
              onTap: () => onSelect(s),
            ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int? count;
  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: _DS.slate, letterSpacing: 0.6),
          ),
          const SizedBox(width: 6),
          if (count != null)
            Text('· $count', style: const TextStyle(fontSize: 10, color: _DS.muted)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final TrackingSessionModel session;
  final bool selected;
  final VoidCallback onTap;
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
  });

  static final _hmFmt = DateFormat('HH:mm', 'pt_BR');
  static final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final info = _statusInfoFor(session.status);
    final name = (session.customerName ?? '').isNotEmpty
        ? session.customerName!
        : 'Cliente anônimo';
    final markerColor = session.isOrderCreated ? _DS.successAccent : _DS.brandBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Material(
        color: selected ? _DS.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(_DS.rLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(_DS.rLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: markerColor,
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withValues(alpha: 0.45),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: _DS.ink),
                            ),
                          ),
                          Text(
                            _hmFmt.format(session.lastActivityAt),
                            style: const TextStyle(fontSize: 10, color: _DS.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _TrackingStatusBadge(status: session.status, compact: true),
                          const SizedBox(width: 6),
                          Text(
                            session.cartItemsCount > 0
                                ? '${session.cartItemsCount} itens · ${_currFmt.format(session.subtotal)}'
                                : 'Sem itens',
                            style: const TextStyle(fontSize: 11, color: _DS.steel),
                          ),
                        ],
                      ),
                      if ((session.address ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            session.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: _DS.stone),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          info.label,
                          style: TextStyle(fontSize: 11, color: info.fg),
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
  }
}

// ─── Status badge reutilizável ──────────────────────────────────────────────
class _TrackingStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  const _TrackingStatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final info = _statusInfoFor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, size: compact ? 10 : 12, color: info.fg),
          SizedBox(width: compact ? 4 : 5),
          Text(
            info.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: info.fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chips de status do mapa ─────────────────────────────────────────────────
class _LiveChip extends StatefulWidget {
  const _LiveChip();
  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_DS.rFull),
          border: Border.all(color: _DS.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _DS.successAccent.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
              ),
            ),
            const SizedBox(width: 6),
            const Text('AO VIVO',
                style: TextStyle(fontSize: 10, color: _DS.ink, letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SmallChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  final BoxConstraints constraints;
  const _EmptyMap({required this.constraints});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.surface,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_searching_rounded, size: 36, color: _DS.muted),
          SizedBox(height: 10),
          Text('Aguardando clientes ativos com localização',
              style: TextStyle(fontSize: 12, color: _DS.stone)),
          SizedBox(height: 4),
          Text('Marcadores aparecem assim que um cliente preenche endereço.',
              style: TextStyle(fontSize: 11, color: _DS.muted)),
        ],
      ),
    );
  }
}
