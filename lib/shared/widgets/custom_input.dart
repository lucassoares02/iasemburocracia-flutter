import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';

class CustomInput extends StatefulWidget {
  const CustomInput({
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
    this.enabled,
    this.onChanged,
    this.onFieldSubmitted,
    this.autoFillHints,
    this.textInputAction,
    this.onEditingComplete,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.helperText,
    this.compactMode = false,
    this.floatingLabel = true,
  });

  final String? title;
  final IconData? icon;
  final int? maxLines;
  final bool? obscureText;
  final int? maxLenght;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool? enabled;
  final Iterable<String>? autoFillHints;
  final TextInputAction? textInputAction;
  final Function()? onEditingComplete;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final String? helperText;
  final bool compactMode;
  final bool floatingLabel;

  @override
  State<CustomInput> createState() => CustomInputState();
}

class CustomInputState extends State<CustomInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = widget.enabled ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null && !widget.floatingLabel)
          Padding(
            padding: EdgeInsets.only(
              bottom: widget.compactMode ? 6.0 : 8.0,
              left: 4.0,
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: _isFocused
                        ? colorScheme.primary
                        : _hasError
                            ? colorScheme.error
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.title!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _isFocused
                        ? colorScheme.primary
                        : _hasError
                            ? colorScheme.error
                            : colorScheme.onSurface.withValues(alpha: 0.87),
                  ),
                ),
              ],
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            boxShadow: _isFocused && isEnabled
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            focusNode: _focusNode,
            onEditingComplete: widget.onEditingComplete,
            onFieldSubmitted: widget.onFieldSubmitted,
            textInputAction: widget.textInputAction,
            validator: (value) {
              final error = widget.validator?.call(value);
              setState(() {
                _hasError = error != null;
                _errorText = error;
              });
              return error;
            },
            autofillHints: widget.autoFillHints,
            onChanged: widget.onChanged,
            obscureText: widget.obscureText ?? false,
            maxLength: widget.maxLenght,
            maxLines: widget.maxLines,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            inputFormatters: widget.inputFormatters,
            keyboardType: widget.keyboardType,
            controller: widget.controller,
            enabled: isEnabled,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            decoration: InputDecoration(
              labelText: widget.floatingLabel ? widget.title : null,
              labelStyle: TextStyle(
                color: _hasError ? colorScheme.error : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              floatingLabelStyle: TextStyle(
                color: _hasError
                    ? colorScheme.error
                    : _isFocused
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              helperText: widget.helperText,
              helperStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              errorStyle: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
              ),
              prefixIcon: widget.prefixIcon ??
                  (widget.icon != null && widget.floatingLabel
                      ? Icon(
                          size: 16,
                          widget.icon,
                          color: _hasError
                              ? colorScheme.error
                              : _isFocused
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                        )
                      : null),
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: isEnabled
                  ? _isFocused
                      ? colorScheme.primary.withValues(alpha: 0.03)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
              contentPadding: widget.compactMode ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12) : AppSpacing.mediumPadding,
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: colorScheme.error,
                  width: 2.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: _hasError ? colorScheme.error.withValues(alpha: 0.5) : colorScheme.outline.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: _hasError ? colorScheme.error : colorScheme.primary,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
