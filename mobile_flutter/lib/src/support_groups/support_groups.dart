import 'package:flutter/material.dart';

import 'screens/screens.dart';

/// Main entry point for the support groups feature
class SupportGroupsFeature {
  /// Returns the main screen for the support groups feature
  static Widget get mainScreen => const SupportGroupsScreen();
  
  /// Returns the route to the main screen for the support groups feature
  static MaterialPageRoute<void> get mainRoute => MaterialPageRoute(
        builder: (context) => const SupportGroupsScreen(),
      );
}