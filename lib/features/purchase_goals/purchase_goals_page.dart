import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../menu_categories/menu_categories_model.dart';
import '../menu_categories/menu_categories_repository.dart';
import 'purchase_goal_entity.dart';
import 'purchase_goal_model.dart';
import 'purchase_goal_repository.dart';

// ─── Design tokens (alinhado ao DESIGN_SYSTEM.md) ─────────────────────────────
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
  static const successSubtle = Color(0xFFE8F8F1);
  static const successText = Color(0xFF15803D);
  static const danger = Color(0xFFE53935);
  static const dangerSubtle = Color(0xFFFEF2F2);
  static const warningAccent = Color(0xFFF59E0B);
  static const surfacePricing = Color(0xFFF5F3FF);
  static const rFull = 9999.0;
  static const rXxxl = 28.0;
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

class PurchaseGoalsPage extends StatefulWidget {
  const PurchaseGoalsPage({super.key});

  @override
  State<PurchaseGoalsPage> createState() => _PurchaseGoalsPageState();
}

class _PurchaseGoalsPageState extends State<PurchaseGoalsPage> {
  final _repo = PurchaseGoalRepository();
  final _catRepo = MenuCategoriesRepository();
  bool _loading = true;
  String? _error;
  List<PurchaseGoalModel> _goals = [];
  List<MenuCategoriesModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<int> _companyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('company') ?? 0;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companyId = await _companyId();
      final results = await Future.wait([
        _repo.findAll(),
        _catRepo.findByCompany(companyId),
      ]);
      if (!mounted) return;
      final goalsRes = results[0];
      final catsRes = results[1];
      if (goalsRes.success && goalsRes.data is List) {
        _goals = (goalsRes.data as List).cast<PurchaseGoalModel>();
      }
      if (catsRes.success && catsRes.data is List) {
        _categories = (catsRes.data as List).cast<MenuCategoriesModel>();
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os objetivos.';
      });
    }
  }

  Future<void> _openEditor({PurchaseGoalModel? existing}) async {
    if (_categories.isEmpty) {
      _snack(
        'Cadastre categorias no Cardápio antes de criar um objetivo.',
        _DS.warningAccent,
      );
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _GoalEditorDialog(
        repository: _repo,
        existing: existing,
        availableCategories: _categories,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(PurchaseGoalModel g) async {
    final next = !g.isActive;
    setState(() => g.isActive = next);
    final res = await _repo.toggle(g.id!, next);
    if (!res.success && mounted) {
      setState(() => g.isActive = !next);
      _snack(res.message, _DS.danger);
    }
  }

  Future<void> _delete(PurchaseGoalModel g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXl)),
        title: const Text('Excluir objetivo?'),
        content: Text(
          'Tem certeza que deseja excluir o objetivo "${g.name}"? Isso não afeta pedidos já realizados.',
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
    final res = await _repo.delete(g.id!);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _snack(res.message, _DS.danger);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 0, bottom: 20, right: 12),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        padding: const EdgeInsets.fromLTRB(_DS.s8, _DS.s6, _DS.s8, _DS.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: _DS.s5),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _DS.surfacePricing,
            borderRadius: BorderRadius.circular(_DS.rLg),
          ),
          child: const Icon(LucideIcons.target, color: _DS.brandBlue, size: 22),
        ),
        const SizedBox(width: _DS.s4),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Objetivo de Compra',
                style: TextStyle(fontSize: 20, color: _DS.ink, letterSpacing: -0.4),
              ),
              SizedBox(height: 2),
              Text(
                'Combine categorias para sugerir produtos com desconto e aumentar o ticket médio.',
                style: TextStyle(fontSize: 13, color: _DS.slate, height: 1.4),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => _openEditor(),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Novo objetivo'),
          style: FilledButton.styleFrom(
            backgroundColor: _DS.ink,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: _DS.danger)),
      );
    }
    if (_goals.isEmpty) return _buildEmpty();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: _DS.s4),
      itemCount: _goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: _DS.s3),
      itemBuilder: (_, i) {
        final g = _goals[i];
        return _GoalCard(
          goal: g,
          onEdit: () => _openEditor(existing: g),
          onToggle: () => _toggle(g),
          onDelete: () => _delete(g),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _DS.surfacePricing,
                borderRadius: BorderRadius.circular(_DS.rFull),
              ),
              child: const Icon(LucideIcons.target, color: _DS.brandBlue, size: 28),
            ),
            const SizedBox(height: _DS.s4),
            const Text(
              'Nenhum objetivo cadastrado',
              style: TextStyle(fontSize: 16, color: _DS.ink, letterSpacing: -0.2),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crie combinações de categorias como "Refeição completa" ou "Combo almoço" e ofereça desconto automático ao cliente no checkout.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _DS.slate, height: 1.5),
            ),
            const SizedBox(height: _DS.s5),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Criar primeiro objetivo'),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.ink,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: _DS.s3),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: _DS.hairlineSoft,
        highlightColor: _DS.surface,
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _DS.hairlineSoft),
          ),
        ),
      ),
    );
  }
}

