import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class ApiClient {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString('access');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('${AuthProvider.baseUrl}$path');

  static Future<http.Response> get(String path) async {
    final res = await http
        .get(_uri(path), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    return res;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(_uri(path), headers: await _headers(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    return res;
  }
}
