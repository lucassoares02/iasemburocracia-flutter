import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/format_currency.dart';

import 'product_options_entity.dart';
import 'product_options_model.dart';
import 'product_options_repository.dart';

class _DS {
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const Color ink = Color(0xFF1C1C1E);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color muted = Color(0xFFA5A8B5);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color successAccent = Color(0xFF00B473);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successText = Color(0xFF15803D);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color surfacePricing = Color(0xFFF5F3FF);
  static const double rMd = 8;
  static const double rLg = 12;
  static const double rXl = 16;
  static const double rXxxl = 28;
  static const double rFull = 9999;
}

Future<void> showProductOptionsManager(
  BuildContext context, {
  required int productId,
  required int companyId,
  required String productName,
}) async {
  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ProductOptionsManager(
        productId: productId,
        companyId: companyId,
        productName: productName,
      ),
    ),
  );
}

class ProductOptionsManager extends StatefulWidget {
  const ProductOptionsManager({
    super.key,
    required this.productId,
    required this.companyId,
    required this.productName,
  });

  final int productId;
  final int companyId;
  final String productName;

  @override
  State<ProductOptionsManager> createState() => _ProductOptionsManagerState();
}

class _ProductOptionsManagerState extends State<ProductOptionsManager> {
  final _repo = ProductOptionsRepository();
  bool _loading = true;
  String? _error;
  List<ProductOptionGroupModel> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.findByProduct(widget.productId);
    if (!mounted) return;
    if (res.success && res.data is List<ProductOptionGroupModel>) {
      setState(() {
        _groups = (res.data as List<ProductOptionGroupModel>);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  Future<void> _openGroupEditor({ProductOptionGroupModel? group}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _GroupEditorDialog(
        productId: widget.productId,
        companyId: widget.companyId,
        repository: _repo,
        existing: group,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _duplicateGroup(ProductOptionGroupModel src) async {
    final dup = ProductOptionGroupModel(
      name: '${src.name} (cópia)',
      type: src.type,
      minSelection: src.minSelection,
      maxSelection: src.maxSelection,
      isRequired: src.isRequired,
      sortOrder: _groups.length,
      items: src.items
          .map((it) => ProductOptionItemModel(
                name: it.name,
                additionalPrice: it.additionalPrice,
                sortOrder: it.sortOrder,
                isActive: it.isActive,
              ))
          .toList(),
    );
    final res = await _repo.create(dup.toCreateJson(
      companyId: widget.companyId,
      productId: widget.productId,
    ));
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _snack(res.message, _DS.danger);
    }
  }

  Future<void> _deleteGroup(ProductOptionGroupModel g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXl)),
        title: const Text('Excluir grupo?'),
        content: Text(
          'Tem certeza que deseja excluir o grupo "${g.name}"? Todos os itens dele também serão removidos.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _DS.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || g.id == null) return;
    final res = await _repo.remove(g.id!, widget.companyId);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _snack(res.message, _DS.danger);
    }
  }

  Future<void> _reorderGroups(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _groups.removeAt(oldIndex);
      _groups.insert(newIndex, item);
    });
    final ids = _groups.map((g) => g.id ?? 0).where((id) => id > 0).toList();
    await _repo.reorder(widget.productId, widget.companyId, ids);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      constraints: const BoxConstraints(maxHeight: 760),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXxxl),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_loading) ...[
            const SizedBox(height: 80),
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(height: 80),
          ] else if (_error != null) ...[
            const SizedBox(height: 40),
            Center(child: Text(_error!, style: const TextStyle(color: _DS.danger))),
            const SizedBox(height: 40),
          ] else
            Flexible(child: _buildList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s8, _DS.s6, _DS.s6, _DS.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _DS.surfacePricing,
              borderRadius: BorderRadius.circular(_DS.rLg),
            ),
            child: const Icon(LucideIcons.sliders, color: _DS.brandBlue, size: 22),
          ),
          const SizedBox(width: _DS.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opções e Adicionais',
                  style: TextStyle(
                    fontSize: 18,
                    color: _DS.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Configure complementos, adicionais e variações para "${widget.productName}".',
                  style: const TextStyle(fontSize: 13, color: _DS.slate, height: 1.4),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(LucideIcons.x, color: _DS.steel),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _DS.s8, vertical: _DS.s8),
        child: Container(
          padding: const EdgeInsets.all(_DS.s8),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairlineSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _DS.surfacePricing,
                  borderRadius: BorderRadius.circular(_DS.rFull),
                ),
                child: const Icon(LucideIcons.layers, color: _DS.brandBlue, size: 28),
              ),
              const SizedBox(height: _DS.s4),
              const Text(
                'Nenhum grupo cadastrado',
                style: TextStyle(
                  fontSize: 15,
                  color: _DS.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Crie grupos como "Complementos", "Adicionais" ou "Tamanho" e defina seus itens.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _DS.slate, height: 1.5),
              ),
              const SizedBox(height: _DS.s5),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                onPressed: () => _openGroupEditor(),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Criar primeiro grupo'),
              ),
            ],
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: _DS.s8, vertical: _DS.s4),
      itemCount: _groups.length,
      onReorder: _reorderGroups,
      itemBuilder: (context, i) {
        final g = _groups[i];
        return Padding(
          key: ValueKey('group-${g.id ?? i}'),
          padding: const EdgeInsets.only(bottom: _DS.s3),
          child: _GroupCard(
            group: g,
            index: i,
            onEdit: () => _openGroupEditor(group: g),
            onDuplicate: () => _duplicateGroup(g),
            onDelete: () => _deleteGroup(g),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s8, _DS.s4, _DS.s8, _DS.s6),
      child: Row(
        children: [
          if (_groups.isNotEmpty)
            Text(
              '${_groups.length} grupo${_groups.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: _DS.steel),
            ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _DS.ink,
              side: const BorderSide(color: _DS.hairline),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          if (_groups.isNotEmpty) ...[
            const SizedBox(width: _DS.s2),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _DS.ink,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => _openGroupEditor(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Novo grupo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.index,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ProductOptionGroupModel group;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  String get _typeLabel {
    switch (group.type) {
      case ProductOptionGroupType.single:
        return 'Seleção única';
      case ProductOptionGroupType.multiple:
        return 'Múltipla escolha';
      case ProductOptionGroupType.quantity:
        return 'Adicionais (+/−)';
    }
  }

  String get _limitLabel {
    if (group.type == ProductOptionGroupType.single) return 'máx 1';
    if (group.maxSelection == 0) return 'ilimitado';
    return 'máx ${group.maxSelection}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_DS.s4, _DS.s4, _DS.s3, _DS.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6, right: 6),
                    child: Icon(LucideIcons.gripVertical, size: 16, color: _DS.muted),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.name.isEmpty ? 'Sem nome' : group.name,
                              style: const TextStyle(
                                fontSize: 15,
                                color: _DS.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: _DS.s2),
                          if (group.isRequired) _badge('Obrigatório', _DS.dangerSubtle, _DS.danger),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _badge(_typeLabel, _DS.surfacePricing, _DS.brandBlue),
                          _badge(_limitLabel, _DS.surface, _DS.slate),
                          _badge('${group.items.length} item${group.items.length == 1 ? '' : 's'}', _DS.successSubtle, _DS.successText),
                        ],
                      ),
                    ],
                  ),
                ),
                _iconBtn(LucideIcons.pencil, 'Editar', onEdit),
                _iconBtn(LucideIcons.copy, 'Duplicar', onDuplicate),
                _iconBtn(LucideIcons.trash2, 'Excluir', onDelete, danger: true),
              ],
            ),
          ),
          if (group.items.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(_DS.s4, _DS.s2, _DS.s4, _DS.s3),
              decoration: const BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_DS.rXl),
                  bottomRight: Radius.circular(_DS.rXl),
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final it in group.items)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _DS.canvas,
                        borderRadius: BorderRadius.circular(_DS.rFull),
                        border: Border.all(color: _DS.hairlineSoft),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!it.isActive)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(LucideIcons.eyeOff, size: 12, color: _DS.muted),
                            ),
                          Text(
                            it.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: it.isActive ? _DS.ink : _DS.muted,
                            ),
                          ),
                          if (it.additionalPrice > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '+${formatCurrency(it.additionalPrice)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _DS.brandBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_DS.rFull),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: 11,
            color: fg,
          )),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap, {bool danger = false}) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 16, color: danger ? _DS.danger : _DS.steel),
      onPressed: onTap,
    );
  }
}

