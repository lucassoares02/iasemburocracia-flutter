import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';

class ItemListTile extends StatefulWidget {
  ItemListTile({
    Key? key,
    this.onTap,
    required this.description,
    required this.icon,
    required this.selected,
    required this.iconSelected,
  }) : super(key: key);

  Function()? onTap;
  final String description;
  final IconData icon;
  final IconData iconSelected;
  final bool selected;

  @override
  State<ItemListTile> createState() => _ItemListTileState();
}

class _ItemListTileState extends State<ItemListTile> {
  // Color _iconColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // onEnter: (_) {
      //   setState(() {
      //     _iconColor = Theme.of(context).colorScheme.primary; // Cor do ícone quando o mouse entra
      //   });
      // },
      // onExit: (_) {
      //   setState(() {
      //     _iconColor = Colors.black;
      //   });
      // },
      child: ListTile(
        title: Text(
          widget.description,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: widget.selected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: Padding(
          padding: AppSpacing.horizontalPadding,
          child: Icon(
            size: 20,
            widget.selected ? widget.iconSelected : widget.icon,
            color: widget.selected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onTap: () {
          widget.onTap?.call(); // Chama o callback onTap, se fornecido
        },
      ),
    );
  }
}
