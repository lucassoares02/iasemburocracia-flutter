import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/format_currency.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/app_state.dart';
import 'menu_items_controller.dart';
import 'menu_items_repository.dart';
import 'menu_items_usecase.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────

class _DS {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;

  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F8);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderStrong = Color(0xFFD4D4D8);
  static const Color borderFocus = Color(0xFF18181B);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFF18181B);
  static const Color accentSubtle = Color(0xFFF4F4F5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color success = Color(0xFF22C55E);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 1),
  ];
  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MenuItemsPage extends StatefulWidget {
  const MenuItemsPage({super.key});

  @override
  State<MenuItemsPage> createState() => _MenuItemsPageState();
}

class _MenuItemsPageState extends State<MenuItemsPage> with SingleTickerProviderStateMixin {
  late final MenuItemsController controller = MenuItemsController(
    StartState(),
    MenuItemsUseCase(MenuItemsRepository()),
  );

  final TextEditingController _searchController = TextEditingController();
  List<MenuItemsModel> _filteredItems = [];
  List<MenuItemsModel> _allItems = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    controller.findAll();
    _searchController.addListener(_filterItems);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = query.isEmpty
          ? _allItems
          : _allItems.where((item) {
              return (item.name?.toLowerCase().contains(query) ?? false) || (item.description?.toLowerCase().contains(query) ?? false);
            }).toList();
    });
  }

  // ─── Add / Edit Dialog ─────────────────────────────────────────────────────

  void _showAddItemDialog({MenuItemsModel? item}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(
      text: item?.price != null ? item!.price.toString() : '',
    );
    bool available = item?.available ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusLg + 2),
              border: Border.all(color: _DS.border),
              boxShadow: _DS.shadowMd,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_DS.s8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item == null ? 'Novo Item' : 'Editar Item',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _DS.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: _DS.s1),
                              Text(
                                item == null ? 'Adicione um novo item ao cardápio.' : 'Atualize as informações do item.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _DS.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DialogCloseButton(onPressed: () => Navigator.pop(context)),
                      ],
                    ),

                    const SizedBox(height: _DS.s6),
                    const _DialogDivider(),
                    const SizedBox(height: _DS.s6),

                    // ── Nome ──
                    const _DialogFieldLabel(label: 'Nome do Item', icon: LucideIcons.tag),
                    const SizedBox(height: _DS.s2),
                    _SaasInput(
                      controller: nameController,
                      hintText: 'Ex: Pizza Margherita',
                      validator: (v) => (v == null || v.isEmpty) ? 'Nome é obrigatório' : null,
                    ),

                    const SizedBox(height: _DS.s5),

                    // ── Descrição ──
                    const _DialogFieldLabel(label: 'Descrição', icon: LucideIcons.alignLeft),
                    const SizedBox(height: _DS.s2),
                    _SaasInput(
                      controller: descriptionController,
                      hintText: 'Descreva os ingredientes e características...',
                      maxLines: 3,
                      validator: (v) => (v == null || v.isEmpty) ? 'Descrição é obrigatória' : null,
                    ),

                    const SizedBox(height: _DS.s5),

                    // ── Preço ──
                    const _DialogFieldLabel(label: 'Preço', icon: LucideIcons.dollarSign),
                    const SizedBox(height: _DS.s2),
                    _SaasInput(
                      controller: priceController,
                      hintText: '0,00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Preço é obrigatório';
                        if (double.tryParse(v) == null) return 'Preço inválido';
                        return null;
                      },
                    ),

                    const SizedBox(height: _DS.s5),

                    // ── Disponibilidade toggle ──
                    _AvailabilityToggleRow(
                      available: available,
                      onChanged: (v) => setDialogState(() => available = v),
                    ),

                    const SizedBox(height: _DS.s6),
                    const _DialogDivider(),
                    const SizedBox(height: _DS.s5),

                    // ── Footer ──
                    Row(
                      children: [
                        // Delete button — only when editing
                        if (item != null)
                          ValueListenableBuilder(
                            valueListenable: controller.stateDelete,
                            builder: (context, stateDelete, _) => _SaasDangerOutlinedButton(
                              label: 'Excluir',
                              icon: LucideIcons.trash2,
                              loading: stateDelete is LoadingState,
                              onPressed: () => _showDeleteConfirmation(item, context),
                            ),
                          ),
                        const Spacer(),
                        _SaasGhostButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: _DS.s2),
                        ValueListenableBuilder(
                          valueListenable: controller.stateCreate,
                          builder: (context, value, _) => SpecialButton(
                            label: 'Salvar',
                            loading: value is LoadingState,
                            error: value is ErrorState,
                            color: _DS.accent,
                            icon: LucideIcons.check,
                            onPressButton: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final company = prefs.getInt('company') ?? 0;
                              if (formKey.currentState!.validate()) {
                                final newItem = MenuItemsModel.fromJson({
                                  item != null ? 'id' : '': item?.id,
                                  'name': nameController.text,
                                  'description': descriptionController.text,
                                  'category_id': 1,
                                  'company_id': company,
                                  'price': double.parse(priceController.text),
                                  'available': available,
                                });
                                if (item != null) {
                                  await controller.update(newItem, context);
                                } else {
                                  await controller.create(newItem, context);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete Confirmation Dialog ────────────────────────────────────────────

  void _showDeleteConfirmation(MenuItemsModel item, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(_DS.s6),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusLg + 2),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowMd,
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
                      borderRadius: BorderRadius.circular(_DS.radiusMd),
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
                          'Excluir Item',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _DS.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.name ?? '',
                          style: const TextStyle(fontSize: 12, color: _DS.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _DialogCloseButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: _DS.s5),
              Container(
                padding: const EdgeInsets.all(_DS.s4),
                decoration: BoxDecoration(
                  color: _DS.background,
                  borderRadius: BorderRadius.circular(_DS.radiusMd),
                  border: Border.all(color: _DS.border),
                ),
                child: const Text(
                  'Esta ação não pode ser desfeita. O item será removido permanentemente do cardápio.',
                  style: TextStyle(fontSize: 13, color: _DS.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: _DS.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SaasGhostButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: _DS.s2),
                  _SaasDangerButton(
                    label: 'Excluir',
                    onPressed: () async {
                      if (item.id != null) {
                        await controller.delete(item.id!, context);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildPageHeader(),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: controller.stateFindAll,
                builder: (context, state, _) {
                  if (state is StartState || state is LoadingState) {
                    return _buildLoadingSkeleton();
                  } else if (state is SuccessState) {
                    _allItems = List<MenuItemsModel>.from(state.data);
                    if (_searchController.text.isEmpty) _filteredItems = _allItems;
                    if (_filteredItems.isEmpty) return _buildEmptyState();
                    return _buildList(_filteredItems);
                  } else if (state is ErrorState) {
                    return _buildErrorState(state.message);
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

  // ─── Page Header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Container(
      color: _DS.surface,
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s5, _DS.s6, _DS.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cardápio',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _DS.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: _DS.s1),
                    Text(
                      'Gerencie os itens do seu cardápio.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _DS.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: _DS.s4),
              _SaasPrimaryButton(
                label: 'Novo Item',
                icon: LucideIcons.plus,
                onPressed: () => _showAddItemDialog(),
              ),
            ],
          ),
          const SizedBox(height: _DS.s4),
          // Search bar
          _SearchBar(controller: _searchController),
        ],
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(List<MenuItemsModel> items) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(_DS.s6),
        itemCount: items.length,
        itemBuilder: (context, index) => _MenuListItem(
          item: items[index],
          onTap: () => _showAddItemDialog(item: items[index]),
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.accentSubtle,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.border),
            ),
            child: Icon(
              isSearching ? LucideIcons.searchX : LucideIcons.utensilsCrossed,
              size: 24,
              color: _DS.textSecondary,
            ),
          ),
          const SizedBox(height: _DS.s4),
          Text(
            isSearching ? 'Nenhum resultado encontrado' : 'Nenhum item cadastrado',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _DS.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            isSearching ? 'Tente ajustar os termos da sua busca.' : 'Adicione o primeiro item ao cardápio.',
            style: const TextStyle(fontSize: 13, color: _DS.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (!isSearching) ...[
            const SizedBox(height: _DS.s6),
            _SaasOutlinedButton(
              label: 'Adicionar Item',
              icon: LucideIcons.plus,
              onPressed: () => _showAddItemDialog(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Loading Skeleton ──────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(_DS.s6),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: _DS.s3),
            padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.border),
            ),
            child: Row(
              children: [
                _SkeletonBox(width: 44, height: 44, radius: _DS.radiusMd),
                const SizedBox(width: _DS.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: _SkeletonBox(width: double.infinity, height: 14, radius: 4)),
                          const SizedBox(width: _DS.s4),
                          _SkeletonBox(width: 72, height: 22, radius: 20),
                        ],
                      ),
                      const SizedBox(height: _DS.s2),
                      const _SkeletonBox(width: double.infinity, height: 11, radius: 4),
                      const SizedBox(height: _DS.s1),
                      const _SkeletonBox(width: 160, height: 11, radius: 4),
                      const SizedBox(height: _DS.s3),
                      const _SkeletonBox(width: 80, height: 18, radius: 4),
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

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.dangerSubtle,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.dangerBorder),
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 24, color: _DS.danger),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Erro ao carregar itens',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _DS.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _DS.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _DS.s6),
          _SaasOutlinedButton(
            label: 'Tentar novamente',
            icon: LucideIcons.refreshCw,
            onPressed: () => controller.findAll(),
          ),
        ],
      ),
    );
  }
}

// ─── Menu List Item ───────────────────────────────────────────────────────────

class _MenuListItem extends StatefulWidget {
  const _MenuListItem({required this.item, required this.onTap});
  final MenuItemsModel item;
  final VoidCallback onTap;

  @override
  State<_MenuListItem> createState() => _MenuListItemState();
}

class _MenuListItemState extends State<_MenuListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAvailable = item.available ?? true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: _DS.s3),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFFAFAFB) : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusLg),
            border: Border.all(color: _hovered ? _DS.borderStrong : _DS.border),
            boxShadow: _hovered ? _DS.shadowSm : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _DS.accentSubtle,
                  borderRadius: BorderRadius.circular(_DS.radiusMd),
                ),
                child: const Icon(LucideIcons.utensilsCrossed, size: 18, color: _DS.textSecondary),
              ),
              const SizedBox(width: _DS.s4),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name ?? 'Sem nome',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _DS.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: _DS.s3),
                        _StatusBadge(isAvailable: isAvailable),
                      ],
                    ),
                    const SizedBox(height: _DS.s1 + 2),
                    // Description
                    Text(
                      item.description ?? 'Sem descrição',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _DS.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.price != null) ...[
                      const SizedBox(height: _DS.s3),
                      Text(
                        formatCurrency(item.price),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _DS.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron hint
              const SizedBox(width: _DS.s3),
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 140),
                child: const Icon(LucideIcons.chevronRight, size: 16, color: _DS.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        border: Border.all(
          color: _focused ? _DS.borderFocus : _DS.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused ? _DS.shadowMd : _DS.shadowSm,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: _DS.s3),
            child: Icon(LucideIcons.search, size: 15, color: _DS.textTertiary),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: _DS.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou descrição...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _DS.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: _DS.s3),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty) _ClearButton(onPressed: widget.controller.clear),
        ],
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  const _ClearButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _hovered ? _DS.borderStrong : _DS.border,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.x, size: 11, color: _DS.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isAvailable});
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? _DS.successSubtle : _DS.dangerSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAvailable ? _DS.successBorder : _DS.dangerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isAvailable ? _DS.success : _DS.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Disponível' : 'Indisponível',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isAvailable ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Availability Toggle ──────────────────────────────────────────────────────

