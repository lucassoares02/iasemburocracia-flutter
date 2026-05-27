import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/format_currency.dart';
import 'package:portal_assoc/features/menu_categories/menu_categories_model.dart';
import 'package:portal_assoc/features/menu_categories/menu_categories_repository.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/product_options/product_options_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/state/app_state.dart';
import 'menu_items_controller.dart';
import 'menu_items_repository.dart';
import 'menu_items_usecase.dart';

part 'menu_items_import.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _DS {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;
  static const double s10 = 40.0;

  static const double rSm = 6.0;
  static const double rMd = 8.0;
  static const double rLg = 12.0;
  static const double rXl = 16.0;
  static const double rXxl = 20.0;
  static const double rXxxl = 28.0;
  static const double rFull = 9999.0;

  static const Color ink = Color(0xFF1C1C1E);
  static const Color charcoal = Color(0xFF2C2C34);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color stone = Color(0xFF8E91A0);
  static const Color muted = Color(0xFFA5A8B5);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color hairlineStrong = Color(0xFFC7CAD5);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color brandYellow = Color(0xFFFFD02F);
  static const Color yellowDark = Color(0xFF746019);
  static const Color yellowLight = Color(0xFFFFF4C4);
  static const Color successAccent = Color(0xFF00B473);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF050038).withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: const Color(0xFF050038).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowModal = [
    BoxShadow(
      color: const Color(0xFF050038).withValues(alpha: 0.12),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MenuItemsPage extends StatefulWidget {
  const MenuItemsPage({super.key});

  @override
  State<MenuItemsPage> createState() => _MenuItemsPageState();
}

class _MenuItemsPageState extends State<MenuItemsPage> with SingleTickerProviderStateMixin {
  late final MenuItemsController _ctrl = MenuItemsController(
    StartState(),
    MenuItemsUseCase(MenuItemsRepository()),
  );

  final TextEditingController _search = TextEditingController();
  List<MenuItemsModel> _all = [];
  List<MenuItemsModel> _filtered = [];

  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl.findAll();
    _search.addListener(_filter);
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _search.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _search.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((e) {
              return (e.name?.toLowerCase().contains(q) ?? false) || (e.description?.toLowerCase().contains(q) ?? false) || (e.sku?.toLowerCase().contains(q) ?? false);
            }).toList();
    });
  }

  void _openForm({MenuItemsModel? item}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _MenuItemFormDialog(
        item: item,
        controller: _ctrl,
        onDeleteRequest: item != null ? () => _openDeleteConfirm(item) : null,
      ),
    );
  }

  Future<void> _openImport() async {
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? 0;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _ImportDialog(
        controller: _ctrl,
        catRepo: MenuCategoriesRepository(),
        companyId: companyId,
      ),
    );
  }

  void _openDeleteConfirm(MenuItemsModel item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _DeleteConfirmDialog(item: item, controller: _ctrl),
    );
  }

  Future<void> _openOptions(MenuItemsModel item) async {
    if (item.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company') ?? item.companyId ?? 0;
    if (!mounted) return;
    await showProductOptionsManager(
      context,
      productId: item.id!,
      companyId: companyId,
      productName: item.name ?? 'Produto',
    );
  }

  Future<void> _toggleItem(MenuItemsModel item) async {
    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getInt('company') ?? 0;
    final toggled = MenuItemsModel.fromJson({
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'category_id': item.categoryId ?? 1,
      'company_id': company,
      'price': item.price,
      'available': !(item.available ?? true),
      'featured': item.featured,
      'sku': item.sku,
      'display_order': item.displayOrder,
      'prep_time_minutes': item.prepTimeMinutes,
    });
    await _ctrl.toggle(toggled);
  }

  MenuItemsModel _cloneItem(MenuItemsModel src) {
    return MenuItemsModel.fromJson({
      'name': '${src.name} (cópia)',
      'description': src.description,
      'category_id': src.categoryId,
      'company_id': src.companyId,
      'price': src.price,
      'available': src.available,
      'featured': false,
      'sku': null,
      'display_order': src.displayOrder,
      'prep_time_minutes': src.prepTimeMinutes,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: ValueListenableBuilder<StateApp>(
                valueListenable: _ctrl.stateFindAll,
                builder: (context, state, _) {
                  if (state is StartState || state is LoadingState) return _buildSkeleton();
                  if (state is ErrorState) return _buildError(state.message);
                  if (state is SuccessState) {
                    _all = List<MenuItemsModel>.from(state.data);
                    if (_search.text.isEmpty) _filtered = _all;
                    if (_filtered.isEmpty) return _buildEmpty();
                    return _buildGrid(_filtered);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s5, _DS.s6, _DS.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cardápio',
                  style: TextStyle(
                    fontSize: 20,
                    color: _DS.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gerencie os produtos e itens do seu cardápio.',
                  style: TextStyle(fontSize: 13, color: _DS.steel, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: _DS.s4),
          ValueListenableBuilder<StateApp>(
            valueListenable: _ctrl.stateFindAll,
            builder: (_, state, __) {
              if (state is! SuccessState) return const SizedBox.shrink();
              final items = List<MenuItemsModel>.from(state.data);
              final active = items.where((e) => e.available == true).length;
              return Row(
                children: [
                  _Chip(label: '${items.length} itens', bg: _DS.surface, fg: _DS.slate),
                  const SizedBox(width: _DS.s2),
                  _Chip(
                    label: '$active ativos',
                    bg: _DS.successSubtle,
                    fg: _DS.successText,
                    border: _DS.successBorder,
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: _DS.s4),
          OutlinedButton.icon(
            onPressed: _openImport,
            icon: const Icon(LucideIcons.upload, size: 14),
            label: const Text('Importar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DS.ink,
              side: const BorderSide(color: _DS.hairline),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: _DS.s2),
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Novo Produto'),
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

  // ─── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s6, 0, _DS.s6, _DS.s4),
      child: _SearchInput(controller: _search),
    );
  }

  // ─── Grid ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<MenuItemsModel> items) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: GridView.builder(
        padding: const EdgeInsets.all(_DS.s6),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 290,
          crossAxisSpacing: _DS.s4,
          mainAxisSpacing: _DS.s4,
          mainAxisExtent: 360,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _MenuItemCard(
          item: items[i],
          onEdit: () => _openForm(item: items[i]),
          onDelete: () => _openDeleteConfirm(items[i]),
          onToggle: () => _toggleItem(items[i]),
          onDuplicate: () => _openForm(item: _cloneItem(items[i])),
          onOptions: () => _openOptions(items[i]),
        ),
      ),
    );
  }

  // ─── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    final searching = _search.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_DS.s10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: searching ? _DS.surface : _DS.yellowLight,
                borderRadius: BorderRadius.circular(_DS.rXxxl),
                border: Border.all(
                  color: searching ? _DS.hairline : const Color(0xFFFFE082),
                ),
              ),
              child: Icon(
                searching ? LucideIcons.searchX : LucideIcons.utensilsCrossed,
                size: 26,
                color: searching ? _DS.stone : _DS.yellowDark,
              ),
            ),
            const SizedBox(height: _DS.s4),
            Text(
              searching ? 'Nenhum resultado encontrado' : 'Cardápio ainda vazio',
              style: const TextStyle(
                fontSize: 16,
                color: _DS.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: _DS.s2),
            Text(
              searching ? 'Tente outros termos de busca para encontrar seu produto.' : 'Adicione o primeiro produto para começar a montar seu cardápio.',
              style: const TextStyle(fontSize: 13, color: _DS.slate, height: 1.6),
              textAlign: TextAlign.center,
            ),
            if (!searching) ...[
              const SizedBox(height: _DS.s6),
              _PillButton(
                label: 'Adicionar produto',
                icon: LucideIcons.plus,
                onPressed: _openForm,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Skeleton ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(_DS.s6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 290,
        crossAxisSpacing: _DS.s4,
        mainAxisSpacing: _DS.s4,
        mainAxisExtent: 360,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.dangerSubtle,
              borderRadius: BorderRadius.circular(_DS.rXxxl),
              border: Border.all(color: _DS.dangerBorder),
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 22, color: _DS.danger),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Falha ao carregar produtos',
            style: TextStyle(
              fontSize: 15,
              color: _DS.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _DS.slate, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _DS.s6),
          _OutlinedPillButton(
            label: 'Tentar novamente',
            icon: LucideIcons.refreshCw,
            onPressed: _ctrl.findAll,
          ),
        ],
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _MenuItemCard extends StatefulWidget {
  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onDuplicate,
    required this.onOptions,
  });

  final MenuItemsModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onOptions;

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final available = item.available ?? true;
    final featured = item.featured ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _hovered ? _DS.hairlineStrong : _DS.hairline),
          boxShadow: _hovered ? _DS.shadowCard : _DS.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_DS.rXl),
                    topRight: Radius.circular(_DS.rXl),
                  ),
                  child: Container(
                    height: 148,
                    width: double.infinity,
                    color: _DS.surface,
                    child: item.imageUrl != null
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ImagePlaceholder(featured: featured),
                          )
                        : _ImagePlaceholder(featured: featured),
                  ),
                ),
                if (featured)
                  Positioned(
                    top: _DS.s2,
                    left: _DS.s2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _DS.brandYellow,
                        borderRadius: BorderRadius.circular(_DS.rFull),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.star, size: 10, color: _DS.ink),
                          SizedBox(width: 4),
                          Text(
                            'Destaque',
                            style: TextStyle(
                              fontSize: 10,
                              color: _DS.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: _DS.s2,
                  right: _DS.s2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: available ? _DS.successAccent : _DS.stone,
                      shape: BoxShape.circle,
                      border: Border.all(color: _DS.canvas, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(_DS.s4, _DS.s3, _DS.s4, _DS.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? 'Sem nome',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _DS.ink,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: _DS.s1),
                    Expanded(
                      child: Text(
                        item.description ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _DS.slate,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Price + meta row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            formatCurrency(item.price),
                            style: const TextStyle(
                              fontSize: 17,
                              color: _DS.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (item.prepTimeMinutes != null)
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 11, color: _DS.stone),
                              const SizedBox(width: 3),
                              Text(
                                '${item.prepTimeMinutes}min',
                                style: const TextStyle(fontSize: 11, color: _DS.stone),
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Actions
                    const SizedBox(height: _DS.s3),
                    Row(
                      children: [
                        _CardAction(
                          icon: LucideIcons.pencil,
                          tooltip: 'Editar',
                          onTap: widget.onEdit,
                        ),
                        const SizedBox(width: _DS.s1),
                        _CardAction(
                          icon: LucideIcons.sliders,
                          tooltip: 'Opções e adicionais',
                          onTap: widget.onOptions,
                        ),
                        const SizedBox(width: _DS.s1),
                        _CardAction(
                          icon: LucideIcons.copy,
                          tooltip: 'Duplicar',
                          onTap: widget.onDuplicate,
                        ),
                        const SizedBox(width: _DS.s1),
                        _CardAction(
                          icon: available ? LucideIcons.eyeOff : LucideIcons.eye,
                          tooltip: available ? 'Desativar' : 'Ativar',
                          onTap: widget.onToggle,
                        ),
                        const Spacer(),
                        _CardAction(
                          icon: LucideIcons.trash2,
                          tooltip: 'Excluir',
                          onTap: widget.onDelete,
                          danger: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.featured = false});
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        LucideIcons.utensilsCrossed,
        size: 36,
        color: featured ? _DS.yellowDark.withValues(alpha: 0.4) : _DS.muted,
      ),
    );
  }
}

class _CardAction extends StatefulWidget {
  const _CardAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_CardAction> createState() => _CardActionState();
}

class _CardActionState extends State<_CardAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? (widget.danger ? _DS.dangerSubtle : _DS.surface) : Colors.transparent,
              borderRadius: BorderRadius.circular(_DS.rMd),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? (widget.danger ? _DS.danger : _DS.ink) : _DS.stone,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chips ────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
  });
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: border ?? _DS.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: fg,
        ),
      ),
    );
  }
}

