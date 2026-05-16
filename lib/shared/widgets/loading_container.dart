import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingContainer extends StatelessWidget {
  const LoadingContainer({super.key, this.height = 130, this.width = 300, this.borderRadius});

  final double height;
  final double width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      highlightColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      period: const Duration(seconds: 1),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}