class _GroupEditorDialog extends StatefulWidget {
  const _GroupEditorDialog({
    required this.productId,
    required this.companyId,
    required this.repository,
    this.existing,
  });

  final int productId;
  final int companyId;
  final ProductOptionsRepository repository;
  final ProductOptionGroupModel? existing;

  @override
  State<_GroupEditorDialog> createState() => _GroupEditorDialogState();
}

class _GroupEditorDialogState extends State<_GroupEditorDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late TextEditingController _name;
  late ProductOptionGroupType _type;
  late int _minSelection;
  late int _maxSelection;
  bool _maxUnlimited = false;
  late bool _required;
  late List<_EditItem> _items;
  bool _saving = false;
  String? _error;

  static const _allowedExts = ['jpg', 'jpeg', 'png', 'webp'];

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _type = g?.type ?? ProductOptionGroupType.single;
    _minSelection = g?.minSelection ?? 0;
    _maxSelection = g?.maxSelection ?? 1;
    _maxUnlimited = _type != ProductOptionGroupType.single && (g?.maxSelection ?? 1) == 0;
    _required = g?.isRequired ?? false;
    _items = (g?.items ?? [])
        .map((it) => _EditItem(
              id: it.id,
              name: TextEditingController(text: it.name),
              price: TextEditingController(
                text: it.additionalPrice > 0 ? it.additionalPrice.toStringAsFixed(2).replaceAll('.', ',') : '',
              ),
              active: it.isActive,
              imageUrl: it.imageUrl,
            ))
        .toList();
    if (_items.isEmpty) _items.add(_EditItem.empty());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _name.dispose();
    for (final it in _items) {
      it.name.dispose();
      it.price.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(ProductOptionGroupType t) {
    setState(() {
      _type = t;
      if (t == ProductOptionGroupType.single) {
        _maxUnlimited = false;
        _maxSelection = 1;
        if (_minSelection > 1) _minSelection = 1;
      }
    });
  }

  Future<void> _pickImageForItem(int index) async {
    if (_items[index].uploading) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final ext = (file.extension ?? '').toLowerCase();
    if (!_allowedExts.contains(ext)) return;
    if (file.bytes!.lengthInBytes > 10 * 1024 * 1024) return;
    setState(() => _items[index].uploading = true);
    try {
      final mime = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
      final res = await widget.repository.uploadItemImage(file.bytes!, file.name, mime);
      if (!mounted) return;
      final url = res.success && res.data is Map ? (res.data as Map)['url'] as String? : null;
      setState(() {
        if (url != null) _items[index].imageUrl = url;
        _items[index].uploading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _items[index].uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do grupo');
      _tabCtrl.animateTo(0);
      return;
    }
    final cleaned = _items.where((it) => it.name.text.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) {
      setState(() => _error = 'Adicione pelo menos um item ao grupo');
      _tabCtrl.animateTo(1);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final maxSel = _type == ProductOptionGroupType.single ? 1 : (_maxUnlimited ? 0 : _maxSelection.clamp(1, 99));
    final minSel = _required ? _minSelection.clamp(1, maxSel == 0 ? 99 : maxSel) : 0;

    final model = ProductOptionGroupModel(
      id: widget.existing?.id,
      name: name,
      type: _type,
      minSelection: minSel,
      maxSelection: maxSel,
      isRequired: _required,
      sortOrder: widget.existing?.sortOrder ?? 0,
      items: [
        for (var i = 0; i < cleaned.length; i++)
          ProductOptionItemModel(
            id: cleaned[i].id,
            name: cleaned[i].name.text.trim(),
            additionalPrice: _parsePrice(cleaned[i].price.text),
            sortOrder: i,
            isActive: cleaned[i].active,
            imageUrl: cleaned[i].imageUrl,
          ),
      ],
    );

    final res = _editing
        ? await widget.repository.update(
            widget.existing!.id!,
            model.toUpdateJson(companyId: widget.companyId),
          )
        : await widget.repository.create(
            model.toCreateJson(
              companyId: widget.companyId,
              productId: widget.productId,
            ),
          );

    if (!mounted) return;
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = res.message;
      });
    }
  }

  double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXxxl),
          border: Border.all(color: _DS.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabBar(),
            const Divider(height: 1, thickness: 1, color: _DS.hairlineSoft),
            Flexible(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGroupTab(),
                  _buildItemsTab(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s5, _DS.s4, _DS.s3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Editar grupo' : 'Novo grupo',
                  style: const TextStyle(
                    fontSize: 17,
                    color: _DS.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Defina como o cliente deve escolher.',
                  style: TextStyle(fontSize: 12, color: _DS.steel),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, color: _DS.steel),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabCtrl,
      labelColor: _DS.ink,
      unselectedLabelColor: _DS.steel,
      indicatorColor: _DS.brandBlue,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontSize: 13, letterSpacing: -0.1),
      unselectedLabelStyle: const TextStyle(fontSize: 13, letterSpacing: -0.1),
      tabs: [
        const Tab(text: 'Grupo'),
        Tab(text: 'Itens (${_items.length})'),
      ],
    );
  }

  Widget _buildGroupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s4, _DS.s6, _DS.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Nome do grupo *'),
          const SizedBox(height: _DS.s2),
          _input(_name, hint: 'Ex.: Complementos, Adicionais, Tamanho'),
          const SizedBox(height: _DS.s5),
          _label('Tipo de seleção *'),
          const SizedBox(height: _DS.s2),
          _buildTypePicker(),
          const SizedBox(height: _DS.s5),
          if (_type != ProductOptionGroupType.single) _buildLimitRow(),
          if (_type != ProductOptionGroupType.single) const SizedBox(height: _DS.s5),
          _buildRequiredToggle(),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(_DS.s5, _DS.s4, _DS.s5, _DS.s2),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: _DS.s2),
            itemBuilder: (_, i) => _buildItemCard(i),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_DS.s5, _DS.s2, _DS.s5, _DS.s3),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _items.add(_EditItem.empty())),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Adicionar item'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.brandBlue,
                side: const BorderSide(color: _DS.brandBlue),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final it = _items[index];
    return Container(
      padding: const EdgeInsets.all(_DS.s3),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageThumbnail(index),
          const SizedBox(width: _DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _input(it.name, hint: 'Nome do item', dense: true),
                const SizedBox(height: _DS.s2),
                Row(
                  children: [
                    SizedBox(
                      width: 130,
                      child: _input(
                        it.price,
                        hint: '0,00',
                        dense: true,
                        prefix: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text('R\$', style: TextStyle(fontSize: 13, color: _DS.steel)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyTextInputFormatter.currency(
                            locale: 'pt_BR',
                            symbol: '',
                            decimalDigits: 2,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: it.active ? 'Desativar' : 'Ativar',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        it.active ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 16,
                        color: it.active ? _DS.successAccent : _DS.muted,
                      ),
                      onPressed: () => setState(() => it.active = !it.active),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(LucideIcons.trash2, size: 16, color: _DS.danger),
                      onPressed: () => setState(() {
                        if (_items.length == 1) {
                          it.name.text = '';
                          it.price.text = '';
                          it.active = true;
                          it.imageUrl = null;
                        } else {
                          _items.removeAt(index);
                        }
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    final it = _items[index];
    return GestureDetector(
      onTap: () => _pickImageForItem(index),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(_DS.rMd),
          border: Border.all(color: _DS.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: it.uploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : it.imageUrl != null
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          it.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, color: _DS.muted, size: 22),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.pencil, size: 9, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 20, color: _DS.muted),
                      SizedBox(height: 3),
                      Text('Foto', style: TextStyle(fontSize: 9, color: _DS.muted)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTypePicker() {
    final entries = [
      (ProductOptionGroupType.single, 'Seleção única', 'Apenas 1 opção (radio)', LucideIcons.circleDot),
      (ProductOptionGroupType.multiple, 'Múltipla', 'Várias opções com limite (checkbox)', LucideIcons.checkSquare),
      (ProductOptionGroupType.quantity, 'Adicionais', 'Quantidades por item (+/−)', LucideIcons.plusCircle),
    ];

    return Column(
      children: [
        for (final e in entries)
          GestureDetector(
            onTap: () => _onTypeChanged(e.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
              decoration: BoxDecoration(
                color: _type == e.$1 ? _DS.surfacePricing : _DS.canvas,
                borderRadius: BorderRadius.circular(_DS.rLg),
                border: Border.all(
                  color: _type == e.$1 ? _DS.brandBlue : _DS.hairline,
                  width: _type == e.$1 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(e.$4, size: 18, color: _type == e.$1 ? _DS.brandBlue : _DS.steel),
                  const SizedBox(width: _DS.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$2,
                          style: TextStyle(
                            fontSize: 13,
                            color: _type == e.$1 ? _DS.brandBlue : _DS.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.$3,
                          style: const TextStyle(fontSize: 11, color: _DS.steel),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _type == e.$1 ? _DS.brandBlue : _DS.hairline,
                        width: 1.5,
                      ),
                      color: _type == e.$1 ? _DS.brandBlue : Colors.transparent,
                    ),
                    child: _type == e.$1 ? const Icon(LucideIcons.check, color: Colors.white, size: 12) : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLimitRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Máximo de seleções'),
              const SizedBox(height: _DS.s2),
              Opacity(
                opacity: _maxUnlimited ? 0.45 : 1,
                child: _stepper(
                  value: _maxSelection,
                  min: 1,
                  max: 20,
                  onChanged: _maxUnlimited
                      ? null
                      : (v) => setState(() {
                            _maxSelection = v;
                            if (_minSelection > v) _minSelection = v;
                          }),
                ),
              ),
              const SizedBox(height: _DS.s2),
              GestureDetector(
                onTap: () => setState(() => _maxUnlimited = !_maxUnlimited),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _maxUnlimited ? _DS.brandBlue : Colors.transparent,
                        border: Border.all(
                          color: _maxUnlimited ? _DS.brandBlue : _DS.hairline,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _maxUnlimited ? const Icon(LucideIcons.check, size: 12, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ilimitado',
                      style: TextStyle(
                        fontSize: 12,
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
    );
  }

  Widget _buildRequiredToggle() {
    final maxSel = _type == ProductOptionGroupType.single ? 1 : (_maxUnlimited ? 99 : _maxSelection);
    return Container(
      padding: const EdgeInsets.all(_DS.s4),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.alertOctagon, size: 16, color: _DS.steel),
              const SizedBox(width: _DS.s2),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleção obrigatória',
                      style: TextStyle(
                        fontSize: 13,
                        color: _DS.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'O cliente precisa escolher para finalizar.',
                      style: TextStyle(fontSize: 11, color: _DS.steel),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _required,
                activeColor: _DS.brandBlue,
                onChanged: (v) => setState(() {
                  _required = v;
                  if (v && _minSelection < 1) _minSelection = 1;
                }),
              ),
            ],
          ),
          if (_required && _type != ProductOptionGroupType.single) ...[
            const SizedBox(height: _DS.s3),
            const Divider(height: 1, color: _DS.hairlineSoft),
            const SizedBox(height: _DS.s3),
            const Text(
              'Mínimo de seleções',
              style: TextStyle(
                fontSize: 12,
                color: _DS.steel,
              ),
            ),
            const SizedBox(height: 6),
            _stepper(
              value: _minSelection,
              min: 1,
              max: maxSel,
              onChanged: (v) => setState(() => _minSelection = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s3, _DS.s6, _DS.s5),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(_DS.s3),
              margin: const EdgeInsets.only(bottom: _DS.s3),
              decoration: BoxDecoration(
                color: _DS.dangerSubtle,
                borderRadius: BorderRadius.circular(_DS.rMd),
                border: Border.all(color: _DS.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: _DS.danger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(fontSize: 12, color: _DS.danger))),
                ],
              ),
            ),
          ],
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.ink,
                  side: const BorderSide(color: _DS.hairline),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: _DS.s2),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_editing ? 'Salvar alterações' : 'Criar grupo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _DS.slate,
          letterSpacing: -0.1,
        ),
      );

  Widget _input(
    TextEditingController c, {
    String? hint,
    bool dense = false,
    Widget? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13, color: _DS.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _DS.muted),
        prefix: prefix,
        isDense: dense,
        filled: true,
        fillColor: _DS.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rMd),
          borderSide: const BorderSide(color: _DS.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rMd),
          borderSide: const BorderSide(color: _DS.brandBlue, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rMd),
          borderSide: const BorderSide(color: _DS.hairline),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 10 : 12),
      ),
    );
  }

  Widget _stepper({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            onPressed: onChanged == null || value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(LucideIcons.minus, color: _DS.steel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 13,
                color: _DS.ink,
              ),
            ),
          ),
          IconButton(
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            onPressed: onChanged == null || value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(LucideIcons.plus, color: _DS.steel),
          ),
        ],
      ),
    );
  }
}

class _EditItem {
  _EditItem({
    this.id,
    required this.name,
    required this.price,
    required this.active,
    this.imageUrl,
  });

  int? id;
  final TextEditingController name;
  final TextEditingController price;
  bool active;
  String? imageUrl;
  bool uploading = false;

  factory _EditItem.empty() => _EditItem(
        name: TextEditingController(),
        price: TextEditingController(),
        active: true,
      );
}
