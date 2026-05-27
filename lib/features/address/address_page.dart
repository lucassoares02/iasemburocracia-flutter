import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/state/app_state.dart';
import '../../shared/widgets/google_map_widget.dart';
import 'address_controller.dart';
import 'address_model.dart';
import 'address_repository.dart';
import 'address_usecase.dart';

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
  static const danger = Color(0xFFE53935);
  static const dangerSoft = Color(0xFFFFEBEA);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
}

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final _controller = AddressController(
    StartState(),
    AddressUseCase(AddressRepository()),
  );

  @override
  void initState() {
    super.initState();
    _controller.findAll();
    _controller.stateDelete.addListener(_onDelete);
    _controller.stateCreate.addListener(_onCreate);
  }

  @override
  void dispose() {
    _controller.stateDelete.removeListener(_onDelete);
    _controller.stateCreate.removeListener(_onCreate);
    super.dispose();
  }

  void _onDelete() {
    final s = _controller.stateDelete.value;
    if (s is SuccessState) _controller.findAll();
    if (s is ErrorState) _showError('Falha ao remover endereço');
  }

  void _onCreate() {
    final s = _controller.stateCreate.value;
    if (s is SuccessState) {
      _controller.findAll();
      _showAddForm(false);
    }
    if (s is ErrorState) _showError('Falha ao salvar endereço');
  }

  bool _formVisible = false;

  void _showAddForm(bool visible) {
    if (mounted) setState(() => _formVisible = visible);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _DS.danger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1100;
          final medium = constraints.maxWidth >= 720;
          final h = constraints.maxWidth >= 1300 ? (constraints.maxWidth - 1300) / 2 : 0.0;
          final basePad = wide ? 32.0 : (medium ? 24.0 : 16.0);
          final horizontal = h > basePad ? h : basePad;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(onAdd: () => _showAddForm(true)),
                const SizedBox(height: 24),
                if (_formVisible)
                  _AddressFormCard(
                    controller: _controller,
                    onCancel: () => _showAddForm(false),
                  ),
                if (_formVisible) const SizedBox(height: 24),
                ValueListenableBuilder<StateApp>(
                  valueListenable: _controller.stateList,
                  builder: (context, state, _) {
                    if (state is LoadingState || state is StartState) {
                      return _ListSkeleton(wide: wide);
                    }
                    if (state is ErrorState) {
                      return _ErrorBanner(
                        message: state.message,
                        onRetry: _controller.findAll,
                      );
                    }
                    if (state is SuccessState) {
                      final items = (state.data as List).cast<AddressModel>();
                      if (items.isEmpty) {
                        return const _EmptyState();
                      }
                      return _AddressList(
                        items: items,
                        controller: _controller,
                        wide: wide,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _PageHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Endereços',
                style: TextStyle(
                  fontSize: 22,
                  color: _DS.ink,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gerencie os endereços vinculados à empresa',
                style: TextStyle(fontSize: 13, color: _DS.stone),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: _DS.brandBlue,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Novo endereço',
              style: TextStyle(
                fontSize: 14,
              )),
        ),
      ],
    );
  }
}

// ─── Address form card ────────────────────────────────────────────────────────
class _AddressFormCard extends StatefulWidget {
  final AddressController controller;
  final VoidCallback onCancel;

  const _AddressFormCard({required this.controller, required this.onCancel});

  @override
  State<_AddressFormCard> createState() => _AddressFormCardState();
}

class _AddressFormCardState extends State<_AddressFormCard> {
  final _labelCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _debounce = _Debouncer(delay: const Duration(milliseconds: 500));
  final _layerLink = LayerLink();

