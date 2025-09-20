import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _loading = false;
  User? _user;
  String? _errorMessage;
  bool _initialized = false;

  bool get isLoading => _loading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _initialized;
  
  SupabaseAuthProvider() {
    // Initialize is called explicitly from AuthWrapper
  }
  
  Future<void> initialize() async {
    if (_initialized) return; // Prevent duplicate initialization
    
    _loading = true;
    // Don't notify listeners during initialization to avoid build-phase errors
    
    try {
      // Verify that Supabase URL is reachable
      final supabaseUrl = SupabaseConfig.url;
      debugPrint('Using Supabase URL: $supabaseUrl');
      
      // Check if the URL appears to be a placeholder or example
      if (supabaseUrl.contains('your-project-id') || 
          supabaseUrl.isEmpty ||
          supabaseUrl.contains('kgekayzazzgvwyjhbaiy')) {
        debugPrint('WARNING: Using what appears to be a placeholder Supabase URL. Authentication will likely fail.');
      }
      
      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });
      
      // Initialize with current user if already signed in
      _user = _supabase.auth.currentUser;
      
      // Verify session is still valid
      if (_user != null) {
        try {
          // Use session from currentSession
          final sessionData = _supabase.auth.currentSession;
          if (sessionData != null && !sessionData.isExpired) {
            _user = sessionData.user;
          } else {
            // Attempt to refresh the session
            try {
              final refreshResponse = await _supabase.auth.refreshSession();
              _user = refreshResponse.session?.user;
            } catch (refreshError) {
              debugPrint('Session refresh error: $refreshError');
              _user = null;
            }
          }
          
          if (_user == null) {
            // No valid session exists
            debugPrint('No valid session found');
          }
        } catch (e) {
          // Session expired or invalid, clear user
          _user = null;
          debugPrint('Session validation error: $e');
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      debugPrint('Trying simplified user registration as a workaround');
    } finally {
      _initialized = true;
      _loading = false;
      // Use Future.microtask to ensure this happens after the build cycle
      Future.microtask(() => notifyListeners());
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check Supabase URL configuration
      final url = SupabaseConfig.url;
      if (url.isEmpty) {
        return 'Invalid Supabase configuration. Please contact support.';
      }
      
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
      // Check if it's a connectivity error
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        _errorMessage = 'Connection error: Please check your internet connection and try again.';
        return _errorMessage;
      }
      
      _errorMessage = 'Network error occurred: ${e.toString()}';
      debugPrint('Login error details: $e');
      return _errorMessage;
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
      // Check Supabase URL configuration
      final url = SupabaseConfig.url;
      if (url.isEmpty) {
        return 'Invalid Supabase configuration. Please contact support.';
      }
      
      debugPrint('Using Supabase URL: $url');
      
      // Display a warning if the URL is the default from the .env example
      if (url.contains('kgekayzazzgvwyjhbaiy.supabase.co')) {
        debugPrint('WARNING: Using example Supabase URL which may not be valid');
      }
      
      debugPrint('Trying simplified user registration as a workaround');
      
      // Use the simplest possible signup approach
      try {
        // Try to login first to see if the user already exists
        final checkResponse = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (checkResponse.user != null) {
          _user = checkResponse.user;
          return 'This email is already registered. Please login instead.';
        }
      } catch (e) {
        // Check if it's a connectivity error
        if (e.toString().contains('SocketException') || 
            e.toString().contains('Failed host lookup')) {
          return 'Connection error: Please check your internet connection and try again.';
        }
        // Otherwise ignore - user probably doesn't exist, which is what we want
      }
      
      // Proceed with registration
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Set user even if session is null
        _user = response.user;
        
        debugPrint('User registered successfully with id: ${response.user!.id}');
        
        // Wait a moment before trying to create the profile
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Create a profile directly in the database instead of using auth metadata
          await _supabase.from('profiles').upsert({
            'id': response.user!.id,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'full_name': [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ').trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('User profile created successfully');
        } catch (profileError) {
          debugPrint('Error creating profile: $profileError');
          // Continue even if profile creation fails
        }
        
        return null; // Success - user registered
      }
      return 'Registration failed. Please try again.';
    } on AuthException catch (e) {
      debugPrint('Auth exception during registration: ${e.message}');
      debugPrint('Auth exception code: ${e.statusCode}');
      
      // Handle specific error codes
      if (e.statusCode == '409') {
        _errorMessage = 'This email is already in use. Please try signing in instead.';
        return _errorMessage;
      } else if (e.statusCode == '422') {
        _errorMessage = 'Invalid email or password. Please check your details.';
        return _errorMessage;
      } else {
        _errorMessage = e.message;
        return e.message;
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
      
      // Handle DNS and connectivity errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup') || 
          e.toString().contains('No address associated')) {
        _errorMessage = 'Connection error: Unable to reach Supabase servers. Please check your internet connection and try again.';
        
        // If using the problematic URL, add more context
        if (SupabaseConfig.url.contains('kgekayzazzgvwyjhbaiy')) {
          _errorMessage = 'Server connection error: The Supabase project configuration appears to be invalid. Please contact the app administrator.';
        }
        
        return _errorMessage;
      } 
      // Check for specific error messages and provide user-friendly responses
      else if (e.toString().contains('duplicate key') || 
          e.toString().contains('already exists') ||
          e.toString().contains('unique constraint')) {
        _errorMessage = 'This email is already registered. Please use a different email or try signing in.';
        return _errorMessage;
      } else if (e.toString().contains('network')) {
        _errorMessage = 'Network error. Please check your internet connection and try again.';
        return _errorMessage;
      } else {
        _errorMessage = 'Registration failed. Please try again later.';
        return _errorMessage;
      }
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
      debugPrint('Logout error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Helper method to check if a user's profile is complete
  Future<bool> isProfileComplete() async {
    if (_user == null) return false;
    
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
          
      // Check if required profile fields are present and non-empty
      final requiredFields = ['first_name', 'last_name'];
      for (final field in requiredFields) {
        if (profile[field] == null || profile[field].toString().isEmpty) {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking profile: $e');
      return false;
    }
  }
}