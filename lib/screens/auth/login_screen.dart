import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/auth_validation.dart';
import '../../services/auth_actions.dart';
import '../../widgets/auth_controls.dart';
import 'reset_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.actions, this.onAuthenticated});
  final AuthActions? actions;
  final VoidCallback? onAuthenticated;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  final AuthActions _defaultActions = FirebaseAuthActions();
  AuthActions get _actions => widget.actions ?? _defaultActions;
  int _busy = 0;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _authenticated() {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
    } else {
      context.go('/home');
    }
  }

  Future<void> _signIn() async {
    if (_busy != 0 || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = 1;
      _error = null;
    });
    try {
      await _actions.signIn(_email.text.trim(), _password.text);
      if (mounted) _authenticated();
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = 0);
    }
  }

  Future<void> _google() async {
    if (_busy != 0) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = 2;
      _error = null;
    });
    try {
      final signedIn = await _actions.signInWithGoogle();
      if (signedIn && mounted) _authenticated();
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = 0);
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) =>
            ResetPasswordSheet(actions: _actions, email: _email.text.trim()));
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
          title: 'Welcome back',
          subtitle: 'Make room for your rhythm.',
          heading: 'Sign in',
          children: [
            AutofillGroup(
                child: Form(
                    key: _formKey,
                    child: Column(children: [
                      AuthField(
                          id: 'email',
                          label: 'Email',
                          controller: _email,
                          hint: 'you@example.com',
                          enabled: _busy == 0,
                          validator: AuthValidation.email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ]),
                      AuthField(
                          id: 'password',
                          label: 'Password',
                          controller: _password,
                          hint: 'Your password',
                          password: true,
                          enabled: _busy == 0,
                          validator: AuthValidation.signInPassword,
                          autofillHints: const [AutofillHints.password],
                          action: TextInputAction.done,
                          onSubmitted: (_) => _signIn()),
                    ]))),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _busy == 0 ? _reset : null,
                    child: const Text('Forgot password?',
                        style: TextStyle(fontSize: 12)))),
            const SizedBox(height: 10),
            AuthError(message: _error),
            AuthSubmit(
                label: 'Sign in',
                busyLabel: 'Signing in…',
                busy: _busy == 1,
                onPressed: _busy == 0 ? _signIn : null),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child:
                      Text('or', style: Theme.of(context).textTheme.bodySmall)),
              const Expanded(child: Divider())
            ]),
            const SizedBox(height: 20),
            OutlinedButton(
                onPressed: _busy == 0 ? _google : null,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_busy == 2)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.6))
                  else
                    const Text('G',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 20)),
                  const SizedBox(width: 12),
                  Flexible(
                      child: Text(
                          _busy == 2 ? 'Connecting…' : 'Continue with Google',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13))),
                ])),
            const SizedBox(height: 20),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New here?', style: TextStyle(fontSize: 12)),
                  TextButton(
                      onPressed:
                          _busy == 0 ? () => context.go('/signup') : null,
                      child: const Text('Create an account',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
          ]);
}
