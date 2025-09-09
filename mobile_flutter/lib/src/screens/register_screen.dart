import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _user = TextEditingController(text: 'alice');
  final _email = TextEditingController(text: 'a@a.com');
  final _pass = TextEditingController(text: 'Str0ngPass!');
  final _age = TextEditingController(text: '35');
  final _gender = TextEditingController(text: 'female');
  final _height = TextEditingController(text: '165');
  final _weight = TextEditingController(text: '68');
  final _waist = TextEditingController(text: '78');
  String _role = 'patient';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'Username')),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          DropdownButtonFormField(
            value: _role,
            items: const [
              DropdownMenuItem(value: 'patient', child: Text('Patient')),
              DropdownMenuItem(value: 'provider', child: Text('Provider')),
              DropdownMenuItem(value: 'worker', child: Text('Worker')),
            ],
            onChanged: (v) => setState(() => _role = v as String),
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          TextField(controller: _age, decoration: const InputDecoration(labelText: 'Age'), keyboardType: TextInputType.number),
          TextField(controller: _gender, decoration: const InputDecoration(labelText: 'Gender')),
          TextField(controller: _height, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: TextInputType.number),
          TextField(controller: _weight, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number),
          TextField(controller: _waist, decoration: const InputDecoration(labelText: 'Waist (cm)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final err = await auth.register({
                      'username': _user.text.trim(),
                      'password': _pass.text,
                      'email': _email.text.trim(),
                      'role': _role,
                      'age': int.tryParse(_age.text) ?? 0,
                      'gender': _gender.text,
                      'height_cm': double.tryParse(_height.text) ?? 0,
                      'weight_kg': double.tryParse(_weight.text) ?? 0,
                      'waist_cm': double.tryParse(_waist.text) ?? 0,
                    });
                    if (!mounted) return;
                    if (err == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered')));
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
            child: Text(auth.isLoading ? '...' : 'Submit'),
          ),
        ]),
      ),
    );
  }
}


