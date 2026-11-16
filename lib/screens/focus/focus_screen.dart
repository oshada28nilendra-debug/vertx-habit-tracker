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
  bool get _finished => _sessionId != null && _remaining == 0;
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
    if (!_ready) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'YOUR QUIET CORNER',
            style: TextStyle(
              letterSpacing: 3,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'One thing at a time.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Small pockets of focus. Big little wins.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            children: [15, 25, 45]
                .map(
                  (minutes) => ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _minutes == minutes,
                    onSelected: _sessionId != null || _busy
                        ? null
                        : (_) async {
                            setState(() {
                              _minutes = minutes;
                              _remaining = minutes * 60;
                            });
                            await _persist();
                          },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: 1 - _remaining / (_minutes * 60),
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE4DDFB),
                      color: const Color(0xFF8062D6),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _finished ? '🎉' : '🌱',
                        style: const TextStyle(fontSize: 38),
                      ),
                      Text(
                        '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _finished
                            ? 'You showed up!'
                            : _running
                                ? 'You’ve got this.'
                                : 'Room to grow.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : _finished
                      ? _save
                      : _toggle,
              icon: Icon(
                _finished
                    ? Icons.check_rounded
                    : _running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
              ),
              label: Text(
                _busy
                    ? 'Saving…'
                    : _finished
                        ? 'Save my session'
                        : _running
                            ? 'Pause focus'
                            : _sessionId != null
                                ? 'Resume focus'
                                : 'Let’s focus',
              ),
            ),
          ),
          if (_sessionId != null)
            TextButton(
              onPressed: _busy ? null : _reset,
              child: const Text('Reset session'),
            ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('focusSessions')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Session history could not be loaded.');
              }
              final sessions = snapshot.data?.docs ?? [];
              final minutes = sessions.fold<int>(
                0,
                (totalMinutes, doc) =>
                    totalMinutes +
                    ((doc.data()['minutes'] as num?)?.toInt() ?? 0),
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${sessions.length} sessions • $minutes focused minutes',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
          const Text(
            'Focus sessions are saved separately from habit completions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
