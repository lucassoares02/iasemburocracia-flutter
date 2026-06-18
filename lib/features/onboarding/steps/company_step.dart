import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/widgets/banner_crop_dialog.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_step_container.dart';
import 'package:portal_assoc/shared/widgets/upload_validation.dart';

const _kSwatches = <Color>[
  Color(0xFF1C1C1E),
  Color(0xFF4262FF),
  Color(0xFF00B473),
  Color(0xFFE53935),
  Color(0xFFFF6B35),
  Color(0xFF7C3AED),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
];

class CompanyStep extends StatefulWidget {
  final OnboardingSnapshot snapshot;
  final Future<void> Function() onSaved;

  const CompanyStep({
    super.key,
    required this.snapshot,
    required this.onSaved,
  });

  @override
  State<CompanyStep> createState() => _CompanyStepState();
}

class _CompanyStepState extends State<CompanyStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _bannerCtrl = TextEditingController();
  final _hexCtrl = TextEditingController();
  final _repo = CompaniesRepository();

  Color? _selectedColor;
  bool _uploading = false;
  bool _uploadingBanner = false;
  bool _saving = false;
  String? _serverError;
  String? _logoError;
  String? _bannerError;

  @override
  void initState() {
    super.initState();
    final c = widget.snapshot.company;
    _nameCtrl.text = c?.name ?? '';
    _descCtrl.text = c?.description ?? '';
    _phoneCtrl.text = c?.phone ?? '';
    _logoCtrl.text = c?.logoUrl ?? '';
    _bannerCtrl.text = c?.bannerUrl ?? '';
    _selectedColor = _parseHex(c?.brandColor);
    _hexCtrl.text = (c?.brandColor ?? '').replaceAll('#', '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _logoCtrl.dispose();
    _bannerCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return null;
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _colorHex(Color c) => c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  Future<void> _uploadLogo() async {
    setState(() => _logoError = null);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (e) {
      if (mounted) setState(() => _logoError = 'Não foi possível abrir o seletor de arquivos.');
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    // Validação preventiva (tamanho/formato) ANTES de enviar — evita o 413.
    final validation = validateImageUpload(f);
    if (!validation.ok) {
      if (!mounted) return;
      await showUploadErrorDialog(
        context,
        title: validation.title!,
        message: validation.message!,
        fileBytes: validation.fileBytes,
      );
      return;
    }
    final ext = (f.extension ?? '').toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };

    setState(() => _uploading = true);
    try {
      final resp = await _repo.uploadCompanyImage(f.bytes!, f.name, mime, type: 'logo');
      if (!resp.success) {
        if (mounted) {
          setState(() => _logoError = (resp.message.isNotEmpty)
              ? 'Falha no upload: ${resp.message}'
              : 'Falha no upload da imagem. Tente novamente.');
        }
        return;
      }
      final data = resp.data;
      String? url;
      if (data is Map) {
        final raw = data['url'];
        if (raw is String) url = raw;
      }
      if (url == null || url.isEmpty) {
        if (mounted) {
          setState(() => _logoError = 'O servidor não retornou a URL da imagem. Tente novamente.');
        }
        return;
      }
      if (mounted) {
        setState(() {
          _logoCtrl.text = url!;
          _logoError = null;
          _serverError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _logoError = 'Erro ao enviar imagem: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _uploadBanner() async {
    setState(() => _bannerError = null);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
    } catch (e) {
      if (mounted) setState(() => _bannerError = 'Não foi possível abrir o seletor de arquivos.');
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    // Validação preventiva (tamanho/formato) ANTES do recorte/upload — evita o
    // 413 do backend e dá feedback claro com o tamanho encontrado.
    final validation = validateImageUpload(f);
    if (!validation.ok) {
      if (!mounted) return;
      await showUploadErrorDialog(
        context,
        title: validation.title!,
        message: validation.message!,
        fileBytes: validation.fileBytes,
      );
      return;
    }

    // O banner é exibido em 21:9 — abre o editor de recorte antes de enviar.
    if (!mounted) return;
    final cropped = await showBannerCropDialog(context, f.bytes!);
    if (cropped == null) return; // usuário cancelou

    setState(() => _uploadingBanner = true);
    try {
      final resp = await _repo.uploadCompanyImage(cropped, 'banner.png', 'image/png', type: 'banner');
      if (!resp.success) {
        if (mounted) {
          setState(() => _bannerError = (resp.message.isNotEmpty)
              ? 'Falha no upload: ${resp.message}'
              : 'Falha no upload da imagem. Tente novamente.');
        }
        return;
      }
      final data = resp.data;
      String? url;
      if (data is Map) {
        final raw = data['url'];
        if (raw is String) url = raw;
      }
      if (url == null || url.isEmpty) {
        if (mounted) {
          setState(() => _bannerError = 'O servidor não retornou a URL da imagem. Tente novamente.');
        }
        return;
      }
      if (mounted) {
        setState(() {
          _bannerCtrl.text = url!;
          _bannerError = null;
          _serverError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _bannerError = 'Erro ao enviar imagem: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _uploadingBanner = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_logoCtrl.text.trim().isEmpty) {
      setState(() {
        _serverError = null;
        _logoError = 'É necessário enviar uma logo antes de continuar.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      final base = widget.snapshot.company;
      final hex = _hexCtrl.text.trim();
      final updated = CompaniesModel.fromJson({
        'id': base?.id,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'status': base?.status,
        'logo_url': _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
        'brand_color': hex.isEmpty ? null : '#${hex.toUpperCase()}',
        'banner_url': _bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim(),
        'ai_name': base?.aiName,
        'ai_gender': base?.aiGender,
        'ai_personality': base?.aiPersonality,
        'cuisine_type': base?.cuisineType,
        'dietary_restrictions': base?.dietaryRestrictions,
        'max_distance_meters_delivery': base?.maxDistanceMetersDelivery,
        'kilometer_price': base?.kilometerPrice,
        'max_distance_meters_free_delivery': base?.maxDistanceMetersFreeDelivery,
        'min_price_order': base?.minPriceOrder,
        'min_tax_delivery': base?.minTaxDelivery,
      });
      final resp = await _repo.update(updated);
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
    return SetupStepContainer(
      stepIndex: 1,
      descriptor: kSetupSteps[1],
      headlinePrefix: 'Etapa',
      description: 'Como sua empresa aparece para os clientes no cardápio público e no WhatsApp.',
      footer: Row(
        children: [
          if (_serverError != null)
            Expanded(
              child: Text(_serverError!, style: const TextStyle(color: OnboardingDS.danger, fontSize: 12)),
            )
          else
            const Spacer(),
          OnboardingPrimaryButton(onPressed: _save, loading: _saving, isLast: false),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BannerCard(
              bannerUrl: _bannerCtrl.text.trim(),
              uploading: _uploadingBanner,
              errorMessage: _bannerError,
              onUpload: _uploadBanner,
              onRemove: () => setState(() {
                _bannerCtrl.text = '';
                _bannerError = null;
              }),
            ),
            const SizedBox(height: 16),
            _LogoCard(
              logoUrl: _logoCtrl.text.trim(),
              uploading: _uploading,
              errorMessage: _logoError,
              onUpload: _uploadLogo,
              onRemove: () => setState(() {
                _logoCtrl.text = '';
                _logoError = null;
              }),
              accent: _selectedColor ?? OnboardingDS.brandBlue,
            ),
            const SizedBox(height: 16),
            OnboardingFieldCard(
              child: TextFormField(
                controller: _nameCtrl,
                decoration: onboardingFieldDecoration('Nome da empresa', hint: 'Ex: Pizzaria do João', icon: LucideIcons.store),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                style: const TextStyle(fontSize: 15, color: OnboardingDS.ink),
              ),
            ),
            const SizedBox(height: 12),
            OnboardingFieldCard(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: onboardingFieldDecoration('Telefone da empresa', hint: '(00) 00000-0000', icon: LucideIcons.phone),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  MaskedInputFormatter('(##) #####-####', allowedCharMatcher: RegExp(r'[0-9]')),
                ],
                style: const TextStyle(fontSize: 15, color: OnboardingDS.ink),
              ),
            ),
            const SizedBox(height: 12),
            OnboardingFieldCard(
              child: TextFormField(
                controller: _descCtrl,
                decoration: onboardingFieldDecoration('Descrição', hint: 'Conte um pouco sobre a sua empresa...', icon: LucideIcons.fileText),
                maxLines: 4,
                maxLength: 300,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Adicione uma descrição' : null,
                style: const TextStyle(fontSize: 15, color: OnboardingDS.ink),
              ),
            ),
            const SizedBox(height: 16),
            _ColorPickerCard(
              selectedColor: _selectedColor,
              hexCtrl: _hexCtrl,
              onColorSelected: (c) => setState(() {
                _selectedColor = c;
                _hexCtrl.text = _colorHex(c);
              }),
              onHexChanged: (v) {
                final p = _parseHex(v);
                if (p != null) setState(() => _selectedColor = p);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner card ──────────────────────────────────────────────────────────────

class _BannerCard extends StatefulWidget {
  final String bannerUrl;
  final bool uploading;
  final String? errorMessage;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _BannerCard({
    required this.bannerUrl,
    required this.uploading,
    required this.errorMessage,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  static const double _bannerHeight = 150;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasBanner = widget.bannerUrl.isNotEmpty;
    final hasError = (widget.errorMessage ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingDS.surface,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(
          color: hasError ? OnboardingDS.danger.withValues(alpha: 0.45) : OnboardingDS.hairlineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.image, size: 16, color: OnboardingDS.stone),
              SizedBox(width: 8),
              Text(
                'Banner do cardápio',
                style: TextStyle(fontSize: 14, color: OnboardingDS.ink, letterSpacing: -0.2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Opcional. Exibido no topo do seu cardápio público.',
            style: TextStyle(fontSize: 12, color: OnboardingDS.stone),
          ),
          const SizedBox(height: 8),
          UploadHints(recommendation: 'Recomendado: ${kBannerOutW.toInt()} × ${kBannerOutH.toInt()} px (21:9)'),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: (!widget.uploading && !hasBanner) ? widget.onUpload : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(OnboardingDS.rLg),
                child: SizedBox(
                  height: _bannerHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasBanner)
                        Image.network(
                          widget.bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      else
                        _placeholder(),
                      if (widget.uploading)
                        _loadingOverlay()
                      else if (_hover)
                        _hoverOverlay(hasBanner),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: OnboardingDS.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OnboardingDS.danger.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 14, color: OnboardingDS.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.errorMessage!,
                              style: const TextStyle(fontSize: 12, color: OnboardingDS.danger, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F2F4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.imagePlus, size: 28, color: Colors.grey[500]),
            const SizedBox(height: 8),
            const Text(
              'Adicionar banner',
              style: TextStyle(fontSize: 13, color: OnboardingDS.steel),
            ),
            const SizedBox(height: 2),
            Text(
              '${kBannerOutW.toInt()} × ${kBannerOutH.toInt()} px · 21:9',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
        ),
      ),
    );
  }

  Widget _hoverOverlay(bool hasBanner) {
    return Container(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _overlayButton(
              icon: hasBanner ? LucideIcons.refreshCw : LucideIcons.upload,
              label: hasBanner ? 'Trocar banner' : 'Enviar banner',
              onTap: widget.onUpload,
              filled: true,
            ),
            if (hasBanner) ...[
              const SizedBox(width: 8),
              _overlayButton(
                icon: LucideIcons.trash2,
                label: 'Remover',
                onTap: widget.onRemove,
                filled: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _overlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final fg = filled ? OnboardingDS.ink : Colors.white;
    final bg = filled ? Colors.white : Colors.transparent;
    return Material(
      color: bg,
      shape: StadiumBorder(side: filled ? BorderSide.none : const BorderSide(color: Colors.white70)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo card ────────────────────────────────────────────────────────────────

class _LogoCard extends StatelessWidget {
  final String logoUrl;
  final bool uploading;
  final String? errorMessage;
  final VoidCallback onUpload;
  final VoidCallback onRemove;
  final Color accent;

  const _LogoCard({
    required this.logoUrl,
    required this.uploading,
    required this.errorMessage,
    required this.onUpload,
    required this.onRemove,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl.isNotEmpty;
    final hasError = (errorMessage ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingDS.surface,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(
          color: hasError ? OnboardingDS.danger.withValues(alpha: 0.45) : OnboardingDS.hairlineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: uploading ? null : onUpload,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OnboardingDS.canvas,
                    border: Border.all(
                      color: hasError
                          ? OnboardingDS.danger
                          : (hasLogo ? OnboardingDS.hairline : accent),
                      width: hasLogo ? 1 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: uploading
                      ? const Center(
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: OnboardingDS.brandBlue)),
                        )
                      : hasLogo
                          ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, color: OnboardingDS.stone, size: 28))
                          : const Icon(LucideIcons.upload, color: OnboardingDS.brandBlue, size: 26),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logo da empresa',
                      style: TextStyle(
                        fontSize: 14,
                        color: OnboardingDS.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Obrigatório. Aparece no cardápio público e no WhatsApp.',
                      style: TextStyle(fontSize: 12, color: OnboardingDS.stone),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: uploading ? null : onUpload,
                          icon: Icon(hasLogo ? LucideIcons.refreshCw : LucideIcons.upload, size: 14),
                          label: Text(uploading ? 'Enviando...' : (hasLogo ? 'Trocar' : 'Enviar logo')),
                          style: FilledButton.styleFrom(
                            backgroundColor: OnboardingDS.brandBlue,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (hasLogo)
                          OutlinedButton.icon(
                            onPressed: uploading ? null : onRemove,
                            icon: const Icon(LucideIcons.trash2, size: 13),
                            label: const Text('Remover'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: OnboardingDS.steel,
                              side: const BorderSide(color: OnboardingDS.hairline),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: hasError
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: OnboardingDS.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: OnboardingDS.danger.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertCircle, size: 14, color: OnboardingDS.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: OnboardingDS.danger,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Color picker ─────────────────────────────────────────────────────────────

class _ColorPickerCard extends StatelessWidget {
  final Color? selectedColor;
  final TextEditingController hexCtrl;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<String> onHexChanged;

  const _ColorPickerCard({
    required this.selectedColor,
    required this.hexCtrl,
    required this.onColorSelected,
    required this.onHexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OnboardingDS.surface,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(color: OnboardingDS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.palette, size: 16, color: OnboardingDS.stone),
              SizedBox(width: 8),
              Text(
                'Cor principal da marca',
                style: TextStyle(
                  fontSize: 14,
                  color: OnboardingDS.ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Aplicada em botões e destaques do cardápio.',
            style: TextStyle(fontSize: 12, color: OnboardingDS.stone),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _kSwatches.map((c) {
              final selected = selectedColor?.toARGB32() == c.toARGB32();
              return GestureDetector(
                onTap: () => onColorSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: OnboardingDS.ink, width: 2.5) : null,
                  ),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 15) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selectedColor ?? Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OnboardingDS.hairline),
                ),
              ),
              const SizedBox(width: 10),
              const Text('#', style: TextStyle(fontSize: 15, color: OnboardingDS.slate)),
              const SizedBox(width: 4),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: hexCtrl,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: onHexChanged,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(fontSize: 14, color: OnboardingDS.ink),
                  decoration: InputDecoration(
                    hintText: '4262FF',
                    hintStyle: const TextStyle(color: OnboardingDS.muted, fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: OnboardingDS.hairline)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: OnboardingDS.brandBlue, width: 2)),
                    filled: true,
                    fillColor: OnboardingDS.canvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
