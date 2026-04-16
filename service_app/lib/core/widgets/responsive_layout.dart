import 'package:flutter/material.dart';

class AppBreakpoints {
  static const double mobileMax = 599;
  static const double tabletMax = 1023;

  static bool isMobile(double width) => width <= mobileMax;
  static bool isTablet(double width) => width > mobileMax && width <= tabletMax;
  static bool isDesktop(double width) => width > tabletMax;

  static double horizontalPadding(double width) {
    if (isDesktop(width)) {
      return 32;
    }

    if (isTablet(width)) {
      return 24;
    }

    return 16;
  }

  static int gridColumns(
    double width, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(width)) {
      return desktop;
    }

    if (isTablet(width)) {
      return tablet;
    }

    return mobile;
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = AppBreakpoints.horizontalPadding(width);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}
