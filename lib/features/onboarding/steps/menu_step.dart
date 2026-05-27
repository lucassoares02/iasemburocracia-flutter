import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/menu_categories/menu_categories_model.dart';
import 'package:portal_assoc/features/menu_categories/menu_categories_repository.dart';
import 'package:portal_assoc/features/menu_items/menu_items_model.dart';
import 'package:portal_assoc/features/menu_items/menu_items_repository.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_step_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuStep extends StatefulWidget {
  final OnboardingSnapshot snapshot;
  final Future<void> Function() onSaved;

  const MenuStep({
    super.key,
    required this.snapshot,
    required this.onSaved,
  });

  @override
  State<MenuStep> createState() => _MenuStepState();
}

class _MenuStepState extends State<MenuStep> {
  final _formKey = GlobalKey<FormState>();
  final _categoryCtrl = TextEditingController(text: 'Cardápio');
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  final _categoriesRepo = MenuCategoriesRepository();
  final _itemsRepo = MenuItemsRepository();

  bool _saving = false;
  bool _uploading = false;
  String? _serverError;

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;
    final mime = switch ((f.extension ?? 'jpg').toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    setState(() => _uploading = true);
    try {
      final resp = await _itemsRepo.uploadImage(f.bytes!, f.name, mime);
      if (resp.success && resp.data != null) {
        final url = resp.data['url'] as String?;
        if (url != null && mounted) setState(() => _imageUrlCtrl.text = url);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Garante existência de uma categoria com o nome informado, criando se preciso.
  /// Retorna o id da categoria a ser usada.
  Future<int?> _ensureCategory(int companyId, String name) async {
    try {
      final resp = await _categoriesRepo.findAll();
      if (resp.success && resp.data != null) {
        final list = (resp.data as List).cast<MenuCategoriesModel>();
        for (final c in list) {
          if (c.companyId == companyId && (c.name ?? '').trim().toLowerCase() == name.trim().toLowerCase()) {
            return c.id;
          }
        }
      }
    } catch (_) {}
    // Cria nova categoria
    final newCat = MenuCategoriesModel.fromJson({
      'company_id': companyId,
      'name': name.trim(),
      'sort_order': 1,
      'active': true,
    });
    final create = await _categoriesRepo.create(newCat);
    if (!create.success) return null;
    final data = create.data;
    if (data is Map && data['id'] != null) return data['id'] as int?;
    if (data is List && data.isNotEmpty && data.first is Map) {
      final first = data.first as Map;
      return first['id'] as int?;
    }
    // Refetch as fallback
    final refetch = await _categoriesRepo.findAll();
    if (refetch.success && refetch.data != null) {
      final list = (refetch.data as List).cast<MenuCategoriesModel>();
      for (final c in list) {
        if ((c.name ?? '').trim().toLowerCase() == name.trim().toLowerCase()) {
          return c.id;
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company') ?? 0;
      if (companyId == 0) {
        setState(() => _serverError = 'Empresa não encontrada.');
        return;
      }

      final categoryId = await _ensureCategory(companyId, _categoryCtrl.text.trim());
      if (categoryId == null) {
        setState(() => _serverError = 'Não foi possível criar/encontrar a categoria. Tente novamente.');
        return;
      }

      final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;

      final item = MenuItemsModel.fromJson({
        'company_id': companyId,
        'category_id': categoryId,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': price,
        'available': true,
        'image_url': _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
      });

      final resp = await _itemsRepo.create(item);
      if (!resp.success) {
        setState(() => _serverError = resp.message);
        return;
      }
      await widget.onSaved();
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.snapshot.menuItems.isNotEmpty;

    return SetupStepContainer(
      stepIndex: 3,
      descriptor: kSetupSteps[3],
      headlinePrefix: 'Etapa final',
      description: hasItems ? 'Seu cardápio já tem produtos cadastrados. Você pode finalizar a configuração.' : 'Cadastre o primeiro produto do seu cardápio. Você pode adicionar mais depois.',
      footer: Row(
        children: [
          if (_serverError != null)
            Expanded(
              child: Text(_serverError!, style: const TextStyle(color: OnboardingDS.danger, fontSize: 12)),
            )
          else
            const Spacer(),
          OnboardingPrimaryButton(onPressed: hasItems ? () => widget.onSaved() : _save, loading: _saving, isLast: true),
        ],
      ),
      child: hasItems ? _buildAlreadyDone() : _buildForm(),
    );
  }

  Widget _buildAlreadyDone() {
    final items = widget.snapshot.menuItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: OnboardingDS.successSoft,
            borderRadius: BorderRadius.circular(OnboardingDS.rMd),
            border: Border.all(color: OnboardingDS.successAccent.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: OnboardingDS.successAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Você tem ${items.length} produto${items.length == 1 ? "" : "s"} cadastrado${items.length == 1 ? "" : "s"}.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: OnboardingDS.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...items.take(5).map((it) => _MenuPreviewRow(item: it)),
        if (items.length > 5) ...[
          const SizedBox(height: 10),
          Text(
            '+${items.length - 5} produto${items.length - 5 == 1 ? "" : "s"}',
            style: const TextStyle(fontSize: 12, color: OnboardingDS.stone),
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImagePicker(
            url: _imageUrlCtrl.text.trim(),
            uploading: _uploading,
            onUpload: _uploadImage,
            onRemove: () => setState(() => _imageUrlCtrl.text = ''),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OnboardingFieldCard(
                  child: TextFormField(
                    controller: _categoryCtrl,
                    decoration: onboardingFieldDecoration(
                      'Categoria',
                      hint: 'Ex: Pizzas, Bebidas',
                      icon: LucideIcons.folder,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a categoria' : null,
                    style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 140,
                child: OnboardingFieldCard(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: onboardingFieldDecoration(
                      'Preço (R\$)',
                      hint: '0,00',
                      icon: LucideIcons.dollarSign,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').replaceAll(',', '.').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Preço inválido';
                      }
                      return null;
                    },
                    style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OnboardingFieldCard(
            child: TextFormField(
              controller: _nameCtrl,
              decoration: onboardingFieldDecoration(
                'Nome do produto',
                hint: 'Ex: Pizza Margherita',
                icon: LucideIcons.utensils,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
            ),
          ),
          const SizedBox(height: 10),
          OnboardingFieldCard(
            child: TextFormField(
              controller: _descCtrl,
              decoration: onboardingFieldDecoration(
                'Descrição',
                hint: 'Ingredientes, peso, observações...',
                icon: LucideIcons.alignLeft,
              ),
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final String url;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _ImagePicker({
    required this.url,
    required this.uploading,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = url.isNotEmpty;
    return GestureDetector(
      onTap: uploading ? null : onUpload,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 150,
        decoration: BoxDecoration(
          color: OnboardingDS.surface,
          borderRadius: BorderRadius.circular(OnboardingDS.rXl),
          border: Border.all(color: hasImage ? OnboardingDS.hairline : OnboardingDS.brandBlue, width: hasImage ? 1 : 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _emptyState()) else _emptyState(),
            if (uploading)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ),
            if (hasImage)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    onPressed: onRemove,
                    tooltip: 'Remover',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.imagePlus, size: 28, color: OnboardingDS.brandBlue),
          SizedBox(height: 8),
          Text(
            'Adicionar foto do produto',
            style: TextStyle(
              fontSize: 12,
              color: OnboardingDS.brandBlue,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'PNG, JPG ou WEBP · opcional',
            style: TextStyle(fontSize: 11, color: OnboardingDS.stone),
          ),
        ],
      ),
    );
  }
}

class _MenuPreviewRow extends StatelessWidget {
  final MenuItemsModel item;
  const _MenuPreviewRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OnboardingDS.surface,
          borderRadius: BorderRadius.circular(OnboardingDS.rMd),
          border: Border.all(color: OnboardingDS.hairlineSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: OnboardingDS.brandBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: (item.imageUrl ?? '').isEmpty
                  ? const Icon(LucideIcons.utensils, color: OnboardingDS.brandBlue, size: 18)
                  : Image.network(item.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.utensils, color: OnboardingDS.brandBlue, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: OnboardingDS.ink,
                ),
              ),
            ),
            Text(
              'R\$ ${(item.price ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(fontSize: 13, color: OnboardingDS.brandBlue),
            ),
          ],
        ),
      ),
    );
  }
}
