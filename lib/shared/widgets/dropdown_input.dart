import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/shared/widgets/alert_dialog_base.dart';
import 'package:portal_assoc/shared/widgets/create_company.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropdownInput extends StatefulWidget {
  const DropdownInput({
    super.key,
    required this.items,
    this.color,
    this.height,
    this.title,
    this.onChanged,
    this.active = true,
    this.value,
    this.search,
    this.onCreate, // callback novo
  });

  final String? title;
  final List<DropdownMenuItem<Object>>? items;
  final Function? onChanged; // recomendado: ValueChanged<Object?>? onChanged;
  final bool active;
  final Object? value;
  final Color? color;
  final double? height;
  final Function(String)? search;
  final VoidCallback? onCreate;

  @override
  State<DropdownInput> createState() => DropdownInputState();
}

class DropdownInputState extends State<DropdownInput> {
  Object? selectedValue;
  int? type;
  static const String _createKey = '__create_new_company__';

  @override
  void initState() {
    super.initState();
    _getType();
    selectedValue = widget.value;
  }

  _getType() async {
    final prefs = await SharedPreferences.getInstance();
    type = prefs.getInt('type');
  }

  @override
  void didUpdateWidget(covariant DropdownInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        selectedValue = widget.value;
      });
    }
  }

  String _labelFromItem(DropdownMenuItem<Object> item) {
    final child = item.child;
    if (child is Text) {
      return child.data ?? '';
    }
    if (item.value != null) return item.value.toString();
    return child.toString();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ?? <DropdownMenuItem<Object>>[];

    final createButton = DropdownMenuItem<Object>(
      value: _createKey,
      enabled: true,
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: InkWell(
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onTap: () {
            Navigator.of(context).pop();
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialogBase(
                    content: CreateCompany(type: type),
                  );
                });
          },
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Criar empresa",
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );

    // junta o item de criar + itens reais
    final List<DropdownMenuItem<Object>> finalItems = [
      createButton,
      ...items,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Row(
            children: [
              Text(
                widget.title ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        if (widget.title != null) const SizedBox(height: 5),
        SizedBox(
          height: widget.height ?? 38,
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<Object>(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: "Inter",
              ),
              isExpanded: true,
              hint: const Text(
                'Selecione',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              items: finalItems,

              value: selectedValue,
              onChanged: widget.active
                  ? (value) {
                      if (value == _createKey) {
                        return;
                      }

                      setState(() {
                        selectedValue = value;
                      });
                      if (widget.onChanged != null) {
                        try {
                          widget.onChanged!(value);
                        } catch (_) {}
                      }
                    }
                  : null,
              // selectedItemBuilder: desfila apenas os itens "selecionáveis" (ignora o primeiro)
              selectedItemBuilder: (context) {
                // mapear somente os itens reais (pula o índice 0, que é o botão criar)
                // final selectable = finalItems.skip(1).toList();
                final selectable = finalItems.toList();
                if (selectable.isEmpty) {
                  return [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Text(
                          '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ];
                }

                return selectable.map((item) {
                  final label = _labelFromItem(item);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList();
              },
              buttonStyleData: ButtonStyleData(
                height: 55,
                padding: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: widget.color ?? Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.large,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(.25),
                    width: 2,
                  ),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 325,
                elevation: 1,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.medium,
                  color: widget.color ?? Theme.of(context).colorScheme.surface,
                ),
              ),
              iconStyleData: IconStyleData(
                icon: const Icon(LucideIcons.chevronDown),
                iconSize: 18,
                iconEnabledColor: Theme.of(context).colorScheme.onSurface,
                openMenuIcon: const Icon(LucideIcons.chevronUp),
              ),
              menuItemStyleData: const MenuItemStyleData(),
              // informar que o índice 0 é um item customizado (altura custom)
              // customItemsIndexes: const [0],
              // customItemsHeights: const [50],
              dropdownSearchData: widget.search == null
                  ? null
                  : DropdownSearchData(
                      searchInnerWidgetHeight: 48,
                      searchInnerWidget: Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          onChanged: widget.search,
                          decoration: InputDecoration(
                            hintText: 'Pesquisar...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