// ─── Search Input ─────────────────────────────────────────────────────────────

class _SearchInput extends StatefulWidget {
  const _SearchInput({required this.controller});
  final TextEditingController controller;

  @override
  State<_SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<_SearchInput> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 40,
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rMd),
        border: Border.all(
          color: _focused ? _DS.brandBlue : _DS.hairlineStrong,
          width: _focused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _DS.s3),
            child: Icon(LucideIcons.search, size: 15, color: _DS.stone),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              style: const TextStyle(fontSize: 14, color: _DS.ink),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, descrição ou SKU...',
                hintStyle: TextStyle(fontSize: 14, color: _DS.muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: widget.controller.clear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: _DS.s3),
                child: Icon(LucideIcons.x, size: 14, color: _DS.stone),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Form Dialog ─────────────────────────────────────────────────────────────

class _MenuItemFormDialog extends StatefulWidget {
  const _MenuItemFormDialog({
    this.item,
    required this.controller,
    this.onDeleteRequest,
  });

  final MenuItemsModel? item;
  final MenuItemsController controller;
  final VoidCallback? onDeleteRequest;

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

// Sugestões padrão exibidas quando a empresa ainda não tem categorias.
const List<String> _kDefaultCategorySuggestions = [
  'Lanches',
  'Hambúrgueres',
  'Pizzas',
  'Bebidas',
  'Sobremesas',
  'Doces',
  'Bolos',
  'Saladas',
  'Pratos',
  'Combos',
  'Acompanhamentos',
  'Cafés',
];

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _sku;
  late final TextEditingController _prepTime;
  late final TextEditingController _order;
  late bool _available;
  late bool _featured;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageMime;
  String? _imageUrl; // resolved URL after upload (or pre-existing)
  bool _uploading = false;
  String? _uploadError;

