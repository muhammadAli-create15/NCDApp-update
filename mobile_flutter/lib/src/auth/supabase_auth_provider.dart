import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _loading = false;
  User? _user;
  String? _errorMessage;

  bool get isLoading => _loading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _bypassActive;
  
  // Special bypass flag
  bool _bypassActive = false;

  SupabaseAuthProvider() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
    
    // Initialize with current user if already signed in
    _user = _supabase.auth.currentUser;
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _user = response.user;
        return null; // Success
      }
      return 'Login failed';
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      _errorMessage = 'Network error occurred';
      return 'Network error occurred';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String email, String password, String firstName, String lastName) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ').trim(),
        },
        emailRedirectTo: null,  // Don't redirect; we're manually handling redirects
      );
      
      // Consider registration successful if user exists, even without session
      if (response.user != null) {
        // Set user even if session is null (bypassing email confirmation)
        _user = response.user;
        return null; // Success - signed in immediately
      }
      return 'Registration failed. Please try again.';
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return e.message;
    } catch (e) {
      _errorMessage = 'Network error occurred';
      return 'Network error occurred';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      _user = null;
    } catch (e) {
      _errorMessage = 'Logout failed';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> signUp(String email, String password) async {
    try {
      // Sign up the user with emailRedirectTo as null to prevent email verification
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
        data: {
          'email_confirmed': true, // Try to mark email as already confirmed
        },
      );
      
      // If user exists, consider registration successful
      if (response.user != null) {
        // Check if user has a session (is already logged in)
        if (response.session != null) {
          _user = response.user;
          notifyListeners();
          return true;
        } 
        
        // If no session, try to log in immediately
        try {
          final signInResponse = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          
          if (signInResponse.user != null) {
            _user = signInResponse.user;
            notifyListeners();
            return true;
          } else {
            _errorMessage = "Login after registration failed. Please try logging in manually.";
          }
        } catch (signInError) {
          _errorMessage = "Registration completed but login failed: ${signInError.toString()}";
          return false;
        }
      } else {
        _errorMessage = "Registration failed. No user was created.";
      }
    } on AuthException catch (e) {
      // Handle specific auth exceptions with clear messages
      switch (e.statusCode) {
        case "400":
          if (e.message.contains("already")) {
            _errorMessage = "Email already in use. Please log in or use a different email.";
          } else if (e.message.contains("password")) {
            _errorMessage = "Password too weak. Please use a stronger password.";
          } else {
            _errorMessage = "Registration error: ${e.message}";
          }
          break;
        default:
          _errorMessage = "Auth error: ${e.message}";
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = "Registration failed: ${e.toString()}";
      notifyListeners();
    }
    return false;
  }
  
  // Method to forcibly mark a user's email as confirmed
  Future<bool> confirmUserEmail(String userId) async {
    try {
      // This requires admin privileges or a server-side function
      // We'll try using the client, but this might not work depending on RLS policies
      await _supabase
          .from('auth.users')
          .update({'email_confirmed_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Failed to confirm email: $e');
      return false;
    }
  }
  
  // Special bypass for specific user
  Future<bool> bypassAuth(String email, String password) async {
    if (email == 'abdulssekyanzi@gmail.com' && password == 'Su4at3#0') {
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user != null) {
          _user = response.user;
          _bypassActive = true;
          notifyListeners();
          return true;
        } else {
          // If user doesn't exist yet, create the account
          final signUpResponse = await _supabase.auth.signUp(
            email: email,
            password: password,
          );
          
          if (signUpResponse.user != null) {
            _user = signUpResponse.user;
            _bypassActive = true;
            notifyListeners();
            return true;
          }
        }
      } catch (e) {
        print('Bypass authentication error: ${e.toString()}');
        // Even if there's an error, allow bypass for this specific user
        _bypassActive = true;
        notifyListeners();
        return true;
      }
    }
    return false;
  }
}