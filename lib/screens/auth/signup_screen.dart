import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/auth_validation.dart';
import '../../services/auth_actions.dart';
import '../../widgets/auth_controls.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.actions, this.onAuthenticated});
  final AuthActions? actions;
  final VoidCallback? onAuthenticated;
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  final AuthActions _defaultActions = FirebaseAuthActions();
  AuthActions get _actions => widget.actions ?? _defaultActions;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _actions.signUp(
          _email.text.trim(), _password.text, _name.text.trim());
      if (mounted) {
        if (widget.onAuthenticated != null) {
          widget.onAuthenticated!();
        } else {
          context.go('/home');
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthFrame(
          title: 'Start your rhythm',
          subtitle: 'A little progress, every day.',
          heading: 'Create account',
          children: [
            AutofillGroup(
                child: Form(
                    key: _formKey,
                    child: Column(children: [
                      AuthField(
                          id: 'name',
                          label: 'Name',
                          controller: _name,
                          hint: 'Your name',
                          validator: AuthValidation.name,
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.name]),
                      AuthField(
                          id: 'email',
                          label: 'Email',
                          controller: _email,
                          hint: 'you@example.com',
                          validator: AuthValidation.email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email]),
                      AuthField(
                          id: 'password',
                          label: 'Password',
                          controller: _password,
                          hint: '6+ characters, A–Z and 0–9',
                          password: true,
                          enabled: !_busy,
                          validator: AuthValidation.newPassword,
                          autofillHints: const [AutofillHints.newPassword]),
                      AuthField(
                          id: 'confirm-password',
                          label: 'Confirm password',
                          controller: _confirm,
                          hint: 'Repeat your password',
                          password: true,
                          enabled: !_busy,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Confirm your password.'
                              : value != _password.text
                                  ? 'Passwords do not match.'
                                  : null,
                          autofillHints: const [AutofillHints.newPassword],
                          action: TextInputAction.done,
                          onSubmitted: (_) => _signup()),
                    ]))),
            const SizedBox(height: 6),
            AuthError(message: _error),
            AuthSubmit(
                label: 'Create account',
                busyLabel: 'Creating account…',
                busy: _busy,
                onPressed: _busy ? null : _signup),
            const SizedBox(height: 12),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already have an account?',
                      style: TextStyle(fontSize: 12)),
                  TextButton(
                      onPressed: _busy ? null : () => context.go('/login'),
                      child: const Text('Sign in',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500))),
                ]),
          ]);
}
