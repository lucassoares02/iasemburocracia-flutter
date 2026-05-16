import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/app/components/cart_button.dart';
import 'package:portal_assoc/features/app/components/companies_dropdown.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/shared/widgets/button_header.dart';
import 'package:provider/provider.dart';

class Header extends StatefulWidget {
  const Header({super.key, required this.controller});

  final AuthController controller;

  @override
  State<Header> createState() => HeaderState();
}

class HeaderState extends State<Header> {
  int countState = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      height: 145,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1350),
              padding: const EdgeInsets.only(top: 36),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        "assets/images/logo.svg",
                        height: 40,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell), iconSize: 20),
                          const Spacing(),
                          IconButton(
                              onPressed: () {
                                context.go("/account");
                              },
                              icon: const Icon(LucideIcons.user),
                              iconSize: 20),
                        ],
                      ),
                    ],
                  ),
                  const Spacing(),
                  const Spacing(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ButtonHeader(
                              text: "Dashboard",
                              onPressed: () {
                                context.go("/home");
                              }),
                          const Spacing(),
                          ButtonHeader(
                              text: "Configuração do Negócio",
                              onPressed: () {
                                context.go("/business-settings");
                              }),
                          const Spacing(),
                          ButtonHeader(text: "Pedidos", enabled: false, onPressed: () {}),
                        ],
                      ),
                      Row(
                        children: [
                          ButtonHeader(text: "Clientes", enabled: false, onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
