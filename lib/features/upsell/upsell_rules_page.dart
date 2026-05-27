import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/state/app_state.dart';
import '../menu_items/menu_items_model.dart';
import '../menu_items/menu_items_repository.dart';
import 'upsell_controller.dart';
import 'upsell_model.dart';
import 'upsell_repository.dart';
import 'upsell_usecase.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const hairlineSoft = Color(0xFFEEF0F3);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const muted = Color(0xFFA5A8B5);
  static const successAccent = Color(0xFF00B473);
  static const successSoft = Color(0xFFE8F8F1);
  static const danger = Color(0xFFE53935);
  static const dangerSoft = Color(0xFFFFEBEA);
  static const yellowBg = Color(0xFFFFF4C4);
  static const yellowText = Color(0xFF746019);
  static const surfacePricing = Color(0xFFF5F3FF);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
}

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

// ─── Page ─────────────────────────────────────────────────────────────────────

class UpsellRulesPage extends StatefulWidget {
  const UpsellRulesPage({super.key});

  @override
  State<UpsellRulesPage> createState() => _UpsellRulesPageState();
}

class _UpsellRulesPageState extends State<UpsellRulesPage> {
  late final UpsellController _ctrl = UpsellController(
    StartState(),
    UpsellUseCase(UpsellRepository()),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.findAll();
  }

