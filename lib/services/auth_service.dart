import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _kEmailKey = 'auth_email';
  static const _kPasswordHashKey = 'auth_password_hash';
  static const _kUserNameKey = 'auth_user_name';
  static const _kAuthTypeKey = 'auth_type';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Check if user is logged in (either Firebase or local)
  Future<bool> isLoggedIn() async {
    // Check Firebase user first
    if (_auth.currentUser != null) return true;
    
    // Check local auth
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kEmailKey) && prefs.containsKey(_kPasswordHashKey);
  }

  // Get current user info
  Future<Map<String, String?>> getCurrentUser() async {
    // Check Firebase user first
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return {
        'name': firebaseUser.displayName,
        'email': firebaseUser.email,
        'type': 'google',
      };
    }
    
    // Check local user
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_kUserNameKey),
      'email': prefs.getString(_kEmailKey),
      'type': prefs.getString(_kAuthTypeKey) ?? 'local',
    };
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Google sign-in error: $e');
      return false;
    }
  }

  // Local account creation
  Future<bool> createLocalAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hash = sha256.convert(utf8.encode(password)).toString();
      
      await prefs.setString(_kUserNameKey, name.trim());
      await prefs.setString(_kEmailKey, email.trim());
      await prefs.setString(_kPasswordHashKey, hash);
      await prefs.setString(_kAuthTypeKey, 'local');
      
      return true;
    } catch (e) {
      print('Local account creation error: $e');
      return false;
    }
  }

  // Local sign-in
  Future<bool> signInWithEmail({required String email, required String password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_kEmailKey);
      final savedHash = prefs.getString(_kPasswordHashKey);
      
      if (savedEmail == null || savedHash == null) return false;
      
      final attemptHash = sha256.convert(utf8.encode(password)).toString();
      return savedEmail.trim() == email.trim() && savedHash == attemptHash;
    } catch (e) {
      print('Local sign-in error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();
      await _googleSignIn.signOut();
      
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kEmailKey);
      await prefs.remove(_kPasswordHashKey);
      await prefs.remove(_kUserNameKey);
      await prefs.remove(_kAuthTypeKey);
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Check if local account exists
  Future<bool> hasLocalAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kEmailKey) && prefs.containsKey(_kPasswordHashKey);
  }
}