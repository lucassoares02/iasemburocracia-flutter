import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/core/utils/format_currency.dart';
import 'package:portal_assoc/features/menu_items/ifood_import_repository.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_repository.dart';
import 'package:provider/provider.dart';

/// Diálogo de "Preenchimento Automático" do cardápio (importação via iFood).
///
/// Widget público e autocontido para ser reutilizado em qualquer tela
/// (página de cardápio, etapa de onboarding, etc.). Após uma importação
/// bem-sucedida chama [onImported] para que a tela hospedeira atualize sua
/// listagem/estado.
Future<void> showIfoodImportDialog(
  BuildContext context, {
  required int companyId,
  VoidCallback? onImported,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => IfoodImportDialog(companyId: companyId, onImported: onImported),
  );
}

// ─── Design tokens (autocontidos) ────────────────────────────────────────────
class _IfDS {
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s10 = 40.0;

  static const double rSm = 6.0;
  static const double rMd = 8.0;
  static const double rLg = 12.0;
  static const double rFull = 9999.0;
  static const double rXxxl = 28.0;

  static const Color ink = Color(0xFF1C1C1E);
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
  static const Color yellowDark = Color(0xFF746019);
  static const Color yellowLight = Color(0xFFFFF4C4);
  static const Color successAccent = Color(0xFF00B473);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static List<BoxShadow> shadowModal = [
    BoxShadow(
      color: const Color(0xFF050038).withValues(alpha: 0.12),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
  ];
}

// ─── Preenchimento Automático (importar cardápio do iFood) ───────────────────

enum _IfoodStep { url, loading, preview, importing, done }

class _IfoodItem {
  final String section;
  final String name;
  final String? details;
  double? price; // editável no preview (iFood às vezes traz 0.01 em itens com variação)
  final double? originalPrice;
  final String? imageUrl;
  final List<dynamic> options; // grupos de opções/adicionais (pass-through)
  bool selected = true;
  bool existing = false; // já existe no cardápio (mesmo nome + categoria)

  // Preço inválido — precisa ser revisado pelo usuário antes de importar.
  bool get needsPriceReview => price == null || price! < 1.0;

  _IfoodItem({
    required this.section,
    required this.name,
    this.details,
    this.price,
    this.originalPrice,
    this.imageUrl,
    this.options = const [],
  });

  factory _IfoodItem.fromJson(Map<String, dynamic> j) => _IfoodItem(
        section: (j['section'] ?? 'Outros').toString(),
        name: (j['name'] ?? '').toString(),
        details: j['details']?.toString(),
        price: _asDouble(j['price']),
        originalPrice: _asDouble(j['originalPrice']),
        imageUrl: j['imageUrl']?.toString(),
        options: (j['options'] as List?) ?? const [],
      );

  int get optionsCount => options.length;

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Map<String, dynamic> toImportJson() => {
        'name': name,
        'description': details,
        'categoryName': section,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'options': options,
      };
}

class IfoodImportDialog extends StatefulWidget {
  final int companyId;
  final VoidCallback? onImported;

  const IfoodImportDialog({super.key, required this.companyId, this.onImported});

  @override
  State<IfoodImportDialog> createState() => _IfoodImportDialogState();
}

class _IfoodImportDialogState extends State<IfoodImportDialog> {
  final _repo = IfoodImportRepository();
  final _urlCtrl = TextEditingController();

  _IfoodStep _step = _IfoodStep.url;
  String? _error;
  String? _restaurantName;
  List<_IfoodItem> _items = [];

  // Loading premium (estágios)
  String _loadingStage = 'Buscando cardápio...';
  Timer? _stageTimer;

  // Resultado da importação
  int _created = 0, _updated = 0, _skipped = 0, _failed = 0, _catsCreated = 0;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _stageTimer?.cancel();
    super.dispose();
  }