  void _openForm({UpsellRuleModel? item}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => UpsellRuleDialog(controller: _ctrl, initial: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text(
                      'Upsell Inteligente',
                      style: TextStyle(fontSize: 20, color: _DS.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure sugestões automáticas de produtos com desconto quando um item é adicionado ao carrinho.',
                      style: TextStyle(fontSize: 13, color: _DS.steel, height: 1.4),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => _openForm(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.ink,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 16),
                      SizedBox(width: 8),
                      Text('Nova regra de upsell'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── List ──
          Expanded(
            child: ValueListenableBuilder<StateApp>(
              valueListenable: _ctrl.stateFindAll,
              builder: (_, state, __) {
                if (state is LoadingState || state is StartState) {
                  return _UpsellSkeleton();
                }
                if (state is ErrorState) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(LucideIcons.alertCircle, size: 40, color: _DS.danger),
                      const SizedBox(height: 12),
                      Text(state.message, style: const TextStyle(color: _DS.danger)),
                    ]),
                  );
                }
                final rows = (state as SuccessState).data as List<UpsellRuleModel>;
                if (rows.isEmpty) {
                  return _UpsellEmptyState(onNew: () => _openForm());
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _UpsellRuleCard(
                    rule: rows[i],
                    onEdit: () => _openForm(item: rows[i]),
                    onToggle: () => _ctrl.toggle(rows[i].id!, !rows[i].active),
                    onDuplicate: () => _ctrl.duplicate(rows[i].id!),
                    onDelete: () => _confirmDelete(rows[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(UpsellRuleModel rule) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXl)),
        title: const Text('Excluir regra?', style: TextStyle(color: _DS.ink)),
        content: Text(
          'A regra de upsell para "${rule.triggerName ?? 'produto'}" será removida permanentemente.',
          style: const TextStyle(color: _DS.steel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _DS.steel)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _ctrl.delete(rule.id!);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _DS.danger,
              shape: const StadiumBorder(),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ─── Rule card ─────────────────────────────────────────────────────────────────

class _UpsellRuleCard extends StatefulWidget {
  final UpsellRuleModel rule;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _UpsellRuleCard({
    required this.rule,
    required this.onEdit,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<_UpsellRuleCard> createState() => _UpsellRuleCardState();
}

class _UpsellRuleCardState extends State<_UpsellRuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(color: _hovered ? _DS.brandBlue.withValues(alpha: 0.3) : _DS.hairlineSoft),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Trigger product thumb
              _ProductThumb(imageUrl: rule.triggerImageUrl, size: 52),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        rule.triggerName ?? 'Produto',
                        style: const TextStyle(fontSize: 15, color: _DS.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(active: rule.active),
                  ]),
                  const SizedBox(height: 4),
                  if ((rule.description ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        rule.description!,
                        style: const TextStyle(fontSize: 12.5, color: _DS.steel),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(children: [
                    Icon(LucideIcons.arrowRight, size: 12, color: _DS.stone),
                    const SizedBox(width: 4),
                    Text(
                      '${rule.items.length} sugestão${rule.items.length != 1 ? 'ões' : ''} de produto',
                      style: const TextStyle(fontSize: 12, color: _DS.stone),
                    ),
                    const SizedBox(width: 12),
                    if (rule.items.isNotEmpty) ...[
                      const Text('·', style: TextStyle(color: _DS.stone)),
                      const SizedBox(width: 8),
                      ...rule.items.take(3).map((it) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _ProductThumb(imageUrl: it.itemImageUrl, size: 20),
                          )),
                      if (rule.items.length > 3) Text('+${rule.items.length - 3}', style: const TextStyle(fontSize: 11, color: _DS.muted)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: rule.items
                        .map((it) {
                          final pct = it.discountType == 'percent' ? it.discountValue ?? 0 : _calcPct(it.itemPrice ?? 0, it.finalPrice ?? 0);
                          return _DiscountChip(label: '${it.itemName ?? ''}: ${pct.toStringAsFixed(0)}% OFF');
                        })
                        .take(4)
                        .toList(),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              // Actions
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                _IconBtn(icon: LucideIcons.pencil, tooltip: 'Editar', onTap: widget.onEdit),
                const SizedBox(height: 6),
                _IconBtn(icon: LucideIcons.copy, tooltip: 'Duplicar', onTap: widget.onDuplicate),
                const SizedBox(height: 6),
                _IconBtn(
                  icon: rule.active ? LucideIcons.toggleRight : LucideIcons.toggleLeft,
                  tooltip: rule.active ? 'Desativar' : 'Ativar',
                  onTap: widget.onToggle,
                  color: rule.active ? _DS.successAccent : _DS.muted,
                ),
                const SizedBox(height: 6),
                _IconBtn(icon: LucideIcons.trash2, tooltip: 'Excluir', onTap: widget.onDelete, danger: true),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  double _calcPct(double orig, double final_) {
    if (orig <= 0) return 0;
    return ((orig - final_) / orig) * 100;
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _UpsellEmptyState extends StatelessWidget {
  final VoidCallback onNew;
  const _UpsellEmptyState({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _DS.surfacePricing, borderRadius: BorderRadius.circular(16)),
            child: const Icon(LucideIcons.zap, size: 28, color: _DS.brandBlue),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhuma regra configurada',
            style: TextStyle(fontSize: 17, color: _DS.ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie regras para sugerir produtos automaticamente quando um cliente adicionar um item ao carrinho.',
            style: TextStyle(fontSize: 13, color: _DS.steel, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onNew,
            style: FilledButton.styleFrom(
              backgroundColor: _DS.ink,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(LucideIcons.plus, size: 16),
              SizedBox(width: 8),
              Text('Criar primeira regra', style: TextStyle()),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _UpsellSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFFAFAFA),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_DS.rXl),
          ),
        ),
      ),
    );
  }
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

class UpsellRuleDialog extends StatefulWidget {
  final UpsellController controller;
  final UpsellRuleModel? initial;

  const UpsellRuleDialog({super.key, required this.controller, this.initial});

  @override
  State<UpsellRuleDialog> createState() => _UpsellRuleDialogState();
}

class _UpsellRuleDialogState extends State<UpsellRuleDialog> {
  final _descCtrl = TextEditingController();
  MenuItemsModel? _triggerItem;
  final List<_SuggestedItemDraft> _suggestions = [];
  List<MenuItemsModel> _allItems = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    final initial = widget.initial;
    if (initial != null) {
      _descCtrl.text = initial.description ?? '';
      // Trigger and suggestions will be set after items load
    }
  }

  Future<void> _loadMenuItems() async {
    final repo = MenuItemsRepository();
    final res = await repo.findAll();
    if (res.success && res.data is List) {
      final items = (res.data as List).cast<MenuItemsModel>();
      setState(() {
        _allItems = items;
        _loadingItems = false;
      });
      final initial = widget.initial;
      if (initial != null) {
        final trigger = items.where((i) => i.id == initial.triggerItemId).firstOrNull;
        final suggs = initial.items.map((ri) {
          final m = items.where((i) => i.id == ri.menuItemId).firstOrNull;
          return _SuggestedItemDraft(
            item: m,
            discountType: ri.discountType ?? 'percent',
            discountValue: ri.discountValue ?? 0,
          );
        }).toList();
        setState(() {
          _triggerItem = trigger;
          _suggestions.addAll(suggs);
        });
      }
    } else {
      setState(() => _loadingItems = false);
    }
  }

  void _addSuggestion(MenuItemsModel item) {
    if (_suggestions.any((s) => s.item?.id == item.id)) return;
    if (_triggerItem?.id == item.id) return;
    setState(() {
      _suggestions.add(_SuggestedItemDraft(item: item, discountType: 'percent', discountValue: 10));
    });
  }

  void _removeSuggestion(int index) => setState(() => _suggestions.removeAt(index));

  String? _validate() {
    if (_triggerItem == null) return 'Selecione o produto gatilho.';
    if (_suggestions.isEmpty) return 'Adicione ao menos um produto sugerido.';
    for (var i = 0; i < _suggestions.length; i++) {
      final s = _suggestions[i];
      if (s.item == null) return 'Produto sugerido #${i + 1} inválido.';
      if (s.discountValue < 0) return 'Desconto não pode ser negativo.';
      final orig = s.item!.price ?? 0;
      if (orig <= 0) continue;
      if (s.discountType == 'percent' && s.discountValue >= 100) return 'Desconto percentual deve ser menor que 100%.';
      if (s.discountType == 'final_price' && s.discountValue > orig) {
        return 'Valor final não pode ser maior que o preço original (${_money.format(orig)}).';
      }
    }
    return null;
  }

  void _submit() {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: _DS.danger),
      );
      return;
    }
    final model = UpsellRuleModel.fromJson({
      'id': widget.initial?.id,
      'company_id': null,
      'trigger_item_id': _triggerItem!.id,
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'active': widget.initial?.active ?? true,
      'max_suggestions': _suggestions.length,
      'items': _suggestions
          .map((s) => {
                'menu_item_id': s.item!.id,
                'discount_type': s.discountType,
                'discount_value': s.discountValue,
              })
          .toList(),
    });

    if (widget.initial == null) {
      widget.controller.create(model, context);
    } else {
      widget.controller.update(model, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Dialog header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: _DS.surfacePricing, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.zap, size: 18, color: _DS.brandBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      isEdit ? 'Editar regra de upsell' : 'Nova regra de upsell',
                      style: const TextStyle(fontSize: 17, color: _DS.ink),
                    ),
                    const Text(
                      'Configure o produto gatilho e as sugestões com desconto.',
                      style: TextStyle(fontSize: 12, color: _DS.stone),
                    ),
                  ]),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 18, color: _DS.stone),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _DS.hairlineSoft),
            // ── Scrollable body ──
            Expanded(
              child: _loadingItems
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left panel: config
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              // Description
                              _SectionLabel('Descrição (opcional)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descCtrl,
                                decoration: _inputDec(
                                  hint: 'Ex: Complete seu combo!',
                                  prefix: const Icon(LucideIcons.messageSquare, size: 16, color: _DS.stone),
                                ),
                                maxLength: 100,
                                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text('$currentLength/$maxLength', style: const TextStyle(fontSize: 11, color: _DS.muted)),
                              ),
                              const SizedBox(height: 20),
                              // Trigger
                              _SectionLabel('Produto gatilho'),
                              const SizedBox(height: 4),
                              Text(
                                'Quando o cliente adicionar este produto ao carrinho, as sugestões serão exibidas.',
                                style: const TextStyle(fontSize: 12, color: _DS.stone),
                              ),
                              const SizedBox(height: 10),
                              if (_triggerItem != null)
                                _SelectedProductTile(
                                  item: _triggerItem!,
                                  onRemove: () => setState(() => _triggerItem = null),
                                  isTrigger: true,
                                )
                              else
                                _ProductSearchDropdown(
                                  allItems: _allItems,
                                  excludeIds: {
                                    ..._suggestions.map((s) => s.item?.id).whereType<int>(),
                                  },
                                  onSelect: (item) => setState(() => _triggerItem = item),
                                  hint: 'Buscar produto gatilho...',
                                ),
                              const SizedBox(height: 24),
                              // Suggestions
                              Row(children: [
                                const Expanded(child: _SectionLabel('Produtos sugeridos com desconto')),
                              ]),
                              const SizedBox(height: 4),
                              const Text(
                                'Adicione produtos que serão sugeridos ao cliente com desconto especial.',
                                style: TextStyle(fontSize: 12, color: _DS.stone),
                              ),
                              const SizedBox(height: 10),
                              ...List.generate(_suggestions.length, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _SuggestionEditor(
                                    draft: _suggestions[i],
                                    onRemove: () => _removeSuggestion(i),
                                    onChange: () => setState(() {}),
                                  ),
                                );
                              }),
                              _ProductSearchDropdown(
                                allItems: _allItems,
                                excludeIds: {
                                  if (_triggerItem?.id != null) _triggerItem!.id!,
                                  ..._suggestions.map((s) => s.item?.id).whereType<int>(),
                                },
                                onSelect: _addSuggestion,
                                hint: 'Adicionar produto sugerido...',
                              ),
                            ]),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: _DS.hairlineSoft),
                        // Right panel: preview
                        SizedBox(
                          width: 220,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: _UpsellPreview(
                              triggerItem: _triggerItem,
                              description: _descCtrl.text.trim(),
                              suggestions: _suggestions,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1, color: _DS.hairlineSoft),
            // ── Footer ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DS.steel,
                    side: const BorderSide(color: _DS.hairline),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
                const Spacer(),
                ValueListenableBuilder<StateApp>(
                  valueListenable: isEdit ? widget.controller.stateUpdate : widget.controller.stateCreate,
                  builder: (_, state, __) {
                    final loading = state is LoadingState;
                    return FilledButton(
                      onPressed: loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _DS.ink,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Salvar alterações' : 'Criar regra', style: const TextStyle()),
                    );
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Preview panel ─────────────────────────────────────────────────────────────

class _UpsellPreview extends StatelessWidget {
  final MenuItemsModel? triggerItem;
  final String description;
  final List<_SuggestedItemDraft> suggestions;

  const _UpsellPreview({
    required this.triggerItem,
    required this.description,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Preview', style: TextStyle(fontSize: 12, color: _DS.stone, letterSpacing: 0.5)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (triggerItem != null) ...[
            const Text('Cliente adicionou:',
                style: TextStyle(
                  fontSize: 11,
                  color: _DS.stone,
                )),
            const SizedBox(height: 6),
            Row(children: [
              _ProductThumb(imageUrl: triggerItem!.imageUrl, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    triggerItem!.name ?? '',
                    style: const TextStyle(fontSize: 12, color: _DS.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _money.format(triggerItem!.price ?? 0),
                    style: const TextStyle(fontSize: 11, color: _DS.steel),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _DS.hairlineSoft),
            const SizedBox(height: 10),
          ],
          if (description.isNotEmpty) ...[
            Row(children: [
              const Icon(LucideIcons.zap, size: 12, color: _DS.brandBlue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 11.5, color: _DS.brandBlue),
                ),
              ),
            ]),
            const SizedBox(height: 10),
          ],
          if (suggestions.isEmpty)
            const Text(
              'Adicione produtos\nsugeridos →',
              style: TextStyle(fontSize: 11, color: _DS.muted),
            )
          else
            ...suggestions.map((s) {
              if (s.item == null) return const SizedBox.shrink();
              final orig = s.item!.price ?? 0;
              final finalP = s.discountType == 'percent' ? orig * (1 - (s.discountValue.clamp(0, 99.99)) / 100) : s.discountValue.clamp(0, orig.toDouble());
              final pct = orig > 0 ? ((orig - finalP) / orig * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: _DS.canvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _DS.hairlineSoft),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    _ProductThumb(imageUrl: s.item!.imageUrl, size: 28),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.item!.name ?? '', style: const TextStyle(fontSize: 11, color: _DS.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (orig > 0) ...[
                          Text(_money.format(orig), style: const TextStyle(fontSize: 10, color: _DS.stone, decoration: TextDecoration.lineThrough)),
                          Text(_money.format(finalP < 0 ? 0 : finalP), style: const TextStyle(fontSize: 11, color: _DS.ink)),
                        ],
                      ]),
                    ),
                    if (pct > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: _DS.yellowBg, borderRadius: BorderRadius.circular(6)),
                        child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: _DS.yellowText)),
                      ),
                  ]),
                ),
              );
            }),
        ]),
      ),
    ]);
  }
}

