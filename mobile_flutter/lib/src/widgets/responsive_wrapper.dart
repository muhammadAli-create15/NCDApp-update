import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A wrapper widget that provides responsive behavior for its child
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidthMobile;
  final double maxWidthTablet;
  final double maxWidthDesktop;
  final EdgeInsetsGeometry mobilePadding;
  final EdgeInsetsGeometry tabletPadding;
  final EdgeInsetsGeometry desktopPadding;
  final bool centerContent;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.maxWidthMobile = double.infinity,
    this.maxWidthTablet = 768.0,
    this.maxWidthDesktop = 1200.0,
    this.mobilePadding = const EdgeInsets.all(16.0),
    this.tabletPadding = const EdgeInsets.all(24.0),
    this.desktopPadding = const EdgeInsets.all(32.0),
    this.centerContent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        double maxWidth;
        EdgeInsetsGeometry padding;

        // Determine layout constraints based on screen size
        if (ResponsiveHelper.isDesktop(context)) {
          maxWidth = maxWidthDesktop;
          padding = desktopPadding;
        } else if (ResponsiveHelper.isTablet(context)) {
          maxWidth = maxWidthTablet;
          padding = tabletPadding;
        } else {
          maxWidth = maxWidthMobile;
          padding = mobilePadding;
        }

        Widget content = Container(
          width: screenWidth,
          padding: padding,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: child,
            ),
          ),
        );

        // For desktop screens, we center the content horizontally
        if (centerContent && ResponsiveHelper.isDesktop(context)) {
          return Center(child: content);
        }

        return content;
      },
    );
  }
}