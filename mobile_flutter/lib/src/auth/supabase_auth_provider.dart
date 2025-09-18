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
  bool get isAuthenticated => _user != null;

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
}