import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/supabase_auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _checkBypassFuture;

  @override
  void initState() {
    super.initState();
    _checkBypassFuture = _checkBypassUser();
  }

  Future<bool> _checkBypassUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store the bypass credentials for future use
      if (!prefs.containsKey('bypass_email')) {
        await prefs.setString('bypass_email', 'abdulssekyanzi@gmail.com');
        await prefs.setString('bypass_password', 'Su4at3#0');
      }
      
      final bypassEmail = prefs.getString('bypass_email');
      final bypassPassword = prefs.getString('bypass_password');
      
      if (bypassEmail == 'abdulssekyanzi@gmail.com' && bypassPassword == 'Su4at3#0') {
        final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
        return await auth.bypassAuth(bypassEmail!, bypassPassword!);
      }
    } catch (e) {
      print('Bypass check error: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkBypassFuture,
      builder: (context, snapshot) {
        // Still checking bypass status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Bypass successful
        if (snapshot.data == true) {
          return const HomeShell();
        }

        // Normal auth flow
        return Consumer<SupabaseAuthProvider>(
          builder: (context, auth, _) {
            // Show loading while checking auth state
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            // Navigate based on auth state
            return auth.isAuthenticated ? const HomeShell() : const LoginScreen();
          },
        );
      },
    );
  }
}