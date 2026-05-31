import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/customers/customers_controller.dart';
import 'package:portal_assoc/features/customers/customers_model.dart';
import 'package:portal_assoc/features/customers/customers_repository.dart';
import 'package:portal_assoc/features/customers/customers_usecase.dart';

part 'customers_card.dart';
part 'customers_details.dart';
part 'customer_detail_page.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
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
  static const rFull = 9999.0;
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
  static const rXxxl = 28.0;

  static const _statusColors = {
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

  static Color statusBg(int? s) => _statusColors[s]?.bg ?? const Color(0xFFEEF0F3);
  static Color statusFg(int? s) => _statusColors[s]?.fg ?? const Color(0xFF555A6A);
  static String statusLabel(int? s) => _statusColors[s]?.label ?? '—';

  static Color avatarBg(String? name) {
    const palette = [
      Color(0xFF4262FF),
      Color(0xFF6D28D9),
      Color(0xFF946C0A),
      Color(0xFF065F46),
      Color(0xFF187574),
      Color(0xFFB45309),
    ];
    if (name == null || name.isEmpty) return palette[0];
    return palette[name.hashCode.abs() % palette.length];
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _datetimeFmt = DateFormat('dd/MM HH:mm', 'pt_BR');

// ─── Page ─────────────────────────────────────────────────────────────────────
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late final CustomersController _ctrl = CustomersController(
    CustomersUseCase(CustomersRepository()),
  );
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl.fetchSummary();
    _ctrl.fetchAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), () {
      _ctrl.fetchAll(search: v.trim(), filter: _filter);
    });
  }

  void _setFilter(String f) {
    if (f == _filter) return;
    setState(() => _filter = f);
    _ctrl.fetchAll(search: _searchCtrl.text.trim(), filter: f);
  }

  void _openDetail(CustomerModel c) {
    context.goNamed('customer-detail', pathParameters: {'id': '${c.id}'});
  }

  void _refresh() {
    _ctrl.fetchAll(search: _searchCtrl.text.trim(), filter: _filter);
    _ctrl.fetchSummary();
  }

  void _openCreate() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomerFormModal(ctrl: _ctrl),
    );
  }

  void _openEdit(CustomerModel c) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomerFormModal(ctrl: _ctrl, customer: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1480),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<StateApp>(
                  valueListenable: _ctrl.stateFindAll,
                  builder: (_, state, __) {
                    final count = state is SuccessState && state.data is List ? (state.data as List).length : null;
                    return _PageHeader(
                      count: count,
                      onCreate: _openCreate,
                      onRefresh: _refresh,
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<StateApp>(
                  valueListenable: _ctrl.stateSummary,
                  builder: (_, state, __) {
                    final s = state is SuccessState && state.data is CustomerSummaryModel ? state.data as CustomerSummaryModel : null;
                    return _SummaryCards(
                      summary: s,
                      loading: state is LoadingState || state is StartState,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _FilterBar(
                  searchCtrl: _searchCtrl,
                  activeFilter: _filter,
                  onSearchChanged: _onSearchChanged,
                  onFilterChanged: _setFilter,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ListPane(
                    ctrl: _ctrl,
                    filter: _filter,
                    onSelect: _openDetail,
                    onEdit: _openEdit,
                    onClearFilters: () {
                      _searchCtrl.clear();
                      _setFilter('all');
                    },
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

// ─── Page Header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final int? count;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;
  const _PageHeader({this.count, required this.onCreate, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text(
                  'Clientes',
                  style: TextStyle(fontSize: 22, color: _DS.ink, fontWeight: FontWeight.w600),
                ),
                if (count != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _DS.canvas,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _DS.hairline),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 12, color: _DS.slate),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              const Text(
                'Gerencie e acompanhe seus clientes',
                style: TextStyle(fontSize: 13, color: _DS.steel),
              ),
            ],
          ),
        ),
        _IconActionButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Atualizar',
          onTap: onRefresh,
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: _DS.ink,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text(
            'Novo cliente',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _IconActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconActionButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hover ? _DS.surface : _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rFull),
              border: Border.all(color: _DS.hairline),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 17, color: _DS.slate),
          ),
        ),
      ),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────
class _SummaryCards extends StatelessWidget {
  final CustomerSummaryModel? summary;
  final bool loading;
  const _SummaryCards({this.summary, required this.loading});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return LayoutBuilder(builder: (_, box) {
      final cols = box.maxWidth < 580
          ? 2
          : box.maxWidth < 980
              ? 3
              : 5;
      final w = (box.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Kpi(
            loading: loading,
            icon: Icons.group_outlined,
            iconColor: _DS.brandBlue,
            iconBg: const Color(0xFFEEF3FF),
            label: 'Total clientes',
            value: s != null ? '${s.totalClients}' : null,
            width: w,
          ),
          _Kpi(
            loading: loading,
            icon: Icons.trending_up_rounded,
            iconColor: _DS.successAccent,
            iconBg: const Color(0xFFE6FAF3),
            label: 'Ativos (30 dias)',
            value: s != null ? '${s.activeClients}' : null,
            width: w,
          ),
          _Kpi(
            loading: loading,
            icon: Icons.person_add_outlined,
            iconColor: const Color(0xFF6D28D9),
            iconBg: const Color(0xFFEDE9FE),
            label: 'Novos este mês',
            value: s != null ? '${s.newThisMonth}' : null,
            width: w,
          ),
          _Kpi(
            loading: loading,
            icon: Icons.repeat_rounded,
            iconColor: const Color(0xFFB45309),
            iconBg: const Color(0xFFFEF3C7),
            label: 'Recorrentes',
            value: s != null ? '${s.recurringClients}' : null,
            width: w,
          ),
          _Kpi(
            loading: loading,
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF187574),
            iconBg: const Color(0xFFCCFBF1),
            label: 'Ticket médio',
            value: s != null ? _currencyFmt.format(s.avgSpentPerClient) : null,
            width: w,
          ),
        ],
      );
    });
  }
}

