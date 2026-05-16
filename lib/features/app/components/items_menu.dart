import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/features/app/components/side_menu.dart';
import 'package:provider/provider.dart';

List<ItemSideMenu> getItemSideMenu(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  final typeUser = authProvider.type;
  return [
    ItemSideMenu(
      description: "Dashboard",
      route: "/home",
      iconSelected: LucideIcons.home,
      icon: LucideIcons.home,
    ),
    if (typeUser == 2)
      ItemSideMenu(
        description: "Ação comercial",
        route: "/commercial-actions",
        iconSelected: LucideIcons.briefcase,
        icon: LucideIcons.briefcase,
      ),
    if (typeUser == 0 || typeUser == 1)
      ItemSideMenu(
        description: "Pagamentos",
        route: "/payments",
        iconSelected: LucideIcons.banknote,
        icon: LucideIcons.banknote,
      ),
    if (typeUser == 0 || typeUser == 1)
      ItemSideMenu(
        description: "Importar",
        route: "/financial",
        iconSelected: LucideIcons.folderUp,
        icon: LucideIcons.folderUp,
      ),
    if (typeUser == 0 || typeUser == 1)
      ItemSideMenu(
        description: "Usuários",
        route: "/users",
        iconSelected: LucideIcons.users,
        icon: LucideIcons.users,
      ),
  ];
}
