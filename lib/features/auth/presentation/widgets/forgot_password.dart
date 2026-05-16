import 'package:flutter_svg/svg.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';
import 'package:portal_assoc/shared/widgets/custom_button.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/l10n/l10n_extension.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:flutter/material.dart';
import 'package:portal_assoc/shared/widgets/container_message.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';

class ForgotPasswordWidget extends StatefulWidget {
  const ForgotPasswordWidget({super.key, required this.actionReturnLogin, this.authController});

  final void Function()? actionReturnLogin;
  final authController;

  @override
  State<ForgotPasswordWidget> createState() => _ForgotPasswordWidgetState();
}

class _ForgotPasswordWidgetState extends State<ForgotPasswordWidget> {
  TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: context.isDesktop
                      ? context.screenWidth * 0.3
                      : context.isTablet
                          ? context.screenWidth * 0.4
                          : context.screenWidth * 0.9,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 60,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.small,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/logo.svg",
                        height: 70,
                      ),
                      const Spacing(),
                      const Spacing(),
                      Text(context.l10n.forgot_password, style: AppTextStyles.title),
                      const Spacing(),
                      const Spacing(),
                      CustomInput(
                        title: context.l10n.email,
                        keyboardType: TextInputType.emailAddress,
                        controller: email,
                      ),
                      const Spacing(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: widget.actionReturnLogin,
                            child: Text(context.l10n.return_to_login),
                          )
                        ],
                      ),
                      const Spacing(),
                      ValueListenableBuilder(
                          valueListenable: widget.authController.stateForgot,
                          builder: (context, state, child) {
                            return Column(
                              children: [
                                if (state is SuccessState)
                                  const ContainerMessage(
                                    color: Colors.green,
                                    title: "E-mail enviado!",
                                    subtitle: "Você receberá um e-mail com a nova senha.",
                                  ),
                                if (state is SuccessState) const Spacing(),
                                CustomButton(
                                    label: context.l10n.send,
                                    icon: Icons.send_outlined,
                                    isLoading: state is LoadingState,
                                    onPressed: () async {
                                      await widget.authController.sendEmailForgotPassword(email.text);
                                    }),
                              ],
                            );
                          })
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
