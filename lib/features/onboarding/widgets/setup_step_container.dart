import 'package:flutter/material.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';

/// Card branco que envolve o conteúdo de uma etapa, com cabeçalho contextual,
/// área scrollável e footer de navegação. Usado por todas as steps do wizard.
class SetupStepContainer extends StatefulWidget {
  final int stepIndex;
  final SetupStepDescriptor descriptor;
  final String headlinePrefix;
  final String description;
  final Widget child;
  final Widget footer;

  const SetupStepContainer({
    super.key,
    required this.stepIndex,
    required this.descriptor,
    required this.headlinePrefix,
    required this.description,
    required this.child,
    required this.footer,
  });

  @override
  State<SetupStepContainer> createState() => _SetupStepContainerState();
}

class _SetupStepContainerState extends State<SetupStepContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          decoration: BoxDecoration(
            color: OnboardingDS.canvas,
            borderRadius: BorderRadius.circular(OnboardingDS.rXl),
            border: Border.all(color: OnboardingDS.hairlineSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const Divider(height: 1, color: OnboardingDS.hairlineSoft),
              Flexible(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: widget.child,
                  ),
                ),
              ),
              const Divider(height: 1, color: OnboardingDS.hairlineSoft),
              Padding(
                padding: const EdgeInsets.all(20),
                child: widget.footer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnboardingDS.brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.descriptor.icon, size: 20, color: OnboardingDS.brandBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: OnboardingDS.brandBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(OnboardingDS.rFull),
                      ),
                      child: Text(
                        '${widget.headlinePrefix} ${widget.stepIndex + 1}/${kSetupSteps.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: OnboardingDS.brandBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.descriptor.title,
                  style: const TextStyle(
                    fontSize: 22,
                    color: OnboardingDS.ink,
                    letterSpacing: -0.6,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 13.5,
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
}
