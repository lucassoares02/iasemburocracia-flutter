import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_radius.dart';

class CustomSearch extends StatefulWidget {
  const CustomSearch({super.key, this.onSearch});

  final Function(String?)? onSearch;

  @override
  State<CustomSearch> createState() => CustomSearchState();
}

class CustomSearchState extends State<CustomSearch> {
  TextEditingController controllerSearch = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 35,
      child: TextField(
        controller: controllerSearch,
        onChanged: (value) {
          widget.onSearch!(value);
        },
        cursorColor: Theme.of(context).colorScheme.primary,
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
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7), width: 2),
          ),
        ),
      ),
    );
  }
}
