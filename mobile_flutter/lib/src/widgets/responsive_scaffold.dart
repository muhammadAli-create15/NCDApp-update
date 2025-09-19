import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

/// A responsive scaffold that adapts to different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  
  const ResponsiveScaffold({
    Key? key,
    required this.title,
    this.actions = const [],
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottom,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    // For desktop/tablet, use a different layout with a persistent drawer
    if (isDesktop || isTablet) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: centerTitle,
          actions: actions,
          bottom: bottom,
          // Larger elevation for desktop
          elevation: isDesktop ? 4.0 : 2.0,
        ),
        // For desktop, use a Row layout with the drawer content always visible
        body: isDesktop && drawer != null
            ? Row(
                children: [
                  // Permanent drawer for desktop
                  SizedBox(
                    width: 250, // Fixed width drawer
                    child: Drawer(
                      child: drawer,
                    ),
                  ),
                  // Expanded body content
                  Expanded(child: body),
                ],
              )
            : body,
        // For tablets, use a standard drawer
        drawer: isDesktop ? null : drawer,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: isDesktop ? null : bottomNavigationBar,
      );
    }
    
    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
        bottom: bottom,
      ),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}