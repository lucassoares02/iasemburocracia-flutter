import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';

class InputComponent extends StatefulWidget {
  InputComponent({
    super.key,
    this.title,
    this.icon,
    this.maxLines = 1,
    this.maxLenght = 100,
    this.keyboardType,
    this.inputFormatters,
    this.hint,
    required this.controller,
    this.suffixIcon,
    this.onSubmitted,
    this.required,
    this.enabled,
    this.focusedBorder,
    this.onChanged,
  });

  String? title;
  IconData? icon;
  int? maxLines;
  int? maxLenght;
  TextEditingController? controller;
  String? hint;
  TextInputType? keyboardType;
  List<TextInputFormatter>? inputFormatters;
  Function(String)? onChanged;
  Widget? suffixIcon;
  Function(String)? onSubmitted;
  bool? enabled;
  InputBorder? focusedBorder;
  bool? required;

  @override
  State<InputComponent> createState() => InputComponentState();
}

class InputComponentState extends State<InputComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.title != null)
          Row(
            children: [
              Text(
                widget.title!,
                style: const TextStyle(),
              ),
              if (widget.required == true) ...[
                const SizedBox(width: 2),
                const Text(
                  "*",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ]
            ],
          ),
        if (widget.title != null) const SizedBox(height: 5),
        SizedBox(
          height: widget.title != null ? 38 : 30,
          child: TextField(
            onSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            maxLength: widget.maxLenght,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null, // Oculta a contagem
            inputFormatters: widget.inputFormatters,
            keyboardType: widget.keyboardType,
            controller: widget.controller,
            cursorColor: Theme.of(context).primaryColor,
            enabled: widget.enabled ?? true,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontWeight: FontWeight.w200,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.7,
                    ),
              ),
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: Theme.of(context).colorScheme.background,
              contentPadding: AppSpacing.horizontalPadding,
              disabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
              ),
              focusedBorder: widget.focusedBorder ??
                  OutlineInputBorder(
                    borderRadius: AppRadius.small,
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7), width: 1),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
