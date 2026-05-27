import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/features/companies/companies_model.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_progress_card.dart';
import 'package:provider/provider.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OnboardingProvider>();
      if (!provider.hasLoaded && !provider.loading) {
        provider.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingDS.surface,
      body: RefreshIndicator(
        color: OnboardingDS.brandBlue,
        onRefresh: () => context.read<OnboardingProvider>().refresh(silent: true),
        child: Consumer<OnboardingProvider>(
          builder: (context, provider, _) {
            return ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OverviewHeader(
                            snapshot: provider.snapshot,
                            loading: provider.loading && !provider.hasLoaded,
                          ),
                          const SizedBox(height: 22),
                          SetupProgressCard(
                            snapshot: provider.snapshot,
                            loading: provider.loading && !provider.hasLoaded,
                          ),
                          const SizedBox(height: 22),
                          _QuickAccessGrid(snapshot: provider.snapshot),
                          const SizedBox(height: 22),
                          _QuickTips(snapshot: provider.snapshot),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _OverviewHeader extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  final bool loading;

  const _OverviewHeader({required this.snapshot, required this.loading});

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return OnboardingDS.brandBlue;
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return OnboardingDS.brandBlue;
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return OnboardingDS.brandBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CompaniesModel? company = snapshot.company;
    final accent = _parseHex(company?.brandColor);
    final name = (company?.name ?? '').trim();
    final greeting = _greeting();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.78),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LogoBadge(url: company?.logoUrl, fallbackName: name),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? 'Carregando...' : (name.isEmpty ? 'Seu Overview' : name),
                  style: const TextStyle(color: Colors.white, fontSize: 26, letterSpacing: -0.6, height: 1.15),
                ),
                const SizedBox(height: 4),
                Text(
                  snapshot.allComplete ? 'Ambiente configurado e pronto para receber pedidos.' : 'Você está a poucos passos de receber o primeiro pedido.',
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _OverviewStatusBadge(snapshot: snapshot),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia 👋';
    if (h < 18) return 'Boa tarde 👋';
    return 'Boa noite 👋';
  }
}

class _LogoBadge extends StatelessWidget {
  final String? url;
  final String fallbackName;
  const _LogoBadge({required this.url, required this.fallbackName});

  String _initials() {
    final name = fallbackName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl ? Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initialsWidget()) : _initialsWidget(),
    );
  }

  Widget _initialsWidget() {
    return Container(
      color: OnboardingDS.surface,
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: const TextStyle(
          fontSize: 26,
          color: OnboardingDS.ink,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _OverviewStatusBadge extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  const _OverviewStatusBadge({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isDone = snapshot.allComplete;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(OnboardingDS.rFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF22C55E) : const Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isDone ? 'Pronto para operar' : 'Configuração pendente',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick access grid (links com bloqueio elegante) ────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  const _QuickAccessGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _AccessTile(
        icon: LucideIcons.layoutDashboard,
        title: 'Configuração',
        subtitle: snapshot.allComplete ? 'Acompanhar progresso' : 'Faltam ${snapshot.totalSteps - snapshot.completedCount} etapas',
        accent: OnboardingDS.brandBlue,
        route: '/home',
        locked: false,
      ),
      _AccessTile(
        icon: LucideIcons.shoppingBag,
        title: 'Pedidos',
        subtitle: snapshot.menuComplete ? 'Acompanhe vendas em tempo real' : 'Cadastre um produto para receber',
        accent: const Color(0xFF7C3AED),
        route: '/orders',
        locked: !snapshot.menuComplete,
      ),
      _AccessTile(
        icon: LucideIcons.utensilsCrossed,
        title: 'Cardápio',
        subtitle: snapshot.menuComplete ? '${snapshot.menuItems.length} item${snapshot.menuItems.length == 1 ? "" : "s"}' : 'Cadastre o primeiro produto',
        accent: const Color(0xFFFF6B35),
        route: '/business-settings',
        locked: !snapshot.companyComplete,
      ),
      _AccessTile(
        icon: LucideIcons.users,
        title: 'Clientes',
        subtitle: 'Histórico e contatos',
        accent: const Color(0xFF0EA5E9),
        route: '/customers',
        locked: false,
      ),
      _AccessTile(
        icon: LucideIcons.store,
        title: 'Empresa',
        subtitle: snapshot.companyComplete ? 'Editar identidade visual' : 'Conclua os dados da empresa',
        accent: const Color(0xFF00B473),
        route: '/business-settings',
        locked: false,
      ),
      _AccessTile(
        icon: LucideIcons.creditCard,
        title: 'Pagamentos',
        subtitle: 'Métodos aceitos',
        accent: const Color(0xFFF59E0B),
        route: '/payment-methods',
        locked: !snapshot.companyComplete,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 980
          ? 3
          : c.maxWidth >= 640
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: cols == 1 ? 3.4 : (cols == 2 ? 2.5 : 2.2),
        children: tiles,
      );
    });
  }
}

class _AccessTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String route;
  final bool locked;

  const _AccessTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.route,
    required this.locked,
  });

  @override
  State<_AccessTile> createState() => _AccessTileState();
}

