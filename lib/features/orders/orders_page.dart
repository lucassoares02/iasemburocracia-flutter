import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_repository.dart';
import 'package:portal_assoc/features/menu_items/menu_items_usecase.dart';
import 'package:portal_assoc/features/address/address_model.dart';
import 'package:portal_assoc/features/address/address_repository.dart';
import 'package:portal_assoc/features/orders/order_message_model.dart';
import 'package:portal_assoc/features/orders/orders_controller.dart';
import 'package:portal_assoc/features/orders/orders_model.dart';
import 'package:portal_assoc/features/orders/orders_repository.dart';
import 'package:portal_assoc/features/orders/orders_usecase.dart';
import 'package:portal_assoc/features/customer_tracking/customer_tracking_map.dart';
import 'package:portal_assoc/shared/widgets/google_map_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

part 'orders_card.dart';
part 'orders_chat.dart';
part 'orders_create_modal.dart';
part 'orders_kanban.dart';
part 'orders_widgets.dart';

enum _ViewMode { list, kanban, map }

// ─── Notificação sonora de novo pedido (Web Audio API) ───────────────────────
// Gera um "chime" curto de duas notas, sem depender de pacote de áudio ou
// arquivo de som. Reaproveita o AudioContext entre os toques.
web.AudioContext? _orderAudioCtx;

void _playNewOrderChime() {
  try {
    final ctx = _orderAudioCtx ??= web.AudioContext();
    // Navegadores suspendem o contexto até um gesto do usuário; após a primeira
    // interação na página o resume() reativa o áudio.
    ctx.resume();
    // Motivo de 3 notas (acorde de Lá maior) repetido 2x para chamar atenção
    // (~1,3s no total).
    const motif = <double>[880, 1108.73, 1318.51]; // A5, C#6, E6
    const noteDur = 0.16;
    const gap = 0.04;
    const repeats = 2;
    const repeatGap = 0.22;
    var t = ctx.currentTime;
    for (var r = 0; r < repeats; r++) {
      for (final f in motif) {
        _orderChimeNote(ctx, t, f, noteDur);
        t += noteDur + gap;
      }
      t += repeatGap;
    }
  } catch (_) {
    // Áudio indisponível no ambiente — ignora silenciosamente.
  }
}

void _orderChimeNote(web.AudioContext ctx, double start, double freq, double dur) {
  final osc = ctx.createOscillator();
  final gain = ctx.createGain();
  osc.type = 'sine';
  osc.frequency.setValueAtTime(freq, start);
  gain.gain.setValueAtTime(0.0001, start);
  gain.gain.exponentialRampToValueAtTime(0.3, start + 0.02);
  gain.gain.exponentialRampToValueAtTime(0.0001, start + dur);
  osc.connect(gain);
  gain.connect(ctx.destination);
  osc.start(start);
  osc.stop(start + dur + 0.02);
}

// ─── Design tokens ───────────────────────────────────────────────────────────
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
  static const dangerLight = Color(0xFFFFEBEA);
  static const yellowLight = Color(0xFFFFF4C4);
  static const yellowDark = Color(0xFF746019);
  static const surfacePricing = Color(0xFFF5F3FF);
  static const rFull = 9999.0;
  static const rXl = 16.0;
  static const rXxxl = 28.0;

  static const statusColors = {
    1: (bg: Color(0xFFEEF3FF), fg: Color(0xFF4262FF), label: 'Aguardando'),
    2: (bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9), label: 'Confirmado'),
    3: (bg: Color(0xFFFFF4C4), fg: Color(0xFF946C0A), label: 'Em Preparo'),
    4: (bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309), label: 'Em Entrega'),
    5: (bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46), label: 'Entregue'),
    6: (bg: Color(0xFFFFEBEA), fg: Color(0xFFE53935), label: 'Cancelado'),
    7: (bg: Color(0xFFFEE2E2), fg: Color(0xFF991B1B), label: 'Rejeitado'),
    8: (
      bg: Color(0xFFCCFBF1),
      fg: Color(0xFF187574),
      label: 'Pronto p/ Retirada'
    ),
    9: (bg: Color(0xFFDCFCE7), fg: Color(0xFF166534), label: 'Retirado'),
  };

  static Color statusBg(int? s) =>
      statusColors[s]?.bg ?? const Color(0xFFEEF0F3);
  static Color statusFg(int? s) =>
      statusColors[s]?.fg ?? const Color(0xFF555A6A);
  static String statusLabel(int? s) => statusColors[s]?.label ?? '—';
}

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

