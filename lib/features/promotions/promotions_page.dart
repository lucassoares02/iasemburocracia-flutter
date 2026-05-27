import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_repository.dart';
import 'package:portal_assoc/features/promotions/promotions_controller.dart';
import 'package:portal_assoc/features/promotions/promotions_model.dart';
import 'package:portal_assoc/features/promotions/promotions_repository.dart';
import 'package:portal_assoc/features/promotions/promotions_usecase.dart';

class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const hairlineSoft = Color(0xFFEEF0F3);
  static const stone = Color(0xFF8E91A0);
  static const success = Color(0xFF00B473);
  static const danger = Color(0xFFE53935);
  static const muted = Color(0xFFA5A8B5);
  static const steel = Color(0xFF6B6F7E);
}

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  late final PromotionsController _ctrl = PromotionsController(StartState(), PromotionsUseCase(PromotionsRepository()));

  @override
  void initState() {
    super.initState();
    _ctrl.findAll();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Promoções / Combos', style: TextStyle(fontSize: 20, color: _DS.ink)),
                    SizedBox(height: 4),
                    Text('Crie combos promocionais com cálculo automático de desconto.', style: TextStyle(fontSize: 13, color: Color(0xFF6B6F7E), height: 1.4)),
                  ]),
                ),
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
                      Text('Nova Promoção'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<StateApp>(
              valueListenable: _ctrl.stateFindAll,
              builder: (_, state, __) {
                if (state is LoadingState || state is StartState) return const Center(child: CircularProgressIndicator());
                if (state is ErrorState) return Center(child: Text(state.message));
                final rows = (state as SuccessState).data as List<PromotionModel>;
                if (rows.isEmpty) {
                  return const Center(child: Text('Nenhuma promoção cadastrada.', style: TextStyle(color: _DS.stone)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 280, crossAxisSpacing: 14, mainAxisSpacing: 14),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => PromotionCard(
                    promo: rows[i],
                    onEdit: () => _openForm(item: rows[i]),
                    onDelete: () => _ctrl.delete(rows[i].id!),
                    onToggle: () => _ctrl.toggle(rows[i].id!, !rows[i].active),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openForm({PromotionModel? item}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => PromotionForm(controller: _ctrl, initial: item),
    );
  }
}

class PromotionCard extends StatelessWidget {
  final PromotionModel promo;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const PromotionCard({super.key, required this.promo, required this.onEdit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(16), border: Border.all(color: _DS.hairlineSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: (promo.imageUrl ?? '').isEmpty
                  ? Container(color: _DS.surface)
                  : Image.network(promo.imageUrl!, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _DS.surface)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(promo.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle())),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: promo.active ? const Color(0xFFE8F8F1) : const Color(0xFFFFEBEA), borderRadius: BorderRadius.circular(99)),
                  child: Text(promo.active ? 'Ativa' : 'Inativa',
                      style: TextStyle(
                        fontSize: 11,
                        color: promo.active ? _DS.success : _DS.danger,
                      )),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${promo.items.length} itens • ${promo.discountPercent?.toStringAsFixed(0) ?? 0}% OFF', style: const TextStyle(fontSize: 12, color: _DS.stone)),
              const SizedBox(height: 4),
              Row(children: [
                Text(_money.format(promo.originalPrice ?? 0), style: const TextStyle(decoration: TextDecoration.lineThrough, color: _DS.stone, fontSize: 12)),
                const SizedBox(width: 8),
                Text(_money.format(promo.finalPrice ?? 0), style: const TextStyle()),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                const Spacer(),
                _IconAction(icon: promo.active ? LucideIcons.toggleRight : LucideIcons.toggleLeft, onTap: onToggle),
                const SizedBox(width: 10),
                _IconAction(icon: LucideIcons.trash2, onTap: onDelete, danger: true),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _IconAction({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Icon(icon, size: 18, color: danger ? _DS.danger : _DS.ink),
    );
  }
}

class PromotionForm extends StatefulWidget {
  final PromotionsController controller;
  final PromotionModel? initial;
  const PromotionForm({super.key, required this.controller, this.initial});

  @override
  State<PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<PromotionForm> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _image = TextEditingController();
  final _discount = TextEditingController();
  final _final = TextEditingController();
  final _productSearch = TextEditingController();
  bool _active = true;
  int _tabIndex = 0;
  bool _saving = false;
  _PriceMode _priceMode = _PriceMode.discount;
  List<MenuItemsModel> _menuItems = [];
  final Map<int, int> _selected = {};

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i.name ?? '';
      _desc.text = i.description ?? '';
      _image.text = i.imageUrl ?? '';
      _discount.text = (i.discountPercent ?? 0).toStringAsFixed(2);
      _final.text = (i.finalPrice ?? 0).toStringAsFixed(2);
      _active = i.active;
      _priceMode = _PriceMode.manualFinal;
      for (final p in i.items) {
        if (p.menuItemId != null) _selected[p.menuItemId!] = p.quantity;
      }
    }
    _loadProducts();
    _productSearch.addListener(() => setState(() {}));
    _discount.addListener(_onPriceInputChanged);
    _final.addListener(_onPriceInputChanged);
  }

  void _onPriceInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadProducts() async {
    final res = await MenuItemsRepository().findAll();
    if (!mounted) return;
    if (res.success && res.data is List<MenuItemsModel>) {
      setState(() => _menuItems = res.data as List<MenuItemsModel>);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _image.dispose();
    _discount.dispose();
    _final.dispose();
    _productSearch.dispose();
    super.dispose();
  }

  double get _original {
    double total = 0;
    for (final e in _selected.entries) {
      MenuItemsModel? item;
      for (final m in _menuItems) {
        if (m.id == e.key) {
          item = m;
          break;
        }
      }
      total += (item?.price ?? 0) * e.value;
    }
    return total;
  }

  double get _discountPct {
    if (_priceMode == _PriceMode.manualFinal) {
      final finalV = double.tryParse(_final.text.replaceAll(',', '.'));
      if (finalV == null || _original <= 0) return 0;
      return ((_original - finalV) / _original) * 100;
    }
    final fromField = double.tryParse(_discount.text.replaceAll(',', '.'));
    if (fromField != null) return fromField;
    return 0;
  }

  double get _finalPrice {
    if (_priceMode == _PriceMode.manualFinal) {
      final fv = double.tryParse(_final.text.replaceAll(',', '.'));
      return fv ?? 0;
    }
    final fv = double.tryParse(_final.text.replaceAll(',', '.'));
    if (fv != null) return fv;
    return _original * (1 - (_discountPct / 100));
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    await _upload(bytes, file.name, file.extension ?? 'png');
  }

  Future<void> _upload(Uint8List bytes, String name, String ext) async {
    final mime = ext.toLowerCase() == 'jpg' || ext.toLowerCase() == 'jpeg'
        ? 'image/jpeg'
        : ext.toLowerCase() == 'webp'
            ? 'image/webp'
            : 'image/png';
    final res = await widget.controller.uploadImage(bytes, name, mime);
    if (res.success && res.data is Map<String, dynamic>) {
      setState(() => _image.text = ((res.data as Map<String, dynamic>)['url'] ?? '').toString());
    }
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    if (_finalPrice > _original || _finalPrice < 0 || _discountPct < 0) return;
    if (_saving) return;

    final model = PromotionModel.fromJson({
      'id': widget.initial?.id,
      'name': _name.text.trim(),
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'image_url': _image.text.trim().isEmpty ? null : _image.text.trim(),
      'active': _active,
      'discount_percent': _priceMode == _PriceMode.discount ? _discountPct : null,
      'final_price': _priceMode == _PriceMode.manualFinal ? _finalPrice : null,
      'items': _selected.entries.map((e) => {'menu_item_id': e.key, 'quantity': e.value}).toList(),
    });

    setState(() => _saving = true);
    try {
      if (widget.initial == null) {
        await widget.controller.create(model, context);
      } else {
        await widget.controller.update(model, context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_saving && _selected.isNotEmpty && _finalPrice >= 0 && _finalPrice <= _original && _discountPct >= 0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: 1080,
        height: 720,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Promoção', style: TextStyle(fontSize: 22, color: _DS.ink)),
                      SizedBox(height: 4),
                      Text('Configure combo, desconto e produtos inclusos.', style: TextStyle(fontSize: 13, color: _DS.stone)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _active ? const Color(0xFFE8F8F1) : const Color(0xFFFFEBEA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _active ? 'Ativa' : 'Inativa',
                    style: TextStyle(fontSize: 11, color: _active ? _DS.success : _DS.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _DS.hairline),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabButton(0, 'Informações'),
                  _tabButton(1, 'Produtos'),
                  _tabButton(2, 'Preços'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _buildTabContent(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canSubmit ? _submit : null,
                style: FilledButton.styleFrom(shape: const StadiumBorder(), backgroundColor: _DS.ink),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Salvar promoção'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final active = _tabIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _DS.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? _DS.ink : _DS.stone,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_tabIndex == 0) {
      return SingleChildScrollView(
        key: const ValueKey('tab-info'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _DS.hairline)),
          child: Column(
            children: [
              _PromoField(controller: _name, label: 'Nome da promoção'),
              const SizedBox(height: 8),
              _PromoField(controller: _desc, label: 'Descrição'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _PromoField(controller: _image, label: 'URL da imagem/banner')),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DS.ink,
                    side: const BorderSide(color: _DS.hairline),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  child: const Text('Upload'),
                ),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Promoção ativa'),
              ),
              if (_image.text.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_image.text.trim(), height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 140, color: _DS.surface)),
                ),
            ],
          ),
        ),
      );
    }
    if (_tabIndex == 1) {
      return SingleChildScrollView(
        key: const ValueKey('tab-products'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produtos do combo', style: TextStyle(color: _DS.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: _productSearch,
              decoration: _promoInputDecoration(
                hintText: 'Digite o nome do produto para adicionar...',
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            PromotionProductsSelector(
              menuItems: _menuItems,
              selected: _selected,
              query: _productSearch.text,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('tab-price'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _DS.hairline),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _priceModeButton(_PriceMode.discount, 'Desconto (%)'),
                _priceModeButton(_PriceMode.manualFinal, 'Valor final manual'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            if (_priceMode == _PriceMode.discount)
              Expanded(child: _PromoField(controller: _discount, label: 'Desconto (%)'))
            else
              Expanded(child: _PromoField(controller: _final, label: 'Valor final manual (R\$)')),
          ]),
          const SizedBox(height: 12),
          PromotionPriceCalculator(original: _original, discountPercent: _discountPct, finalPrice: _finalPrice),
        ],
      ),
    );
  }

  Widget _priceModeButton(_PriceMode mode, String label) {
    final active = _priceMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _priceMode = mode;
          if (mode == _PriceMode.discount) {
            _final.clear();
          } else {
            _discount.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _DS.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? _DS.ink : _DS.stone,
          ),
        ),
      ),
    );
  }
}

enum _PriceMode { discount, manualFinal }

InputDecoration _promoInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    hintStyle: const TextStyle(fontSize: 13, color: _DS.muted),
    labelStyle: const TextStyle(fontSize: 13, color: _DS.steel),
    filled: true,
    fillColor: _DS.canvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _DS.hairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _DS.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _DS.brandBlue, width: 1.6),
    ),
  );
}

