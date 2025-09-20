import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/supabase_auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

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
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Set to initialized anyway so the UI can show the login screen
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Initializing...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Consumer<SupabaseAuthProvider>(
      builder: (context, auth, _) {
        // Show loading while checking auth state
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Loading...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }
        
        // Navigate based on auth state
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: auth.isAuthenticated 
            ? const HomeShell(key: ValueKey('home')) 
            : const LoginScreen(key: ValueKey('login')),
        );
      },
    );
  }
}