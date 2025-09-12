import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static final String baseUrl = _resolveBaseUrl();
  String? _access;
  String? _refresh;
  bool _loading = false;

  bool get isLoading => _loading;
  String? get access => _access;

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString('access');
    _refresh = prefs.getString('refresh');
    notifyListeners();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    return await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15))
        .then((r) => {'status': r.statusCode, 'data': r.body.isNotEmpty ? jsonDecode(r.body) : {}});
  }

  Future<String?> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _post('/token/', {'username': username, 'password': password});
      if (res['status'] == 200) {
        final data = res['data'];
        _access = data['access'];
        _refresh = data['refresh'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access', _access!);
        await prefs.setString('refresh', _refresh!);
        return null;
      }
      return 'Invalid credentials';
    } catch (e) {
      return 'Network timeout or error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(Map<String, dynamic> payload) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _post('/register/', payload);
      if (res['status'] == 201) {
        return null;
      }
      return 'Registration failed';
    } catch (e) {
      return 'Network timeout or error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