class _PromoField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  const _PromoField({
    required this.controller,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: _DS.ink),
      decoration: _promoInputDecoration(
        labelText: label,
      ),
    );
  }
}

class PromotionProductsSelector extends StatelessWidget {
  final List<MenuItemsModel> menuItems;
  final Map<int, int> selected;
  final String query;
  final VoidCallback onChanged;
  const PromotionProductsSelector({super.key, required this.menuItems, required this.selected, required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final filtered = normalized.isEmpty ? const <MenuItemsModel>[] : menuItems.where((m) => (m.name ?? '').toLowerCase().contains(normalized)).take(8).toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _DS.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _DS.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected.isNotEmpty) ...[
            const Text('Itens adicionados', style: TextStyle(fontSize: 12, color: _DS.stone)),
            const SizedBox(height: 8),
            ...selected.entries.map((entry) {
              final item = menuItems.cast<MenuItemsModel?>().firstWhere((m) => m?.id == entry.key, orElse: () => null);
              if (item == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(10), border: Border.all(color: _DS.hairlineSoft)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Text(item.name ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                              ))),
                      Text(_money.format(item.price ?? 0), style: const TextStyle(fontSize: 12, color: _DS.stone)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 86,
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: entry.value,
                          underline: const SizedBox.shrink(),
                          items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('Qtd $v'))).toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            selected[entry.key] = v;
                            onChanged();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          selected.remove(entry.key);
                          onChanged();
                        },
                        icon: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Divider(height: 20, color: _DS.hairline),
          ],
          if (normalized.isEmpty)
            const Text('Comece digitando para pesquisar produtos.', style: TextStyle(fontSize: 12, color: _DS.stone))
          else if (filtered.isEmpty)
            const Text('Nenhum produto encontrado para essa busca.', style: TextStyle(fontSize: 12, color: _DS.stone))
          else
            ...filtered.map((item) {
              final id = item.id ?? 0;
              final alreadyAdded = selected.containsKey(id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                              )),
                          const SizedBox(height: 2),
                          Text(_money.format(item.price ?? 0), style: const TextStyle(fontSize: 12, color: _DS.stone)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: alreadyAdded
                          ? null
                          : () {
                              selected[id] = 1;
                              onChanged();
                            },
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: _DS.brandBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(alreadyAdded ? 'Adicionado' : 'Adicionar'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class PromotionPriceCalculator extends StatelessWidget {
  final double original;
  final double discountPercent;
  final double finalPrice;
  const PromotionPriceCalculator({super.key, required this.original, required this.discountPercent, required this.finalPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: _DS.hairlineSoft)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Valor original: ${_money.format(original)}', style: const TextStyle(fontSize: 13, color: _DS.stone)),
        const SizedBox(height: 4),
        Text('Desconto: ${discountPercent.isFinite ? discountPercent.toStringAsFixed(2) : '0.00'}%',
            style: const TextStyle(
              fontSize: 14,
            )),
        const SizedBox(height: 4),
        Text('Valor promocional: ${_money.format(finalPrice)}', style: const TextStyle(fontSize: 16, color: _DS.ink)),
      ]),
    );
  }
}
