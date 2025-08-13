import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_response.dart';

class AuthService {
  static const String baseUrl = 'https://localhost:4000';

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign In
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // เริ่ม Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResponse(
          success: false,
          message: 'Google sign in was cancelled',
        );
      }

      // รับ authentication credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // สร้าง Firebase credential
      final firebase_auth.AuthCredential credential =
          firebase_auth.GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

      // Sign in กับ Firebase
      final firebase_auth.UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // รับ ID Token
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token');
      }

      // ส่ง ID Token ไปยัง backend
      return await _sendTokenToBackend(idToken);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      return AuthResponse(
        success: false,
        message: 'Failed to sign in with Google: ${e.toString()}',
      );
    }
  }

  // ส่ง Firebase ID Token ไปยัง Backend
  Future<AuthResponse> _sendTokenToBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/signin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      debugPrint('Backend Response Status: ${response.statusCode}');
      debugPrint('Backend Response Body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);
      final AuthResponse authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        // บันทึก tokens
        await _saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );
      }

      return authResponse;
    } catch (e) {
      debugPrint('Backend API Error: $e');
      return AuthResponse(
        success: false,
        message: 'Failed to authenticate with backend: ${e.toString()}',
      );
    }
  }

  // บันทึก tokens
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  // รับ access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Refresh token
  Future<AuthResponse> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        return AuthResponse(success: false, message: 'No refresh token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      final AuthResponse authResponse = AuthResponse.fromJson(responseData);

      if (authResponse.success && authResponse.data != null) {
        await _saveTokens(
          authResponse.data!.accessToken,
          authResponse.data!.refreshToken,
        );
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to refresh token: ${e.toString()}',
      );
    }
  }

  // รับข้อมูลผู้ใช้
  Future<AuthResponse> getProfile() async {
    try {
      final String? accessToken = await getAccessToken();

      if (accessToken == null) {
        return AuthResponse(success: false, message: 'No access token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 401) {
        // Token หมดอายุ ลอง refresh
        final refreshResult = await refreshToken();
        if (refreshResult.success) {
          return await getProfile(); // ลองใหม่
        }
        return refreshResult;
      }

      final Map<String, dynamic> responseData = json.decode(response.body);
      return AuthResponse.fromJson(responseData);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Failed to get profile: ${e.toString()}',
      );
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // ตรวจสอบสถานะการเข้าสู่ระบบ
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }
}
