import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A responsive grid that adapts to different screen sizes
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileCrossAxisCount;
  final int? tabletCrossAxisCount;
  final int? desktopCrossAxisCount;
  final double childAspectRatio;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileCrossAxisCount,
    this.tabletCrossAxisCount,
    this.desktopCrossAxisCount,
    this.childAspectRatio = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        
        // Determine number of columns based on screen size
        if (ResponsiveHelper.isDesktop(context)) {
          crossAxisCount = desktopCrossAxisCount ?? 3;
        } else if (ResponsiveHelper.isTablet(context)) {
          crossAxisCount = tabletCrossAxisCount ?? 2;
        } else {
          crossAxisCount = mobileCrossAxisCount ?? 1;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive list that adapts to different screen sizes
class ResponsiveList extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveList({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.shrinkWrap = true,
    this.physics,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For desktop/tablet, use a different spacing
    final responsiveSpacing = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: spacing,
      tablet: spacing * 1.25,
      desktop: spacing * 1.5,
    );
    
    final responsivePadding = padding ?? EdgeInsets.all(
      ResponsiveHelper.responsiveValue(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
    
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: responsivePadding,
      itemCount: children.length,
      separatorBuilder: (_, __) => SizedBox(height: responsiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}