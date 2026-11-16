import '../../widgets/focus_panel.dart';
import '../../utils/app_theme.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/reminder_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  Timer? _ticker;
  DateTime? _end;
  String? _sessionId;
  int _minutes = 25;
  int _remaining = 25 * 60;
  bool _ready = false;
  bool _busy = false;
  bool get _running => _end != null;
  String get _key => 'focus_${FirebaseAuth.instance.currentUser!.uid}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sessionId = prefs.getString('${_key}_id');
      _minutes = prefs.getInt('${_key}_minutes') ?? 25;
      _remaining = prefs.getInt('${_key}_remaining') ?? _minutes * 60;
      final end = prefs.getInt('${_key}_end');
      _end = end == null ? null : DateTime.fromMillisecondsSinceEpoch(end);
      _ready = true;
    });
    _tick();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_key}_minutes', _minutes);
    await prefs.setInt('${_key}_remaining', _remaining);
    if (_sessionId == null) {
      await prefs.remove('${_key}_id');
    } else {
      await prefs.setString('${_key}_id', _sessionId!);
    }
    if (_end == null) {
      await prefs.remove('${_key}_end');
    } else {
      await prefs.setInt('${_key}_end', _end!.millisecondsSinceEpoch);
    }
  }

  void _tick() {
    if (!_ready || _end == null || !mounted) return;
    final seconds = ((_end!.difference(DateTime.now()).inMilliseconds) / 1000)
        .ceil()
        .clamp(0, _minutes * 60);
    setState(() {
      _remaining = seconds;
    });
    // Keep the deadline until the user saves or resets. Relaunches can recover it.
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t save this change. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle() => _action(() async {
        if (_running) {
          _tick();
          setState(() => _end = null);
          await _persist();
          await ReminderService.instance.cancelFocus();
        } else {
          setState(() {
            _sessionId ??= FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('focusSessions')
                .doc()
                .id;
            _end = DateTime.now().add(Duration(seconds: _remaining));
          });
          await _persist();
          try {
            if (await ReminderService.instance.requestPermission()) {
              await ReminderService.instance.focusEnd(_end!);
            } else {
              _notice(
                'Timer started. Notifications are disabled in device settings.',
              );
            }
          } catch (_) {
            _notice(
              'Timer started. The finish notification could not be scheduled.',
            );
          }
        }
      });

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _reset() => _action(() async {
        await ReminderService.instance.cancelFocus();
        setState(() {
          _end = null;
          _sessionId = null;
          _remaining = _minutes * 60;
        });
        await _persist();
      });

  Future<void> _save() => _action(() async {
        final id = _sessionId!;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('focusSessions')
            .doc(id)
            .set({
          'minutes': _minutes,
          'completedAt': Timestamp.fromDate(_end ?? DateTime.now()),
        });
        await ReminderService.instance.cancelFocus();
        setState(() {
          _sessionId = null;
          _end = null;
          _remaining = _minutes * 60;
        });
        await _persist();
        _notice('Session saved. A little focus goes a long way!');
      });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
          child: CircularProgressIndicator(color: FlowColors.ivory));
    }
    return FocusPanel(
      minutes: _minutes,
      remaining: _remaining,
      hasSession: _sessionId != null,
      running: _running,
      busy: _busy,
      onDuration: (minutes) => _action(() async {
        setState(() {
          _minutes = minutes;
          _remaining = minutes * 60;
        });
        await _persist();
      }),
      onToggle: _toggle,
      onSave: _save,
      onReset: _reset,
      summary: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('focusSessions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Session history could not be loaded.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11));
          }
          if (!snapshot.hasData) {
            return const Text('Loading your sessions…',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11));
          }
          final sessions = snapshot.data!.docs;
          final minutes = sessions.fold<int>(
              0,
              (totalMinutes, doc) =>
                  totalMinutes +
                  ((doc.data()['minutes'] as num?)?.toInt() ?? 0));
          return Text('${sessions.length} sessions · $minutes focused minutes',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11));
        },
      ),
    );
  }
}
