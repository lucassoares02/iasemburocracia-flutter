import 'package:flutter/material.dart';

extension ScreenSizeExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < 700;
  bool get isTablet => screenWidth >= 700 && screenWidth < 1388;
  bool get isDesktop => screenWidth >= 1388;
}
