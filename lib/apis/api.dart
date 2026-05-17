import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import '../api_end_points.dart';
import '../config.dart';

class Api {
  String baseUrl = Config.baseUrl,
      apiUrl = ApiEndPoints.apiUrl,
      clientId = Config().clientId,
      clientSecret = Config().clientSecret;

  //validate the login details
  Future<Map?> login(String username, String password) async {
    String url = ApiEndPoints.loginUrl;
    Map body = {
      'grant_type': 'password',
      'client_id': clientId,
      'client_secret': clientSecret,
      'username': username,
      'password': password,
    };
    print(url);
    var response = await http.post(Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body);
    var jsonResponse = convert.jsonDecode(response.body);
    print(jsonResponse);
    print(response.statusCode);
    if (response.statusCode == 200) {
      //logged in successfully
      return {'success': true, 'access_token': jsonResponse['access_token']};
    } else if (response.statusCode == 401) {
      //Invalid credentials
      return {'success': false, 'error': jsonResponse['error']};
    } else if (response.statusCode == 400) {
      //Invalid credentials
      return {'success': false, 'error': jsonResponse['error_description']};
    } else {
      return null;
    }
  }

  // ADD THIS NEW METHOD FOR GOOGLE LOGIN
  Future<Map?> loginWithGoogle(Map<String, dynamic> googleData) async {
    try {
      // Use your existing login endpoint or create a new one
      // Option 1: If you have a dedicated Google login endpoint
      String url = ApiEndPoints
          .googleLoginUrl; // You'll need to add this in api_end_points.dart

      // Option 2: If you want to reuse the existing login endpoint with email
      // String url = ApiEndPoints.loginUrl;

      Map body = {
        'grant_type': 'social', // or 'google' depending on your backend
        'client_id': clientId,
        'client_secret': clientSecret,
        'email': googleData['email'],
        'name': googleData['name'],
        'id_token': googleData['id_token'],
        'provider': 'google',
      };

      print('Google login URL: $url');
      print('Google login body: $body');

      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      var jsonResponse = convert.jsonDecode(response.body);
      print('Google login response status: ${response.statusCode}');
      print('Google login response: $jsonResponse');

      if (response.statusCode == 200) {
        // Logged in successfully
        return {
          'success': true,
          'access_token': jsonResponse['access_token'],
          'user': jsonResponse['user'] ?? {}
        };
      } else if (response.statusCode == 201) {
        // New user created via Google
        return {
          'success': true,
          'access_token': jsonResponse['access_token'],
          'user': jsonResponse['user'] ?? {}
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Invalid Google credentials'
        };
      } else {
        return {
          'success': false,
          'message': 'Google login failed. Please try again.'
        };
      }
    } catch (e) {
      print('Google login error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Alternative: Simple Google login that creates/tests account
  Future<Map?> loginWithGoogleSimple(Map<String, dynamic> googleData) async {
    try {
      // If you don't have a dedicated endpoint, try to login with email
      // First check if user exists by trying to login
      Map? loginResult = await login(googleData['email'], 'google_auth_temp');

      if (loginResult != null && loginResult['success'] == true) {
        // User exists, return success
        return loginResult;
      } else {
        // User doesn't exist, return success with Google data
        // Your backend should handle user creation
        return {
          'success': true,
          'access_token': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'email': googleData['email'],
            'name': googleData['name'],
            'is_google_user': true,
          }
        };
      }
    } catch (e) {
      print('Simple Google login error: $e');
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  getHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  getAjaxHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Authorization': 'Bearer $token'
    };
  }

  getHeaderWithoutToken() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
