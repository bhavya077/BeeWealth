import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> login(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.post(ApiConstants.login, {
        'email': email,
        'password': 'nopassword', // Assuming backend supports or will support passwordless
      }, authenticated: false);
      _setLoading(false);
      return true; // OTP Sent
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String name, String email, String mobile) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.post(ApiConstants.register, {
        'name': name,
        'email': email,
        'mobile': mobile,
      }, authenticated: false);
      _setLoading(false);
      return true; // OTP Sent
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.post(ApiConstants.verifyOtp, {
        'email': email,
        'code': code,
      }, authenticated: false);
      
      await _storage.write(key: 'access_token', value: response['access']);
      await _storage.write(key: 'refresh_token', value: response['refresh']);
      
      _user = User.fromJson(response['user']);
      _isLoggedIn = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final response = await _apiService.get(ApiConstants.me);
        _user = User.fromJson(response);
        _isLoggedIn = true;
        notifyListeners();
      } catch (e) {
        logout();
      }
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.patch(ApiConstants.me, data);
      _user = User.fromJson(response);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
