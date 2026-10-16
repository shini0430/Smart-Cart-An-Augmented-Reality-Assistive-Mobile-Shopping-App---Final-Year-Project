import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://172.20.10.4:8080/smart_cart_backend';

  // ============================================================
  // FIREBASE TOKEN
  // ============================================================

  static Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('API: No Firebase user logged in.');
        return null;
      }

      // Force refresh so create_order.php receives a valid current token.
      final token = await user
          .getIdToken(true)
          .timeout(const Duration(seconds: 10));

      debugPrint('API: Firebase token received.');
      return token;
    } on TimeoutException {
      debugPrint('API: Firebase token request timed out.');
      return null;
    } catch (e) {
      debugPrint('API: Firebase token error: $e');
      return null;
    }
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static dynamic _decodeResponse(
    http.Response response, {
    required String requestName,
  }) {
    debugPrint('$requestName STATUS: ${response.statusCode}');
    debugPrint('$requestName RESPONSE: ${response.body}');

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is List) {
        return decoded;
      }

      return {'status': 'error', 'error': 'Unexpected server response.'};
    } catch (e) {
      debugPrint('$requestName JSON ERROR: $e');

      return {
        'status': 'error',
        'error': response.body.isNotEmpty
            ? response.body
            : 'Invalid response from server.',
        'http_status': response.statusCode,
      };
    }
  }

  // ============================================================
  // GET REQUEST
  // ============================================================

  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await _getToken();

      final headers = <String, String>{
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl/$endpoint');

      debugPrint('API GET: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      return _decodeResponse(response, requestName: 'API GET');
    } on TimeoutException {
      debugPrint('API GET TIMEOUT: $endpoint');

      return {'status': 'error', 'error': 'Connection timed out.'};
    } catch (e) {
      debugPrint('API GET ERROR: $e');

      return {'status': 'error', 'error': e.toString()};
    }
  }

  // ============================================================
  // POST REQUEST
  // ============================================================

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        debugPrint('API POST ERROR: Firebase token unavailable.');

        return {
          'status': 'error',
          'error': 'Firebase authentication token unavailable.',
        };
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('$baseUrl/$endpoint');

      debugPrint('API POST: $uri');
      debugPrint('API POST BODY: ${jsonEncode(body)}');

      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      return _decodeResponse(response, requestName: 'API POST');
    } on TimeoutException {
      debugPrint('API POST TIMEOUT: $endpoint');

      return {'status': 'error', 'error': 'Connection timed out.'};
    } catch (e) {
      debugPrint('API POST ERROR: $e');

      return {'status': 'error', 'error': e.toString()};
    }
  }

  // ============================================================
  // GET PRODUCTS
  // ============================================================

  static Future<List<dynamic>> getItems() async {
    try {
      final uri = Uri.parse('$baseUrl/get_products.php');

      debugPrint('GET ITEMS: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      debugPrint('GET ITEMS STATUS: ${response.statusCode}');
      debugPrint('GET ITEMS RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            if (data['success'] == true) {
              final result = data['data'];
              return result is List ? result : [];
            }

            // Some PHP versions may return the product list directly under data.
            if (data['status'] == 'success' && data['data'] is List) {
              return data['data'];
            }

            debugPrint(
              'GET ITEMS API ERROR: '
              '${data['error'] ?? data['message'] ?? 'Unknown error'}',
            );
          }

          return [];
        } catch (e) {
          debugPrint('GET ITEMS JSON ERROR: $e');
          return [];
        }
      }

      debugPrint('GET ITEMS SERVER ERROR: HTTP ${response.statusCode}');
      return [];
    } on TimeoutException {
      debugPrint('GET ITEMS TIMEOUT');
      return [];
    } catch (e) {
      debugPrint('GET ITEMS CONNECTION ERROR: $e');
      return [];
    }
  }
}
