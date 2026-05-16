import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/providers/theme_provider.dart';
import 'package:portal_assoc/features/app/components/header.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:provider/provider.dart';

class AppPage extends StatefulWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  late final AuthController authController = Provider.of<AuthController>(context, listen: false);
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    setState(() {
      isDark = themeProvider.isDarkMode;
    });
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // const SideMenu(),
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.only(top: AppSpacing.extraLargePadding.top, left: AppSpacing.extraLargePadding.left, right: AppSpacing.extraLargePadding.right),
                child: Column(
                  children: [
                    Header(controller: authController),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
