import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';

/// Card de progresso reutilizável — usado pela [OverviewPage] e qualquer
/// outra tela que queira mostrar o status do onboarding.
class SetupProgressCard extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  final bool loading;
  final VoidCallback? onContinue;

  const SetupProgressCard({
    super.key,
    required this.snapshot,
    this.loading = false,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _ProgressSkeleton();

    final total = snapshot.totalSteps;
    final completed = snapshot.completedCount;
    final progress = total == 0 ? 0.0 : completed / total;
    final allDone = snapshot.allComplete;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: OnboardingDS.canvas,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
        border: Border.all(color: OnboardingDS.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: allDone ? OnboardingDS.successAccent.withValues(alpha: 0.12) : OnboardingDS.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  allDone ? LucideIcons.checkCircle2 : LucideIcons.rocket,
                  size: 18,
                  color: allDone ? OnboardingDS.successAccent : OnboardingDS.brandBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allDone ? 'Configuração concluída' : 'Complete sua configuração',
                      style: const TextStyle(
                        fontSize: 16,
                        color: OnboardingDS.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allDone ? 'Seu ambiente está pronto para receber pedidos.' : 'Faltam ${total - completed} etapa${total - completed == 1 ? "" : "s"} para começar a receber pedidos.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: OnboardingDS.steel,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!allDone)
                FilledButton.icon(
                  onPressed: onContinue ?? () => context.go('/home'),
                  icon: const Icon(LucideIcons.arrowRight, size: 16),
                  label: const Text('Continuar configuração'),
                  style: FilledButton.styleFrom(
                    backgroundColor: OnboardingDS.ink,
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
          const SizedBox(height: 22),
          // Progress meter
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(OnboardingDS.rFull),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      backgroundColor: OnboardingDS.hairlineSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(allDone ? OnboardingDS.successAccent : OnboardingDS.brandBlue),
                      minHeight: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: 13,
                  color: OnboardingDS.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Step list
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(kSetupSteps.length, (i) {
              final state = snapshot.stepStates[i];
              return _StepChip(
                meta: kSetupSteps[i],
                done: state,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final SetupStepDescriptor meta;
  final bool done;
  const _StepChip({required this.meta, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: done ? OnboardingDS.successAccent.withValues(alpha: 0.08) : OnboardingDS.surface,
        borderRadius: BorderRadius.circular(OnboardingDS.rFull),
        border: Border.all(
          color: done ? OnboardingDS.successAccent.withValues(alpha: 0.4) : OnboardingDS.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? LucideIcons.check : meta.icon,
            size: 14,
            color: done ? OnboardingDS.successAccent : OnboardingDS.stone,
          ),
          const SizedBox(width: 6),
          Text(
            meta.title,
            style: TextStyle(
              fontSize: 12.5,
              color: done ? OnboardingDS.ink : OnboardingDS.steel,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: OnboardingDS.hairlineSoft,
        borderRadius: BorderRadius.circular(OnboardingDS.rXl),
      ),
    );
  }
}
