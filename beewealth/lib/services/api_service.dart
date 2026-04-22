import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();
  
  Future<String?> get _token async => await _storage.read(key: 'access_token');

  Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    final body = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final error = body['error'] ?? body['detail'] ?? 'Something went wrong';
      throw ApiException(error, response.statusCode);
    }
  }

  Future<dynamic> get(String endpoint, {bool authenticated = true}) async {
    try {
      final token = authenticated ? await _token : null;
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _headers(token),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString(), 500);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool authenticated = true}) async {
    try {
      final token = authenticated ? await _token : null;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _headers(token),
        body: json.encode(data),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString(), 500);
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {bool authenticated = true}) async {
    try {
      final token = authenticated ? await _token : null;
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _headers(token),
        body: json.encode(data),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString(), 500);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
