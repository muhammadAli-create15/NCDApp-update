import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/supabase_auth_provider.dart';
// import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to ensure this runs after the current build cycle completes
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
      await auth.initialize();
      
      // No longer needed: _isInitialized
      // if (mounted) {
      //   setState(() => _isInitialized = true);
      // }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Set to initialized anyway so the UI can show the login screen
      // No longer needed: _isInitialized
      // if (mounted) {
      //   setState(() => _isInitialized = true);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show dashboard (HomeShell) regardless of auth state
    return const HomeShell(key: ValueKey('home'));
  }
}