class _Kpi extends StatelessWidget {
  final bool loading;
  final IconData icon;
  final Color iconColor, iconBg;
  final String label;
  final String? value;
  final double width;

  const _Kpi({
    required this.loading,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.stone,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              loading || value == null
                  ? Container(height: 14, width: 50, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4)))
                  : Text(value!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _DS.ink,
                        fontWeight: FontWeight.w600,
                      )),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;

  const _FilterBar({
    required this.searchCtrl,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  static const _filters = [
    ('all', 'Todos'),
    ('recurring', 'Recorrentes'),
    ('new', 'Novos'),
    ('high_value', 'Alto Valor'),
    ('inactive', 'Inativos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 360,
          height: 40,
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 13, color: _DS.ink),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou telefone…',
              hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18, color: _DS.stone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
              filled: true,
              fillColor: _DS.canvas,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _filters.map((f) {
              final active = activeFilter == f.$1;
              return _FilterChip(
                label: f.$2,
                active: active,
                onTap: () => onFilterChanged(f.$1),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _DS.ink : (_hover ? _DS.surface : _DS.canvas),
            borderRadius: BorderRadius.circular(_DS.rFull),
            border: Border.all(color: active ? _DS.ink : _DS.hairline),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? Colors.white : _DS.slate,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List Pane ────────────────────────────────────────────────────────────────
class _ListPane extends StatelessWidget {
  final CustomersController ctrl;
  final String filter;
  final ValueChanged<CustomerModel> onSelect;
  final ValueChanged<CustomerModel> onEdit;
  final VoidCallback onClearFilters;

  const _ListPane({
    required this.ctrl,
    required this.filter,
    required this.onSelect,
    required this.onEdit,
    required this.onClearFilters,
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
      child: Column(
        children: [
          const _TableHeader(),
          Expanded(
            child: ValueListenableBuilder<StateApp>(
              valueListenable: ctrl.stateFindAll,
              builder: (_, state, __) {
                if (state is LoadingState || state is StartState) {
                  return const _SkeletonList();
                }
                if (state is ErrorState) {
                  return _ErrorWidget(message: state.message);
                }
                if (state is SuccessState) {
                  final list = (state.data as List? ?? []).cast<CustomerModel>();
                  if (list.isEmpty) {
                    return _EmptyState(filter: filter, onClear: onClearFilters);
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    itemBuilder: (_, i) => _CustomerRow(
                      customer: list[i],
                      isLast: i == list.length - 1,
                      onTap: () => onSelect(list[i]),
                      onEdit: () => onEdit(list[i]),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _DS.surface,
        border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 36),
          SizedBox(width: 12),
          Expanded(flex: 4, child: _ColLabel('Cliente')),
          Expanded(flex: 3, child: _ColLabel('Telefone')),
          Expanded(flex: 2, child: _ColLabel('Pedidos')),
          Expanded(flex: 3, child: _ColLabel('Total gasto', align: TextAlign.right)),
          SizedBox(width: 62),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _ColLabel(this.text, {this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 11,
        color: _DS.stone,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: EdgeInsets.zero,
      itemBuilder: (_, __) => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
        ),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: const BoxDecoration(color: _DS.hairlineSoft, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(height: 12, width: 130, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 10, width: 80, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
            ]),
          ),
          Expanded(flex: 3, child: Container(height: 11, width: 90, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4)))),
          Expanded(flex: 2, child: Container(height: 11, width: 30, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4)))),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(height: 12, width: 70, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
            ),
          ),
          const SizedBox(width: 62),
        ]),
      ),
    );
  }
}

// ─── Empty & Error states ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onClear;
  const _EmptyState({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final filtered = filter != 'all';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: _DS.surface, shape: BoxShape.circle, border: Border.all(color: _DS.hairline)),
            child: const Icon(Icons.group_outlined, size: 30, color: _DS.stone),
          ),
          const SizedBox(height: 14),
          Text(
            filtered ? 'Nenhum cliente neste filtro' : 'Nenhum cliente cadastrado',
            style: const TextStyle(fontSize: 15, color: _DS.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            filtered ? 'Tente limpar os filtros aplicados.' : 'Adicione seu primeiro cliente clicando em "Novo cliente".',
            style: const TextStyle(fontSize: 13, color: _DS.stone),
            textAlign: TextAlign.center,
          ),
          if (filtered) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.ink,
                side: const BorderSide(color: _DS.hairline),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Limpar filtros'),
            ),
          ],
        ]),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 36, color: _DS.danger),
        const SizedBox(height: 10),
        const Text('Erro ao carregar', style: TextStyle(fontSize: 15, color: _DS.ink)),
        const SizedBox(height: 4),
        Text(message, style: const TextStyle(fontSize: 12, color: _DS.stone), textAlign: TextAlign.center),
      ]),
    );
  }
}
