import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _kEmailKey = 'auth_email';
  static const _kPasswordHashKey = 'auth_password_hash';
  static const _kGoogleSignedInKey = 'google_signed_in';
  static const _kUserNameKey = 'user_name';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Check if user is logged in (either locally or via Google)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kGoogleSignedInKey) == true || 
           (prefs.containsKey(_kEmailKey) && prefs.containsKey(_kPasswordHashKey));
  }

  // Get current user info
  Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_kEmailKey),
      'name': prefs.getString(_kUserNameKey),
      'isGoogle': prefs.getBool(_kGoogleSignedInKey).toString(),
    };
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEmailKey, account.email);
      await prefs.setString(_kUserNameKey, account.displayName ?? '');
      await prefs.setBool(_kGoogleSignedInKey, true);
      return true;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
    }
  }

  // Local account creation
  Future<bool> createAccount({required String email, required String password, required String name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hash = sha256.convert(utf8.encode(password)).toString();
      await prefs.setString(_kEmailKey, email.trim());
      await prefs.setString(_kPasswordHashKey, hash);
      await prefs.setString(_kUserNameKey, name.trim());
      await prefs.setBool(_kGoogleSignedInKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Local sign-in
  Future<bool> signIn({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmailKey);
    final savedHash = prefs.getString(_kPasswordHashKey);
    if (savedEmail == null || savedHash == null) return false;
    
    final attempt = sha256.convert(utf8.encode(password)).toString();
    if (savedEmail.trim() == email.trim() && savedHash == attempt) {
      await prefs.setBool(_kGoogleSignedInKey, false);
      return true;
    }
    return false;
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await _googleSignIn.signOut();
    await prefs.clear();
  }
}