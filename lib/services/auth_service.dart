import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const _kEmailKey = 'auth_email';
  static const _kPasswordHashKey = 'auth_password_hash';

  Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kEmailKey) && prefs.containsKey(_kPasswordHashKey);
  }

  Future<void> createAccount({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = sha256.convert(utf8.encode(password)).toString();
    await prefs.setString(_kEmailKey, email.trim());
    await prefs.setString(_kPasswordHashKey, hash);
  }

  Future<bool> signIn({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmailKey);
    final savedHash = prefs.getString(_kPasswordHashKey);
    if (savedEmail == null || savedHash == null) return false;
    final attempt = sha256.convert(utf8.encode(password)).toString();
    return savedEmail.trim() == email.trim() && savedHash == attempt;
  }

  Future<void> signOut() async {
    // For local auth demo, nothing to clear besides session flags if added later
  }
}


