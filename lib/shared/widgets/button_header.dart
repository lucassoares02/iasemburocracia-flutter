import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';

class ButtonHeader extends StatefulWidget {
  const ButtonHeader({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<ButtonHeader> createState() => _ButtonHeaderState();
}

class _ButtonHeaderState extends State<ButtonHeader> {
  bool isHovering = false;
  @override
  Widget build(BuildContext context) {
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
        onTap: widget.enabled ? widget.onPressed : null,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Row(
          children: [
            if (widget.enabled == false)
              Tooltip(
                message: "Somente Plano Premium. Atualize o plano para ter acesso.",
                child: Icon(
                  LucideIcons.lock,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              widget.text,
              style: AppTextStyles.titleSmall.copyWith(
                fontSize: 15,
                color: isHovering && widget.enabled
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: widget.enabled ? 1.0 : 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