class _AvailabilityToggleRow extends StatelessWidget {
  const _AvailabilityToggleRow({required this.available, required this.onChanged});
  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: available ? _DS.successSubtle : _DS.accentSubtle,
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        border: Border.all(color: available ? _DS.successBorder : _DS.border),
      ),
      child: Row(
        children: [
          Icon(
            available ? LucideIcons.checkCircle : LucideIcons.xCircle,
            size: 16,
            color: available ? _DS.success : _DS.textTertiary,
          ),
          const SizedBox(width: _DS.s3),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disponível para pedidos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _DS.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Item visível e disponível no cardápio',
                  style: TextStyle(fontSize: 11, color: _DS.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            onChanged: onChanged,
            activeColor: _DS.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Helpers ───────────────────────────────────────────────────────────

class _DialogFieldLabel extends StatelessWidget {
  const _DialogFieldLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _DS.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _DS.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _DialogDivider extends StatelessWidget {
  const _DialogDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F2));
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: const Icon(LucideIcons.x, size: 15, color: _DS.textSecondary),
        ),
      ),
    );
  }
}

// ─── Input ────────────────────────────────────────────────────────────────────

class _SaasInput extends StatefulWidget {
  const _SaasInput({
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  State<_SaasInput> createState() => _SaasInputState();
}

class _SaasInputState extends State<_SaasInput> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(
          color: _focused ? _DS.borderFocus : _DS.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused ? _DS.shadowMd : _DS.shadowSm,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        validator: widget.validator,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _DS.textPrimary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: _DS.textTertiary, fontSize: 14, fontWeight: FontWeight.w400),
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

// ─── Buttons ──────────────────────────────────────────────────────────────────

class _SaasPrimaryButton extends StatefulWidget {
  const _SaasPrimaryButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_SaasPrimaryButton> createState() => _SaasPrimaryButtonState();
}

class _SaasPrimaryButtonState extends State<_SaasPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF27272A) : _DS.accent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: Colors.white),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

