import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';

class SetupStepDescriptor {
  final String title;
  final String subtitle;
  final IconData icon;
  const SetupStepDescriptor(this.title, this.subtitle, this.icon);
}

const kSetupSteps = <SetupStepDescriptor>[
  SetupStepDescriptor('Perfil', 'Seus dados de contato', LucideIcons.user),
  SetupStepDescriptor('Empresa', 'Identidade e marca', LucideIcons.store),
  SetupStepDescriptor('Endereço & entrega', 'Localização e taxas', LucideIcons.mapPin),
  SetupStepDescriptor('Cardápio', 'Primeiro produto', LucideIcons.utensilsCrossed),
];

class SetupHorizontalTimeline extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  final int activeStep;
  final ValueChanged<int>? onStepTap;

  const SetupHorizontalTimeline({
    super.key,
    required this.snapshot,
    required this.activeStep,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;
      return compact
          ? _CompactTimeline(
              snapshot: snapshot,
              activeStep: activeStep,
              onStepTap: onStepTap,
            )
          : _WideTimeline(
              snapshot: snapshot,
              activeStep: activeStep,
              onStepTap: onStepTap,
            );
    });
  }
}

// ─── Wide horizontal timeline (desktop / tablet) ─────────────────────────────

class _WideTimeline extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  final int activeStep;
  final ValueChanged<int>? onStepTap;

  const _WideTimeline({
    required this.snapshot,
    required this.activeStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final states = snapshot.stepStates;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(kSetupSteps.length, (i) {
          final meta = kSetupSteps[i];
          final done = states[i];
          final current = i == activeStep && !done;
          final reachable = done || i <= activeStep;
          final isLast = i == kSetupSteps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Flexible(
                  child: _StepNode(
                    index: i,
                    descriptor: meta,
                    done: done,
                    current: current,
                    reachable: reachable,
                    onTap: reachable && onStepTap != null ? () => onStepTap!(i) : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: _Connector(
                      done: done && states[i + 1] || done,
                      filled: done,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Compact timeline (mobile) ───────────────────────────────────────────────

class _CompactTimeline extends StatelessWidget {
  final OnboardingSnapshot snapshot;
  final int activeStep;
  final ValueChanged<int>? onStepTap;

  const _CompactTimeline({
    required this.snapshot,
    required this.activeStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalSteps;
    final completed = snapshot.completedCount;
    final progress = total == 0 ? 0.0 : completed / total;
    final currentMeta = kSetupSteps[activeStep.clamp(0, total - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: OnboardingDS.brandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(OnboardingDS.rFull),
              ),
              child: Text(
                'Passo ${activeStep + 1} de $total',
                style: const TextStyle(
                  fontSize: 11,
                  color: OnboardingDS.brandBlue,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '$completed/$total concluídas',
              style: const TextStyle(
                fontSize: 11,
                color: OnboardingDS.steel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: OnboardingDS.brandBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(currentMeta.icon, size: 18, color: OnboardingDS.brandBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentMeta.title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: OnboardingDS.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    currentMeta.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OnboardingDS.stone,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(OnboardingDS.rFull),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              backgroundColor: OnboardingDS.hairlineSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(OnboardingDS.brandBlue),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Step node ──────────────────────────────────────────────────────────────

class _StepNode extends StatefulWidget {
  final int index;
  final SetupStepDescriptor descriptor;
  final bool done;
  final bool current;
  final bool reachable;
  final VoidCallback? onTap;

  const _StepNode({
    required this.index,
    required this.descriptor,
    required this.done,
    required this.current,
    required this.reachable,
    required this.onTap,
  });

  @override
  State<_StepNode> createState() => _StepNodeState();
}

class _StepNodeState extends State<_StepNode> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.done
        ? OnboardingDS.successAccent
        : widget.current
            ? OnboardingDS.brandBlue
            : OnboardingDS.hairline;
    final labelColor = widget.done || widget.current ? OnboardingDS.ink : OnboardingDS.stone;

    final node = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: widget.done
            ? OnboardingDS.successAccent.withValues(alpha: 0.12)
            : widget.current
                ? OnboardingDS.brandBlue.withValues(alpha: 0.12)
                : OnboardingDS.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: dotColor,
          width: widget.current ? 2 : 1.2,
        ),
        boxShadow: widget.current
            ? [
                BoxShadow(
                  color: OnboardingDS.brandBlue.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: widget.done
            ? const Icon(LucideIcons.check, key: ValueKey('done'), color: OnboardingDS.successAccent, size: 18)
            : Icon(
                widget.descriptor.icon,
                key: ValueKey('icon_${widget.index}'),
                color: widget.current ? OnboardingDS.brandBlue : OnboardingDS.stone,
                size: 18,
              ),
      ),
    );

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _hover && widget.onTap != null ? 1.05 : 1,
              child: node,
            ),
            const SizedBox(height: 10),
            Text(
              widget.descriptor.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: widget.current ? FontWeight.bold : FontWeight.normal,
                color: labelColor,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.descriptor.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: OnboardingDS.stone,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Connector line between nodes ────────────────────────────────────────────

class _Connector extends StatelessWidget {
  final bool done;
  final bool filled;

  const _Connector({required this.done, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: filled ? OnboardingDS.successAccent.withValues(alpha: 0.55) : OnboardingDS.hairlineSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
