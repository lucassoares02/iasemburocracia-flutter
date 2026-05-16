import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:flutter/material.dart';

class SpecialSearch extends StatefulWidget {
  SpecialSearch({super.key, this.onSearch});

  Function(String?)? onSearch;

  @override
  State<SpecialSearch> createState() => _SpecialSearchState();
}

class _SpecialSearchState extends State<SpecialSearch> {
  TextEditingController controllerSearch = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 35,
      child: TextField(
        controller: controllerSearch,
        onChanged: (value) {
          widget.onSearch!(value);
        },
        cursorColor: Theme.of(context).colorScheme.secondary,
        decoration: InputDecoration(
          fillColor: Theme.of(context).colorScheme.surface,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.withValues(alpha: 0.8),
          ),
          hintText: "Pesquisar",
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.small,
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.small,
            borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7), width: 2),
          ),
        ),
      ),
    );
  }
}