// ─── Page ────────────────────────────────────────────────────────────────────
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final OrdersController _ctrl = OrdersController(
    StartState(),
    OrdersUseCase(OrdersRepository()),
  );

  late final TabController _tabs = TabController(length: 2, vsync: this);

  _ViewMode _viewMode = _ViewMode.list;
  static const _menuWidth = 220.0;

  // ── Kanban: estado em ValueNotifier para o board inline e o fullscreen
  //    compartilharem a mesma fonte de dados (tempo real via polling).
  final ValueNotifier<List<OrderModel>> _kanbanOrders = ValueNotifier([]);
  final ValueNotifier<DateTime?> _kanbanSyncedAt = ValueNotifier(null);
  Timer? _kanbanPoll;
  bool _kanbanDragging = false;
  List<OrderModel>? _pendingKanbanOrders;
  static const _kanbanPollInterval = Duration(seconds: 10);

  // Notificação de novos pedidos (som + visual).
  final Set<int> _knownOrderIds = {};
  bool _ordersSeeded = false;
  bool _soundEnabled = true;
  int _newOrderCount = 0; // badge: novos pedidos ainda não "vistos"
  static const _soundPrefKey = 'orders_sound_enabled';

  @override
  void initState() {
    super.initState();
    _ctrl.stateFindAll.addListener(_syncKanban);
    // Ao navegar/trocar de aba, considera os novos pedidos como vistos.
    _tabs.addListener(_clearNewOrderBadge);
    _kanbanPoll = Timer.periodic(_kanbanPollInterval, (_) => _pollKanban());
    _loadSoundPref();
    _load();
  }

  void _clearNewOrderBadge() {
    if (_newOrderCount != 0 && mounted) setState(() => _newOrderCount = 0);
  }

  Future<void> _loadSoundPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _soundEnabled = prefs.getBool(_soundPrefKey) ?? true);
  }

  Future<void> _toggleSound() async {
    final next = !_soundEnabled;
    setState(() => _soundEnabled = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundPrefKey, next);
    // Toca um chime ao ativar para confirmar (e destravar o áudio do navegador).
    if (next) _playNewOrderChime();
  }

  /// Detecta pedidos com IDs ainda não vistos. A primeira carga apenas "semeia"
  /// os IDs conhecidos, sem notificar (evita alerta ao abrir a tela).
  void _detectNewOrders(List<OrderModel> orders) {
    final ids = orders.map((o) => o.id).whereType<int>().toSet();
    if (!_ordersSeeded) {
      _knownOrderIds
        ..clear()
        ..addAll(ids);
      _ordersSeeded = true;
      return;
    }
    final newIds = ids.difference(_knownOrderIds);
    _knownOrderIds.addAll(ids);
    if (newIds.isNotEmpty) {
      _onNewOrders(newIds.length);
    }
  }

  /// Dispara as notificações de novos pedidos: som, snackbar, badge e
  /// atualização da listagem visível (a aba "Todos" é mantida fresca pelo
  /// polling; aqui atualizamos "Hoje" e os cards de resumo).
  void _onNewOrders(int count) {
    if (!mounted) return;
    if (_soundEnabled) _playNewOrderChime();
    setState(() => _newOrderCount += count);
    _ctrl.findToday();
    _ctrl.summary();
    final label = count == 1 ? 'Novo pedido recebido!' : '$count novos pedidos recebidos!';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _DS.ink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('🛎️ $label', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ver',
            textColor: _DS.brandBlue,
            onPressed: () {
              setState(() {
                _viewMode = _ViewMode.list;
                _newOrderCount = 0;
              });
              _tabs.animateTo(1); // "Todos os Pedidos"
            },
          ),
        ),
      );
  }

  void _load() {
    _ctrl.summary();
    _ctrl.findToday();
    _ctrl.findAll();
  }

  void _syncKanban() {
    final s = _ctrl.stateFindAll.value;
    if (!mounted) return;
    if (s is SuccessState && s.data is List) {
      _applyKanbanOrders((s.data as List).cast<OrderModel>().toList());
    }
  }

  /// Busca silenciosa: vai direto ao usecase sem passar pelos states da
  /// página, para não disparar skeletons/loading na lista. Roda em qualquer
  /// view (lista/kanban/mapa) para que a notificação sonora de novos pedidos
  /// funcione na aba de pedidos como um todo.
  Future<void> _pollKanban() async {
    if (!mounted) return;
    try {
      final res = await _ctrl.useCase.findAll();
      if (!mounted || res.data is! List) return;
      final orders = (res.data as List).cast<OrderModel>().toList();
      // Atualiza silenciosamente a lista "Todos os Pedidos" (sem skeleton). O
      // listener _syncKanban cuida da detecção de novos pedidos e do kanban.
      _ctrl.stateFindAll.value = SuccessState(orders);
    } catch (_) {
      // Silencioso: a próxima rodada do timer tenta de novo.
    }
  }

  void _applyKanbanOrders(List<OrderModel> orders) {
    // Detecta novos pedidos e dispara o som independentemente do drag/visão.
    _detectNewOrders(orders);
    // Trocar a lista durante um drag desmontaria o Draggable em voo;
    // guarda e aplica quando o drag terminar.
    if (_kanbanDragging) {
      _pendingKanbanOrders = orders;
      return;
    }
    _kanbanOrders.value = orders;
    _kanbanSyncedAt.value = DateTime.now();
  }

  void _setKanbanDragging(bool dragging) {
    _kanbanDragging = dragging;
    if (!dragging && _pendingKanbanOrders != null) {
      final pending = _pendingKanbanOrders!;
      _pendingKanbanOrders = null;
      _applyKanbanOrders(pending);
    }
  }

  Future<void> _handleKanbanStatusChange(
      OrderModel order, int newStatus) async {
    if (newStatus == 6 || newStatus == 7) {
      _showKanbanCancelDialog(order, newStatus);
      return;
    }
    // Optimistic update
    for (final o in _kanbanOrders.value) {
      if (o.id == order.id) {
        o.status = newStatus;
        break;
      }
    }
    _kanbanOrders.value = List.of(_kanbanOrders.value);
    await _ctrl.updateStatus(order.id!, newStatus);
  }

  Future<void> _openKanbanFullscreen() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _KanbanFullscreenView(
        orders: _kanbanOrders,
        syncedAt: _kanbanSyncedAt,
        ctrl: _ctrl,
        onStatusChange: _handleKanbanStatusChange,
        onDraggingChanged: _setKanbanDragging,
        onRefresh: _pollKanban,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  void _showKanbanCancelDialog(OrderModel order, int targetStatus) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CancelOrderModal(
          orderId: order.id!, ctrl: _ctrl, targetStatus: targetStatus),
    );
  }

  @override
  void dispose() {
    _kanbanPoll?.cancel();
    _ctrl.stateFindAll.removeListener(_syncKanban);
    _tabs.removeListener(_clearNewOrderBadge);
    _kanbanOrders.dispose();
    _kanbanSyncedAt.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _openCreate() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CreateOrderModal(ctrl: _ctrl),
    );
  }

  void _openOrderById(int orderId) {
    // Volta para a lista para localizar o pedido (usa a busca padrão da página).
    setState(() => _viewMode = _ViewMode.list);
    _tabs.animateTo(1); // "Todos os Pedidos"
    _ctrl.findAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _DS.ink,
        behavior: SnackBarBehavior.floating,
        content: Text('Pedido #$orderId — abra na lista para detalhes',
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = <({String label, IconData icon, _ViewMode mode})>[
      (label: 'Lista', icon: Icons.view_list_rounded, mode: _ViewMode.list),
      (
        label: 'Kanban',
        icon: Icons.view_kanban_outlined,
        mode: _ViewMode.kanban
      ),
      (label: 'Mapa', icon: Icons.map_outlined, mode: _ViewMode.map),
    ];

    return Scaffold(
      backgroundColor: _DS.surface,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Row(
                children: [
                  SizedBox(
                    width: _menuWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: menuItems.map((item) {
                          return _OrdersNavItem(
                            label: item.label,
                            icon: item.icon,
                            active: _viewMode == item.mode,
                            onTap: () => setState(() {
                              _viewMode = item.mode;
                              _newOrderCount = 0;
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PageHeader(
                          onCreateTap: _openCreate,
                          soundEnabled: _soundEnabled,
                          onToggleSound: _toggleSound,
                          newOrderCount: _newOrderCount,
                        ),
                        const SizedBox(height: 12),
                        if (_viewMode == _ViewMode.list) ...[
                          _SummaryRow(ctrl: _ctrl),
                          const SizedBox(height: 14),
                          _TabBar(tabs: _tabs),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              controller: _tabs,
                              children: [
                                _OrdersList(
                                    state: _ctrl.stateFindToday,
                                    emptyMessage: 'Nenhum pedido hoje.'),
                                _OrdersList(
                                    state: _ctrl.stateFindAll,
                                    emptyMessage: 'Nenhum pedido encontrado.'),
                              ],
                            ),
                          ),
                        ] else if (_viewMode == _ViewMode.kanban) ...[
                          _KanbanToolbar(
                            syncedAt: _kanbanSyncedAt,
                            onRefresh: _pollKanban,
                            onFullscreen: _openKanbanFullscreen,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ValueListenableBuilder<List<OrderModel>>(
                              valueListenable: _kanbanOrders,
                              builder: (_, orders, __) => _KanbanBoard(
                                orders: orders,
                                ctrl: _ctrl,
                                onStatusChange: _handleKanbanStatusChange,
                                onDraggingChanged: _setKanbanDragging,
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: CustomerTrackingMapPage(
                              onOpenOrder: _openOrderById,
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
        ],
      ),
    );
  }
}

class _OrdersNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _OrdersNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_OrdersNavItem> createState() => _OrdersNavItemState();
}

class _OrdersNavItemState extends State<_OrdersNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selectedBg =
        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12);
    final selectedFg = Theme.of(context).colorScheme.secondary;
    final idleFg = Theme.of(context).colorScheme.onSurface;
    final hoverFg =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.active ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? selectedFg.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color:
                    widget.active ? selectedFg : (_hovered ? hoverFg : idleFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: widget.active
                        ? selectedFg
                        : (_hovered ? hoverFg : idleFg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page header ─────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final VoidCallback onCreateTap;
  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final int newOrderCount;

  const _PageHeader({
    required this.onCreateTap,
    required this.soundEnabled,
    required this.onToggleSound,
    required this.newOrderCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedidos', style: TextStyle(fontSize: 22, color: _DS.ink)),
                Text('Gerencie os pedidos da sua empresa',
                    style: TextStyle(fontSize: 14, color: _DS.steel)),
              ],
            ),
          ),
          Badge.count(
            count: newOrderCount,
            isLabelVisible: newOrderCount > 0,
            backgroundColor: _DS.danger,
            child: Tooltip(
              message: soundEnabled
                  ? 'Som de novos pedidos ativado'
                  : 'Som de novos pedidos desativado',
              child: IconButton(
                onPressed: onToggleSound,
                icon: Icon(
                  soundEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  size: 20,
                  color: soundEnabled ? _DS.ink : _DS.steel,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _DS.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: const BorderSide(color: _DS.hairline),
                  ),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Criar pedido'),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.ink,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary row ─────────────────────────────────────────────────────────────
class _SummaryRow extends StatefulWidget {
  final OrdersController ctrl;
  const _SummaryRow({required this.ctrl});

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  OrderSummaryModel? _lastSummary;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StateApp>(
      valueListenable: widget.ctrl.stateSummary,
      builder: (_, state, __) {
        if (state is SuccessState && state.data is OrderSummaryModel) {
          _lastSummary = state.data as OrderSummaryModel;
        }

        if (_lastSummary == null &&
            (state is LoadingState || state is StartState)) {
          return _SkeletonSummary();
        }

        return _SummaryCards(summary: _lastSummary);
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final OrderSummaryModel? summary;
  const _SummaryCards({this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        'Hoje',
        'Todos os status',
        summary?.today ?? 0,
        summary?.todayValue ?? 0,
        Icons.today_outlined,
        _DS.brandBlue,
        _DS.surfacePricing,
      ),
      _SummaryCardData(
        'Total',
        'Todos os pedidos',
        summary?.total ?? 0,
        summary?.totalValue ?? 0,
        Icons.receipt_long_outlined,
        _DS.ink,
        _DS.surface,
      ),
      _SummaryCardData(
        'Em andamento',
        '1, 2, 3, 4 e 8',
        summary?.inProgress ?? 0,
        summary?.inProgressValue ?? 0,
        Icons.timelapse_outlined,
        _DS.yellowDark,
        _DS.yellowLight,
      ),
      _SummaryCardData(
        'Concluídos',
        '5 e 9',
        summary?.completed ?? 0,
        summary?.completedValue ?? 0,
        Icons.check_circle_outline,
        _DS.successAccent,
        const Color(0xFFD1FAE5),
      ),
      _SummaryCardData(
        'Cancelados',
        '6 e 7',
        summary?.cancelled ?? 0,
        summary?.cancelledValue ?? 0,
        Icons.cancel_outlined,
        _DS.danger,
        _DS.dangerLight,
      ),
    ];
    return SizedBox(
      height: 116,
      child: Row(
        children: List.generate(cards.length, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == cards.length - 1 ? 0 : 12),
              child: _SummaryCard(data: cards[i]),
            ),
          );
        }),
      ),
    );
  }
}

class _SummaryCardData {
  final String label;
  final String description;
  final int value;
  final double amount;
  final IconData icon;
  final Color fg;
  final Color bg;
  const _SummaryCardData(
    this.label,
    this.description,
    this.value,
    this.amount,
    this.icon,
    this.fg,
    this.bg,
  );
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                color: data.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, size: 18, color: data.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${data.value}',
                    style: TextStyle(fontSize: 20, color: data.fg)),
                Text(data.label,
                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(_currencyFmt.format(data.amount),
                    style: const TextStyle(fontSize: 11, color: _DS.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(data.description,
                    style: const TextStyle(fontSize: 10, color: _DS.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Row(
        children: List.generate(
          5,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 4 ? 0 : 12),
              child: Container(
                decoration: BoxDecoration(
                  color: _DS.canvas,
                  borderRadius: BorderRadius.circular(_DS.rXl),
                  border: Border.all(color: _DS.hairlineSoft),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tab bar ─────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController tabs;
  const _TabBar({required this.tabs});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabs,
      builder: (_, __) => Row(
        children: [
          _Tab(
              label: 'Pedidos de Hoje',
              active: tabs.index == 0,
              onTap: () => tabs.animateTo(0)),
          const SizedBox(width: 8),
          _Tab(
              label: 'Todos os Pedidos',
              active: tabs.index == 1,
              onTap: () => tabs.animateTo(1)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _DS.ink : _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rFull),
          border: Border.all(color: active ? _DS.ink : _DS.hairline),
        ),
        child: Text(
          label,
          style:
              TextStyle(fontSize: 13, color: active ? Colors.white : _DS.steel),
        ),
      ),
    );
  }
}

// ─── Orders list ─────────────────────────────────────────────────────────────
class _OrdersList extends StatelessWidget {
  final ValueNotifier<StateApp> state;
  final String emptyMessage;
  const _OrdersList({required this.state, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StateApp>(
      valueListenable: state,
      builder: (_, s, __) {
        if (s is LoadingState || s is StartState) return _SkeletonList();
        if (s is ErrorState) {
          return Center(
              child:
                  Text(s.message, style: const TextStyle(color: _DS.danger)));
        }
        if (s is SuccessState) {
          final orders = s.data is List
              ? (s.data as List).cast<OrderModel>()
              : <OrderModel>[];
          if (orders.isEmpty) return _EmptyState(message: emptyMessage);
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: _DS.surface, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_outlined,
                size: 32, color: _DS.muted),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, color: _DS.slate)),
          const SizedBox(height: 4),
          const Text('Os pedidos aparecerão aqui assim que forem criados.',
              style: TextStyle(fontSize: 13, color: _DS.stone)),
        ],
      ),
    );
  }
}
