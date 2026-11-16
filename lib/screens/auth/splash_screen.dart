import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_actions.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_controls.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.actions, this.onResolved});
  final AuthActions? actions;
  final ValueChanged<bool>? onResolved;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _navigationTimer;
  final AuthActions _defaultActions = FirebaseAuthActions();
  String? _error;
  bool _restoring = false;
  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _restore();
  }

  Future<void> _restore() async {
    if (_restoring) return;
    _restoring = true;
    final watch = Stopwatch()..start();
    _navigationTimer?.cancel();
    if (_error != null) setState(() => _error = null);
    try {
      final signedIn =
          await (widget.actions ?? _defaultActions).restoreSession();
      if (!mounted) return;
      final remaining =
          Duration(milliseconds: math.max(0, 900 - watch.elapsedMilliseconds));
      _navigationTimer = Timer(remaining, () {
        if (!mounted) return;
        if (widget.onResolved != null) {
          widget.onResolved!(signedIn);
        } else {
          context.go(signedIn ? '/home' : '/login');
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Couldn’t restore your session. Check your connection and try again.');
      }
    } finally {
      _restoring = false;
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _fade, child: SplashView(error: _error, onRetry: _restore));
}

/// Presentation separated from session restoration so previews never sign in.
class SplashView extends StatelessWidget {
  const SplashView({super.key, this.error, this.onRetry});
  final String? error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: FlowColors.charcoal,
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                  child: SizedBox(
                      height: math.max(620, constraints.maxHeight),
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                          child: Column(children: [
                            const Spacer(flex: 3),
                            const VertxMonogram(),
                            const SizedBox(height: 26),
                            const Text('VERTX',
                                style: TextStyle(
                                    color: FlowColors.ivory,
                                    fontSize: 28,
                                    letterSpacing: 12,
                                    fontWeight: FontWeight.w400)),
                            const SizedBox(height: 18),
                            const Text('Your rhythm starts here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: FlowColors.ivory,
                                    fontSize: 13,
                                    letterSpacing: 1)),
                            const Spacer(flex: 2),
                            if (error == null)
                              Semantics(
                                  label: 'Restoring your session',
                                  liveRegion: true,
                                  child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.3,
                                          color: FlowColors.ivory,
                                          backgroundColor: Color(0xFF5D5954))))
                            else ...[
                              Text(error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: FlowColors.ivory, fontSize: 12)),
                              const SizedBox(height: 12),
                              TextButton(
                                  onPressed: onRetry,
                                  child: const Text('Try again',
                                      style:
                                          TextStyle(color: FlowColors.ivory)))
                            ],
                            const Spacer(),
                            const Text('Small steps. Lasting change.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: FlowColors.ivory,
                                    fontSize: 11,
                                    letterSpacing: .5)),
                          ])))))));
}
