import 'package:flutter/material.dart';

/// A utility class to manage responsiveness across the app
class ResponsiveHelper {
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < 768;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= 768 && 
      MediaQuery.of(context).size.width < 1200;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= 1200;

  /// Returns a value based on the screen size
  /// mobile: returns [mobile] value
  /// tablet: returns [tablet] value (or [mobile] if [tablet] is null)
  /// desktop: returns [desktop] value (or [tablet] if [desktop] is null, or [mobile] if both are null)
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Returns a responsive font size based on screen size
  static double fontSize(BuildContext context, double size) {
    if (isDesktop(context)) {
      return size * 1.2; // 20% larger on desktop
    } else if (isTablet(context)) {
      return size * 1.1; // 10% larger on tablet
    } else {
      return size;
    }
  }

  /// Returns a responsive padding based on screen size
  static EdgeInsetsGeometry padding(BuildContext context, {
    double mobile = 16.0,
    double? tablet,
    double? desktop,
  }) {
    return EdgeInsets.all(responsiveValue(
      context: context, 
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ));
  }
  
  /// Returns a responsive width percentage based on screen size
  static double widthPercent(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    final percent = responsiveValue(
      context: context, 
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    
    return width * percent;
  }

  /// Returns a responsive number of grid columns based on screen size
  static int gridColumns(BuildContext context) {
    return responsiveValue(
      context: context, 
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
  }

  /// Returns a responsive widget based on screen size
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Returns a responsive layout builder that adjusts based on screen width
  static Widget responsiveLayout({
    required BuildContext context,
    required WidgetBuilder mobile,
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop(context);
        } else if (constraints.maxWidth >= 768 && tablet != null) {
          return tablet(context);
        } else {
          return mobile(context);
        }
      },
    );
  }
}