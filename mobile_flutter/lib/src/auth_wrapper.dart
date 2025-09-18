import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/supabase_auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAuthProvider>(
      builder: (context, auth, _) {
        // Show loading while checking auth state
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Navigate based on auth state
        return auth.isAuthenticated ? const HomeShell() : const LoginScreen();
      },
    );
  }
}