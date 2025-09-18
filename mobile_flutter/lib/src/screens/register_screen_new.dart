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
  final _firstName = TextEditingController(text: 'John');
  final _lastName = TextEditingController(text: 'Doe');
  final _email = TextEditingController(text: 'user@example.com');
  final _pass = TextEditingController(text: 'password123');
  String? _errorMsg;
  bool _showPassword = false;

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
                  TextField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                    ),
                  ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            setState(() => _errorMsg = null);
                            final err = await auth.register(
                              _email.text.trim(),
                              _pass.text,
                              _firstName.text.trim(),
                              _lastName.text.trim(),
                            );
                            if (!mounted) return;
                            if (err == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Welcome! Account created and signed in.')),
                              );
                              if (!mounted) return;
                              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                            } else {
                              // If email confirmation is required, guide user back to login
                              if (err.toLowerCase().contains('confirm')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(context, '/login');
                              } else {
                                setState(() => _errorMsg = err);
                              }
                            }
                          },
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Login'),
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