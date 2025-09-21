import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseAuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _loading = false;
  User? _user;
  String? _errorMessage;
  bool _initialized = false;
  bool _isBypassed = false; // Track if using bypass mode

  bool get isLoading => _loading;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _isBypassed;
  bool get isInitialized => _initialized;
  bool get isBypassed => _isBypassed;
  
  SupabaseAuthProvider() {
    // Initialize is called explicitly from AuthWrapper
  }
  
  // Development bypass method - only works with specific credentials
  Future<bool> tryBypassAuth(String email, String password) async {
    if (kReleaseMode) {
      // Don't allow bypass in release builds
      return false;
    }

    const bypassEmail = 'abdulsalamssekyanzi';
    const bypassPassword = 'Su4at3#0';
    
    if (email == bypassEmail && password == bypassPassword) {
      debugPrint('🔓 AUTH BYPASS: Development credentials detected');
      
      // Create a mock user for bypass mode
      _user = User(
        id: 'bypass-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        userMetadata: {
          'first_name': 'Admin',
          'last_name': 'Bypass',
          'bypass_mode': true,
        },
        appMetadata: {'provider': 'bypass'},
        aud: 'authenticated',
        confirmationSentAt: DateTime.now().toIso8601String(),
        createdAt: DateTime.now().toIso8601String(),
        emailConfirmedAt: DateTime.now().toIso8601String(),
        identities: [],
        lastSignInAt: DateTime.now().toIso8601String(),
        phone: null,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      _isBypassed = true;
      _errorMessage = null;
      _loading = false;
      
      notifyListeners();
      
      debugPrint('✅ AUTH BYPASS: Successfully activated bypass mode');
      return true;
    }
    
    return false;
  }
  
  Future<void> initialize() async {
    if (_initialized) return; // Prevent duplicate initialization
    
    _loading = true;
    // Don't notify listeners during initialization to avoid build-phase errors
    
    try {
      // Verify that Supabase URL is reachable
      final supabaseUrl = SupabaseConfig.url;
      debugPrint('Using Supabase URL: $supabaseUrl');
      
      // Check if the URL appears to be a placeholder or empty
      if (supabaseUrl.contains('your-project-id') || 
          supabaseUrl.isEmpty) {
        debugPrint('WARNING: Using what appears to be a placeholder Supabase URL. Authentication will likely fail.');
      }
      
      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        if (!_isBypassed) { // Don't override bypass mode
          _user = data.session?.user;
          notifyListeners();
        }
      });
      
      // Initialize with current user if already signed in
      _user = _supabase.auth.currentUser;
      
      // Verify session is still valid
      if (_user != null && !_isBypassed) {
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
      // First, try the bypass mechanism for development
      if (await tryBypassAuth(email, password)) {
        return null; // Success - bypass mode activated
      }

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
        _isBypassed = false; // Clear bypass mode
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
    // Don't allow registration in bypass mode
    if (await tryBypassAuth(email, password)) {
      return 'Development bypass mode activated. Use the login screen for normal registration.';
    }

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
      
      // No need to warn about valid URLs
      
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
      debugPrint('Attempting user registration with email: $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Disable email confirmation redirect
        // Remove custom data which might be causing issues
      );
      
      // If registration was successful but needs confirmation
      if (response.user != null && response.session == null) {
        debugPrint('User registered successfully but may require confirmation');
        
        // Try to immediately sign in to skip confirmation
        try {
          final signInResponse = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          
          if (signInResponse.session != null) {
            debugPrint('Auto sign-in after registration successful');
            // We'll use this session later
            _user = signInResponse.user;
          }
        } catch (signInError) {
          debugPrint('Auto sign-in failed: $signInError');
          // Continue with original response even if auto-login fails
        }
      }
      
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
        
        // Since the email exists, try to sign in immediately if it's a development environment
        if (SupabaseConfig.url.contains('kgekayzazzgvwyjhbaiy')) {
          try {
            debugPrint('Development mode: Attempting auto sign-in for existing user');
            final signInResponse = await _supabase.auth.signInWithPassword(
              email: email,
              password: password,
            );
            
            if (signInResponse.user != null) {
              _user = signInResponse.user;
              debugPrint('Auto sign-in successful for existing user');
              return null; // Success
            }
          } catch (signInError) {
            debugPrint('Auto sign-in for existing user failed: $signInError');
          }
        }
        
        return _errorMessage;
      } else if (e.statusCode == '422') {
        _errorMessage = 'Invalid email or password. Please check your details.';
        return _errorMessage;
      } else if (e.statusCode == '500' && e.message.contains('Database error')) {
        _errorMessage = 'Registration failed due to a database error. This may be a temporary issue.';
        
        // If the app is in development mode, try a direct bypass
        if (SupabaseConfig.url.contains('kgekayzazzgvwyjhbaiy')) {
          debugPrint('Development mode: Attempting bypass due to database error');
          if (await tryBypassAuth(email, password)) {
            debugPrint('Development bypass activated due to database error');
            return null; // Success
          }
        }
        
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
      if (_isBypassed) {
        // Clear bypass mode
        _user = null;
        _isBypassed = false;
        debugPrint('🔓 AUTH BYPASS: Bypass mode deactivated');
      } else {
        await _supabase.auth.signOut();
        _user = null;
      }
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
    if (_user == null && !_isBypassed) return false;
    
    // In bypass mode, consider profile complete
    if (_isBypassed) return true;
    
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

  // Method to check if current user is in bypass mode
  bool get isDevelopmentUser {
    if (_user == null) return false;
    final metadata = _user!.userMetadata;
    return metadata?['bypass_mode'] == true;
  }
}