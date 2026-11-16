import 'package:vertx/services/auth_actions.dart';

class FakeAuthActions implements AuthActions {
  int signIns = 0, signUps = 0, googleSignIns = 0, resets = 0, restores = 0;
  String? email, password, name;
  Future<void> Function()? onSignIn, onSignUp, onReset;
  Future<bool> Function()? onGoogle, onRestore;
  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    this.email = email;
    this.password = password;
    await onSignIn?.call();
  }

  @override
  Future<void> signUp(String email, String password, String name) async {
    signUps++;
    this.email = email;
    this.password = password;
    this.name = name;
    await onSignUp?.call();
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleSignIns++;
    return await onGoogle?.call() ?? true;
  }

  @override
  Future<void> resetPassword(String email) async {
    resets++;
    this.email = email;
    await onReset?.call();
  }

  @override
  Future<bool> restoreSession() async {
    restores++;
    return await onRestore?.call() ?? false;
  }
}
