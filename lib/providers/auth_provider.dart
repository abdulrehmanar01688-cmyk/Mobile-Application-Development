import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn && _auth.currentUser != null) {
      _user = _auth.currentUser;
      notifyListeners();
    }
  }

  Future<void> _saveLoginStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', status);
  }

  // ✅ FIXED: Sirf ek signInWithEmail — trim + simple errors
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _saveLoginStatus(true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth Error: ${e.code}');
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        _error = 'Email ya password galat hai. Dobara check karo.';
      } else if (e.code == 'invalid-email') {
        _error = 'Email format sahi nahi hai.';
      } else if (e.code == 'too-many-requests') {
        _error = 'Bahut zyada tries. Thodi der baad try karo.';
      } else if (e.code == 'network-request-failed') {
        _error = 'Internet connection check karo.';
      } else {
        _error = 'Email ya password galat hai.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Kuch masla hua. Dobara try karo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.updateDisplayName(name);
      await _saveLoginStatus(true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'Yeh email pehle se registered hai. Login karo.';
          break;
        case 'weak-password':
          _error = 'Password kam se kam 6 characters ka hona chahiye.';
          break;
        case 'invalid-email':
          _error = 'Email format sahi nahi hai.';
          break;
        default:
          _error = 'Kuch masla hua. Dobara try karo.';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _saveLoginStatus(true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Google sign in failed. Dobara try karo.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ FIXED: signOut ke baad user null + notifyListeners
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _saveLoginStatus(false);
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}