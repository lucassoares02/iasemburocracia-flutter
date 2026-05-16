import 'package:portal_assoc/features/auth/presentation/widgets/forgot_password.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';
import 'package:portal_assoc/features/auth/presentation/widgets/login.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/utils/abstract_clip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final AuthController authController = Provider.of<AuthController>(context, listen: false);
  dynamic authState;

  @override
  Widget build(BuildContext context) {
    authState = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: ClipPath(
                clipper: AbstractClipper(),
                child: Container(
                  width: context.screenWidth * 0.6,
                  height: context.screenHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomLeft,
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    ),
                  ),
                ),
              ),
            ),
            authState.showForgotPassword
                ? ForgotPasswordWidget(
                    authController: authController,
                    actionReturnLogin: () {
                      authState.setForgotPassword(false);
                    })
                : ValueListenableBuilder(
                    valueListenable: authController.stateLogin,
                    builder: (context, value, child) {
                      return LoginWidget(
                        authController: authController,
                        actionForgotPassword: () {
                          authState.setForgotPassword(true);
                        },
                      );
                    })
          ],
        ),
      ),
    );
  }
}
