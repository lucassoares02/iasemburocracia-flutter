import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
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
    8: (bg: Color(0xFFCCFBF1), fg: Color(0xFF187574), label: 'Pronto p/ Retirada'),
    9: (bg: Color(0xFFDCFCE7), fg: Color(0xFF166534), label: 'Retirado'),
  };

  static Color statusBg(int? s) => statusColors[s]?.bg ?? const Color(0xFFEEF0F3);
  static Color statusFg(int? s) => statusColors[s]?.fg ?? const Color(0xFF555A6A);
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

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late final OrdersController _ctrl = OrdersController(
    StartState(),
    OrdersUseCase(OrdersRepository()),
  );

  late final TabController _tabs = TabController(length: 2, vsync: this);

  _ViewMode _viewMode = _ViewMode.list;
  List<OrderModel> _kanbanOrders = [];

  @override
  void initState() {
    super.initState();
    _ctrl.stateFindAll.addListener(_syncKanban);
    _load();
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
      setState(() {
        _kanbanOrders = (s.data as List).cast<OrderModel>().toList();
      });
    }
  }

  Future<void> _handleKanbanStatusChange(OrderModel order, int newStatus) async {
    if (newStatus == 6 || newStatus == 7) {
      _showKanbanCancelDialog(order, newStatus);
      return;
    }
    // Optimistic update
    setState(() {
      for (final o in _kanbanOrders) {
        if (o.id == order.id) {
          o.status = newStatus;
          break;
        }
      }
    });
    await _ctrl.updateStatus(order.id!, newStatus);
  }

  void _showKanbanCancelDialog(OrderModel order, int targetStatus) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CancelOrderModal(orderId: order.id!, ctrl: _ctrl, targetStatus: targetStatus),
    );
  }

  @override
  void dispose() {
    _ctrl.stateFindAll.removeListener(_syncKanban);
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

  Future<void> _openPublicOrderTab() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;
    if (companyId <= 0) return;
    final url = '${Uri.base.origin}/order?company=$companyId&phone=';
    _jsWindowOpen(url, '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    onCreateTap: _openCreate,
                    onCreatePublicTap: _openPublicOrderTab,
                    viewMode: _viewMode,
                    onViewModeChange: (m) => setState(() => _viewMode = m),
                  ),
                  _SummaryRow(ctrl: _ctrl),
                  const SizedBox(height: 16),
                  if (_viewMode == _ViewMode.list) ...[
                    _TabBar(tabs: _tabs),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _OrdersList(state: _ctrl.stateFindToday, emptyMessage: 'Nenhum pedido hoje.'),
                          _OrdersList(state: _ctrl.stateFindAll, emptyMessage: 'Nenhum pedido encontrado.'),
                        ],
                      ),
                    ),
                  ] else if (_viewMode == _ViewMode.kanban) ...[
                    Expanded(
                      child: _KanbanBoard(
                        orders: _kanbanOrders,
                        ctrl: _ctrl,
                        onStatusChange: _handleKanbanStatusChange,
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
          ),
        ],
      ),
    );
  }
}

// ─── Page header ─────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final VoidCallback onCreateTap;
  final VoidCallback onCreatePublicTap;
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewModeChange;

  const _PageHeader({
    required this.onCreateTap,
    required this.onCreatePublicTap,
    required this.viewMode,
    required this.onViewModeChange,
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
                Text('Gerencie os pedidos da sua empresa', style: TextStyle(fontSize: 14, color: _DS.steel)),
              ],
            ),
          ),
          _ViewSwitcher(current: viewMode, onChange: onViewModeChange),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onCreatePublicTap,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Pedido público'),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.brandBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
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

        if (_lastSummary == null && (state is LoadingState || state is StartState)) {
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
        Icons.today_outlined,
        _DS.brandBlue,
        _DS.surfacePricing,
      ),
      _SummaryCardData(
        'Total',
        'Todos os pedidos',
        summary?.total ?? 0,
        Icons.receipt_long_outlined,
        _DS.ink,
        _DS.surface,
      ),
      _SummaryCardData(
        'Em andamento',
        '1, 2, 3, 4 e 8',
        summary?.inProgress ?? 0,
        Icons.timelapse_outlined,
        _DS.yellowDark,
        _DS.yellowLight,
      ),
      _SummaryCardData(
        'Concluídos',
        '5 e 9',
        summary?.completed ?? 0,
        Icons.check_circle_outline,
        _DS.successAccent,
        const Color(0xFFD1FAE5),
      ),
      _SummaryCardData(
        'Cancelados',
        '6 e 7',
        summary?.cancelled ?? 0,
        Icons.cancel_outlined,
        _DS.danger,
        _DS.dangerLight,
      ),
    ];
    return SizedBox(
      height: 110,
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
  final IconData icon;
  final Color fg;
  final Color bg;
  const _SummaryCardData(
    this.label,
    this.description,
    this.value,
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
            decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, size: 18, color: data.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${data.value}', style: TextStyle(fontSize: 20, color: data.fg)),
                Text(data.label, style: const TextStyle(fontSize: 11, color: _DS.stone), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(data.description, style: const TextStyle(fontSize: 10, color: _DS.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
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
          _Tab(label: 'Pedidos de Hoje', active: tabs.index == 0, onTap: () => tabs.animateTo(0)),
          const SizedBox(width: 8),
          _Tab(label: 'Todos os Pedidos', active: tabs.index == 1, onTap: () => tabs.animateTo(1)),
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
          style: TextStyle(fontSize: 13, color: active ? Colors.white : _DS.steel),
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
        if (s is ErrorState) return Center(child: Text(s.message, style: const TextStyle(color: _DS.danger)));
        if (s is SuccessState) {
          final orders = s.data is List ? (s.data as List).cast<OrderModel>() : <OrderModel>[];
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
            decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.receipt_long_outlined, size: 32, color: _DS.muted),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, color: _DS.slate)),
          const SizedBox(height: 4),
          const Text('Os pedidos aparecerão aqui assim que forem criados.', style: TextStyle(fontSize: 13, color: _DS.stone)),
        ],
      ),
    );
  }
}
