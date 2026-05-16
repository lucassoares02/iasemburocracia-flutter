import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:flutter/material.dart';

enum ButtonType { filled, tonal, outlined }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final ButtonType type;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.type = ButtonType.filled,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = _getButtonStyle(context);

    return SizedBox(
      height: 45,
      width: double.infinity,
      child: _buildButton(style),
    );
  }

  Widget _buildButton(ButtonStyle style) {
    final Widget content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: isDisabled ? Colors.grey : Colors.white),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(fontFamily: "Inter", color: isDisabled ? Colors.grey : Colors.white)),
            ],
          );

    final VoidCallback? action = (isDisabled || isLoading) ? null : onPressed;

    switch (type) {
      case ButtonType.filled:
        return ElevatedButton(
          onPressed: action,
          style: style,
          child: content,
        );
      case ButtonType.tonal:
        return FilledButton.tonal(
          onPressed: action,
          style: style,
          child: content,
        );
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: action,
          style: style,
          child: content,
        );
    }
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    const rounded = RoundedRectangleBorder(
      borderRadius: AppRadius.small,
    );

    return switch (type) {
      ButtonType.filled => ElevatedButton.styleFrom(
          shape: rounded,
        ),
      ButtonType.tonal => FilledButton.styleFrom(
          shape: rounded,
        ),
      ButtonType.outlined => OutlinedButton.styleFrom(
          shape: rounded,
        ),
    };
  }
}