class _AccessTileState extends State<_AccessTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.locked) {
            context.go('/home');
          } else {
            context.go(widget.route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: OnboardingDS.canvas,
            borderRadius: BorderRadius.circular(OnboardingDS.rXl),
            border: Border.all(
              color: _hover ? widget.accent.withValues(alpha: 0.45) : OnboardingDS.hairlineSoft,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, size: 20, color: widget.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: OnboardingDS.ink,
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.locked) ...[
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.lock, size: 12, color: OnboardingDS.stone),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.locked ? OnboardingDS.stone : OnboardingDS.steel,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _hover ? 0.0625 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.arrowUpRight,
                  size: 16,
                  color: _hover ? widget.accent : OnboardingDS.stone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick tips / próximos passos ────────────────────────────────────────────

class _QuickTips extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  const _QuickTips({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.allComplete) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: OnboardingDS.successSoft,
          borderRadius: BorderRadius.circular(OnboardingDS.rXl),
          border: Border.all(color: OnboardingDS.successAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: OnboardingDS.successAccent, size: 22),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tudo certo por aqui!',
                    style: TextStyle(
                      fontSize: 14,
                      color: OnboardingDS.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Compartilhe o link do seu cardápio com seus clientes e comece a receber pedidos.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: OnboardingDS.steel,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final next = _nextStepHint(snapshot);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OnboardingDS.canvas,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(color: OnboardingDS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: OnboardingDS.brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(LucideIcons.lightbulb, color: OnboardingDS.brandBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próximo passo',
                  style: TextStyle(
                    fontSize: 12,
                    color: OnboardingDS.stone,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: OnboardingDS.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: OnboardingDS.steel,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(LucideIcons.arrowRight, size: 16),
            label: const Text('Continuar'),
            style: FilledButton.styleFrom(
              backgroundColor: OnboardingDS.brandBlue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({String title, String description}) _nextStepHint(OnboardingSnapshot snap) {
    if (!snap.personalComplete) {
      return (
        title: 'Complete seus dados pessoais',
        description: 'Adicione seu nome e telefone para personalizar a conta.',
      );
    }
    if (!snap.companyComplete) {
      return (
        title: 'Cadastre sua empresa',
        description: 'Logo, descrição e cor da marca aparecem no cardápio público.',
      );
    }
    if (!snap.addressComplete) {
      return (
        title: 'Configure endereço e entrega',
        description: 'Defina onde sua empresa fica e como cobra a taxa de entrega.',
      );
    }
    return (
      title: 'Crie seu primeiro produto',
      description: 'Sem produtos no cardápio, os clientes não podem fazer pedidos.',
    );
  }
}