class _SaasOutlinedButton extends StatefulWidget {
  const _SaasOutlinedButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_SaasOutlinedButton> createState() => _SaasOutlinedButtonState();
}

class _SaasOutlinedButtonState extends State<_SaasOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _DS.textSecondary),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _DS.textPrimary,
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

class _SaasGhostButton extends StatefulWidget {
  const _SaasGhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SaasGhostButton> createState() => _SaasGhostButtonState();
}

class _SaasGhostButtonState extends State<_SaasGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hovered ? _DS.textPrimary : _DS.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaasDangerButton extends StatefulWidget {
  const _SaasDangerButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SaasDangerButton> createState() => _SaasDangerButtonState();
}

class _SaasDangerButtonState extends State<_SaasDangerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFDC2626) : _DS.danger,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: _DS.shadowSm,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaasDangerOutlinedButton extends StatefulWidget {
  const _SaasDangerOutlinedButton({
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
  State<_SaasDangerOutlinedButton> createState() => _SaasDangerOutlinedButtonState();
}

class _SaasDangerOutlinedButtonState extends State<_SaasDangerOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.dangerSubtle : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            border: Border.all(color: _hovered ? _DS.dangerBorder : _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _hovered ? _DS.danger : _DS.textSecondary),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? _DS.danger : _DS.textPrimary,
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

// ─── Skeleton Box ─────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 4});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
