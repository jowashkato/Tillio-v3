import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api_end_points.dart';
import '../models/system.dart';
import 'api.dart';

class BusinessApi extends Api {
  // Register business (direct registration)
  Future<Map<String, dynamic>> registerBusiness(
      Map<String, dynamic> businessData) async {
    try {
      String url = ApiEndPoints.registerBusiness;

      print("Register Business URL: $url");
      print("Register Business Data: $businessData");

      var response = await http.post(
        Uri.parse(url),
        headers: this.getHeaderWithoutToken(),
        body: convert.jsonEncode(businessData),
      );

      print("Business Registration Response Status: ${response.statusCode}");
      print("Business Registration Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = convert.jsonDecode(response.body);

        // Store token if provided
        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access_token']);
          await System().insertToken(data['access_token']);
        } else if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['token']);
          await System().insertToken(data['token']);
        }

        return {
          'success': true,
          'data': data,
          'message': data['message'] ??
              data['msg'] ??
              'Business registered successfully'
        };
      } else {
        var error = convert.jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? error['msg'] ?? 'Registration failed',
          'errors': error['errors'] ?? {}
        };
      }
    } catch (e) {
      print('Error in registerBusiness: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'errors': {}
      };
    }
  }

  // ❌ REMOVED getPackages() — NOT NEEDED (WebView handles pricing)

  // Register with email (temporary password)
  Future<Map<String, dynamic>> registerWithEmail(
      String email, String temporaryPassword) async {
    try {
      String url = ApiEndPoints.emailRegister;

      print("Email Register URL: $url");
      print("Email: $email");

      var response = await http.post(
        Uri.parse(url),
        headers: this.getHeaderWithoutToken(),
        body: convert.jsonEncode({
          'email': email,
          'password': temporaryPassword,
          'password_confirmation': temporaryPassword,
          'registration_type': 'email',
        }),
      );

      print("Email Registration Response: ${response.statusCode}");
      print("Email Registration Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = convert.jsonDecode(response.body);

        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('temp_token', data['access_token']);
        } else if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('temp_token', data['token']);
        }

        return {
          'success': true,
          'data': data,
          'message': data['message'] ??
              data['msg'] ??
              'Verification email sent successfully'
        };
      } else {
        var error = convert.jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? error['msg'] ?? 'Registration failed',
          'errors': error['errors'] ?? {}
        };
      }
    } catch (e) {
      print('Error in registerWithEmail: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'errors': {}
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword(
    String email,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      String url = ApiEndPoints.changePassword;

      print("Change Password URL: $url");

      String? token = await System().getToken();
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('temp_token');
      }

      Map<String, String> headers;
      if (token != null && token.isNotEmpty) {
        headers = this.getHeader(token);
      } else {
        headers = this.getHeaderWithoutToken();
      }

      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: convert.jsonEncode({
          'email': email,
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        }),
      );

      print("Change Password Response Status: ${response.statusCode}");
      print("Change Password Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = convert.jsonDecode(response.body);

        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('temp_token');
          await prefs.setString('access_token', data['access_token']);
          await System().insertToken(data['access_token']);
        } else if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('temp_token');
          await prefs.setString('access_token', data['token']);
          await System().insertToken(data['token']);
        }

        return {
          'success': true,
          'message':
              data['message'] ?? data['msg'] ?? 'Password changed successfully'
        };
      } else {
        var error = convert.jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['msg'] ?? 'Password change failed'
        };
      }
    } catch (e) {
      print('Error in changePassword: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
