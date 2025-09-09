import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController(text: 'alice');
  final _pass = TextEditingController(text: 'Str0ngPass!');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final err = await auth.login(_user.text.trim(), _pass.text);
                    if (!mounted) return;
                    if (err == null) {
                      if (!mounted) return;
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
            child: Text(auth.isLoading ? '...' : 'Login'),
          ),
          TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Create account')),
        ]),
      ),
    );
  }
}


