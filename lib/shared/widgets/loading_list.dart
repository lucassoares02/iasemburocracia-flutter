import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: AppSpacing.largePadding.top),
        child: const Column(
          children: [
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
            LoadingContainer(
              width: double.maxFinite,
              height: 50,
            ),
            Spacing(),
          ],
        ),
      ),
    );
  }
}