// ─── Suggestion editor ─────────────────────────────────────────────────────────

class _SuggestedItemDraft {
  MenuItemsModel? item;
  String discountType;
  double discountValue;

  _SuggestedItemDraft({
    required this.item,
    required this.discountType,
    required this.discountValue,
  });
}

class _SuggestionEditor extends StatefulWidget {
  final _SuggestedItemDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onChange;

  const _SuggestionEditor({required this.draft, required this.onRemove, required this.onChange});

  @override
  State<_SuggestionEditor> createState() => _SuggestionEditorState();
}

class _SuggestionEditorState extends State<_SuggestionEditor> {
  late final TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _discountCtrl = TextEditingController(text: widget.draft.discountValue.toStringAsFixed(widget.draft.discountType == 'percent' ? 0 : 2));
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  double get _origPrice => widget.draft.item?.price ?? 0;

  double get _computedFinal {
    if (widget.draft.discountType == 'percent') {
      return _origPrice * (1 - (widget.draft.discountValue.clamp(0, 99.99)) / 100);
    } else {
      return widget.draft.discountValue.clamp(0, _origPrice.toDouble());
    }
  }

  double get _computedPct {
    if (_origPrice <= 0) return 0;
    if (widget.draft.discountType == 'percent') return widget.draft.discountValue;
    return (_origPrice - widget.draft.discountValue.clamp(0, _origPrice.toDouble())) / _origPrice * 100;
  }

