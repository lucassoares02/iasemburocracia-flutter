import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';

class AlertDialogBase extends StatefulWidget {
  const AlertDialogBase({super.key, required this.content});

  final Widget content;

  @override
  State<AlertDialogBase> createState() => _AlertDialogBaseState();
}

class _AlertDialogBaseState extends State<AlertDialogBase> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      elevation: 0.1,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.small,
      ),
      content: Container(padding: AppSpacing.largePadding, width: context.screenWidth * 0.4, height: context.screenHeight * 0.4, child: widget.content),
    );
  }
}
