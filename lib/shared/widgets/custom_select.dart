import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/utils/spacing.dart';

class CustomSelect extends StatefulWidget {
  const CustomSelect({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onPressButton,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback? onPressButton;
  final IconData? icon;

  @override
  State<CustomSelect> createState() => _CustomSelectState();
}

class _CustomSelectState extends State<CustomSelect> {
  bool isHovering = false;
  @override
  Widget build(BuildContext context) {
    Color colorSelected = widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface;
    // add hover effect
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovering = false;
        });
      },
      child: InkWell(
        onTap: widget.onPressButton,
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: AppSpacing.mediumPadding,
          decoration: BoxDecoration(
            color: widget.selected ? colorSelected.withValues(alpha: 0.2) : colorSelected.withValues(alpha: isHovering ? 0.06 : 0.05),
            borderRadius: AppRadius.small,
            border: Border.all(
              color: widget.selected ? colorSelected.withValues(alpha: 0.2) : colorSelected.withValues(alpha: isHovering ? 0.2 : 0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(widget.icon ?? LucideIcons.info, size: 20, color: widget.selected ? colorSelected.withValues(alpha: 1) : colorSelected.withValues(alpha: isHovering ? 0.5 : 0.3)),
                  const Spacing(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: widget.selected ? colorSelected : null,
                        ),
                      ),
                      Text(widget.subtitle, style: AppTextStyles.normal),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