  void _onDiscountChanged(String val) {
    final v = double.tryParse(val.replaceAll(',', '.')) ?? 0;
    widget.draft.discountValue = v;
    widget.onChange();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairline),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _ProductThumb(imageUrl: draft.item?.imageUrl, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(draft.item?.name ?? 'Produto', style: const TextStyle(fontSize: 13, color: _DS.ink)),
              Text(_money.format(_origPrice), style: const TextStyle(fontSize: 12, color: _DS.stone)),
            ]),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 15, color: _DS.stone),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
            splashRadius: 14,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // Type selector
          Expanded(
            flex: 2,
            child: _TypeSelector(
              value: draft.discountType,
              onChanged: (v) {
                setState(() {
                  draft.discountType = v;
                  if (v == 'percent') {
                    draft.discountValue = 10;
                    _discountCtrl.text = '10';
                  } else {
                    final fin = _origPrice * 0.9;
                    draft.discountValue = fin;
                    _discountCtrl.text = fin.toStringAsFixed(2);
                  }
                });
                widget.onChange();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Discount value
          Expanded(
            flex: 2,
            child: TextField(
              controller: _discountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: _onDiscountChanged,
              decoration: _inputDec(
                hint: draft.discountType == 'percent' ? '10' : '4,99',
                suffix: Text(draft.discountType == 'percent' ? '%' : 'R\$', style: const TextStyle(fontSize: 13, color: _DS.stone)),
              ),
            ),
          ),
        ]),
        if (_origPrice > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _DS.yellowBg, borderRadius: BorderRadius.circular(_DS.rMd)),
            child: Row(children: [
              const Icon(LucideIcons.tag, size: 13, color: _DS.yellowText),
              const SizedBox(width: 6),
              Text(
                'De ${_money.format(_origPrice)} por ${_money.format(_computedFinal < 0 ? 0 : _computedFinal)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _DS.yellowText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _DS.yellowText.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
                child: Text(
                  '${_computedPct.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.yellowText,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─── Product search dropdown ───────────────────────────────────────────────────

class _ProductSearchDropdown extends StatefulWidget {
  final List<MenuItemsModel> allItems;
  final Set<int> excludeIds;
  final ValueChanged<MenuItemsModel> onSelect;
  final String hint;

  const _ProductSearchDropdown({
    required this.allItems,
    required this.excludeIds,
    required this.onSelect,
    required this.hint,
  });

  @override
  State<_ProductSearchDropdown> createState() => _ProductSearchDropdownState();
}

class _ProductSearchDropdownState extends State<_ProductSearchDropdown> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _open = false;

  List<MenuItemsModel> get _results {
    final q = _ctrl.text.toLowerCase().trim();
    return widget.allItems.where((i) => !widget.excludeIds.contains(i.id) && (q.isEmpty || (i.name ?? '').toLowerCase().contains(q))).take(8).toList();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _ctrl,
        focusNode: _focus,
        onTap: () => setState(() => _open = true),
        onChanged: (_) => setState(() => _open = true),
        decoration: _inputDec(
          hint: widget.hint,
          prefix: const Icon(LucideIcons.search, size: 16, color: _DS.stone),
        ),
      ),
      if (_open && _results.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(color: _DS.hairline),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: _results.map((item) {
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  widget.onSelect(item);
                  _ctrl.clear();
                  setState(() => _open = false);
                  _focus.unfocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    _ProductThumb(imageUrl: item.imageUrl, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name ?? '', style: const TextStyle(fontSize: 13, color: _DS.ink)),
                        Text(_money.format(item.price ?? 0), style: const TextStyle(fontSize: 12, color: _DS.steel)),
                      ]),
                    ),
                    const Icon(LucideIcons.plus, size: 14, color: _DS.stone),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}

// ─── Selected product tile ─────────────────────────────────────────────────────

class _SelectedProductTile extends StatelessWidget {
  final MenuItemsModel item;
  final VoidCallback onRemove;
  final bool isTrigger;

  const _SelectedProductTile({required this.item, required this.onRemove, this.isTrigger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isTrigger ? _DS.surfacePricing : _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: isTrigger ? _DS.brandBlue.withValues(alpha: 0.3) : _DS.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        _ProductThumb(imageUrl: item.imageUrl, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name ?? '', style: TextStyle(fontSize: 13.5, color: isTrigger ? _DS.brandBlue : _DS.ink)),
            Text(_money.format(item.price ?? 0), style: const TextStyle(fontSize: 12, color: _DS.steel)),
          ]),
        ),
        if (isTrigger)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _DS.brandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
            child: const Text('Gatilho',
                style: TextStyle(
                  fontSize: 11,
                  color: _DS.brandBlue,
                )),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(LucideIcons.x, size: 15, color: _DS.stone),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(maxWidth: 28, maxHeight: 28),
          splashRadius: 14,
        ),
      ]),
    );
  }
}

