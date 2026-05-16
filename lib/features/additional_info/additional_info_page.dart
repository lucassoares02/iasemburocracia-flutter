import 'package:flutter/material.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/additional_info/additional_info_model.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';
import '../../core/state/app_state.dart';
import 'additional_info_controller.dart';
import 'additional_info_repository.dart';
import 'additional_info_usecase.dart';

// =============================================================================
// Design tokens — fonte única de verdade para espaçamentos, raios e tipografia
// =============================================================================
abstract class _DS {
  // Raios
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // Espaçamentos
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Elevação / sombra
  static List<BoxShadow> shadowSm(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// =============================================================================
// Mapeamento de categorias (icons + cores)
// =============================================================================
class _CategoryMeta {
  const _CategoryMeta({required this.icon, required this.colorResolver});
  final IconData icon;
  final Color Function(ColorScheme) colorResolver;

  static const _fallback = _CategoryMeta(
    icon: Icons.label_rounded,
    colorResolver: _outlineColor,
  );

  static Color _outlineColor(ColorScheme c) => c.outline;

  static const _map = <String, _CategoryMeta>{
    'financeiro': _CategoryMeta(
      icon: Icons.account_balance_wallet_rounded,
      colorResolver: _tertiaryColor,
    ),
    'contato': _CategoryMeta(
      icon: Icons.contacts_rounded,
      colorResolver: _secondaryColor,
    ),
    'endereço': _CategoryMeta(
      icon: Icons.location_on_rounded,
      colorResolver: _errorColor,
    ),
    'documento': _CategoryMeta(
      icon: Icons.description_rounded,
      colorResolver: _primaryColor,
    ),
  };

  static Color _tertiaryColor(ColorScheme c) => c.tertiary;
  static Color _secondaryColor(ColorScheme c) => c.secondary;
  static Color _errorColor(ColorScheme c) => c.error;
  static Color _primaryColor(ColorScheme c) => c.primary;

  static _CategoryMeta of(String? category) => _map[category?.toLowerCase()] ?? _fallback;
}

// =============================================================================
// Página principal
// =============================================================================
class AdditionalInfoPage extends StatefulWidget {
  const AdditionalInfoPage({super.key});

  @override
  State<AdditionalInfoPage> createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  late final AdditionalInfoController _controller = AdditionalInfoController(
    StartState(),
    AdditionalInfoUseCase(AdditionalInfoRepository()),
  );

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.findAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDialog({AdditionalInfoModel? existing}) => showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (_) => _InfoDialog(
          controller: _controller,
          existingInfo: existing,
        ),
      );

  void _confirmDelete(AdditionalInfoModel item) => showDialog(
        context: context,
        builder: (ctx) => _DeleteDialog(
          itemTitle: item.title ?? '',
          onConfirm: () async {
            if (item.id != null) {
              await _controller.delete(item.id!);
              _controller.findAll();
            }
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(_DS.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(onAdd: () => _openDialog()),
            const SizedBox(height: _DS.space20),
            _SearchBar(
              controller: _searchCtrl,
              hasQuery: _query.isNotEmpty,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
            const SizedBox(height: _DS.space8),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _controller.stateFindAll,
                builder: (context, state, _) {
                  if (state is LoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ErrorState) {
                    return _EmptyState(
                      icon: Icons.wifi_off_rounded,
                      iconColor: colors.error,
                      title: 'Falha ao carregar',
                      subtitle: 'Verifique sua conexão e tente novamente.',
                      action: FilledButton.tonalIcon(
                        onPressed: _controller.findAll,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Tentar novamente'),
                      ),
                    );
                  }

                  if (state is SuccessState) {
                    final items = _filter(state.data);
                    if (items.isEmpty) {
                      return _EmptyState(
                        icon: Icons.layers_outlined,
                        iconColor: colors.primary,
                        title: 'Nenhuma informação',
                        subtitle: _query.isEmpty ? 'Adicione informações para complementar o perfil.' : 'Nenhum resultado para "$_query".',
                      );
                    }
                    return _InfoList(
                      items: items,
                      onTap: (item) => _openDialog(existing: item),
                      onDelete: _confirmDelete,
                    );
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

  List<AdditionalInfoModel> _filter(List<AdditionalInfoModel> all) => all.where((item) {
        if (_query.isEmpty) return true;
        return (item.title?.toLowerCase().contains(_query) ?? false) || (item.content?.toLowerCase().contains(_query) ?? false) || (item.category?.toLowerCase().contains(_query) ?? false);
      }).toList();
}

// =============================================================================
// Cabeçalho da página
// =============================================================================
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informações adicionais',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: _DS.space4),
              Text(
                'Gerencie e organize as informações do perfil',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SpecialButton(
          icon: Icons.add_rounded,
          color: colors.primary,
          label: 'Adicionar',
          onPressButton: onAdd,
        ),
      ],
    );
  }
}

// =============================================================================
// Barra de busca
// =============================================================================
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Buscar por título, conteúdo ou categoria…',
        hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6)),
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.onSurfaceVariant),
        suffixIcon: hasQuery
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: 16, color: colors.onSurfaceVariant),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: colors.surfaceVariant.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.radiusMd),
          borderSide: BorderSide(color: colors.primary.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DS.space16,
          vertical: _DS.space12,
        ),
        isDense: true,
      ),
    );
  }
}

