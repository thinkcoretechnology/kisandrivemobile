import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saas_models.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;

  AuthService() {
    _loadStoredSession();
  }

  Future<String> _getAuthBaseUrl() async {
    final apiBase = await ApiService.getBaseUrl();
    return '$apiBase/auth';
  }

  Future<void> _loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('tracktor_token');
    final userStr = prefs.getString('tracktor_user');
    if (userStr != null) {
      _currentUser = User.fromJson(jsonDecode(userStr));
    }
    notifyListeners();
  }

  Future<bool> login(String mobileNumber, String password) async {
    try {
      final authBaseUrl = await _getAuthBaseUrl();
      final res = await http.post(
        Uri.parse('$authBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile_number': mobileNumber,
          'password': password,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tracktor_token', _token!);
        await prefs.setString('tracktor_user', jsonEncode(data['user']));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login exception: $e');
      return false;
    }
  }

  Future<bool> register(String fullName, String mobileNumber, String password) async {
    try {
      final authBaseUrl = await _getAuthBaseUrl();
      final res = await http.post(
        Uri.parse('$authBaseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'password': password,
          'role': 'Tractor Owner',
        }),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('tracktor_token', _token!);
        await prefs.setString('tracktor_user', jsonEncode(data['user']));

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register exception: $e');
      return false;
    }
  }

  Future<void> updateCurrentUser(User updatedUser) async {
    _currentUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracktor_user', jsonEncode(updatedUser.toJson()));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tracktor_token');
    await prefs.remove('tracktor_user');
    notifyListeners();
  }
}