// ─── Goal card ────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final PurchaseGoalModel goal;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(_DS.rXl),
        child: Ink(
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: goal.isActive ? _DS.successSubtle : _DS.surface,
                    borderRadius: BorderRadius.circular(_DS.rLg),
                  ),
                  child: Icon(
                    LucideIcons.target,
                    color: goal.isActive ? _DS.successText : _DS.stone,
                    size: 20,
                  ),
                ),
                const SizedBox(width: _DS.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 15,
                                color: _DS.ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: _DS.s2),
                          if (!goal.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _DS.surface,
                                borderRadius: BorderRadius.circular(_DS.rFull),
                                border: Border.all(color: _DS.hairline),
                              ),
                              child: const Text(
                                'Inativo',
                                style: TextStyle(fontSize: 11, color: _DS.steel),
                              ),
                            ),
                          if (goal.discountPercentage > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _DS.surfacePricing,
                                borderRadius: BorderRadius.circular(_DS.rFull),
                              ),
                              child: Text(
                                '${goal.discountPercentage.toStringAsFixed(goal.discountPercentage.truncateToDouble() == goal.discountPercentage ? 0 : 1)}% OFF',
                                style: const TextStyle(fontSize: 11, color: _DS.brandBlue),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if ((goal.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description!,
                          style: const TextStyle(fontSize: 12, color: _DS.steel, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: goal.isActive,
                  activeColor: _DS.brandBlue,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(LucideIcons.trash2, size: 16, color: _DS.danger),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          if (goal.categories.isNotEmpty)
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
                  for (final c in goal.categories)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _DS.canvas,
                        borderRadius: BorderRadius.circular(_DS.rFull),
                        border: Border.all(color: _DS.hairlineSoft),
                      ),
                      child: Text(
                        c.name ?? 'Categoria ${c.id}',
                        style: const TextStyle(fontSize: 12, color: _DS.ink),
                      ),
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

// ─── Editor dialog ────────────────────────────────────────────────────────────

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({
    required this.repository,
    required this.availableCategories,
    this.existing,
  });

  final PurchaseGoalRepository repository;
  final List<MenuCategoriesModel> availableCategories;
  final PurchaseGoalModel? existing;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _discount;
  late bool _active;
  late Set<int> _selectedCategoryIds;
  String _categorySearch = '';
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _description = TextEditingController(text: g?.description ?? '');
    _discount = TextEditingController(
      text: g != null && g.discountPercentage > 0
          ? g.discountPercentage.toStringAsFixed(g.discountPercentage.truncateToDouble() == g.discountPercentage ? 0 : 2).replaceAll('.', ',')
          : '',
    );
    _active = g?.isActive ?? true;
    _selectedCategoryIds = (g?.categories ?? const <PurchaseGoalCategoryEntity>[])
        .map((c) => c.id)
        .whereType<int>()
        .toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  double _parseDiscount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d,\.]'), '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe o nome do objetivo');
      return;
    }
    if (_selectedCategoryIds.length < 2) {
      setState(() => _error = 'Selecione pelo menos 2 categorias para compor o objetivo');
      return;
    }
    final pct = _parseDiscount(_discount.text);
    if (pct <= 0) {
      setState(() => _error = 'Informe um desconto maior que 0%');
      return;
    }
    if (pct > 100) {
      setState(() => _error = 'O desconto não pode ser maior que 100%');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final model = PurchaseGoalModel(
      id: widget.existing?.id,
      name: name,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      discountPercentage: pct,
      isActive: _active,
      categories: _selectedCategoryIds
          .map((id) => PurchaseGoalCategoryModel(id: id))
          .toList(),
    );

    final res = _editing ? await widget.repository.update(model) : await widget.repository.create(model);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s2, _DS.s6, _DS.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nome do objetivo *'),
                    const SizedBox(height: _DS.s2),
                    _textField(_name, hint: 'Ex.: Refeição completa, Combo almoço'),
                    const SizedBox(height: _DS.s5),
                    _label('Descrição (opcional)'),
                    const SizedBox(height: _DS.s2),
                    _textField(
                      _description,
                      hint: 'Texto curto exibido no card de sugestão',
                      maxLines: 2,
                    ),
                    const SizedBox(height: _DS.s5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Desconto aplicado *'),
                              const SizedBox(height: _DS.s2),
                              _textField(
                                _discount,
                                hint: '15',
                                suffix: const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text('%', style: TextStyle(fontSize: 14, color: _DS.steel)),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'O desconto é aplicado apenas no item sugerido.',
                                style: TextStyle(fontSize: 11, color: _DS.steel),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: _DS.s4),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.all(_DS.s4),
                            decoration: BoxDecoration(
                              color: _DS.surface,
                              borderRadius: BorderRadius.circular(_DS.rLg),
                              border: Border.all(color: _DS.hairlineSoft),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _active ? LucideIcons.zap : LucideIcons.zapOff,
                                  size: 16,
                                  color: _active ? _DS.successAccent : _DS.muted,
                                ),
                                const SizedBox(width: _DS.s2),
                                const Expanded(
                                  child: Text(
                                    'Objetivo ativo',
                                    style: TextStyle(fontSize: 13, color: _DS.ink),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _active,
                                  activeColor: _DS.brandBlue,
                                  onChanged: (v) => setState(() => _active = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _DS.s5),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Categorias do objetivo *',
                            style: TextStyle(fontSize: 13, color: _DS.slate, letterSpacing: -0.1),
                          ),
                        ),
                        Text(
                          '${_selectedCategoryIds.length}/${widget.availableCategories.length} selecionada${_selectedCategoryIds.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, color: _DS.steel),
                        ),
                      ],
                    ),
                    const SizedBox(height: _DS.s2),
                    _buildCategorySelector(),
                  ],
                ),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _DS.surfacePricing,
              borderRadius: BorderRadius.circular(_DS.rLg),
            ),
            child: const Icon(LucideIcons.target, color: _DS.brandBlue, size: 20),
          ),
          const SizedBox(width: _DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Editar objetivo' : 'Novo objetivo',
                  style: const TextStyle(fontSize: 16, color: _DS.ink, letterSpacing: -0.4),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Combine categorias e ofereça desconto automático.',
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

  Widget _buildCategorySelector() {
    final filtered = _categorySearch.isEmpty
        ? widget.availableCategories
        : widget.availableCategories
            .where((c) => (c.name ?? '').toLowerCase().contains(_categorySearch.toLowerCase()))
            .toList();
    return Container(
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_DS.s3, _DS.s3, _DS.s3, 0),
            child: TextField(
              onChanged: (v) => setState(() => _categorySearch = v),
              style: const TextStyle(fontSize: 13, color: _DS.ink),
              decoration: InputDecoration(
                hintText: 'Buscar categoria...',
                hintStyle: const TextStyle(fontSize: 13, color: _DS.muted),
                prefixIcon: const Icon(LucideIcons.search, size: 16, color: _DS.stone),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                isDense: true,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: _DS.s3),
          Container(
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 220),
            padding: const EdgeInsets.fromLTRB(_DS.s3, 0, _DS.s3, _DS.s3),
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma categoria encontrada',
                      style: TextStyle(fontSize: 12, color: _DS.steel),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in filtered)
                          _CategoryChip(
                            label: c.name ?? '#${c.id}',
                            selected: _selectedCategoryIds.contains(c.id),
                            onTap: () => setState(() {
                              if (_selectedCategoryIds.contains(c.id)) {
                                _selectedCategoryIds.remove(c.id);
                              } else {
                                _selectedCategoryIds.add(c.id ?? 0);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
          ),
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
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_editing ? 'Salvar alterações' : 'Criar objetivo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, color: _DS.slate, letterSpacing: -0.1),
      );

  Widget _textField(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 13, color: _DS.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _DS.muted),
        suffix: suffix,
        isDense: true,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _DS.brandBlue : _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rFull),
          border: Border.all(
            color: selected ? _DS.brandBlue : _DS.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? LucideIcons.check : LucideIcons.plus,
              size: 13,
              color: selected ? Colors.white : _DS.steel,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : _DS.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