// =============================================================================
// Lista de cards
// =============================================================================
class _InfoList extends StatelessWidget {
  const _InfoList({
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final List<AdditionalInfoModel> items;
  final ValueChanged<AdditionalInfoModel> onTap;
  final ValueChanged<AdditionalInfoModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ListView.separated(
        key: ValueKey(items.length),
        padding: const EdgeInsets.only(top: _DS.space12, bottom: _DS.space24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: _DS.space8),
        itemBuilder: (_, i) {
          final item = items[i];
          final meta = _CategoryMeta.of(item.category);
          final color = meta.colorResolver(Theme.of(context).colorScheme);
          return _InfoCard(
            item: item,
            accentColor: color,
            categoryIcon: meta.icon,
            onTap: () => onTap(item),
            onDelete: () => onDelete(item),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Card de informação
// =============================================================================
class _InfoCard extends StatefulWidget {
  const _InfoCard({
    required this.item,
    required this.accentColor,
    required this.categoryIcon,
    required this.onTap,
    required this.onDelete,
  });

  final AdditionalInfoModel item;
  final Color accentColor;
  final IconData categoryIcon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = widget.accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          border: Border.all(
            color: _hovered ? accent.withOpacity(0.3) : colors.outlineVariant.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: _hovered ? _DS.shadowMd(accent) : _DS.shadowSm(colors.shadow),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          splashColor: accent.withOpacity(0.06),
          highlightColor: accent.withOpacity(0.04),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _DS.space16,
              vertical: _DS.space14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ícone de categoria
                _CategoryIcon(icon: widget.categoryIcon, color: accent),
                SizedBox(width: _DS.space14),

                // Conteúdo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.title ?? 'Sem título',
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: _DS.space8),
                          _VisibilityBadge(visibility: widget.item.visibility),
                        ],
                      ),
                      if ((widget.item.content ?? '').isNotEmpty) ...[
                        const SizedBox(height: _DS.space4),
                        Text(
                          widget.item.content!,
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if ((widget.item.triggerKeywords ?? '').isNotEmpty) ...[
                        const SizedBox(height: _DS.space8),
                        _KeywordChips(
                          keywords: widget.item.triggerKeywords!,
                          color: accent,
                        ),
                      ],
                    ],
                  ),
                ),

                // Menu contextual
                _CardMenu(
                  onView: widget.onTap,
                  onDelete: widget.onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-widgets do card
// =============================================================================
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(_DS.radiusSm),
        ),
        child: Icon(icon, size: 18, color: color),
      );
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});
  final String? visibility;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPrivate = visibility == 'private';
    final bgColor = isPrivate ? colors.errorContainer.withOpacity(0.4) : colors.primaryContainer.withOpacity(0.4);
    final fgColor = isPrivate ? colors.onErrorContainer : colors.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.space8, vertical: _DS.space4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPrivate ? Icons.lock_outline_rounded : Icons.public_rounded,
            size: 10,
            color: fgColor,
          ),
          const SizedBox(width: _DS.space4),
          Text(
            isPrivate ? 'Privado' : 'Público',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _KeywordChips extends StatelessWidget {
  const _KeywordChips({required this.keywords, required this.color});
  final String keywords;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tags = keywords.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).take(4).toList();

    return Wrap(
      spacing: _DS.space4,
      runSpacing: _DS.space4,
      children: tags
          .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: _DS.space8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(_DS.radiusSm),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ))
          .toList(),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.onView, required this.onDelete});
  final VoidCallback onView;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMd)),
      elevation: 3,
      onSelected: (v) {
        if (v == 'view') onView();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        _menuItem(value: 'view', icon: Icons.open_in_new_rounded, label: 'Ver detalhes', color: colors.primary),
        _menuItem(value: 'delete', icon: Icons.delete_outline_rounded, label: 'Excluir', color: colors.error),
      ],
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      PopupMenuItem(
        value: value,
        padding: const EdgeInsets.symmetric(horizontal: _DS.space16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: _DS.space8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// =============================================================================
// Dialog de confirmação de exclusão
// =============================================================================
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.itemTitle, required this.onConfirm});
  final String itemTitle;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusXl)),
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.errorContainer.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.onErrorContainer, size: 26),
      ),
      title: Text('Excluir informação', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      content: Text(
        'Tem certeza que deseja excluir "$itemTitle"? Esta ação não pode ser desfeita.',
        style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(_DS.space24, 0, _DS.space24, _DS.space20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(100, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMd)),
          ),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: _DS.space8),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
            minimumSize: const Size(100, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMd)),
          ),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}

