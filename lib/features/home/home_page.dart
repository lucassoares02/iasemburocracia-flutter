import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/features/onboarding/setup_wizard_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/services/http_service.dart';
import '../../core/state/app_state.dart';
import 'home_controller.dart';
import 'home_entity.dart';
import 'home_model.dart';
import 'home_repository.dart';
import 'home_usecase.dart';

part 'home_header.dart';
part 'home_kpis.dart';
part 'home_products.dart';
part 'home_charts.dart';
part 'home_orders_recent.dart';
part 'home_customers.dart';
part 'home_insights.dart';
part 'home_states.dart';
part 'home_search_analytics.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
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
  static const successSoft = Color(0xFFE8F8F1);
  static const danger = Color(0xFFE53935);
  static const dangerSoft = Color(0xFFFFEBEA);
  static const warningAccent = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF8E1);
  static const surfacePricing = Color(0xFFF5F3FF);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
}

// ─── Formatters ───────────────────────────────────────────────────────────────
final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _intFmt = NumberFormat.decimalPattern('pt_BR');
final _timeFmt = DateFormat('HH:mm', 'pt_BR');
final _dateChartFmt = DateFormat('dd/MM', 'pt_BR');

// ─── Helpers ──────────────────────────────────────────────────────────────────
Color _parseBrand(String? hex, {Color fallback = _DS.brandBlue}) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.replaceAll('#', '').trim();
  if (h.length != 6) return fallback;
  try {
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return fallback;
  }
}

String _greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

String _statusLabel(String? s) {
  switch (s) {
    case 'novo':
    case 'aguardando':
      return 'Novo';
    case 'confirmado':
      return 'Confirmado';
    case 'em_preparo':
    case 'preparo':
      return 'Em preparo';
    case 'pronto':
    case 'pronto_retirada':
      return 'Pronto';
    case 'entrega':
      return 'Em entrega';
    case 'entregue':
      return 'Entregue';
    case 'retirado':
      return 'Retirado';
    case 'cancelado':
      return 'Cancelado';
    case 'rejeitado':
      return 'Rejeitado';
    default:
      return s ?? '—';
  }
}

Color _statusColor(String? s) {
  switch (s) {
    case 'novo':
    case 'aguardando':
      return _DS.brandBlue;
    case 'confirmado':
      return const Color(0xFF6D28D9);
    case 'em_preparo':
    case 'preparo':
      return _DS.warningAccent;
    case 'pronto':
    case 'pronto_retirada':
      return const Color(0xFF7C3AED);
    case 'entrega':
      return const Color(0xFFB45309);
    case 'entregue':
      return _DS.successAccent;
    case 'retirado':
      return const Color(0xFF166534);
    case 'cancelado':
    case 'rejeitado':
      return _DS.danger;
    default:
      return _DS.stone;
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller = HomeController(StartState(), HomeUseCase(HomeRepository()));

  AuthController? _authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onRefreshRequest();
      // Sempre revalida o snapshot de onboarding ao entrar no /home, para
      // refletir alterações feitas em outras telas (ex.: cadastro de endereço
      // em business_information, edição de empresa, cardápio etc.).
      context.read<OnboardingProvider>().refresh(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthController>(context, listen: false);
    if (_authController == auth) return;
    _authController?.homeRefreshNotifier.removeListener(_onRefreshRequest);
    _authController = auth;
    _authController?.homeRefreshNotifier.addListener(_onRefreshRequest);
  }

  @override
  void dispose() {
    _authController?.homeRefreshNotifier.removeListener(_onRefreshRequest);
    controller.stateDashboard.dispose();
    super.dispose();
  }

  void _onRefreshRequest() {
    controller.loadDashboard();
  }

  Future<void> _refresh() async => controller.loadDashboard();

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();

    // Enquanto o onboarding não estiver concluído, o "Dashboard" exibe o
    // wizard de configuração inicial. Após concluído, mostra o dashboard
    // real com KPIs, gráficos, etc.
    if (!onboarding.isCompleted) {
      return const Scaffold(
        backgroundColor: _DS.surface,
        body: SetupWizardView(),
      );
    }

    return Scaffold(
      backgroundColor: _DS.surface,
      body: ValueListenableBuilder<StateApp>(
        valueListenable: controller.stateDashboard,
        builder: (context, state, _) {
          if (state is LoadingState || state is StartState) {
            return const _DashboardSkeleton();
          }
          if (state is ErrorState) {
            return _DashboardError(message: state.message, onRetry: _refresh);
          }
          if (state is SuccessState && state.data is DashboardModel) {
            return _DashboardContent(
              data: state.data as DashboardModel,
              onRefresh: _refresh,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Content layout ───────────────────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  final DashboardModel data;
  final Future<void> Function() onRefresh;
  const _DashboardContent({required this.data, required this.onRefresh});

  static const double _maxContentWidth = 1300.0;

  @override
  Widget build(BuildContext context) {
    final brand = _parseBrand(data.company?.brandColor);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: brand,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: true),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 1100;
            final medium = c.maxWidth >= 720;
            final basePadding = wide ? 32.0 : (medium ? 24.0 : 16.0);
            // Center the content at _maxContentWidth without breaking
            // the ListView's edge-to-edge scrolling.
            final extra = (c.maxWidth - _maxContentWidth) / 2;
            final horizontal = extra > basePadding ? extra : basePadding;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: 20,
              ),
              children: [
                _DashboardHeader(company: data.company as CompanyInfoModel?, brand: brand),
                const SizedBox(height: 24),
                _KpiTodaySection(today: data.today as PeriodStatsModel?, brand: brand),
                const SizedBox(height: 24),
                _ChartsRow(
                  sales: (data.salesChart ?? []).cast<SalesPointModel>(),
                  statusBreakdown: (data.statusBreakdown ?? []).cast<StatusBreakdownModel>(),
                  top5: (data.products?.top5 ?? []).cast<TopProductModel>(),
                  brand: brand,
                  wide: wide,
                  medium: medium,
                ),
                const SizedBox(height: 24),
                _KpiMonthSection(month: data.month as MonthStatsModel?, brand: brand),
                const SizedBox(height: 20),
                _KpiOperationSection(op: data.operation as OperationStatsModel?),
                if (data.insights != null && data.insights!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SmartInsights(insights: data.insights!.cast<InsightModel>()),
                ],
                const SizedBox(height: 24),
                _ProductsSection(
                  products: data.products as ProductsSectionModel?,
                  wide: wide,
                  medium: medium,
                ),
                const SizedBox(height: 24),
                _BottomRow(
                  recentOrders: (data.recentOrders ?? []).cast<RecentOrderModel>(),
                  clients: data.clients as ClientsSectionModel?,
                  brand: brand,
                  wide: wide,
                  medium: medium,
                ),
                const SizedBox(height: 24),
                _SearchAnalyticsSection(
                  companyId: data.company?.id,
                  wide: wide,
                  medium: medium,
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Generic section title ────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (iconColor ?? _DS.brandBlue).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: iconColor ?? _DS.brandBlue),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _DS.ink,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _DS.stone,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: child,
    );
  }
}
