part of 'menu_items_page.dart';

// ─── Field aliases (accept PT-BR or EN) ──────────────────────────────────────

const _aliasName = ['nome', 'name', 'produto', 'product'];
const _aliasDescription = ['descricao', 'description', 'desc'];
const _aliasPrice = ['preco', 'price', 'valor'];
const _aliasCategory = ['categoria', 'category', 'category_name'];
const _aliasAvailable = ['disponivel', 'available', 'ativo'];
const _aliasFeatured = ['destaque', 'featured'];
const _aliasOrder = ['ordem', 'display_order', 'order'];
const _aliasPrepTime = ['tempo_preparo', 'prep_time', 'prep_time_minutes', 'preparo'];
const _aliasSku = ['sku', 'codigo'];
const _aliasImage = ['imagem', 'image', 'image_url'];

const _templateHeaders = [
  'nome',
  'descricao',
  'preco',
  'categoria',
  'disponivel',
  'destaque',
  'ordem',
  'tempo_preparo',
  'sku',
  'imagem',
];

// ─── Models ──────────────────────────────────────────────────────────────────

class _ImportRow {
  final int sourceIndex;
  String? name;
  String? description;
  double? price;
  String? categoryName;
  bool available = true;
  bool featured = false;
  int? displayOrder;
  int? prepTimeMinutes;
  String? sku;
  String? imageUrl;
  final List<String> errors = [];
  bool selected = true;

  _ImportRow({required this.sourceIndex});

  bool get isValid => errors.isEmpty;
}

class _ImportPreview {
  final List<_ImportRow> rows;
  final Set<String> existingCategories;
  final Set<String> newCategories;

  _ImportPreview({
    required this.rows,
    required this.existingCategories,
    required this.newCategories,
  });

  int get validCount => rows.where((r) => r.isValid).length;
  int get invalidCount => rows.length - validCount;
  int get selectedCount => rows.where((r) => r.selected && r.isValid).length;
}

// ─── Header / value normalization ────────────────────────────────────────────

String _normalizeKey(String h) {
  final s = h.toLowerCase().trim();
  const repl = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(repl[ch] ?? ch);
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), '_');
}

String? _readField(Map<String, dynamic> row, List<String> keys) {
  for (final k in keys) {
    if (row.containsKey(k) && row[k] != null) {
      final s = row[k].toString().trim();
      if (s.isNotEmpty) return s;
    }
  }
  return null;
}

bool? _parseBool(String? s) {
  if (s == null) return null;
  final t = s.toLowerCase().trim();
  if (['sim', 'yes', 'true', '1', 'y', 's', 'ativo'].contains(t)) return true;
  if (['nao', 'não', 'no', 'false', '0', 'n', 'inativo'].contains(t)) return false;
  return null;
}

double? _parsePrice(String? s) {
  if (s == null) return null;
  final cleaned = s.replaceAll(RegExp(r'[R\$\s]'), '');
  // Brazilian format "1.234,56" → "1234.56"
  final hasComma = cleaned.contains(',');
  final hasDot = cleaned.contains('.');
  String normalized = cleaned;
  if (hasComma && hasDot) {
    normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    normalized = cleaned.replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

// ─── File parsing ────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> _parseImportFile(PlatformFile file) async {
  final ext = (file.extension ?? '').toLowerCase();
  final bytes = file.bytes;
  if (bytes == null) throw Exception('Arquivo vazio.');

  switch (ext) {
    case 'csv':
      return _parseCsv(utf8.decode(bytes, allowMalformed: true));
    case 'xlsx':
      return _parseXlsx(bytes);
    case 'json':
      return _parseJson(utf8.decode(bytes, allowMalformed: true));
    default:
      throw Exception('Formato não suportado: .$ext');
  }
}

List<Map<String, dynamic>> _parseCsv(String text) {
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  final sep = firstLine.contains(';') && !firstLine.contains(',') ? ';' : ',';

  final rows = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(text.replaceAll('\r\n', '\n'), fieldDelimiter: sep);

  if (rows.isEmpty) return [];

  final headers = rows.first.map((e) => _normalizeKey(e.toString())).toList();
  return rows
      .skip(1)
      .map((row) {
        final map = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i]] = row[i];
        }
        return map;
      })
      .where((m) => m.values.any((v) => v != null && v.toString().trim().isNotEmpty))
      .toList();
}

