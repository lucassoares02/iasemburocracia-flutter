import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portal_assoc/core/services/response_model.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/customers/customers_controller.dart';
import 'package:portal_assoc/features/customers/customers_model.dart';
import 'package:portal_assoc/features/customers/customers_repository.dart';
import 'package:portal_assoc/features/customers/customers_usecase.dart';

part 'customers_card.dart';
part 'customers_details.dart';

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
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => _CustomerDetailPage(customerId: c.id!, ctrl: _ctrl),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ));
  }

  void _openCreate() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomerFormModal(ctrl: _ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              ValueListenableBuilder<StateApp>(
                valueListenable: _ctrl.stateFindAll,
                builder: (_, state, __) {
                  final count = state is SuccessState && state.data is List ? (state.data as List).length : null;
                  return _PageHeader(count: count, onCreateTap: _openCreate);
                },
              ),
              // ── KPI cards ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: ValueListenableBuilder<StateApp>(
                  valueListenable: _ctrl.stateSummary,
                  builder: (_, state, __) {
                    final s = state is SuccessState && state.data is CustomerSummaryModel ? state.data as CustomerSummaryModel : null;
                    return _SummaryCards(
                      summary: s,
                      loading: state is LoadingState || state is StartState,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // ── Filter bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: _FilterBar(
                  searchCtrl: _searchCtrl,
                  activeFilter: _filter,
                  onSearchChanged: _onSearchChanged,
                  onFilterChanged: _setFilter,
                ),
              ),
              // ── List ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: ValueListenableBuilder<StateApp>(
                    valueListenable: _ctrl.stateFindAll,
                    builder: (_, state, __) {
                      if (state is LoadingState || state is StartState) {
                        return _SkeletonList();
                      }
                      if (state is ErrorState) {
                        return _ErrorWidget(message: state.message);
                      }
                      if (state is SuccessState) {
                        final list = (state.data as List? ?? []).cast<CustomerModel>();
                        if (list.isEmpty) {
                          return _EmptyState(
                            filter: _filter,
                            onClear: () {
                              _searchCtrl.clear();
                              _setFilter('all');
                            },
                          );
                        }
                        return RefreshIndicator(
                          color: _DS.brandBlue,
                          onRefresh: () => _ctrl.fetchAll(
                            search: _searchCtrl.text.trim(),
                            filter: _filter,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: list.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CustomerCard(
                                customer: list[i],
                                onTap: () => _openDetail(list[i]),
                                onEdit: () => showDialog(
                                  context: context,
                                  barrierColor: Colors.black.withValues(alpha: 0.4),
                                  builder: (_) => _CustomerFormModal(
                                    ctrl: _ctrl,
                                    customer: list[i],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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

// ─── Page Header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final int? count;
  final VoidCallback onCreateTap;
  const _PageHeader({this.count, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text(
                    'Clientes',
                    style: TextStyle(fontSize: 22, color: _DS.ink),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _DS.surface,
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
          FilledButton.icon(
            onPressed: onCreateTap,
            style: FilledButton.styleFrom(
              backgroundColor: _DS.ink,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Novo cliente',
                style: TextStyle(
                  fontSize: 13,
                )),
          ),
        ],
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
      final narrow = box.maxWidth < 580;
      final cols = narrow ? 2 : 5;
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
                    fontSize: 10,
                    color: _DS.stone,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              loading || value == null
                  ? Container(height: 14, width: 50, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4)))
                  : Text(value!, style: const TextStyle(fontSize: 14, color: _DS.ink)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
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
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((f) {
            final active = activeFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onFilterChanged(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? _DS.ink : _DS.canvas,
                    borderRadius: BorderRadius.circular(_DS.rFull),
                    border: Border.all(color: active ? _DS.ink : _DS.hairline),
                  ),
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.w400,
                      color: active ? Colors.white : _DS.slate,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.zero,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: const BoxDecoration(color: _DS.hairlineSoft, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(height: 12, width: 130, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 80, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
                ]),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(height: 12, width: 56, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 36, decoration: BoxDecoration(color: _DS.hairlineSoft, borderRadius: BorderRadius.circular(4))),
              ]),
            ]),
          ),
        ),
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
          style: const TextStyle(fontSize: 15, color: _DS.ink),
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
