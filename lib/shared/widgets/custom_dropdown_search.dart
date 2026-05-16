import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_radius.dart';

class CustomDropdownSearch extends StatefulWidget {
  const CustomDropdownSearch({
    super.key,
    required this.items,
    required this.controller,
    required this.labelBuilder,
    this.hintText = 'Selecione',
    this.searchHintText = 'Pesquisar',
    this.overlayHeightFactor = 0.5,
    this.onChanged,
  });

  final List items;
  final SingleSelectController controller;

  final String Function(dynamic item) labelBuilder;
  final void Function(dynamic value)? onChanged;
  final String hintText;
  final String searchHintText;
  final double overlayHeightFactor;

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
  @override
  Widget build(BuildContext context) {
    return CustomDropdown.search(
      items: widget.items,
      controller: widget.controller,
      searchHintText: widget.searchHintText,
      hintText: widget.hintText,
      overlayHeight: MediaQuery.of(context).size.height * widget.overlayHeightFactor,
      decoration: CustomDropdownDecoration(
        hintStyle: const TextStyle(fontSize: 12),
        closedBorderRadius: AppRadius.small,
        expandedBorderRadius: AppRadius.small,
        closedErrorBorderRadius: AppRadius.small,
        closedBorder: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        ),
      ),
      closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      listItemPadding: EdgeInsets.zero,
      headerBuilder: (context, selectedItem, enabled) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(
            selectedItem != null ? widget.labelBuilder(selectedItem) : widget.hintText,
          ),
        );
      },
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return ListTile(
          title: Text(widget.labelBuilder(item)),
          selected: isSelected,
          onTap: onItemSelect,
        );
      },
      onChanged: (value) {
        setState(() {
          widget.controller.value = value;
        });
        widget.onChanged?.call(value);
      },
    );
  }
}
