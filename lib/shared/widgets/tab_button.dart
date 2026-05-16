import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  const TabButton({super.key, this.onTap, this.selected = false, required this.label, required this.icon});

  final void Function()? onTap;
  final bool selected;
  final String label;
  final IconData icon;

  @override
  State<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: widget.selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: widget.selected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
