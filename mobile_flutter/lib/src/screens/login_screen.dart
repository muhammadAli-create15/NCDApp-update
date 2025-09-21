import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/supabase_auth_provider.dart';
import '../utils/responsive_helper.dart';
import '../widgets/auth_button.dart';
import '../widgets/connectivity_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final auth = Provider.of<SupabaseAuthProvider>(context, listen: false);
      
      final error = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (error != null && mounted) {
        setState(() => _errorMessage = error);
      } else if (mounted) {
        // Success - check if bypass mode was activated
        if (auth.isBypassed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔓 Development mode activated'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        // Note: Navigation should be handled by AuthWrapper or parent widget
        // listening to auth changes. If not, add explicit navigation here:
        // Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Network error: Unable to connect to authentication service. Please check your connection and try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SupabaseAuthProvider>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Connectivity banner at the top
            const ConnectivityBanner(),
            
            // Main content
            Expanded(
              child: ResponsiveHelper.responsiveWidget(
                context: context,
                // Mobile layout (single column)
                mobile: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildLoginForm(auth, theme),
                  ),
                ),
                // Tablet/Desktop layout (centered with max width)
                tablet: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(32.0),
                      child: _buildLoginForm(auth, theme),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoginForm(SupabaseAuthProvider auth, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo or app icon
          Icon(
            Icons.health_and_safety,
            size: ResponsiveHelper.responsiveValue(
              context: context, 
              mobile: 80.0,
              tablet: 100.0,
              desktop: 120.0,
            ),
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),
          
          // App title
          Text(
            'NCD Mobile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, 28),
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // App subtitle
          Text(
            'Monitor and manage your health',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveHelper.fontSize(context, 16),
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 32),
          
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset functionality coming soon'),
                  ),
                );
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          
          // Error message
          if (_errorMessage != null || auth.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage ?? auth.errorMessage ?? 'An error occurred',
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          if (_errorMessage != null || auth.errorMessage != null)
            const SizedBox(height: 16),
          
          // Login button
          AuthButton(
            text: 'Login',
            onPressed: _login,
            isLoading: auth.isLoading,
          ),
          const SizedBox(height: 24),
          
          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: theme.hintColor),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/register');
                },
                child: const Text('Sign up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}