  // Categorias
  final _categoriesRepo = MenuCategoriesRepository();
  List<MenuCategoriesModel> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _creatingCategory = false;
  String? _categoryError;
  int? _companyId;

  bool get _editing => widget.item != null;
  static const _allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name ?? '');
    _description = TextEditingController(text: i?.description ?? '');
    _price = TextEditingController(
      text: i?.price != null ? i!.price!.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _sku = TextEditingController(text: i?.sku ?? '');
    _prepTime = TextEditingController(
      text: i?.prepTimeMinutes != null ? i!.prepTimeMinutes.toString() : '',
    );
    _order = TextEditingController(
      text: i?.displayOrder != null ? i!.displayOrder.toString() : '',
    );
    _available = i?.available ?? true;
    _featured = i?.featured ?? false;
    _imageUrl = i?.imageUrl;
    _selectedCategoryId = i?.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company') ?? 0;
      _companyId = companyId;
      if (companyId == 0) {
        if (!mounted) return;
        setState(() => _loadingCategories = false);
        return;
      }
      final resp = await _categoriesRepo.findByCompany(companyId);
      if (!mounted) return;
      if (resp.success && resp.data is List) {
        final list = (resp.data as List).cast<MenuCategoriesModel>();
        setState(() {
          _categories = list;
          _loadingCategories = false;
          // Se editar e o id existe na lista, mantém; senão limpa
          if (_selectedCategoryId != null && !list.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      } else {
        setState(() {
          _loadingCategories = false;
          _categoryError = 'Não foi possível carregar categorias.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoryError = 'Erro ao carregar categorias.';
      });
    }
  }

  Future<MenuCategoriesModel?> _createCategory(String name) async {
    final companyId = _companyId ?? 0;
    if (companyId == 0 || name.trim().isEmpty) return null;
    setState(() {
      _creatingCategory = true;
      _categoryError = null;
    });
    try {
      final newCat = MenuCategoriesModel.fromJson({
        'company_id': companyId,
        'name': name.trim(),
        'sort_order': _categories.length + 1,
        'active': true,
      });
      final resp = await _categoriesRepo.create(newCat);
      if (!mounted) return null;
      if (resp.success && resp.data is Map<String, dynamic>) {
        final created = MenuCategoriesModel.fromJson(resp.data as Map<String, dynamic>);
        setState(() {
          // Evita duplicar se já existir
          if (!_categories.any((c) => c.id == created.id)) {
            _categories = [..._categories, created];
          }
          _selectedCategoryId = created.id;
          _creatingCategory = false;
        });
        return created;
      }
      setState(() {
        _creatingCategory = false;
        _categoryError = 'Não foi possível criar a categoria.';
      });
      return null;
    } catch (_) {
      if (!mounted) return null;
      setState(() {
        _creatingCategory = false;
        _categoryError = 'Erro de conexão ao criar categoria.';
      });
      return null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _sku.dispose();
    _prepTime.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      _showSnack('Não foi possível ler o arquivo selecionado.', _DS.danger);
      return;
    }

    final ext = (file.extension ?? '').toLowerCase();
    if (!_allowedExts.contains(ext)) {
      _showSnack(
        'Formato não suportado. Use JPG, PNG, WEBP ou GIF.',
        _DS.danger,
      );
      return;
    }

    // 10 MB hard limit (matches API)
    if (file.bytes!.lengthInBytes > 10 * 1024 * 1024) {
      _showSnack('Imagem maior que 10 MB. Escolha uma menor.', _DS.danger);
      return;
    }

    setState(() {
      _imageBytes = file.bytes;
      _imageName = file.name;
      _imageMime = _mimeFromExtension(ext);
      _uploadError = null;
    });

    await _uploadPicked();
  }

  Future<void> _uploadPicked() async {
    if (_imageBytes == null) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final uploadResult = await widget.controller.uploadImage(
        _imageBytes!,
        _imageName ?? 'product_image.jpg',
        _imageMime ?? 'image/jpeg',
      );
      if (!mounted) return;
      if (!uploadResult.success) {
        setState(() {
          _uploading = false;
          _uploadError = 'Falha ao enviar imagem. Toque para tentar novamente.';
        });
        return;
      }
      final data = uploadResult.data;
      final url = (data is Map) ? data['url'] as String? : null;
      if (url == null || url.isEmpty) {
        setState(() {
          _uploading = false;
          _uploadError = 'Resposta inesperada do servidor. Toque para tentar novamente.';
        });
        return;
      }
      setState(() {
        _imageUrl = url;
        _imageBytes = null; // free memory, we now have URL
        _uploading = false;
        _uploadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = 'Erro de conexão. Toque para tentar novamente.';
      });
    }
  }

  void _removeImage() {
    if (_uploading) return;
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageMime = null;
      _imageUrl = null;
      _uploadError = null;
    });
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  String _mimeFromExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _save() async {
    if (_uploading) {
      _showSnack('Aguarde o upload da imagem terminar.', const Color(0xFFF59E0B));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Categoria obrigatória
    if (_selectedCategoryId == null) {
      _showSnack(
        'Selecione uma categoria ou crie uma nova.',
        _DS.danger,
      );
      return;
    }

    // If the user picked an image but upload failed, block save until resolved
    if (_imageBytes != null && _imageUrl == null) {
      _showSnack(
        'A imagem ainda não foi enviada. Toque na imagem para tentar novamente ou remova-a.',
        _DS.danger,
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final company = prefs.getInt('company') ?? 0;
    final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0;

    final json = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'category_id': _selectedCategoryId,
      'company_id': company,
      'price': price,
      'available': _available,
      'featured': _featured,
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'prep_time_minutes': _prepTime.text.isEmpty ? null : int.tryParse(_prepTime.text),
      'display_order': _order.text.isEmpty ? null : int.tryParse(_order.text),
      'image_url': _imageUrl,
    };
    if (_editing) json['id'] = widget.item!.id;

    final model = MenuItemsModel.fromJson(json);
    if (!mounted) return;
    if (_editing) {
      await widget.controller.update(model, context);
    } else {
      await widget.controller.create(model, context);
    }
    if (!mounted) return;
    context.read<OnboardingProvider>().refresh(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: _DS.s6, vertical: _DS.s8),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 800),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXxxl),
          border: Border.all(color: _DS.hairline),
          boxShadow: _DS.shadowModal,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_DS.s8, 0, _DS.s8, _DS.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageUpload(),
                      const SizedBox(height: _DS.s6),
                      _buildNameSkuRow(),
                      const SizedBox(height: _DS.s5),
                      const _Label(text: 'Descrição *', icon: LucideIcons.alignLeft),
                      const SizedBox(height: _DS.s2),
                      _Input(
                        controller: _description,
                        hint: 'Descreva ingredientes e características...',
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição obrigatória' : null,
                      ),
                      const SizedBox(height: _DS.s5),
                      _CategoryPicker(
                        loading: _loadingCategories,
                        creating: _creatingCategory,
                        categories: _categories,
                        selectedId: _selectedCategoryId,
                        errorMessage: _categoryError,
                        onSelect: (id) => setState(() => _selectedCategoryId = id),
                        onCreate: (name) => _createCategory(name),
                      ),
                      const SizedBox(height: _DS.s5),
                      _buildPricePrepOrderRow(),
                      const SizedBox(height: _DS.s6),
                      _Toggle(
                        icon: LucideIcons.checkCircle,
                        label: 'Disponível para pedidos',
                        subtitle: 'Produto visível e ativo no cardápio',
                        value: _available,
                        activeColor: _DS.successAccent,
                        onChanged: (v) => setState(() => _available = v),
                      ),
                      const SizedBox(height: _DS.s3),
                      _Toggle(
                        icon: LucideIcons.star,
                        label: 'Produto em destaque',
                        subtitle: 'Exibe badge dourado e aparece em evidência',
                        value: _featured,
                        activeColor: _DS.brandYellow,
                        onChanged: (v) => setState(() => _featured = v),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDialogFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s8, _DS.s6, _DS.s6, _DS.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Editar Produto' : 'Novo Produto',
                  style: const TextStyle(
                    fontSize: 18,
                    color: _DS.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _editing ? 'Atualize as informações do produto.' : 'Preencha os dados para adicionar ao cardápio.',
                  style: const TextStyle(fontSize: 13, color: _DS.slate, height: 1.4),
                ),
              ],
            ),
          ),
          _CloseBtn(onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildImageUpload() {
    final hasPreview = _imageBytes != null || _imageUrl != null;
    final hasError = _uploadError != null;
    return GestureDetector(
      onTap: hasError ? _uploadPicked : _pickImage,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(
              color: hasError ? _DS.danger : _DS.hairline,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: hasPreview ? _buildImagePreview() : _buildUploadPrompt(),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_DS.rXl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image: prefer remote URL, then local bytes (during upload)
          if (_imageUrl != null && _imageUrl!.isNotEmpty)
            Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildImagePreviewFallback(),
            )
          else if (_imageBytes != null)
            Image.memory(_imageBytes!, fit: BoxFit.cover)
          else
            _buildImagePreviewFallback(),
          // Upload progress overlay
          if (_uploading)
            Container(
              color: _DS.ink.withValues(alpha: 0.55),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enviando imagem...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Error overlay with retry
          if (_uploadError != null && !_uploading)
            Container(
              color: _DS.danger.withValues(alpha: 0.85),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 26, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      _uploadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Action chips
          if (!_uploading)
            Positioned(
              bottom: _DS.s2,
              right: _DS.s2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _previewChip(
                    icon: LucideIcons.refreshCw,
                    label: 'Trocar',
                    onTap: _pickImage,
                  ),
                  const SizedBox(width: 6),
                  _previewChip(
                    icon: LucideIcons.trash2,
                    label: 'Remover',
                    onTap: _removeImage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: 5),
        decoration: BoxDecoration(
          color: _DS.ink.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(_DS.rFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewFallback() {
    return Container(
      color: _DS.surface,
      child: const Center(
        child: Icon(LucideIcons.image, size: 32, color: _DS.muted),
      ),
    );
  }

  Widget _buildUploadPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(color: _DS.hairlineStrong),
          ),
          child: const Icon(LucideIcons.upload, size: 18, color: _DS.stone),
        ),
        const SizedBox(height: _DS.s3),
        const Text(
          'Clique para enviar uma imagem',
          style: TextStyle(fontSize: 13, color: _DS.slate),
        ),
        const SizedBox(height: 2),
        const Text(
          'PNG, JPG ou WEBP · Máx. 5 MB',
          style: TextStyle(fontSize: 11, color: _DS.stone),
        ),
      ],
    );
  }

  Widget _buildNameSkuRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: 'Nome *', icon: LucideIcons.tag),
              const SizedBox(height: _DS.s2),
              _Input(
                controller: _name,
                hint: 'Ex: Pizza Margherita',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: _DS.s4),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: 'SKU', icon: LucideIcons.hash),
              const SizedBox(height: _DS.s2),
              _Input(controller: _sku, hint: 'Ex: PIZZA-001'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricePrepOrderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: 'Preço *', icon: LucideIcons.dollarSign),
              const SizedBox(height: _DS.s2),
              _Input(
                controller: _price,
                hint: '0,00',
                prefix: 'R\$ ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Preço obrigatório';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: _DS.s4),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: 'Preparo (min)', icon: LucideIcons.clock),
              const SizedBox(height: _DS.s2),
              _Input(
                controller: _prepTime,
                hint: '30',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        const SizedBox(width: _DS.s4),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(text: 'Ordem', icon: LucideIcons.arrowUpDown),
              const SizedBox(height: _DS.s2),
              _Input(
                controller: _order,
                hint: '1',
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDialogFooter() {
    return ValueListenableBuilder<StateApp>(
      valueListenable: widget.controller.stateCreate,
      builder: (_, state, __) {
        final saving = state is LoadingState;
        final busy = _uploading || saving;
        final btnLabel = _uploading ? 'Enviando imagem...' : (_editing ? 'Salvar' : 'Adicionar');

        return Container(
          padding: const EdgeInsets.fromLTRB(_DS.s8, _DS.s4, _DS.s8, _DS.s6),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _DS.hairlineSoft)),
          ),
          child: Row(
            children: [
              if (_editing && widget.onDeleteRequest != null)
                _DangerOutlinedBtn(
                  label: 'Excluir',
                  icon: LucideIcons.trash2,
                  onTap: busy
                      ? () {}
                      : () {
                          Navigator.pop(context);
                          widget.onDeleteRequest!();
                        },
                ),
              const Spacer(),
              _GhostBtn(label: 'Cancelar', onTap: busy ? () {} : () => Navigator.pop(context)),
              const SizedBox(width: _DS.s2),
              _PillButton(
                label: btnLabel,
                icon: busy ? LucideIcons.loader : LucideIcons.check,
                loading: busy,
                onPressed: busy ? () {} : _save,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Delete Confirm Dialog ────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({required this.item, required this.controller});
  final MenuItemsModel item;
  final MenuItemsController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(_DS.s6),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXxl),
          border: Border.all(color: _DS.hairline),
          boxShadow: _DS.shadowModal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _DS.dangerSubtle,
                    borderRadius: BorderRadius.circular(_DS.rLg),
                    border: Border.all(color: _DS.dangerBorder),
                  ),
                  child: const Icon(LucideIcons.trash2, size: 16, color: _DS.danger),
                ),
                const SizedBox(width: _DS.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Excluir produto',
                        style: TextStyle(
                          fontSize: 15,
                          color: _DS.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        item.name ?? '',
                        style: const TextStyle(fontSize: 12, color: _DS.slate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _CloseBtn(onTap: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: _DS.s5),
            Container(
              padding: const EdgeInsets.all(_DS.s4),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(_DS.rMd),
                border: Border.all(color: _DS.hairline),
              ),
              child: const Text(
                'Esta ação não pode ser desfeita. O produto será removido permanentemente do cardápio.',
                style: TextStyle(fontSize: 13, color: _DS.slate, height: 1.5),
              ),
            ),
            const SizedBox(height: _DS.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _GhostBtn(label: 'Cancelar', onTap: () => Navigator.pop(context)),
                const SizedBox(width: _DS.s2),
                _DangerBtn(
                  label: 'Excluir produto',
                  onTap: () async {
                    if (item.id != null) {
                      await controller.delete(item.id!, context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Helpers ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _DS.stone),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: _DS.slate,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─── Category picker ─────────────────────────────────────────────────────────
class _CategoryPicker extends StatefulWidget {
  final bool loading;
  final bool creating;
  final List<MenuCategoriesModel> categories;
  final int? selectedId;
  final String? errorMessage;
  final void Function(int? id) onSelect;
  final Future<MenuCategoriesModel?> Function(String name) onCreate;

  const _CategoryPicker({
    required this.loading,
    required this.creating,
    required this.categories,
    required this.selectedId,
    required this.errorMessage,
    required this.onSelect,
    required this.onCreate,
  });

  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  bool _showCreateForm = false;
  final TextEditingController _newCategoryCtrl = TextEditingController();

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    super.dispose();
  }

  Iterable<String> get _unusedSuggestions {
    final existingNames = widget.categories.map((c) => (c.name ?? '').trim().toLowerCase()).toSet();
    return _kDefaultCategorySuggestions.where((s) => !existingNames.contains(s.toLowerCase()));
  }

  Future<void> _createFromName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final created = await widget.onCreate(trimmed);
    if (created != null && mounted) {
      setState(() {
        _showCreateForm = false;
        _newCategoryCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(text: 'Categoria *', icon: LucideIcons.layoutGrid),
          const SizedBox(height: _DS.s2),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rMd),
              border: Border.all(color: _DS.hairlineSoft),
            ),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _DS.stone),
              ),
            ),
          ),
        ],
      );
    }

    final hasCategories = widget.categories.isNotEmpty;
    final isEmpty = !hasCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _Label(text: 'Categoria *', icon: LucideIcons.layoutGrid),
            const Spacer(),
            if (hasCategories && !_showCreateForm)
              GestureDetector(
                onTap: widget.creating ? null : () => setState(() => _showCreateForm = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _DS.brandBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(_DS.rFull),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 12, color: _DS.brandBlue),
                      SizedBox(width: 4),
                      Text('Nova categoria',
                          style: TextStyle(
                            fontSize: 11,
                            color: _DS.brandBlue,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: _DS.s2),
        if (hasCategories && !_showCreateForm)
          _CategoryChipsRow(
            categories: widget.categories,
            selectedId: widget.selectedId,
            onSelect: widget.onSelect,
          ),
        if (_showCreateForm || isEmpty) ...[
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: _DS.s3),
              child: Container(
                padding: const EdgeInsets.all(_DS.s3),
                decoration: BoxDecoration(
                  color: _DS.brandBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(_DS.rMd),
                  border: Border.all(color: _DS.brandBlue.withValues(alpha: 0.18)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.info, size: 14, color: _DS.brandBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você ainda não tem categorias. Escolha uma sugestão ou crie a sua.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _DS.slate,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_unusedSuggestions.isNotEmpty) ...[
            const Text(
              'Sugestões',
              style: TextStyle(
                fontSize: 11,
                color: _DS.steel,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: _DS.s2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _unusedSuggestions.map((s) {
                return GestureDetector(
                  onTap: widget.creating ? null : () => _createFromName(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _DS.canvas,
                      borderRadius: BorderRadius.circular(_DS.rFull),
                      border: Border.all(color: _DS.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plus, size: 11, color: _DS.stone),
                        const SizedBox(width: 4),
                        Text(
                          s,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _DS.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: _DS.s3),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCategoryCtrl,
                  enabled: !widget.creating,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _createFromName,
                  style: const TextStyle(fontSize: 13, color: _DS.ink),
                  decoration: InputDecoration(
                    hintText: 'Ex: Lanches, Bebidas...',
                    hintStyle: const TextStyle(color: _DS.stone, fontSize: 13),
                    filled: true,
                    fillColor: _DS.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.brandBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _DS.s2),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: widget.creating ? null : () => _createFromName(_newCategoryCtrl.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: widget.creating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Criar',
                          style: TextStyle(
                            fontSize: 12,
                          )),
                ),
              ),
              if (hasCategories) ...[
                const SizedBox(width: _DS.s2),
                TextButton(
                  onPressed: widget.creating
                      ? null
                      : () => setState(() {
                            _showCreateForm = false;
                            _newCategoryCtrl.clear();
                          }),
                  style: TextButton.styleFrom(
                    foregroundColor: _DS.steel,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ],
        if (widget.errorMessage != null) ...[
          const SizedBox(height: _DS.s2),
          Text(
            widget.errorMessage!,
            style: const TextStyle(fontSize: 11, color: _DS.danger),
          ),
        ],
      ],
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  final List<MenuCategoriesModel> categories;
  final int? selectedId;
  final void Function(int? id) onSelect;

  const _CategoryChipsRow({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: categories.map((c) {
        final selected = c.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(c.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _DS.ink : _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rFull),
              border: Border.all(
                color: selected ? _DS.ink : _DS.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(LucideIcons.check, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  c.name ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : _DS.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Input extends StatefulWidget {
  const _Input({
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.prefix,
    this.formatters,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? prefix;
  final List<TextInputFormatter>? formatters;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rMd),
        border: Border.all(
          color: _focused ? _DS.brandBlue : _DS.hairlineStrong,
          width: _focused ? 1.5 : 1.0,
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        inputFormatters: widget.formatters,
        style: const TextStyle(fontSize: 14, color: _DS.ink, height: 1.5),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 14, color: _DS.muted),
          prefixText: widget.prefix,
          prefixStyle: const TextStyle(fontSize: 14, color: _DS.slate),
          contentPadding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s3),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(fontSize: 11, color: _DS.danger, height: 1.4),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: value ? activeColor.withValues(alpha: 0.06) : _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rMd),
        border: Border.all(
          color: value ? activeColor.withValues(alpha: 0.28) : _DS.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: value ? activeColor : _DS.stone),
          const SizedBox(width: _DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.ink,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: _DS.slate)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final op = 0.5 + _pulse.value * 0.5;
        return Container(
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(_DS.rXl),
                  topRight: Radius.circular(_DS.rXl),
                ),
                child: Opacity(
                  opacity: op,
                  child: Container(height: 148, color: const Color(0xFFF0F1F4)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_DS.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(w: double.infinity, h: 14, op: op),
                    const SizedBox(height: _DS.s2),
                    _Bone(w: 180, h: 11, op: op),
                    const SizedBox(height: _DS.s1),
                    _Bone(w: 120, h: 11, op: op),
                    const SizedBox(height: _DS.s3),
                    _Bone(w: 80, h: 20, op: op),
                    const SizedBox(height: _DS.s3),
                    Row(
                      children: [
                        _Bone(w: 30, h: 30, op: op, r: _DS.rMd),
                        const SizedBox(width: _DS.s1),
                        _Bone(w: 30, h: 30, op: op, r: _DS.rMd),
                        const SizedBox(width: _DS.s1),
                        _Bone(w: 30, h: 30, op: op, r: _DS.rMd),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({required this.w, required this.h, required this.op, this.r = 4});
  final double w;
  final double h;
  final double op;
  final double r;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: op,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F4),
          borderRadius: BorderRadius.circular(r),
        ),
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class _PillButton extends StatefulWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.loading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.charcoal : _DS.ink,
            borderRadius: BorderRadius.circular(_DS.rFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(widget.icon, size: 14, color: Colors.white),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlinedPillButton extends StatefulWidget {
  const _OutlinedPillButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_OutlinedPillButton> createState() => _OutlinedPillButtonState();
}

class _OutlinedPillButtonState extends State<_OutlinedPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.surface : _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rFull),
            border: Border.all(color: _DS.hairlineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _DS.slate),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: _DS.ink,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatefulWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.rMd),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(fontSize: 13, color: _DS.slate),
          ),
        ),
      ),
    );
  }
}

class _DangerBtn extends StatefulWidget {
  const _DangerBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_DangerBtn> createState() => _DangerBtnState();
}

class _DangerBtnState extends State<_DangerBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFDC2626) : _DS.danger,
            borderRadius: BorderRadius.circular(_DS.rFull),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _DangerOutlinedBtn extends StatefulWidget {
  const _DangerOutlinedBtn({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_DangerOutlinedBtn> createState() => _DangerOutlinedBtnState();
}

class _DangerOutlinedBtnState extends State<_DangerOutlinedBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.dangerSubtle : _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rFull),
            border: Border.all(color: _hovered ? _DS.dangerBorder : _DS.hairlineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _hovered ? _DS.danger : _DS.slate),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? _DS.danger : _DS.ink,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseBtn extends StatefulWidget {
  const _CloseBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseBtn> createState() => _CloseBtnState();
}

class _CloseBtnState extends State<_CloseBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? _DS.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.rSm),
          ),
          child: const Icon(LucideIcons.x, size: 15, color: _DS.slate),
        ),
      ),
    );
  }
}