List<Map<String, dynamic>> _parseXlsx(Uint8List bytes) {
  final excel = xls.Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return [];
  final sheet = excel.tables.values.first;
  if (sheet.rows.isEmpty) return [];

  final headers = sheet.rows.first.map((cell) => _normalizeKey(_cellValue(cell)?.toString() ?? '')).toList();

  return sheet.rows
      .skip(1)
      .map((row) {
        final map = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i]] = _cellValue(row[i]);
        }
        return map;
      })
      .where((m) => m.values.any((v) => v != null && v.toString().trim().isNotEmpty))
      .toList();
}

Object? _cellValue(xls.Data? cell) {
  final v = cell?.value;
  if (v == null) return null;
  try {
    final dyn = (v as dynamic).value;
    if (dyn == null) return null;
    return dyn is String ? dyn : dyn.toString();
  } catch (_) {
    return v.toString();
  }
}

List<Map<String, dynamic>> _parseJson(String text) {
  final decoded = jsonDecode(text);
  List<dynamic> list;
  if (decoded is List) {
    list = decoded;
  } else if (decoded is Map<String, dynamic>) {
    // Try common wrapper keys
    list = (decoded['items'] ?? decoded['produtos'] ?? decoded['products'] ?? []) as List;
    if (list.isEmpty) throw Exception('Estrutura JSON inválida. Esperado um array de produtos.');
  } else {
    throw Exception('Estrutura JSON inválida.');
  }

  return list.cast<Map<String, dynamic>>().map((m) {
    final out = <String, dynamic>{};
    m.forEach((k, v) => out[_normalizeKey(k)] = v);
    return out;
  }).toList();
}

// ─── Row validation ──────────────────────────────────────────────────────────

_ImportRow _validateRow(int idx, Map<String, dynamic> row) {
  final r = _ImportRow(sourceIndex: idx);

  r.name = _readField(row, _aliasName);
  r.description = _readField(row, _aliasDescription);
  r.categoryName = _readField(row, _aliasCategory);
  r.sku = _readField(row, _aliasSku);
  r.imageUrl = _readField(row, _aliasImage);

  r.price = _parsePrice(_readField(row, _aliasPrice));

  final orderStr = _readField(row, _aliasOrder);
  if (orderStr != null) r.displayOrder = int.tryParse(orderStr);

  final prepStr = _readField(row, _aliasPrepTime);
  if (prepStr != null) r.prepTimeMinutes = int.tryParse(prepStr);

  r.available = _parseBool(_readField(row, _aliasAvailable)) ?? true;
  r.featured = _parseBool(_readField(row, _aliasFeatured)) ?? false;

  if (r.name == null) r.errors.add('Nome obrigatório');
  if (r.price == null) r.errors.add('Preço inválido ou ausente');
  if (r.categoryName == null) r.errors.add('Categoria obrigatória');

  return r;
}

// ─── Template generator (XLSX) ───────────────────────────────────────────────

Future<void> _downloadImportTemplate() async {
  final excel = xls.Excel.createExcel();
  final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
  final sheet = excel[sheetName];
  excel.rename(sheetName, 'Produtos');

  // Header row
  for (var i = 0; i < _templateHeaders.length; i++) {
    final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.value = xls.TextCellValue(_templateHeaders[i]);
    cell.cellStyle = xls.CellStyle(
      bold: true,
      backgroundColorHex: xls.ExcelColor.fromHexString('#F7F8FA'),
      fontColorHex: xls.ExcelColor.fromHexString('#1C1C1E'),
    );
  }

  // Example rows
  final examples = <List<Object>>[
    [
      'Pizza Margherita',
      'Massa fina com molho de tomate, mussarela e manjericão fresco',
      45.90,
      'Pizzas',
      'sim',
      'sim',
      1,
      25,
      'PIZZ-001',
      '',
    ],
    [
      'Refrigerante 350ml',
      'Coca-Cola, Guaraná ou Sprite',
      6.50,
      'Bebidas',
      'sim',
      'nao',
      1,
      0,
      'BEB-001',
      '',
    ],
    [
      'Pudim de Leite',
      'Pudim caseiro com calda de caramelo',
      14.00,
      'Sobremesas',
      'sim',
      'nao',
      1,
      5,
      'SOB-001',
      '',
    ],
  ];

  for (var r = 0; r < examples.length; r++) {
    for (var c = 0; c < examples[r].length; c++) {
      final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
      final v = examples[r][c];
      if (v is num) {
        cell.value = v is int ? xls.IntCellValue(v) : xls.DoubleCellValue(v.toDouble());
      } else {
        cell.value = xls.TextCellValue(v.toString());
      }
    }
  }

  for (var i = 0; i < _templateHeaders.length; i++) {
    sheet.setColumnWidth(i, 20);
  }

  final bytes = excel.save();
  if (bytes == null) return;

  await FileSaver.instance.saveFile(
    name: 'modelo_cardapio',
    bytes: Uint8List.fromList(bytes),
    ext: 'xlsx',
    mimeType: MimeType.microsoftExcel,
  );
}

