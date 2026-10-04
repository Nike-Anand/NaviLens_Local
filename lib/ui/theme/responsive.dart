import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isSmallPhone(BuildContext context) {
    return width(context) < 360;
  }

  static bool isPhone(BuildContext context) {
    return width(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= 600;
  }

  static double horizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 340) return 16;
    if (w < 400) return 20;
    if (w < 600) return 24;
    if (w < 900) return 32;

    return 48;
  }

  static double maxContentWidth(BuildContext context) {
    final w = width(context);

    if (w >= 1200) return 840;
    if (w >= 900) return 760;
    if (w >= 600) return 680;

    return double.infinity;
  }

  static double adaptive(double value) {
    return value;
  }
}