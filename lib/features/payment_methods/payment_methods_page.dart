import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/app_state.dart';
import 'payment_methods_controller.dart';
import 'payment_methods_repository.dart';
import 'payment_methods_usecase.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

class _DS {
  static const Color ink = Color(0xFF1C1C1E);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color stone = Color(0xFF8E91A0);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color success = Color(0xFF00B473);
  static const Color successSubtle = Color(0xFFDCFCE7);

  static const double rXl = 16.0;
  static const double rLg = 12.0;
  static const double rFull = 9999.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
}

// ─── Payment type catalog (type = integer stored in DB) ───────────────────────

class _PaymentType {
  final int id;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;

  const _PaymentType({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
  });
}

const List<_PaymentType> _kCatalog = [
  _PaymentType(id: 1, label: 'Cartão de Crédito', description: 'Visa, Mastercard, Elo e demais bandeiras', icon: Icons.credit_card, accent: Color(0xFF4262FF)),
  _PaymentType(id: 2, label: 'Cartão de Débito', description: 'Débito direto na conta bancária', icon: Icons.payment, accent: Color(0xFF00B473)),
  _PaymentType(id: 3, label: 'PIX', description: 'Transferência instantânea, disponível 24/7', icon: Icons.pix, accent: Color(0xFF00BCD4)),
  _PaymentType(id: 4, label: 'Dinheiro', description: 'Pagamento em espécie na entrega', icon: Icons.money, accent: Color(0xFF22C55E)),
  _PaymentType(id: 5, label: 'Vale Refeição', description: 'Alelo, Sodexo, VR e similares', icon: Icons.card_giftcard, accent: Color(0xFFFF9800)),
  _PaymentType(id: 6, label: 'Transferência', description: 'TED e DOC via banco tradicional', icon: Icons.account_balance, accent: Color(0xFF9C27B0)),
  _PaymentType(id: 7, label: 'Carteira Digital', description: 'PicPay, Mercado Pago e similares', icon: Icons.wallet, accent: Color(0xFFE91E63)),
  _PaymentType(id: 8, label: 'PayPal', description: 'Pagamentos internacionais via PayPal', icon: Icons.payments_outlined, accent: Color(0xFF003087)),
  _PaymentType(id: 9, label: 'Boleto', description: 'Boleto bancário com vencimento definido', icon: Icons.receipt_long, accent: Color(0xFFFF5722)),
  _PaymentType(id: 10, label: 'Apple Pay', description: 'Pagamento rápido para dispositivos Apple', icon: Icons.apple, accent: Color(0xFF1C1C1E)),
  _PaymentType(id: 11, label: 'Google Pay', description: 'Pagamento integrado com o Google', icon: Icons.g_mobiledata, accent: Color(0xFF4285F4)),
  _PaymentType(id: 12, label: 'Criptomoedas', description: 'Bitcoin, Ethereum e outras criptos', icon: Icons.currency_bitcoin, accent: Color(0xFFF7931A)),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late final PaymentMethodsController _ctrl = PaymentMethodsController(
    StartState(),
    PaymentMethodsUseCase(PaymentMethodsRepository()),
  );

  List<PaymentMethodsModel> _active = [];
  final Set<int> _loadingTypes = {};

  @override
  void initState() {
    super.initState();
    _ctrl.findAll();
    _ctrl.stateFindAll.addListener(_onFindAll);
  }

  @override
  void dispose() {
    _ctrl.stateFindAll.removeListener(_onFindAll);
    super.dispose();
  }

  void _onFindAll() {
    final state = _ctrl.stateFindAll.value;
    if (state is SuccessState && mounted) {
      setState(() {
        _active = (state.data as List).cast<PaymentMethodsModel>();
        _loadingTypes.clear();
      });
    }
  }

  bool _isActive(int typeId) => _active.any((m) => m.type == typeId);

  PaymentMethodsModel? _getActive(int typeId) {
    try {
      return _active.firstWhere((m) => m.type == typeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggle(int typeId) async {
    if (_loadingTypes.contains(typeId)) return;
    setState(() => _loadingTypes.add(typeId));

    final existing = _getActive(typeId);
    if (existing != null) {
      _ctrl.delete(existing.id!);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final companyId = prefs.getInt('company') ?? 0;
      final def = _kCatalog.firstWhere((c) => c.id == typeId);
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      _ctrl.create(
        PaymentMethodsModel.fromJson({
          'company_id': companyId,
          'type': typeId,
          'label': def.label,
          'description': def.description,
          'active': true,
        }),
        context,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final loaded = _ctrl.stateFindAll.value is SuccessState;
    final count = _active.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_DS.s6, _DS.s6, _DS.s6, _DS.s5),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formas de Pagamento',
                  style: TextStyle(
                    fontSize: 20,
                    color: _DS.ink,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ative os métodos aceitos pelo seu estabelecimento',
                  style: TextStyle(fontSize: 13, color: _DS.stone, height: 1.4),
                ),
              ],
            ),
          ),
          if (loaded) ...[
            const SizedBox(width: _DS.s4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: count > 0 ? _DS.successSubtle : _DS.surface,
                borderRadius: BorderRadius.circular(_DS.rFull),
                border: Border.all(
                  color: count > 0 ? _DS.success.withValues(alpha: 0.35) : _DS.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: count > 0 ? _DS.success : _DS.stone,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    count == 1 ? '1 ativo' : '$count ativos',
                    style: TextStyle(
                      fontSize: 12,
                      color: count > 0 ? _DS.success : _DS.stone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ValueListenableBuilder<StateApp>(
      valueListenable: _ctrl.stateFindAll,
      builder: (_, state, __) {
        if (state is StartState || state is LoadingState) return _buildSkeleton();
        if (state is ErrorState) return _buildError(state.message);
        return _buildGrid();
      },
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_DS.s6),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final cols = _colCount(constraints.maxWidth);
          final w = (constraints.maxWidth - (_DS.s4 * (cols - 1))) / cols;
          return Wrap(
            spacing: _DS.s4,
            runSpacing: _DS.s4,
            children: List.generate(
              12,
              (_) => SizedBox(
                width: w,
                child: Container(
                  height: 148,
                  decoration: BoxDecoration(
                    color: _DS.hairlineSoft,
                    borderRadius: BorderRadius.circular(_DS.rXl),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_DS.s6),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final cols = _colCount(constraints.maxWidth);
          final w = (constraints.maxWidth - (_DS.s4 * (cols - 1))) / cols;
          return Wrap(
            spacing: _DS.s4,
            runSpacing: _DS.s4,
            children: _kCatalog.map((type) {
              return SizedBox(
                width: w,
                child: _PaymentCard(
                  type: type,
                  active: _isActive(type.id),
                  loading: _loadingTypes.contains(type.id),
                  onTap: () => _toggle(type.id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 40, color: _DS.stone),
          const SizedBox(height: _DS.s3),
          const Text(
            'Erro ao carregar métodos',
            style: TextStyle(fontSize: 15, color: _DS.ink),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _DS.steel),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _DS.s5),
          FilledButton.icon(
            onPressed: () => _ctrl.findAll(),
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Tentar novamente'),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.ink,
              foregroundColor: _DS.canvas,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  int _colCount(double width) {
    if (width > 1100) return 4;
    if (width > 750) return 3;
    return 2;
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatefulWidget {
  const _PaymentCard({
    required this.type,
    required this.active,
    required this.loading,
    required this.onTap,
  });

  final _PaymentType type;
  final bool active;
  final bool loading;
  final VoidCallback onTap;

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final accent = widget.type.accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(_DS.s4),
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rXl),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.55)
                  : _hovered
                      ? _DS.hairline
                      : _DS.hairlineSoft,
              width: active ? 2.0 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ]
                : _hovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: active ? accent.withValues(alpha: 0.12) : _DS.surface,
                      borderRadius: BorderRadius.circular(_DS.rLg),
                    ),
                    child: Icon(
                      widget.type.icon,
                      size: 22,
                      color: active ? accent : _DS.stone,
                    ),
                  ),
                  const Spacer(),
                  // Toggle circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: active ? _DS.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? _DS.success : _DS.hairline,
                        width: 1.5,
                      ),
                    ),
                    child: widget.loading
                        ? Padding(
                            padding: const EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: active ? _DS.canvas : _DS.stone,
                            ),
                          )
                        : active
                            ? const Icon(Icons.check_rounded, size: 14, color: _DS.canvas)
                            : null,
                  ),
                ],
              ),
              const SizedBox(height: _DS.s3),
              Text(
                widget.type.label,
                style: TextStyle(
                  fontSize: 14,
                  color: active ? _DS.ink : _DS.slate,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.type.description,
                style: const TextStyle(fontSize: 11.5, color: _DS.stone, height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: _DS.s3),
              // Status chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? _DS.successSubtle : _DS.surface,
                  borderRadius: BorderRadius.circular(_DS.rFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? _DS.success : _DS.stone,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      active ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? _DS.success : _DS.stone,
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