// =============================================================================
// Dialog de criação / edição
// =============================================================================
class _InfoDialog extends StatefulWidget {
  const _InfoDialog({required this.controller, this.existingInfo});
  final AdditionalInfoController controller;
  final AdditionalInfoModel? existingInfo;

  @override
  State<_InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<_InfoDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _keywordsCtrl;
  late String _visibility;
  late bool _isEditing;

  bool get _isNew => widget.existingInfo == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingInfo;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _keywordsCtrl = TextEditingController(text: e?.triggerKeywords ?? '');
    _visibility = e?.visibility ?? 'public';
    _isEditing = _isNew;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _categoryCtrl.dispose();
    _keywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final model = AdditionalInfoModel.fromJson({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'triggerKeywords': _keywordsCtrl.text.trim(),
      'visibility': _visibility,
    });

    if (_isNew) {
      await widget.controller.create(model);
    } else {
      model.id = widget.existingInfo!.id;
      await widget.controller.update(model);
    }

    if (!mounted) return;
    Navigator.pop(context);
    widget.controller.findAll();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final title = _isNew ? 'Nova informação' : (_isEditing ? 'Editar informação' : 'Detalhes');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusXl)),
      insetPadding: const EdgeInsets.symmetric(horizontal: _DS.space24, vertical: _DS.space32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(_DS.space24, _DS.space20, _DS.space16, _DS.space16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceVariant.withOpacity(0.5),
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_DS.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogField(
                      controller: _titleCtrl,
                      label: 'Título',
                      icon: Icons.title_rounded,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: _DS.space12),
                    _DialogField(
                      controller: _contentCtrl,
                      label: 'Conteúdo',
                      icon: Icons.notes_rounded,
                      maxLines: 4,
                      readOnly: !_isEditing,
                    ),
                    const SizedBox(height: _DS.space12),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogField(
                            controller: _categoryCtrl,
                            label: 'Categoria',
                            icon: Icons.category_rounded,
                            readOnly: !_isEditing,
                          ),
                        ),
                        const SizedBox(width: _DS.space12),
                        Expanded(
                          child: _DialogField(
                            controller: _keywordsCtrl,
                            label: 'Palavras-chave',
                            icon: Icons.tag_rounded,
                            readOnly: !_isEditing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _DS.space16),

                    // Visibilidade
                    Text(
                      'Visibilidade',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: _DS.space8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'public',
                          label: Text('Público'),
                          icon: Icon(Icons.public_rounded),
                        ),
                        ButtonSegment(
                          value: 'private',
                          label: Text('Privado'),
                          icon: Icon(Icons.lock_outline_rounded),
                        ),
                      ],
                      selected: {_visibility},
                      onSelectionChanged: _isEditing ? (s) => setState(() => _visibility = s.first) : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return colors.primary;
                          }
                          return colors.surfaceVariant.withOpacity(0.4);
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return colors.onPrimary;
                          }
                          return colors.onSurfaceVariant;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(_DS.space24, _DS.space16, _DS.space24, _DS.space20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isNew && !_isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMd)),
                      ),
                    ),
                  ],
                  if (_isEditing)
                    ValueListenableBuilder(
                      valueListenable: widget.controller.stateCreate,
                      builder: (_, state, __) {
                        final loading = state is LoadingState;
                        return FilledButton.icon(
                          onPressed: loading ? null : _save,
                          icon: loading
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 16),
                          label: Text(loading ? 'Salvando…' : 'Salvar'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(110, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.radiusMd)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Campo reutilizável do formulário
// =============================================================================
class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 16, color: colors.onSurfaceVariant),
        filled: true,
        fillColor: readOnly ? colors.surfaceVariant.withOpacity(0.2) : colors.surfaceVariant.withOpacity(0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.radiusMd),
          borderSide: BorderSide(
            color: colors.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _DS.space16,
          vertical: _DS.space12,
        ),
        isDense: true,
      ),
    );
  }
}

// =============================================================================
// Estado vazio
// =============================================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _DS.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(_DS.radiusLg),
              ),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: _DS.space16),
            Text(title, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: _DS.space4),
            Text(
              subtitle,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: _DS.space20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Extensão de padding (space14 não é padrão do DS — definido localmente)
// =============================================================================
extension on _DS {
  static const double space14 = 14;
}
