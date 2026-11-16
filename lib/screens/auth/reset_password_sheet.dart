import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/auth_validation.dart';
import '../../services/auth_actions.dart';
import '../../widgets/auth_controls.dart';

class ResetPasswordSheet extends StatefulWidget {
  const ResetPasswordSheet({super.key, required this.actions, this.email = ''});
  final AuthActions actions;
  final String email;
  @override
  State<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _busy = false, _sent = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.actions.resetPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        if (error is FirebaseAuthException && error.code == 'user-not-found') {
          setState(() => _sent = true);
        } else {
          setState(() => _error = authErrorMessage(error));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset password',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (_sent) ...[
                  Semantics(
                      liveRegion: true,
                      child: Text(
                          'If an account uses this email, check its inbox for a password reset link.')),
                  const SizedBox(height: 22),
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done')),
                ] else ...[
                  const Text(
                      'Enter your email and we’ll help you get back to your rhythm.',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 22),
                  Form(
                      key: _formKey,
                      child: AuthField(
                          id: 'reset-email',
                          label: 'Email',
                          controller: _email,
                          hint: 'you@example.com',
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidation.email,
                          action: TextInputAction.done,
                          onSubmitted: (_) => _send())),
                  AuthError(message: _error),
                  AuthSubmit(
                      label: 'Send reset link',
                      busyLabel: 'Sending…',
                      busy: _busy,
                      onPressed: _busy ? null : _send),
                ],
              ])));
}
