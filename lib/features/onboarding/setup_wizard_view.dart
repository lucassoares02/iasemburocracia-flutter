import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/onboarding_provider.dart';
import 'package:portal_assoc/features/onboarding/steps/address_step.dart';
import 'package:portal_assoc/features/onboarding/steps/company_step.dart';
import 'package:portal_assoc/features/onboarding/steps/menu_step.dart';
import 'package:portal_assoc/features/onboarding/steps/personal_step.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';
import 'package:provider/provider.dart';

/// View do wizard de configuração inicial — exibida dentro de [HomePage]
/// enquanto o onboarding não estiver concluído.
class SetupWizardView extends StatefulWidget {
  const SetupWizardView({super.key});

  @override
  State<SetupWizardView> createState() => _SetupWizardViewState();
}

class _SetupWizardViewState extends State<SetupWizardView> {
  int? _selectedStep;

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

  Future<void> _handleStepSaved() async {
    final provider = context.read<OnboardingProvider>();
    await provider.refresh(silent: false);
    if (!mounted) return;
    // Limpa seleção manual para deixar provider definir o próximo step
    setState(() => _selectedStep = null);
  }

  void _onStepTap(int i) {
    final provider = context.read<OnboardingProvider>();
    final states = provider.snapshot.stepStates;
    final reachable = states[i] || i <= provider.currentStep;
    if (!reachable) return;
    setState(() => _selectedStep = i);
  }

  int _resolveActiveStep(OnboardingProvider provider) {
    if (provider.snapshot.allComplete) return provider.totalSteps - 1;
    final manual = _selectedStep;
    if (manual != null) {
      // Se a step manualmente selecionada já foi concluída pelo refresh,
      // automaticamente avança para a próxima incompleta.
      final states = provider.snapshot.stepStates;
      if (states[manual]) return provider.currentStep.clamp(0, provider.totalSteps - 1);
      return manual;
    }
    return provider.currentStep.clamp(0, provider.totalSteps - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        if (provider.loading && !provider.hasLoaded) {
          return const _WizardSkeleton();
        }
        if (provider.snapshot.allComplete) {
          return _CompletionView(
            onGoOverview: () => context.go('/home'),
          );
        }

        final activeStep = _resolveActiveStep(provider);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SetupIntro(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      decoration: BoxDecoration(
                        color: OnboardingDS.canvas,
                        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
                        border: Border.all(color: OnboardingDS.hairlineSoft),
                      ),
                      child: SetupHorizontalTimeline(
                        snapshot: provider.snapshot,
                        activeStep: activeStep,
                        onStepTap: _onStepTap,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: KeyedSubtree(
                        key: ValueKey('step_$activeStep'),
                        child: _buildStepContent(provider, activeStep),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent(OnboardingProvider provider, int step) {
    switch (step) {
      case 0:
        return PersonalStep(snapshot: provider.snapshot, onSaved: _handleStepSaved);
      case 1:
        return CompanyStep(snapshot: provider.snapshot, onSaved: _handleStepSaved);
      case 2:
        return AddressStep(snapshot: provider.snapshot, onSaved: _handleStepSaved);
      case 3:
        return MenuStep(snapshot: provider.snapshot, onSaved: _handleStepSaved);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Intro card ─────────────────────────────────────────────────────────────

class _SetupIntro extends StatelessWidget {
  const _SetupIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OnboardingDS.ink,
            Color(0xFF0F1226),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnboardingDS.brandBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.rocket, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuração inicial',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vamos preparar seu ambiente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Conclua as etapas abaixo para começar a receber pedidos pelo WhatsApp.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
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
}

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _WizardSkeleton extends StatelessWidget {
  const _WizardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimBox(140),
              const SizedBox(height: 20),
              _shimBox(110),
              const SizedBox(height: 20),
              _shimBox(420),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimBox(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: OnboardingDS.hairlineSoft,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
      ),
    );
  }
}

// ─── Completion view ────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final VoidCallback onGoOverview;
  const _CompletionView({required this.onGoOverview});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: OnboardingDS.successAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.checkCircle2, size: 44, color: OnboardingDS.successAccent),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seu ambiente está pronto!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: OnboardingDS.ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tudo configurado. Você já pode receber pedidos e acessar todos os módulos da plataforma.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: OnboardingDS.steel,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onGoOverview,
                icon: const Icon(LucideIcons.layoutDashboard, size: 18),
                label: const Text('Ir para o Overview'),
                style: FilledButton.styleFrom(
                  backgroundColor: OnboardingDS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
