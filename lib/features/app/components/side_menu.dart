import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/app/components/item_list_tile.dart';
import 'package:portal_assoc/features/app/components/items_menu.dart';
import 'package:provider/provider.dart';

class ItemSideMenu {
  final String description;
  final IconData icon;
  final IconData iconSelected;
  final String route;

  ItemSideMenu({
    required this.description,
    required this.icon,
    required this.iconSelected,
    required this.route,
  });
}

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  ValueNotifier<int> index = ValueNotifier(0);
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 230,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceBright,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            const Spacing(),
            Container(
              width: double.maxFinite,
              padding: AppSpacing.mediumPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/images/logo.svg",
                    height: 40,
                  ),
                ],
              ),
            ),
            const Spacing(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder(
                    valueListenable: index,
                    builder: (contextIndex, stateIndex, childIndex) {
                      index.value = getItemSideMenu(context).indexWhere((item) => item.route == GoRouter.of(context).state.fullPath);

                      return Column(
                          children: getItemSideMenu(context).asMap().entries.map((item) {
                        return ItemListTile(
                          description: item.value.description,
                          icon: item.value.icon,
                          iconSelected: item.value.iconSelected,
                          selected: GoRouter.of(context).state.fullPath == item.value.route,
                          onTap: () {
                            index.value = item.key;
                            context.go(item.value.route);
                          },
                        );
                      }).toList());
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ItemListTile(
                        selected: false,
                        iconSelected: Icons.logout,
                        description: "Sair",
                        icon: Icons.logout_outlined,
                        onTap: () async {
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          await authProvider.logout();
                          if (context.mounted) {
                            context.go('/');
                          }
                        },
                      ),
                      const Spacing(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