  List<PlaceSuggestion> _suggestions = [];
  PlaceDetails? _selectedDetails;
  bool _loadingSuggestions = false;
  String? _sessionToken;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    widget.controller.stateSuggestions.addListener(_onSuggestions);
    widget.controller.stateDetails.addListener(_onDetails);
  }

  @override
  void dispose() {
    _removeOverlay();
    _labelCtrl.dispose();
    _complementCtrl.dispose();
    _searchCtrl.dispose();
    _debounce.cancel();
    widget.controller.stateSuggestions.removeListener(_onSuggestions);
    widget.controller.stateDetails.removeListener(_onDetails);
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: _layerLink.leaderSize?.width ?? 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, (_layerLink.leaderSize?.height ?? 48) + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_DS.rLg),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.canvas,
                borderRadius: BorderRadius.circular(_DS.rLg),
                border: Border.all(color: _DS.hairlineSoft),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((s) {
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    borderRadius: BorderRadius.circular(_DS.rLg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: _DS.stone),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.mainText ?? s.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _DS.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.secondaryText != null) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    s.secondaryText!,
                                    style: const TextStyle(fontSize: 11, color: _DS.stone),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onSuggestions() {
    final s = widget.controller.stateSuggestions.value;
    if (!mounted) return;
    if (s is LoadingState) {
      setState(() => _loadingSuggestions = true);
    } else if (s is SuccessState) {
      setState(() {
        _loadingSuggestions = false;
        _suggestions = (s.data as List).cast<PlaceSuggestion>();
      });
      _showOverlay();
    } else {
      setState(() => _loadingSuggestions = false);
      _removeOverlay();
    }
  }

  void _onDetails() {
    final s = widget.controller.stateDetails.value;
    if (!mounted) return;
    if (s is SuccessState) {
      setState(() {
        _selectedDetails = s.data as PlaceDetails;
        _sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
      });
      _removeOverlay();
    }
  }

  void _onSearchChanged(String v) {
    if (v.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
      _removeOverlay();
      return;
    }
    _debounce.run(() {
      widget.controller.autocomplete(v.trim(), sessionToken: _sessionToken);
    });
  }

  void _selectSuggestion(PlaceSuggestion s) {
    _searchCtrl.text = s.description;
    _removeOverlay();
    widget.controller.details(s.placeId, sessionToken: _sessionToken);
  }

  Future<void> _submit() async {
    final d = _selectedDetails;
    if (d == null) return;

    final model = AddressModel(
      label: _labelCtrl.text.trim().isEmpty ? null : _labelCtrl.text.trim(),
      complement: _complementCtrl.text.trim().isEmpty ? null : _complementCtrl.text.trim(),
      street: d.street,
      number: d.number,
      neighborhood: d.neighborhood,
      city: d.city,
      state: d.state,
      zipCode: d.zipCode,
      country: d.country,
      lat: d.lat,
      lng: d.lng,
      placeId: d.placeId,
      formattedAddress: d.formattedAddress,
    );
    await widget.controller.create(model);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _DS.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_DS.rMd),
                ),
                child: const Icon(LucideIcons.mapPin, size: 16, color: _DS.brandBlue),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Novo endereço',
                  style: TextStyle(fontSize: 15, color: _DS.ink),
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(LucideIcons.x, size: 18, color: _DS.stone),
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search field with dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FieldLabel(text: 'Buscar endereço'),
              const SizedBox(height: 6),
              CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Ex: Rua das Flores, 123 — São Paulo',
                    hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                    prefixIcon: _loadingSuggestions
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue),
                            ),
                          )
                        : const Icon(LucideIcons.search, size: 16, color: _DS.stone),
                    filled: true,
                    fillColor: _DS.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_DS.rMd),
                      borderSide: const BorderSide(color: _DS.brandBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          if (_selectedDetails != null) ...[
            const SizedBox(height: 16),
            _SelectedAddressChip(details: _selectedDetails!),
          ],

          if (_selectedDetails != null && _selectedDetails!.lat != null && _selectedDetails!.lng != null) ...[
            const SizedBox(height: 16),
            GoogleMapWidget(
              lat: _selectedDetails!.lat!,
              lng: _selectedDetails!.lng!,
              height: 220,
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel(text: 'Rótulo (opcional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _labelCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Loja Principal, Depósito...',
                        hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.tag, size: 15, color: _DS.stone),
                        filled: true,
                        fillColor: _DS.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.brandBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel(text: 'Complemento (opcional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _complementCtrl,
                      decoration: InputDecoration(
                        hintText: 'Apto, Sala, Bloco...',
                        hintStyle: const TextStyle(color: _DS.muted, fontSize: 13),
                        prefixIcon: const Icon(LucideIcons.building2, size: 15, color: _DS.stone),
                        filled: true,
                        fillColor: _DS.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_DS.rMd),
                          borderSide: const BorderSide(color: _DS.brandBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.steel,
                  side: const BorderSide(color: _DS.hairline),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<StateApp>(
                valueListenable: widget.controller.stateCreate,
                builder: (context, state, _) {
                  final loading = state is LoadingState;
                  return FilledButton(
                    onPressed: (_selectedDetails == null || loading) ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.brandBlue,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      disabledBackgroundColor: _DS.brandBlue.withValues(alpha: 0.5),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar endereço', style: TextStyle()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Selected address chip ────────────────────────────────────────────────────
class _SelectedAddressChip extends StatelessWidget {
  final PlaceDetails details;
  const _SelectedAddressChip({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _DS.brandBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(_DS.rMd),
        border: Border.all(color: _DS.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, size: 15, color: _DS.brandBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              details.formattedAddress ?? '',
              style: const TextStyle(fontSize: 12, color: _DS.brandBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address list ─────────────────────────────────────────────────────────────
class _AddressList extends StatelessWidget {
  final List<AddressModel> items;
  final AddressController controller;
  final bool wide;

  const _AddressList({
    required this.items,
    required this.controller,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items
            .map((a) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 200) / 2,
                  child: _AddressCard(address: a, controller: controller),
                ))
            .toList(),
      );
    }
    return Column(
      children: items
          .map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AddressCard(address: a, controller: controller),
              ))
          .toList(),
    );
  }
}

// ─── Address card ─────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final AddressController controller;

  const _AddressCard({required this.address, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _DS.brandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(_DS.rMd),
                ),
                child: const Icon(LucideIcons.mapPin, size: 16, color: _DS.brandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address.label != null && address.label!.isNotEmpty)
                      Text(
                        address.label!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _DS.ink,
                        ),
                      ),
                    Text(
                      address.formattedAddress ?? _buildAddress(address),
                      style: TextStyle(
                        fontSize: address.label != null ? 12 : 14,
                        color: address.label != null ? _DS.stone : _DS.ink,
                        height: 1.4,
                      ),
                    ),
                    if (address.complement != null && address.complement!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        address.complement!,
                        style: const TextStyle(fontSize: 12, color: _DS.steel),
                      ),
                    ],
                  ],
                ),
              ),
              ValueListenableBuilder<StateApp>(
                valueListenable: controller.stateDelete,
                builder: (context, state, _) {
                  return IconButton(
                    onPressed: state is LoadingState ? null : () => _confirmDelete(context),
                    icon: const Icon(LucideIcons.trash2, size: 15, color: _DS.stone),
                    splashRadius: 18,
                    tooltip: 'Remover endereço',
                  );
                },
              ),
            ],
          ),
          if (address.lat != null && address.lng != null) ...[
            const SizedBox(height: 12),
            GoogleMapWidget(
              lat: address.lat!,
              lng: address.lng!,
              height: 160,
            ),
          ],
        ],
      ),
    );
  }

  String _buildAddress(AddressModel a) {
    final parts = <String>[
      if (a.street != null) a.street!,
      if (a.number != null) a.number!,
      if (a.neighborhood != null) a.neighborhood!,
      if (a.city != null) a.city!,
      if (a.state != null) a.state!,
    ];
    return parts.join(', ');
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover endereço',
            style: TextStyle(
              fontSize: 16,
            )),
        content: Text(
          'Tem certeza que deseja remover "${address.label ?? address.formattedAddress ?? 'este endereço'}"?',
          style: const TextStyle(fontSize: 14, color: _DS.steel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              controller.delete(address.id!);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _DS.danger,
              shape: const StadiumBorder(),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rXl),
            ),
            child: const Icon(LucideIcons.mapPinOff, size: 24, color: _DS.muted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum endereço cadastrado',
            style: TextStyle(fontSize: 15, color: _DS.ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clique em "Novo endereço" para adicionar',
            style: TextStyle(fontSize: 13, color: _DS.stone),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.dangerSoft,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 16, color: _DS.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 13, color: _DS.danger)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente', style: TextStyle(fontSize: 12, color: _DS.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _ListSkeleton extends StatelessWidget {
  final bool wide;
  const _ListSkeleton({required this.wide});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEF0F3),
      highlightColor: const Color(0xFFF7F8FA),
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _DS.canvas,
                borderRadius: BorderRadius.circular(_DS.rXl),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: _DS.steel,
      ),
    );
  }
}

// ─── Debouncer ────────────────────────────────────────────────────────────────
class _Debouncer {
  final Duration delay;
  Timer? _timer;

  _Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}
