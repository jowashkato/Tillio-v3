import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_pos/constants.dart';
import 'package:http/http.dart' as http;
import '../../api_end_points.dart';
import '../../config.dart';
import '../../models/system.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  String defaultGoogleImage = 'assets/images/verification_bg.png';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password',style: TextStyle(
          color: Colors.white
        ),),
        backgroundColor: const Color(0xff3d63ff),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add an illustration or logo at the top
            SizedBox(
              height: 250,
              child: Image(
                fit: BoxFit.fill,
                // height: 24,
                // width:24,
                image: AssetImage(defaultGoogleImage),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your email address to receive a password reset link.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (_isValidEmail(email)) {
                  _sendResetLink(context, email);
                } else {
                  _showSnackBar(
                    context,
                    'Invalid Email',
                    'Please enter a valid email address',
                    Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff3d63ff),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }

  void _sendResetLink(BuildContext context, String email) async {
    // Simulating an API call
    // try {
    //   Map<String, dynamic> checkInMap = {
    //     "user_id": Config.userId,
    //     "latitude": "$latitude",
    //     "longitude": "$longitude"
    //   };
    //   String url =  ApiEndPoints.checkOut;
    //   var token = await System().getToken();
    //   var response = await http.post(Uri.parse(url),
    //       headers: this.getHeader('$token'), body: jsonEncode(data));
    //   var info = jsonDecode(response.body);
    //   return info;
    // } catch (e) {
    //   return null;
    // }
    await Future.delayed(const Duration(seconds: 2));
    _showSnackBar(
      context,
      'Email Sent',
      'A password reset link has been sent to $email',
      Colors.green,
    );
  }

  void _showSnackBar(BuildContext context, String title, String message, Color color) {
    final snackBar = SnackBar(
      content: Text('$title: $message'),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