  // ─── Estatísticas ──────────────────────────────────────────────────────────
  int get _categoriesCount => _items.map((e) => e.section.toLowerCase().trim()).toSet().length;
  int get _withImageCount => _items.where((e) => (e.imageUrl ?? '').isNotEmpty).length;
  int get _withOptionsCount => _items.where((e) => e.optionsCount > 0).length;
  // Itens selecionados que ainda têm preço inválido (< 1,00) para revisar.
  int get _needsPriceCount => _items.where((e) => e.selected && e.needsPriceReview).length;
  int get _selectedCount => _items.where((e) => e.selected).length;

  // ─── Etapa 1 → buscar cardápio ─────────────────────────────────────────────
  Future<void> _search() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Cole a URL do restaurante no iFood.');
      return;
    }
    setState(() {
      _error = null;
      _step = _IfoodStep.loading;
      _loadingStage = 'Buscando cardápio...';
    });

    final res = await _repo.preview(url);
    if (!mounted) return;

    if (!res.ok) {
      final msg = switch (res.errorCode) {
        'INVALID_URL' => 'Não foi possível localizar esse restaurante.',
        'APIFY_FAILED' => 'Falha ao consultar o cardápio.',
        _ => 'Falha ao consultar o cardápio.',
      };
      setState(() {
        _error = msg;
        _step = _IfoodStep.url;
      });
      return;
    }

    final rawItems = (res.body['items'] as List? ?? []);
    final items = rawItems.map((e) => _IfoodItem.fromJson(Map<String, dynamic>.from(e as Map))).where((e) => e.name.isNotEmpty).toList();

    if (items.isEmpty) {
      setState(() {
        _error = 'Nenhum produto encontrado.';
        _step = _IfoodStep.url;
      });
      return;
    }

    // Detecta produtos já existentes (nome + categoria) no cardápio atual.
    final existing = await _loadExistingKeys();

    for (final it in items) {
      it.existing = existing.contains('${it.name.toLowerCase().trim()}|${it.section.toLowerCase().trim()}');
    }

    setState(() {
      _restaurantName = res.body['restaurantName']?.toString();
      _items = items;
      _step = _IfoodStep.preview;
    });
  }

  Future<Set<String>> _loadExistingKeys() async {
    try {
      final res = await MenuItemsRepository().findAll();
      if (!res.success || res.data is! List) return {};
      final keys = <String>{};
      for (final m in (res.data as List).cast<MenuItemsModel>()) {
        final n = (m.name ?? '').toLowerCase().trim();
        final c = (m.categoryName ?? '').toLowerCase().trim();
        if (n.isNotEmpty) keys.add('$n|$c');
      }
      return keys;
    } catch (_) {
      return {};
    }
  }

  // ─── Seleção ───────────────────────────────────────────────────────────────
  void _toggleAll(bool v) => setState(() {
        for (final it in _items) {
          it.selected = v;
        }
      });

  // ─── Etapa final → importar ────────────────────────────────────────────────
  Future<void> _confirmImport() async {
    final selected = _items.where((e) => e.selected).toList();
    if (selected.isEmpty) return;

    var strategy = 'ignore';
    final hasExisting = selected.any((e) => e.existing);
    if (hasExisting) {
      final choice = await _askConflictStrategy(selected.where((e) => e.existing).length);
      if (choice == null) return; // cancelou
      strategy = choice;
    }

    await _runImport(selected, strategy);
  }

  Future<String?> _askConflictStrategy(int count) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _IfDS.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_IfDS.rXxxl)),
        child: Padding(
          padding: const EdgeInsets.all(_IfDS.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Produtos já existentes', style: TextStyle(fontSize: 18, color: _IfDS.ink)),
              const SizedBox(height: 6),
              Text(
                '$count produto${count == 1 ? '' : 's'} selecionado${count == 1 ? '' : 's'} já existe${count == 1 ? '' : 'm'} no seu cardápio. O que deseja fazer?',
                style: const TextStyle(fontSize: 13, color: _IfDS.steel, height: 1.5),
              ),
              const SizedBox(height: _IfDS.s5),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'update'),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Atualizar existentes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _IfDS.ink,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: _IfDS.s2),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'ignore'),
                  icon: const Icon(LucideIcons.skipForward, size: 16),
                  label: const Text('Ignorar existentes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _IfDS.ink,
                    side: const BorderSide(color: _IfDS.hairline),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: _IfDS.s2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  style: TextButton.styleFrom(foregroundColor: _IfDS.steel),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runImport(List<_IfoodItem> selected, String strategy) async {
    setState(() => _step = _IfoodStep.importing);
    _startStageCycle();

    final res = await _repo.import(
      companyId: widget.companyId,
      items: selected.map((e) => e.toImportJson()).toList(),
      conflictStrategy: strategy,
    );

    _stageTimer?.cancel();
    if (!mounted) return;

    if (!res.ok) {
      setState(() {
        _error = res.body['message']?.toString() ?? 'Falha ao importar o cardápio.';
        _step = _IfoodStep.preview;
      });
      return;
    }

    setState(() {
      _created = (res.body['created'] as num?)?.toInt() ?? 0;
      _updated = (res.body['updated'] as num?)?.toInt() ?? 0;
      _skipped = (res.body['skipped'] as num?)?.toInt() ?? 0;
      _failed = (res.body['failed'] as num?)?.toInt() ?? 0;
      _catsCreated = (res.body['categoriesCreated'] as num?)?.toInt() ?? 0;
      _step = _IfoodStep.done;
    });

    widget.onImported?.call();
    try {
      context.read<OnboardingProvider>().refresh(silent: true);
    } catch (_) {/* provider pode não estar no escopo */}
  }

  void _startStageCycle() {
    const stages = [
      'Processando categorias...',
      'Preparando imagens...',
      'Importando produtos...',
      'Finalizando...',
    ];
    var i = 0;
    setState(() => _loadingStage = stages.first);
    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted) return;
      if (i < stages.length - 1) {
        i++;
        setState(() => _loadingStage = stages[i]);
      }
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = screen.width < 920 ? screen.width - 48 : 880.0;
    final dialogHeight = _step == _IfoodStep.preview ? 720.0 : null;

    final Widget body = switch (_step) {
      _IfoodStep.url => _buildUrlStep(),
      _IfoodStep.loading => _buildLoading('Buscando cardápio...', 'Estamos lendo o cardápio do restaurante no iFood.'),
      _IfoodStep.preview => _buildPreview(),
      _IfoodStep.importing => _buildLoading(_loadingStage, 'Não feche esta janela.'),
      _IfoodStep.done => _buildDone(),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: _IfDS.canvas,
          borderRadius: BorderRadius.circular(_IfDS.rXxxl),
          border: Border.all(color: _IfDS.hairline),
          boxShadow: _IfDS.shadowModal,
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }

  Widget _header({required String title, String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEA1D2C).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(_IfDS.rMd),
          ),
          child: const Icon(LucideIcons.utensils, size: 18, color: Color(0xFFEA1D2C)),
        ),
        const SizedBox(width: _IfDS.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, color: _IfDS.ink, letterSpacing: -0.4)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: _IfDS.steel, height: 1.5)),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: _IfDS.stone),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ─── Etapa: URL ────────────────────────────────────────────────────────────
  Widget _buildUrlStep() {
    return Padding(
      padding: const EdgeInsets.all(_IfDS.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            title: 'Importar Cardápio do iFood',
            subtitle: 'Cole a URL do restaurante no iFood para importar automaticamente categorias, produtos, descrições e imagens.',
          ),
          const SizedBox(height: _IfDS.s5),
          const Text('URL do restaurante', style: TextStyle(fontSize: 13, color: _IfDS.slate)),
          const SizedBox(height: _IfDS.s2),
          TextField(
            controller: _urlCtrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 14, color: _IfDS.ink),
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'https://www.ifood.com.br/delivery/cidade/restaurante/uuid',
              hintStyle: const TextStyle(fontSize: 13, color: _IfDS.muted),
              prefixIcon: const Icon(LucideIcons.link, size: 16, color: _IfDS.stone),
              filled: true,
              fillColor: _IfDS.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_IfDS.rMd), borderSide: const BorderSide(color: _IfDS.hairline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_IfDS.rMd), borderSide: const BorderSide(color: _IfDS.hairline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_IfDS.rMd), borderSide: const BorderSide(color: _IfDS.brandBlue, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: _IfDS.s4),
            _IfErrorBanner(message: _error!),
          ],
          const SizedBox(height: _IfDS.s5),
          Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _IfDS.steel),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _search,
                icon: const Icon(LucideIcons.search, size: 16),
                label: const Text('Buscar Cardápio'),
                style: FilledButton.styleFrom(
                  backgroundColor: _IfDS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Etapa: loading premium ────────────────────────────────────────────────
  Widget _buildLoading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(_IfDS.s10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _IfDS.brandBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(strokeWidth: 2.6, color: _IfDS.brandBlue),
            ),
          ),
          const SizedBox(height: _IfDS.s5),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              title,
              key: ValueKey(title),
              style: const TextStyle(fontSize: 18, color: _IfDS.ink),
            ),
          ),
          const SizedBox(height: _IfDS.s2),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: _IfDS.steel), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Etapa: preview ────────────────────────────────────────────────────────
  Widget _buildPreview() {
    final allSelected = _items.isNotEmpty && _items.every((e) => e.selected);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_IfDS.s6, _IfDS.s6, _IfDS.s6, _IfDS.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            title: 'Pré-visualização',
            subtitle: _restaurantName != null ? 'Restaurante: $_restaurantName' : 'Revise e selecione os produtos a importar.',
          ),
          const SizedBox(height: _IfDS.s4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _IfChip(label: 'Categorias encontradas: $_categoriesCount', bg: _IfDS.surface, fg: _IfDS.slate),
              _IfChip(label: 'Produtos encontrados: ${_items.length}', bg: _IfDS.successSubtle, fg: _IfDS.successText, border: _IfDS.successBorder),
              _IfChip(label: 'Produtos com imagem: $_withImageCount', bg: _IfDS.yellowLight, fg: _IfDS.yellowDark),
              if (_withOptionsCount > 0) _IfChip(label: 'Com adicionais: $_withOptionsCount', bg: _IfDS.brandBlue.withValues(alpha: 0.10), fg: _IfDS.brandBlue),
              if (_needsPriceCount > 0) _IfChip(label: 'Preços a revisar: $_needsPriceCount', bg: _IfDS.dangerSubtle, fg: _IfDS.danger, border: _IfDS.dangerBorder),
            ],
          ),
          const SizedBox(height: _IfDS.s3),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _toggleAll(true),
                icon: const Icon(LucideIcons.checkCheck, size: 14),
                label: const Text('Selecionar tudo'),
                style: TextButton.styleFrom(foregroundColor: _IfDS.ink, textStyle: const TextStyle(fontSize: 13)),
              ),
              TextButton.icon(
                onPressed: () => _toggleAll(false),
                icon: const Icon(LucideIcons.square, size: 14),
                label: const Text('Desmarcar tudo'),
                style: TextButton.styleFrom(foregroundColor: _IfDS.steel, textStyle: const TextStyle(fontSize: 13)),
              ),
              const Spacer(),
              Checkbox(
                value: allSelected,
                onChanged: (v) => _toggleAll(v ?? false),
                activeColor: _IfDS.ink,
              ),
              const Text('Todos', style: TextStyle(fontSize: 12, color: _IfDS.steel)),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: _IfDS.s2),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _IfDS.hairlineSoft),
                borderRadius: BorderRadius.circular(_IfDS.rLg),
              ),
              clipBehavior: Clip.antiAlias,
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(color: _IfDS.hairlineSoft, height: 1),
                  itemBuilder: (_, i) => _IfoodItemTile(
                    key: ValueKey('ifood-item-$i'),
                    item: _items[i],
                    onToggle: (v) => setState(() => _items[i].selected = v),
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _IfDS.s4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _step = _IfoodStep.url;
                  _items = [];
                }),
                icon: const Icon(LucideIcons.arrowLeft, size: 14),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(foregroundColor: _IfDS.steel),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _IfDS.steel),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (_selectedCount == 0 || _needsPriceCount > 0) ? null : _confirmImport,
                icon: const Icon(LucideIcons.download, size: 16),
                label: Text(
                  _selectedCount == 0
                      ? 'Selecione ao menos um produto'
                      : _needsPriceCount > 0
                          ? 'Revise os preços destacados'
                          : 'Importar Produtos ($_selectedCount)',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _IfDS.ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _IfDS.hairlineStrong,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Etapa: done ───────────────────────────────────────────────────────────
  Widget _buildDone() {
    final allOk = _failed == 0;
    return Padding(
      padding: const EdgeInsets.all(_IfDS.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: allOk ? _IfDS.successSubtle : _IfDS.yellowLight, shape: BoxShape.circle),
              child: Icon(allOk ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle, size: 28, color: allOk ? _IfDS.successAccent : _IfDS.yellowDark),
            ),
          ),
          const SizedBox(height: _IfDS.s4),
          Center(
            child: Text(allOk ? 'Importação concluída!' : 'Importação parcial', style: const TextStyle(fontSize: 20, color: _IfDS.ink)),
          ),
          const SizedBox(height: _IfDS.s4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_created > 0) _IfChip(label: '$_created criado${_created == 1 ? '' : 's'}', bg: _IfDS.successSubtle, fg: _IfDS.successText, border: _IfDS.successBorder),
              if (_updated > 0) _IfChip(label: '$_updated atualizado${_updated == 1 ? '' : 's'}', bg: _IfDS.surface, fg: _IfDS.slate),
              if (_skipped > 0) _IfChip(label: '$_skipped ignorado${_skipped == 1 ? '' : 's'}', bg: _IfDS.surface, fg: _IfDS.steel),
              if (_catsCreated > 0) _IfChip(label: '$_catsCreated nova(s) categoria(s)', bg: _IfDS.yellowLight, fg: _IfDS.yellowDark),
              if (_failed > 0) _IfChip(label: '$_failed com erro', bg: _IfDS.dangerSubtle, fg: _IfDS.danger, border: _IfDS.dangerBorder),
            ],
          ),
          const SizedBox(height: _IfDS.s6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _IfDS.ink,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Concluir'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item card do preview ────────────────────────────────────────────────────
class _IfoodItemTile extends StatefulWidget {
  final _IfoodItem item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;

  const _IfoodItemTile({super.key, required this.item, required this.onToggle, required this.onChanged});

  @override
  State<_IfoodItemTile> createState() => _IfoodItemTileState();
}

class _IfoodItemTileState extends State<_IfoodItemTile> {
  late final TextEditingController _priceCtrl;
  // Item começou com preço inválido → renderiza campo editável (estável,
  // mesmo depois de corrigido, para não perder o foco enquanto digita).
  late final bool _editable;

  @override
  void initState() {
    super.initState();
    _editable = widget.item.needsPriceReview;
    final p = widget.item.price;
    _priceCtrl = TextEditingController(
      text: (p == null || p < 1.0) ? '' : p.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _onPriceChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9,\.]'), '').replaceAll('.', '').replaceAll(',', '.');
    widget.item.price = double.tryParse(digits);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final onToggle = widget.onToggle;
    final hasImg = (item.imageUrl ?? '').isNotEmpty;
    return InkWell(
      onTap: () => onToggle(!item.selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Checkbox(
                value: item.selected,
                onChanged: (v) => onToggle(v ?? false),
                activeColor: _IfDS.ink,
              ),
            ),
            const SizedBox(width: 4),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(_IfDS.rMd),
              child: Container(
                width: 48,
                height: 48,
                color: _IfDS.surface,
                child: hasImg
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 18, color: _IfDS.stone),
                      )
                    : const Icon(LucideIcons.image, size: 18, color: _IfDS.stone),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 13, color: _IfDS.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.existing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _IfDS.yellowLight,
                            borderRadius: BorderRadius.circular(_IfDS.rFull),
                          ),
                          child: const Text('Produto já existente', style: TextStyle(fontSize: 10, color: _IfDS.yellowDark)),
                        ),
                      ],
                      if (item.needsPriceReview) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _IfDS.dangerSubtle,
                            borderRadius: BorderRadius.circular(_IfDS.rFull),
                            border: Border.all(color: _IfDS.dangerBorder),
                          ),
                          child: const Text('Revisar preço', style: TextStyle(fontSize: 10, color: _IfDS.danger)),
                        ),
                      ],
                    ],
                  ),
                  if ((item.details ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.details!,
                        style: const TextStyle(fontSize: 11, color: _IfDS.stone),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(item.section, style: const TextStyle(fontSize: 11, color: _IfDS.slate)),
                      if (item.optionsCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _IfDS.brandBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(_IfDS.rFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.listPlus, size: 11, color: _IfDS.brandBlue),
                              const SizedBox(width: 4),
                              Text(
                                '${item.optionsCount} ${item.optionsCount == 1 ? 'grupo de adicionais' : 'grupos de adicionais'}',
                                style: const TextStyle(fontSize: 10, color: _IfDS.brandBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Preço: editável quando o item veio com preço inválido (< 1,00),
            // senão somente leitura. A cor reflete a validade atual.
            if (_editable)
              SizedBox(
                width: 104,
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 13, color: _IfDS.ink),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'))],
                  onChanged: _onPriceChanged,
                  onTap: () {}, // evita propagar o toque para o InkWell (toggle)
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: 'R\$ ',
                    prefixStyle: const TextStyle(fontSize: 13, color: _IfDS.steel),
                    hintText: '0,00',
                    hintStyle: const TextStyle(fontSize: 13, color: _IfDS.muted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: item.needsPriceReview ? _IfDS.dangerSubtle : _IfDS.successSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_IfDS.rSm),
                      borderSide: BorderSide(color: item.needsPriceReview ? _IfDS.dangerBorder : _IfDS.successBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_IfDS.rSm),
                      borderSide: BorderSide(color: item.needsPriceReview ? _IfDS.dangerBorder : _IfDS.successBorder),
                    ),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(_IfDS.rSm), borderSide: const BorderSide(color: _IfDS.brandBlue, width: 1.5)),
                  ),
                ),
              )
            else
              Text(
                formatCurrency(item.price),
                style: const TextStyle(fontSize: 13, color: _IfDS.ink),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers de UI ───────────────────────────────────────────────────────────
class _IfChip extends StatelessWidget {
  const _IfChip({
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
      padding: const EdgeInsets.symmetric(horizontal: _IfDS.s3, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_IfDS.rFull),
        border: Border.all(color: border ?? _IfDS.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: fg),
      ),
    );
  }
}

class _IfErrorBanner extends StatelessWidget {
  final String message;
  const _IfErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_IfDS.s3),
      decoration: BoxDecoration(
        color: _IfDS.dangerSubtle,
        borderRadius: BorderRadius.circular(_IfDS.rMd),
        border: Border.all(color: _IfDS.dangerBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(LucideIcons.alertCircle, size: 14, color: _IfDS.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: _IfDS.danger, height: 1.5),
          ),
        ),
      ]),
    );
  }
}
