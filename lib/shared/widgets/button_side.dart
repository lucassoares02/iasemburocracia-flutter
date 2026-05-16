import 'package:flutter/material.dart';
import 'package:portal_assoc/core/utils/spacing.dart';

class ButtonSide extends StatefulWidget {
  ButtonSide({
    Key? key,
    this.onTap,
    required this.description,
    this.icon,
    this.selected = false,
    this.newItem = false,
    this.borderLeft = true,
  }) : super(key: key);

  Function()? onTap;
  final String? description;
  final IconData? icon;
  final bool selected;
  final bool newItem;
  final bool borderLeft;

  @override
  State<ButtonSide> createState() => _ButtonSideState();
}

class _ButtonSideState extends State<ButtonSide> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => setState(() {
        _isHovered = true;
      }),
      onExit: (event) => setState(() {
        _isHovered = false;
      }),
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
        },
        child: Container(
          decoration: BoxDecoration(
            border: widget.borderLeft
                ? Border(
                    left: BorderSide(
                      color: widget.selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      width: 4,
                    ),
                  )
                : null,
          ),
          height: 50,
          width: 230,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) const Spacing(),
              if (widget.icon != null)
                Tooltip(
                  message: widget.description ?? '',
                  child: Icon(
                    size: 18,
                    widget.icon,
                    color: widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              if (widget.description != null) const SizedBox(width: 20),
              if (widget.description != null)
                Row(
                  children: [
                    Text(
                      widget.description!,
                      style: TextStyle(
                        fontWeight: widget.selected ? FontWeight.bold : FontWeight.w400,
                        fontSize: 14,
                        color: widget.selected
                            ? Theme.of(context).colorScheme.primary
                            : _isHovered
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurface,
                      ),
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