// ─── Dialog ──────────────────────────────────────────────────────────────────

enum _ImportStep { pickFile, preview, importing, done }

class _ImportDialog extends StatefulWidget {
  final MenuItemsController controller;
  final MenuCategoriesRepository catRepo;
  final int companyId;

  const _ImportDialog({
    required this.controller,
    required this.catRepo,
    required this.companyId,
  });

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  _ImportStep _step = _ImportStep.pickFile;
  _ImportPreview? _preview;
  String? _fileName;
  String? _error;
  bool _busyParse = false;
  bool _busyTemplate = false;

  int _progressDone = 0;
  int _progressTotal = 0;
  int _successCount = 0;
  int _failCount = 0;
  final List<String> _failedNames = [];

  Future<void> _onDownloadTemplate() async {
    setState(() => _busyTemplate = true);
    try {
      await _downloadImportTemplate();
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao gerar modelo: $e');
    } finally {
      if (mounted) setState(() => _busyTemplate = false);
    }
  }

  Future<void> _onPickFile() async {
    setState(() {
      _busyParse = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _busyParse = false);
        return;
      }

      final file = result.files.first;
      _fileName = file.name;

      // Existing categories
      final catRes = await widget.catRepo.findByCompany(widget.companyId);
      final existing = <String>{};
      if (catRes.success && catRes.data is List) {
        for (final c in (catRes.data as List).cast<MenuCategoriesModel>()) {
          if (c.name != null) existing.add(c.name!.toLowerCase().trim());
        }
      }

      final raw = await _parseImportFile(file);
      if (raw.isEmpty) {
        setState(() {
          _error = 'O arquivo não contém produtos.';
          _busyParse = false;
        });
        return;
      }

      final rows = <_ImportRow>[];
      final newCats = <String>{};
      for (var i = 0; i < raw.length; i++) {
        final r = _validateRow(i + 1, raw[i]);
        rows.add(r);
        if (r.categoryName != null && r.isValid) {
          final lower = r.categoryName!.toLowerCase().trim();
          if (!existing.contains(lower)) newCats.add(r.categoryName!.trim());
        }
      }

      setState(() {
        _preview = _ImportPreview(
          rows: rows,
          existingCategories: existing,
          newCategories: newCats,
        );
        _step = _ImportStep.preview;
        _busyParse = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao ler arquivo: ${e.toString().replaceFirst('Exception: ', '')}';
        _busyParse = false;
      });
    }
  }

  Future<void> _doImport() async {
    final preview = _preview!;
    final toImport = preview.rows.where((r) => r.selected && r.isValid).toList();
    if (toImport.isEmpty) return;

    setState(() {
      _step = _ImportStep.importing;
      _progressTotal = toImport.length;
      _progressDone = 0;
      _successCount = 0;
      _failCount = 0;
      _failedNames.clear();
    });

    final catIdMap = <String, int>{};
    final allCatsRes = await widget.catRepo.findByCompany(widget.companyId);
    if (allCatsRes.success && allCatsRes.data is List) {
      for (final c in (allCatsRes.data as List).cast<MenuCategoriesModel>()) {
        if (c.name != null && c.id != null) {
          catIdMap[c.name!.toLowerCase().trim()] = c.id!;
        }
      }
    }

    // Create missing categories first
    for (final newName in preview.newCategories) {
      try {
        final model = MenuCategoriesModel.fromJson({
          'name': newName,
          'company_id': widget.companyId,
          'sort_order': 999,
          'active': true,
        });
        await widget.catRepo.create(model);
      } catch (_) {
        // continue — we'll try to resolve afterwards
      }
    }

    // Refresh categories so newly created ones get IDs
    final refreshRes = await widget.catRepo.findByCompany(widget.companyId);
    if (refreshRes.success && refreshRes.data is List) {
      catIdMap.clear();
      for (final c in (refreshRes.data as List).cast<MenuCategoriesModel>()) {
        if (c.name != null && c.id != null) {
          catIdMap[c.name!.toLowerCase().trim()] = c.id!;
        }
      }
    }

    final itemsRepo = MenuItemsRepository();
    for (final r in toImport) {
      try {
        final catId = catIdMap[r.categoryName!.toLowerCase().trim()];
        if (catId == null) {
          _failCount++;
          _failedNames.add(r.name ?? 'sem nome');
        } else {
          final model = MenuItemsModel.fromJson({
            'name': r.name,
            'description': r.description,
            'category_id': catId,
            'company_id': widget.companyId,
            'price': r.price,
            'available': r.available,
            'featured': r.featured,
            'display_order': r.displayOrder,
            'prep_time_minutes': r.prepTimeMinutes,
            'sku': r.sku,
            'image_url': r.imageUrl,
          });
          await itemsRepo.create(model);
          _successCount++;
        }
      } catch (_) {
        _failCount++;
        _failedNames.add(r.name ?? 'sem nome');
      } finally {
        if (mounted) setState(() => _progressDone++);
      }
    }

    if (!mounted) return;
    setState(() => _step = _ImportStep.done);
    widget.controller.findAll();
    try {
      context.read<OnboardingProvider>().refresh(silent: true);
    } catch (_) {/* provider may not be in scope */}
  }

  void _toggleAll(bool value) {
    if (_preview == null) return;
    setState(() {
      for (final r in _preview!.rows) {
        if (r.isValid) r.selected = value;
      }
    });
  }

  void _toggleRow(_ImportRow r, bool v) {
    if (!r.isValid) return;
    setState(() => r.selected = v);
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_step) {
      _ImportStep.pickFile => _buildPickFile(),
      _ImportStep.preview => _buildPreview(),
      _ImportStep.importing => _buildImporting(),
      _ImportStep.done => _buildDone(),
    };

    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = screen.width < 920 ? screen.width - 48 : 880.0;
    final dialogHeight = _step == _ImportStep.preview ? 720.0 : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXxxl),
          border: Border.all(color: _DS.hairline),
          boxShadow: _DS.shadowModal,
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }

  // ─── Step 1: pick file ────────────────────────────────────────────────────

  Widget _buildPickFile() {
    return Padding(
      padding: const EdgeInsets.all(_DS.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogHeader(
            title: 'Importar produtos',
            subtitle: 'Importe seu cardápio a partir de uma planilha ou arquivo JSON.',
          ),
          const SizedBox(height: _DS.s5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionCard(
                  icon: LucideIcons.download,
                  iconBg: _DS.surface,
                  iconFg: _DS.ink,
                  title: 'Baixar modelo',
                  subtitle: 'Planilha .xlsx pronta para preencher com seus produtos.',
                  busy: _busyTemplate,
                  buttonLabel: 'Baixar modelo (.xlsx)',
                  onTap: _busyTemplate ? null : _onDownloadTemplate,
                ),
              ),
              const SizedBox(width: _DS.s4),
              Expanded(
                child: _ActionCard(
                  icon: LucideIcons.upload,
                  iconBg: _DS.brandBlue.withValues(alpha: 0.1),
                  iconFg: _DS.brandBlue,
                  title: 'Selecionar arquivo',
                  subtitle: 'Aceita .csv, .xlsx ou .json com os dados dos produtos.',
                  busy: _busyParse,
                  buttonLabel: 'Escolher arquivo',
                  onTap: _busyParse ? null : _onPickFile,
                  primary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: _DS.s5),
          Container(
            padding: const EdgeInsets.all(_DS.s4),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rLg),
              border: Border.all(color: _DS.hairlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(LucideIcons.info, size: 14, color: _DS.steel),
                  SizedBox(width: 6),
                  Text(
                    'Campos aceitos',
                    style: TextStyle(fontSize: 12, color: _DS.slate),
                  ),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _templateHeaders
                      .map((h) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _DS.canvas,
                              borderRadius: BorderRadius.circular(_DS.rSm),
                              border: Border.all(color: _DS.hairline),
                            ),
                            child: Text(
                              h,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _DS.slate,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Obrigatórios: nome, preco, categoria. Categorias inexistentes serão criadas automaticamente.',
                  style: TextStyle(fontSize: 11, color: _DS.steel, height: 1.5),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: _DS.s4),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: _DS.s5),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _DS.steel),
              child: const Text('Cancelar'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: preview ──────────────────────────────────────────────────────

  Widget _buildPreview() {
    final p = _preview!;
    final allSelected = p.rows.where((r) => r.isValid).every((r) => r.selected);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s6, _DS.s6, _DS.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dialogHeader(
            title: 'Pré-visualização',
            subtitle: _fileName != null ? 'Arquivo: $_fileName' : null,
          ),
          const SizedBox(height: _DS.s4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: '${p.rows.length} linhas',
                bg: _DS.surface,
                fg: _DS.slate,
              ),
              _Chip(
                label: '${p.validCount} válidas',
                bg: _DS.successSubtle,
                fg: _DS.successText,
                border: _DS.successBorder,
              ),
              if (p.invalidCount > 0)
                _Chip(
                  label: '${p.invalidCount} com erro',
                  bg: _DS.dangerSubtle,
                  fg: _DS.danger,
                  border: _DS.dangerBorder,
                ),
              if (p.newCategories.isNotEmpty)
                _Chip(
                  label: '${p.newCategories.length} nova(s) categoria(s)',
                  bg: _DS.yellowLight,
                  fg: _DS.yellowDark,
                ),
            ],
          ),
          if (p.newCategories.isNotEmpty) ...[
            const SizedBox(height: _DS.s3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(_DS.s3),
              decoration: BoxDecoration(
                color: _DS.yellowLight,
                borderRadius: BorderRadius.circular(_DS.rMd),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(LucideIcons.tag, size: 14, color: _DS.yellowDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Categorias que serão criadas: ${p.newCategories.join(', ')}',
                    style: const TextStyle(fontSize: 12, color: _DS.yellowDark, height: 1.5),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: _DS.s3),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _DS.hairlineSoft),
                borderRadius: BorderRadius.circular(_DS.rLg),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    color: _DS.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      SizedBox(
                        width: 28,
                        child: Checkbox(
                          value: allSelected,
                          tristate: false,
                          onChanged: (v) => _toggleAll(v ?? false),
                          activeColor: _DS.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(flex: 3, child: Text('Produto', style: _hdrStyle)),
                      const Expanded(flex: 2, child: Text('Categoria', style: _hdrStyle)),
                      const SizedBox(
                        width: 80,
                        child: Text('Preço', style: _hdrStyle, textAlign: TextAlign.end),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(
                        width: 80,
                        child: Text('Status', style: _hdrStyle, textAlign: TextAlign.center),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(scrollbars: false),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: p.rows.length,
                        separatorBuilder: (_, __) => const Divider(color: _DS.hairlineSoft, height: 1),
                        itemBuilder: (_, i) {
                          final r = p.rows[i];
                          final newCat = r.categoryName != null && !p.existingCategories.contains(r.categoryName!.toLowerCase().trim());
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            color: r.isValid ? null : _DS.dangerSubtle.withValues(alpha: 0.4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(
                                width: 28,
                                child: Checkbox(
                                  value: r.selected && r.isValid,
                                  onChanged: r.isValid ? (v) => _toggleRow(r, v ?? false) : null,
                                  activeColor: _DS.ink,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name ?? '—',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _DS.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((r.description ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          r.description!,
                                          style: const TextStyle(fontSize: 11, color: _DS.stone),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (!r.isValid) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        r.errors.join(' · '),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _DS.danger,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      r.categoryName ?? '—',
                                      style: const TextStyle(fontSize: 12, color: _DS.slate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (r.categoryName != null && newCat)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          'nova',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _DS.yellowDark,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  r.price != null ? formatCurrency(r.price!) : '—',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _DS.slate,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 80,
                                child: Center(
                                  child: r.isValid
                                      ? Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: _DS.successAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: _DS.danger,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _DS.s4),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _step = _ImportStep.pickFile;
                  _preview = null;
                }),
                icon: const Icon(LucideIcons.arrowLeft, size: 14),
                label: const Text('Voltar'),
                style: TextButton.styleFrom(foregroundColor: _DS.steel),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _DS.steel),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: p.selectedCount == 0 ? null : _doImport,
                icon: const Icon(LucideIcons.check, size: 16),
                label: Text(
                  p.selectedCount == 0 ? 'Selecione ao menos um produto' : 'Importar ${p.selectedCount} produto${p.selectedCount == 1 ? '' : 's'}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _DS.hairlineStrong,
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

  // ─── Step 3: importing ────────────────────────────────────────────────────

  Widget _buildImporting() {
    final pct = _progressTotal == 0 ? 0.0 : _progressDone / _progressTotal;
    return Padding(
      padding: const EdgeInsets.all(_DS.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _DS.brandBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.uploadCloud, size: 26, color: _DS.brandBlue),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Importando produtos...',
            style: TextStyle(fontSize: 18, color: _DS.ink),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            '$_progressDone de $_progressTotal',
            style: const TextStyle(fontSize: 13, color: _DS.steel),
          ),
          const SizedBox(height: _DS.s5),
          ClipRRect(
            borderRadius: BorderRadius.circular(_DS.rFull),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _DS.hairlineSoft,
              valueColor: const AlwaysStoppedAnimation(_DS.brandBlue),
            ),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Não feche esta janela.',
            style: TextStyle(fontSize: 11, color: _DS.stone, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: done ─────────────────────────────────────────────────────────

  Widget _buildDone() {
    final allOk = _failCount == 0;
    return Padding(
      padding: const EdgeInsets.all(_DS.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: allOk ? _DS.successSubtle : _DS.yellowLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                allOk ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                size: 28,
                color: allOk ? _DS.successAccent : _DS.yellowDark,
              ),
            ),
          ),
          const SizedBox(height: _DS.s4),
          Center(
            child: Text(
              allOk ? 'Importação concluída!' : 'Importação parcial',
              style: const TextStyle(fontSize: 20, color: _DS.ink),
            ),
          ),
          const SizedBox(height: _DS.s2),
          Center(
            child: Text(
              '$_successCount produto${_successCount == 1 ? '' : 's'} importado${_successCount == 1 ? '' : 's'} com sucesso'
              '${_failCount > 0 ? ' · $_failCount com erro' : ''}.',
              style: const TextStyle(fontSize: 13, color: _DS.steel, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          if (_failCount > 0) ...[
            const SizedBox(height: _DS.s5),
            Container(
              padding: const EdgeInsets.all(_DS.s3),
              decoration: BoxDecoration(
                color: _DS.dangerSubtle,
                borderRadius: BorderRadius.circular(_DS.rMd),
                border: Border.all(color: _DS.dangerBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Falha ao importar:',
                    style: TextStyle(fontSize: 12, color: _DS.danger),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: SingleChildScrollView(
                      child: Text(
                        _failedNames.join('\n'),
                        style: const TextStyle(fontSize: 12, color: _DS.slate, height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: _DS.s6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.ink,
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

  // ─── Common helpers ───────────────────────────────────────────────────────

  Widget _dialogHeader({required String title, String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, color: _DS.ink, letterSpacing: -0.4),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: _DS.steel, height: 1.5),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: _DS.stone),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

const TextStyle _hdrStyle = TextStyle(
  fontSize: 11,
  color: _DS.steel,
  letterSpacing: 0.2,
);

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onTap;
  final bool busy;
  final bool primary;

  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    this.busy = false,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DS.s4),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(_DS.rMd)),
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(height: _DS.s3),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: _DS.ink),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: _DS.steel, height: 1.5),
          ),
          const SizedBox(height: _DS.s4),
          SizedBox(
            width: double.infinity,
            child: primary
                ? FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(buttonLabel,
                            style: const TextStyle(
                              fontSize: 13,
                            )),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.ink,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _DS.ink),
                          )
                        : Text(buttonLabel,
                            style: const TextStyle(
                              fontSize: 13,
                            )),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_DS.s3),
      decoration: BoxDecoration(
        color: _DS.dangerSubtle,
        borderRadius: BorderRadius.circular(_DS.rMd),
        border: Border.all(color: _DS.dangerBorder),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(LucideIcons.alertCircle, size: 14, color: _DS.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, color: _DS.danger, height: 1.5),
          ),
        ),
      ]),
    );
  }
}
