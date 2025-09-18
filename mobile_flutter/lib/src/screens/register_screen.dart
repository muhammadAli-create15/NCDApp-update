import 'package:flutter/material.dart';
import '../auth/logout_helper.dart';
import 'package:provider/provider.dart';
import '../auth/supabase_auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController(text: 'user@example.com');
  final _pass = TextEditingController(text: 'password123');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<SupabaseAuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 12),
                  TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
                  const SizedBox(height: 16),
  ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final err = await auth.register(
                              _email.text.trim(),
                              _pass.text,
                              _firstName.text.trim(),
                              _lastName.text.trim(),
                            );
                            if (!mounted) return;
                            if (err == null) {
                              // Registration successful and user is automatically signed in
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Welcome! Account created and signed in.')),
                              );
                              if (!mounted) return;
                              // Navigate directly to the home dashboard
                              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                            } else {
                              // Show error regardless of type - no special handling for confirmation
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


