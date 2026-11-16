import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Authentication boundary shared by the UI and its asynchronous behavior tests.
abstract interface class AuthActions {
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password, String name);
  Future<bool> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<bool> restoreSession();
}

class FirebaseAuthActions implements AuthActions {
  AuthService? _service;
  AuthService get _auth => _service ??= AuthService();
  @override
  Future<void> signIn(String email, String password) =>
      _auth.signIn(email, password);
  @override
  Future<void> signUp(String email, String password, String name) =>
      _auth.signUp(email, password, name);
  @override
  Future<bool> signInWithGoogle() async =>
      await _auth.signInWithGoogle() != null;
  @override
  Future<void> resetPassword(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  @override
  Future<bool> restoreSession() async =>
      (await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 10))) !=
      null;
}

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'The email or password wasn’t recognised. Please try again.';
      case 'email-already-in-use':
        return 'This email already has an account. Try signing in instead.';
      case 'invalid-email':
        return 'Please check your email address.';
      case 'weak-password':
        return 'Choose a stronger password and try again.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a little and try again.';
      case 'user-disabled':
        return 'This account is unavailable. Please contact support.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable.';
    }
  }
  return 'Couldn’t complete that request. Please try again.';
}
