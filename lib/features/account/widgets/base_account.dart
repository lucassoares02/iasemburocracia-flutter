import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';

class BaseAccount extends StatefulWidget {
  const BaseAccount({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  State<BaseAccount> createState() => _BaseAccountState();
}

class _BaseAccountState extends State<BaseAccount> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.extraLargePadding.right),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Text(widget.title, style: AppTextStyles.title),
              ],
            ),
            const SizedBox(height: 20),
            widget.child,
          ],
        ),
      ),
    );
  }
}
