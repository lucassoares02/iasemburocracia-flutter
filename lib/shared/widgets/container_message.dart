import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';

class ContainerMessage extends StatefulWidget {
  const ContainerMessage({
    super.key,
    required this.color,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onPressButton,
  });

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onPressButton;
  final IconData? icon;

  @override
  State<ContainerMessage> createState() => _ContainerMessageState();
}

class _ContainerMessageState extends State<ContainerMessage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.mediumPadding,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.1),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: widget.color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(widget.icon ?? LucideIcons.info, color: widget.color.withValues(alpha: 0.5)),
              const Spacing(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTextStyles.titleSmall),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.info,
                  ),
                ],
              ),
            ],
          ),
          if (widget.onPressButton != null)
            SpecialButton(
              icon: LucideIcons.download,
              label: "Baixar exemplo",
              color: Colors.blue,
              onPressButton: widget.onPressButton,
            )
        ],
      ),
    );
  }
}
