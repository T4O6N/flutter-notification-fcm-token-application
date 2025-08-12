import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: GoogleAuthPage());
  }
}

class GoogleAuthPage extends StatefulWidget {
  const GoogleAuthPage({super.key});

  @override
  State<GoogleAuthPage> createState() => _GoogleAuthPageState();
}

class _GoogleAuthPageState extends State<GoogleAuthPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use your Google OAuth client ID for Android/iOS here if needed
  );

  String? _accessToken;
  String? _refreshToken;

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('User cancelled sign-in');
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        debugPrint('No ID token found');
        return;
      }

      // Send token to your backend
      final response = await http.post(
        // Uri.parse('http://localhost:4000/api/v1/auth/google/token'),
        Uri.parse(
          'https://charming-primarily-crane.ngrok-free.app/api/v1/auth/google/token',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _accessToken = data['access_token'];
          _refreshToken = data['refresh_token'];
        });
        debugPrint('Access Token: $_accessToken');
        debugPrint('Refresh Token: $_refreshToken');
      } else {
        debugPrint('Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      debugPrint('Sign in failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleSignIn,
              child: const Text('Sign in with Google'),
            ),
            if (_accessToken != null) ...[
              const SizedBox(height: 20),
              Text('Access Token: $_accessToken'),
            ],
          ],
        ),
      ),
    );
  }
}