// ─── Type selector ─────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _TypeChip(label: '%', selected: value == 'percent', onTap: () => onChanged('percent')),
      const SizedBox(width: 6),
      _TypeChip(label: 'R\$', selected: value == 'final_price', onTap: () => onChanged('final_price')),
    ]);
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _DS.ink : _DS.canvas,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? _DS.ink : _DS.hairline),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : _DS.steel)),
      ),
    );
  }
}

// ─── Shared helpers ─────────────────────────────────────────────────────────────

class _ProductThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ProductThumb({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: (imageUrl ?? '').isNotEmpty
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: size,
        height: size,
        color: _DS.surface,
        child: Icon(LucideIcons.package, size: size * 0.45, color: _DS.stone),
      );
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _DS.successSoft : _DS.dangerSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        active ? 'Ativa' : 'Inativa',
        style: TextStyle(fontSize: 11, color: active ? _DS.successAccent : _DS.danger),
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  final String label;
  const _DiscountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: _DS.yellowBg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
            fontSize: 10.5,
            color: _DS.yellowText,
          )),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final Color? color;

  const _IconBtn({required this.icon, required this.tooltip, required this.onTap, this.danger = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? (danger ? _DS.danger : _DS.stone)),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 13, color: _DS.ink));
  }
}

InputDecoration _inputDec({String hint = '', Widget? prefix, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
    prefixIcon: prefix,
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.hairline)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _DS.brandBlue, width: 2)),
    filled: true,
    fillColor: _DS.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}
