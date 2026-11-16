import '../../widgets/flow_layout.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/habit_progress.dart';
import '../../services/auth_service.dart';
import '../../services/reminder_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/progress_panels.dart';
import '../../widgets/profile_panel.dart';
import '../../widgets/schedule_fields.dart';
import '../focus/focus_screen.dart';
import '../habits/add_habit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0;
  Timer? _dayTimer;
  String? _profileImagePath;
  final Set<String> _pendingHabits = {};
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _habitStream;
  User? get _user => FirebaseAuth.instance.currentUser;
  String get _name => _user?.displayName?.trim().isNotEmpty == true
      ? _user!.displayName!
      : _user?.email?.split('@').first ?? 'Your space';
  CollectionReference<Map<String, dynamic>> get _habits =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('habits');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _habitStream = _user == null
        ? const Stream.empty()
        : _habits.orderBy('createdAt').snapshots();
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadPreferences();
    if (_user != null) _restoreReminders();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final path = prefs.getString('profileImage_${_user?.uid}');
    appThemeMode.value =
        prefs.getBool('darkMode') == true ? ThemeMode.dark : ThemeMode.light;
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImagePath = path);
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      if (_user != null) _restoreReminders();
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _restoreReminders() async {
    try {
      final docs = await _habits.get();
      await ReminderService.instance.refreshTimeZone();
      for (final doc in docs.docs) {
        if (doc.data()['reminderEnabled'] == true) {
          await ReminderService.instance.scheduleHabit(doc.id, doc.data());
        }
      }
    } catch (_) {
      _message(
          'Reminders could not be restored. Check notification settings and reopen the app.');
    }
  }

  Map<String, dynamic> _data(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    if (!data.containsKey('completionDays') &&
        data['lastCompleted'] is Timestamp) {
      data['completionDays'] = {
        HabitProgress.dayKey((data['lastCompleted'] as Timestamp).toDate()):
            true
      };
    }
    if (data['createdAt'] is Timestamp) {
      data['createdDay'] =
          HabitProgress.dayKey((data['createdAt'] as Timestamp).toDate());
    }
    return data;
  }

  Future<void> _openEditor(
      [QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AddHabitScreen(initial: doc == null ? null : _data(doc))));
    if (result == null) return;
    try {
      final value = <String, dynamic>{
        'name': result['name'],
        'category': result['category'],
        'iconCode': (result['icon'] as IconData).codePoint,
        'iconFontFamily': (result['icon'] as IconData).fontFamily,
        'colorValue': (result['color'] as Color).toARGB32(),
        for (final key in [
          'frequency',
          'weekdays',
          'reminderEnabled',
          'reminderMinutes',
          'goalTarget'
        ])
          key: result[key],
      };
      await _checkPermission(value);
      final ref = doc?.reference ?? _habits.doc();
      if (doc == null) {
        await ref.set({
          ...value,
          'createdAt': FieldValue.serverTimestamp(),
          'done': false,
          'streak': 0,
          'completionDays': <String, bool>{}
        });
      } else {
        await ref.update(value);
      }
      await _scheduleReminder(ref.id, value);
    } catch (_) {
      _message('Could not save your habit. Please try again.');
    }
  }

  Future<void> _checkPermission(Map<String, dynamic> value) async {
    if (value['reminderEnabled'] == true &&
        !await ReminderService.instance.requestPermission()) {
      value['reminderEnabled'] = false;
      _message(
          'Notifications are disabled. Your routine will be saved without reminders.');
    }
  }

  Future<void> _scheduleReminder(String id, Map<String, dynamic> value) async {
    try {
      await ReminderService.instance.scheduleHabit(id, value);
    } catch (_) {
      _message(
          'Habit saved. The reminder could not be scheduled; reopen the app to retry.');
    }
  }

  Future<void> _schedule(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = _data(doc);
    var config = <String, dynamic>{
      'weekdays': HabitProgress.weekdays(data),
      'goalTarget': HabitProgress.goal(data),
      'reminderEnabled': data['reminderEnabled'] ?? false,
      'reminderMinutes': data['reminderMinutes'] ?? 540
    };
    final save = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheet) => SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    24, 8, 24, MediaQuery.viewInsetsOf(sheet).bottom + 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(data['name'] as String? ?? 'Your routine',
                          style: Theme.of(sheet).textTheme.titleLarge),
                      const SizedBox(height: 22),
                      ScheduleFields(
                          initial: config,
                          onChanged: (value) => config = value),
                      const SizedBox(height: 24),
                      FilledButton(
                          onPressed: () => Navigator.pop(sheet, true),
                          child: const Text('Save routine')),
                    ]))));
    if (save != true) return;
    try {
      await _checkPermission(config);
      await doc.reference.update(config);
      await _scheduleReminder(doc.id, {...data, ...config});
    } catch (_) {
      _message('Could not save this routine. Please try again.');
    }
  }

  Future<void> _toggle(
      QueryDocumentSnapshot<Map<String, dynamic>> doc, bool done) async {
    if (!_pendingHabits.add(doc.id)) return;
    try {
      final now = DateTime.now(), key = HabitProgress.dayKey(DateTime.now());
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(doc.reference);
        if (!snapshot.exists) return;
        final value = Map<String, dynamic>.from(snapshot.data()!);
        if (!value.containsKey('completionDays') &&
            value['lastCompleted'] is Timestamp) {
          value['completionDays'] = {
            HabitProgress.dayKey(
                (value['lastCompleted'] as Timestamp).toDate()): true
          };
        }
        final history = HabitProgress.history(value);
        if (done) {
          history.remove(key);
        } else {
          history[key] = true;
        }
        value['completionDays'] = history;
        transaction.update(doc.reference, {
          'completionDays': history,
          'done': !done,
          'streak': HabitProgress.streak(value, now),
          'lastCompleted':
              done ? value['lastCompleted'] : Timestamp.fromDate(now)
        });
      });
    } catch (_) {
      _message('Could not update your habit. Please try again.');
    } finally {
      _pendingHabits.remove(doc.id);
    }
  }

  Widget _habitCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = _data(doc);
    return Dismissible(
        key: ValueKey(doc.id),
        direction: DismissDirection.endToStart,
        background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Icon(Icons.delete_outline)),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialog) => AlertDialog(
                      title: const Text('Delete habit?'),
                      content: Text(
                          'Remove “${data['name']}” and its recorded progress?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialog, false),
                            child: const Text('Keep habit')),
                        TextButton(
                            onPressed: () => Navigator.pop(dialog, true),
                            child: const Text('Delete'))
                      ]));
          if (confirmed == true) {
            try {
              await doc.reference.delete();
              try {
                await ReminderService.instance.cancelHabit(doc.id);
              } catch (_) {
                _message(
                    'Habit deleted, but its reminder could not be cancelled.');
              }
            } catch (_) {
              _message('Could not delete your habit. Please try again.');
            }
          }
          // Firestore removes the row; leave dismissal to its stream so errors can recover.
          return false;
        },
        child: HabitTile(
            habit: data,
            onToggle: () =>
                _toggle(doc, HabitProgress.completed(data, DateTime.now())),
            onSchedule: () => _schedule(doc),
            onEdit: () => _openEditor(doc)));
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (sheet) => SafeArea(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const ListTile(title: Text('Change profile photo')),
              ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(sheet, ImageSource.camera)),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(sheet, ImageSource.gallery)),
              if (_profileImagePath != null)
                ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Remove photo'),
                    onTap: () async {
                      await (await SharedPreferences.getInstance())
                          .remove('profileImage_${_user?.uid}');
                      if (mounted) setState(() => _profileImagePath = null);
                      if (sheet.mounted) Navigator.pop(sheet);
                    }),
            ])));
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return;
      await (await SharedPreferences.getInstance())
          .setString('profileImage_${_user?.uid}', picked.path);
      if (mounted) setState(() => _profileImagePath = picked.path);
    } catch (_) {
      _message(
          'Could not open your photo. Check camera or photo permissions in device settings.');
    }
  }

  void _showInfo(String title, String body) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: Theme.of(sheet).textTheme.titleLarge),
                    const SizedBox(height: 18),
                    Text(body, style: const TextStyle(height: 1.7)),
                    const SizedBox(height: 22),
                    OutlinedButton(
                        onPressed: () => Navigator.pop(sheet),
                        child: const Text('Got it'))
                  ]))));
  void _notifications() => showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Your reminders',
                        style: Theme.of(sheet).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    const Text(
                        'Use the tune control on any habit to choose its reminder time and days. Notifications must be enabled in device settings.'),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                        onPressed: () async {
                          try {
                            if (!await ReminderService.instance
                                .requestPermission()) {
                              _message(
                                  'Enable notifications in device settings first.');
                              return;
                            }
                            await ReminderService.instance.plugin.show(
                                0,
                                'Your rhythm is waiting',
                                'Vertx reminders are ready.',
                                ReminderService.details);
                          } catch (_) {
                            _message(
                                'Could not send a notification on this device.');
                          }
                        },
                        icon: const Icon(Icons.notifications_none),
                        label: const Text('Test notification')),
                  ]))));
  Future<void> _signOut() async {
    try {
      await ReminderService.instance.cancelAll();
      await AuthService().signOut();
      appThemeMode.value = ThemeMode.light;
      if (mounted) context.go('/login');
    } catch (_) {
      _message('Could not finish signing out. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
          body: SafeArea(
              child: Center(
                  child: FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign in')))));
    }
    return Scaffold(
        body: SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _habitStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                                'Could not load your habits. Check your connection and try again.',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface))));
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: FlowColors.ivory));
                  }
                  final habits = snapshot.data!.docs,
                      due = habits
                          .where((doc) =>
                              HabitProgress.isDue(_data(doc), DateTime.now()))
                          .toList();
                  return IndexedStack(index: _index, children: [
                    TodayPanel(
                        name: _name,
                        habits: due.map(_data).toList(),
                        cards: due.map(_habitCard).toList(),
                        onAdd: () => _openEditor(),
                        onFocus: () => setState(() => _index = 2),
                        onGoals: () => setState(() => _index = 3)),
                    HabitListPanel(
                        habits: habits.map(_data).toList(),
                        cards: habits.map(_habitCard).toList(),
                        onAdd: () => _openEditor()),
                    const FocusScreen(),
                    GoalsPanel(
                        habits: habits.map(_data).toList(),
                        onEdit: (i) => _schedule(habits[i])),
                    ProfilePanel(
                        name: _name,
                        dark: Theme.of(context).brightness == Brightness.dark,
                        image: _profileImagePath == null
                            ? null
                            : FileImage(File(_profileImagePath!)),
                        onDarkChanged: (dark) async {
                          appThemeMode.value =
                              dark ? ThemeMode.dark : ThemeMode.light;
                          await (await SharedPreferences.getInstance())
                              .setBool('darkMode', dark);
                        },
                        onPhoto: _pickPhoto,
                        onNotifications: _notifications,
                        onPrivacy: () => _showInfo('Privacy',
                            'Your habits and saved focus sessions are stored in your Firebase account. Reminder schedules, active timer recovery and your chosen profile photo are stored on this device. You can delete individual habits by swiping left.'),
                        onHelp: () => _showInfo('Help & support',
                            'Tap a habit or its check circle to complete it.\n\nUse the tune control for repeat days, reminders and session goals. Rest days do not break a streak.\n\nLong press a habit to edit it, or swipe left to delete it.\n\nStart a focus session from Focus. Completed focus sessions are saved separately from habit completions.\n\nVisit Grow to see your milestones and recorded weekly progress.'),
                        onSignOut: _signOut),
                  ]);
                })),
        bottomNavigationBar: FlowNavigationBar(
            index: _index, onChanged: (i) => setState(() => _index = i)));
  }
}
