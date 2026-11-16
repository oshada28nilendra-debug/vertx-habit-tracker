import '../../widgets/habit_tile.dart';
import 'dart:async';
import '../../utils/app_theme.dart';
import '../../models/habit_progress.dart';
import '../../services/reminder_service.dart';
import '../../widgets/schedule_fields.dart';
import '../../widgets/progress_panels.dart';
import '../focus/focus_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../habits/add_habit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _dayTimer;
  final Set<String> _pendingHabits = {};
  int _currentIndex = 0;
  bool _isDarkMode = false;
  String? _profileImagePath;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final name = _user?.displayName;
    if (name != null && name.isNotEmpty) return name;
    final email = _user?.email ?? '';
    return email.split('@').first;
  }

  // ============================================================
  // DATABASE & BACKEND MODULE — Role 1: Project Lead & Database Developer
  // Developer:Dissanayaka Dissanayaka
  // Responsibilities:
  // - Firebase Firestore database structure and configuration
  // - Security rules — user data isolation
  // - Streak calculation algorithm
  // - Daily habit reset system (SharedPreferences)
  // - GitHub repository management and deployment
  // ============================================================
  CollectionReference get _habitsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user?.uid)
      .collection('habits');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _restoreReminders();
    _loadProfileImage();
    _loadAppearance();
  }

  // ============================================================
  // DEVICE FEATURES MODULE — Role 7: Device Features Developer
  // Developer: Kotuwe Kotuwegedara
  // Responsibilities:
  // - Camera integration (capture profile photos)
  // - Gallery access (select images)
  // - Push notifications (Firebase / local notifications)
  // - Permission handling (Camera, Storage, Notifications)
  // - AndroidManifest configuration
  // ============================================================

  // ── Permissions ────────────────────────────────────────────────────────────
  Future<void> _loadAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('darkMode');
    if (!mounted) return;
    setState(
      () => _isDarkMode =
          dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    );
    appThemeMode.value = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _restoreReminders();
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _restoreReminders() async {
    try {
      final docs = await _habitsRef.get();
      await ReminderService.instance.refreshTimeZone();
      for (final doc in docs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['reminderEnabled'] == true) {
          await ReminderService.instance.scheduleHabit(doc.id, data);
        }
      }
    } catch (_) {
      _message(
        'Reminders could not be restored. Check notification permissions and reopen the app.',
      );
    }
  }

  Map<String, dynamic> _data(QueryDocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    // Preserve the one historical date legacy records actually know.
    if (!data.containsKey('completionDays') &&
        data['lastCompleted'] is Timestamp) {
      final last = (data['lastCompleted'] as Timestamp).toDate();
      data['completionDays'] = {HabitProgress.dayKey(last): true};
    }
    if (data['createdAt'] is Timestamp) {
      data['createdDay'] = HabitProgress.dayKey(
        (data['createdAt'] as Timestamp).toDate(),
      );
    }
    return data;
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
    );
    if (result != null) {
      try {
        await _addHabit(result);
      } catch (_) {
        _message('Could not create your habit. Please try again.');
      }
    }
  }

  Future<void> _schedule(QueryDocumentSnapshot doc) async {
    var changes = <String, dynamic>{};
    final data = _data(doc);
    final initial = {...data, 'weekdays': HabitProgress.weekdays(data)};
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['name'] ?? 'Your routine',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ScheduleFields(
                initial: initial,
                onChanged: (value) => changes = value,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('Save routine'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    final updated = {...initial, ...changes};
    try {
      if (updated['reminderEnabled'] == true &&
          !await ReminderService.instance.requestPermission()) {
        _message(
          'Routine saved without reminders. Enable notifications in device settings to use them.',
        );
        updated['reminderEnabled'] = false;
      }
      await doc.reference.update({
        for (final key in [
          'weekdays',
          'goalTarget',
          'reminderEnabled',
          'reminderMinutes',
        ])
          if (updated[key] != null) key: updated[key],
      });
      try {
        await ReminderService.instance.scheduleHabit(doc.id, updated);
      } catch (_) {
        _message(
          'Routine saved, but the reminder could not be scheduled. Reopen the app to retry.',
        );
      }
    } catch (_) {
      _message('Could not save your routine. Please try again.');
    }
  }

  Future<void> _sendNotification(String title, String body) async {
    try {
      if (!await ReminderService.instance.requestPermission()) {
        _message('Notifications are disabled. Enable them in device settings.');
        return;
      }
      await ReminderService.instance.plugin.show(
        0,
        title,
        body,
        ReminderService.details,
      );
    } catch (_) {
      _message('Could not send a notification on this device.');
    }
  }

  // ── Profile Image ──────────────────────────────────────────────────────────

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profileImage_${_user?.uid}');
    if (path != null && File(path).existsSync()) {
      setState(() => _profileImagePath = path);
    }
  }

  Future<void> _pickProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Change Profile Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.camera);
                  },
                ),
                _imageSourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () async {
                    Navigator.pop(context);
                    await _getImage(ImageSource.gallery);
                  },
                ),
                if (_profileImagePath != null)
                  _imageSourceOption(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('profileImage_${_user?.uid}');
                      setState(() => _profileImagePath = null);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF6C63FF),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImage_${_user?.uid}', picked.path);
        setState(() => _profileImagePath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // ============================================================
  // STREAK CALCULATION & HABIT TOGGLE — Role 1: Project Lead
  // Developer: Dissanayaka Dissanayaka
  // Completion history drives scheduled-day streaks and session milestones.
  // ============================================================
  // ── Habits ─────────────────────────────────────────────────────────────────

  Future<void> _toggleHabit(String habitId, bool currentDone) async {
    if (!_pendingHabits.add(habitId)) return;
    try {
      final now = DateTime.now();
      final key = HabitProgress.dayKey(now);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ref = _habitsRef.doc(habitId);
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) return;
        final data = Map<String, dynamic>.from(snapshot.data() as Map);
        if (!data.containsKey('completionDays') &&
            data['lastCompleted'] is Timestamp) {
          data['completionDays'] = {
            HabitProgress.dayKey((data['lastCompleted'] as Timestamp).toDate()):
                true,
          };
        }
        final history = HabitProgress.history(data);
        if (currentDone) {
          history.remove(key);
        } else {
          history[key] = true;
        }
        data['completionDays'] = history;
        transaction.update(ref, {
          'completionDays': history,
          'done': !currentDone,
          'streak': HabitProgress.streak(data, now),
          'lastCompleted':
              currentDone ? data['lastCompleted'] : Timestamp.fromDate(now),
        });
      });
    } catch (_) {
      _message('Could not update your habit. Please try again.');
    } finally {
      _pendingHabits.remove(habitId);
    }
  }

  Future<void> _addHabit(Map<String, dynamic> habit) async {
    final data = <String, dynamic>{
      'name': habit['name'],
      'iconCode': (habit['icon'] as IconData).codePoint,
      'iconFontFamily': (habit['icon'] as IconData).fontFamily,
      'colorValue': (habit['color'] as Color).toARGB32(),
      'category': habit['category'],
      'frequency': habit['frequency'] ?? 'Daily',
      'weekdays': habit['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7],
      'goalTarget': habit['goalTarget'] ?? 21,
      'reminderEnabled': habit['reminderEnabled'] ?? false,
      'reminderMinutes': habit['reminderMinutes'] ?? 540,
      'completionDays': <String, bool>{},
      'done': false,
      'streak': 0,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (data['reminderEnabled'] == true &&
        !await ReminderService.instance.requestPermission()) {
      data['reminderEnabled'] = false;
      _message(
        'Notifications are disabled. Your habit will be saved without reminders.',
      );
    }
    final ref = await _habitsRef.add(data);
    try {
      await ReminderService.instance.scheduleHabit(ref.id, data);
    } catch (_) {
      _message(
        'Habit saved. The reminder could not be scheduled; reopen the app to retry.',
      );
    }
  }

  Future<void> _editHabit(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    String selectedCategory = data['category'] ?? 'Health';
    final categories = [
      'Health',
      'Fitness',
      'Learning',
      'Mindfulness',
      'Finance',
      'Social',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Habit',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      _message('Give your habit a name first.');
                      return;
                    }
                    try {
                      await _habitsRef.doc(doc.id).update({
                        'name': nameController.text.trim(),
                        'category': selectedCategory,
                      });
                    } catch (_) {
                      _message(
                        'Could not update this habit. Please try again.',
                      );
                      return;
                    }
                    try {
                      await ReminderService.instance.scheduleHabit(doc.id, {
                        ...data,
                        'name': nameController.text.trim(),
                      });
                    } catch (_) {
                      _message(
                        'Habit updated. Reopen the app to refresh reminders.',
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // Dated completions roll over without destructive midnight writes.
  // ── Dialogs ────────────────────────────────────────────────────────────────

  //  UI/UX & Settings Developer
  // Developer: [Udan Wijetunga] | GitHub: [udangit]

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your little nudges',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Use the tune button on any habit to choose its reminder time and weekdays. Device notification permissions must be enabled.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _sendNotification(
                  'Hello from Vertx ✨',
                  'Your little nudges are ready.',
                ),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Test notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your habits and saved focus sessions are stored in your Firebase account. '
              'Reminder schedules and active timer recovery are stored on this device. '
              'You can remove individual habits by swiping left.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            _helpItem(
              Icons.add_circle_outline,
              'How to add a habit',
              'Tap the + button on the Habits page',
            ),
            _helpItem(
              Icons.check_circle_outline,
              'How to complete a habit',
              'Tap on any habit card to mark it done',
            ),
            _helpItem(
              Icons.local_fire_department_outlined,
              'How streaks work',
              'Complete habits on your chosen days to grow your streak',
            ),
            _helpItem(
              Icons.camera_alt_outlined,
              'Profile photo',
              'Tap your profile picture to change it',
            ),
            _helpItem(
              Icons.bar_chart,
              'Analytics',
              'View your progress and stats on the Analytics page',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor =
        _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFFFF9F2);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _habitsRef.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your habits. Check your connection and try again.',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final habits = snapshot.data?.docs ?? [];
          final due = habits
              .where((h) => HabitProgress.isDue(_data(h), DateTime.now()))
              .toList();
          final completedCount = due
              .where((h) => HabitProgress.completed(_data(h), DateTime.now()))
              .length;
          final progress = due.isEmpty ? 0.0 : completedCount / due.length;

          return SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboard(due, completedCount, progress),
                _buildHabitsPage(habits),
                const FocusScreen(),
                _buildAnalyticsPage(habits),
                _buildProfilePage(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() => NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.wb_sunny_rounded), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline), label: 'Habits'),
          NavigationDestination(icon: Icon(Icons.timelapse), label: 'Focus'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined), label: 'Grow'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
        ],
      );

  Widget _buildDashboard(
    List<QueryDocumentSnapshot> habits,
    int completedCount,
    double progress,
  ) =>
      TodayPanel(
        name: _displayName,
        habits: habits.map(_data).toList(),
        cards: habits.map(_habitCard).toList(),
        onAdd: _openAdd,
        onFocus: () => setState(() => _currentIndex = 2),
        onGoals: () => setState(() => _currentIndex = 3),
      );

  Widget _habitCard(QueryDocumentSnapshot doc) {
    final data = _data(doc);
    final isDone = HabitProgress.completed(data, DateTime.now());
    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Habit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to delete "${data['name']}"?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return false;
        try {
          await _habitsRef.doc(doc.id).delete();
        } catch (_) {
          _message('Could not delete this habit. Please try again.');
          return false;
        }
        try {
          await ReminderService.instance.cancelHabit(doc.id);
        } catch (_) {
          _message(
            'Habit deleted. Its reminder could not be cancelled on this device.',
          );
        }
        return true;
      },
      child: HabitTile(
        habit: data,
        onToggle: () => _toggleHabit(doc.id, isDone),
        onSchedule: () => _schedule(doc),
        onEdit: () => _editHabit(doc),
      ),
    );
  }

  Widget _buildHabitsPage(List<QueryDocumentSnapshot> habits) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Habits',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                GestureDetector(
                  onTap: _openAdd,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        'No habits yet!\nTap + to add your first habit.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) =>
                          _habitCard(habits[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANALYTICS PAGE : AI & Analytics Developer
  // Developer: Vidana Rakjitha | GitHub: nethuparakjitha
  // Features:
  //   - Weekly overview bar chart (7-day completion tracking)
  //   - Today's completion progress with linear indicator
  //   - Best streak calculation across all habits
  //   - Total habits statistics card
  // ============================================================
  Widget _buildAnalyticsPage(List<QueryDocumentSnapshot> habits) => GoalsPanel(
        habits: habits.map(_data).toList(),
        onEdit: (index) => _schedule(habits[index]),
      );

  Widget _buildProfilePage() {
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF6C63FF),
                        width: 2,
                      ),
                    ),
                    child: _profileImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.file(
                              File(_profileImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 44,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _displayName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              _user?.email ?? '',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 28),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.dark_mode_outlined,
                    color: Color(0xFF6C63FF),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Dark Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (val) async {
                      setState(() => _isDarkMode = val);
                      appThemeMode.value =
                          val ? ThemeMode.dark : ThemeMode.light;
                      await (await SharedPreferences.getInstance()).setBool(
                        'darkMode',
                        val,
                      );
                    },
                    activeThumbColor: const Color(0xFF6C63FF),
                  ),
                ],
              ),
            ),
            _profileItem(
              Icons.notifications_outlined,
              'Notifications',
              textColor,
              onTap: () => _showNotificationsDialog(),
            ),
            _profileItem(
              Icons.shield_outlined,
              'Privacy',
              textColor,
              onTap: () => _showPrivacyDialog(),
            ),
            _profileItem(
              Icons.help_outline,
              'Help & Support',
              textColor,
              onTap: () => _showHelpDialog(),
            ),
            const SizedBox(height: 8),
            _profileItem(
              Icons.logout,
              'Sign Out',
              textColor,
              isRed: true,
              onTap: () async {
                try {
                  await ReminderService.instance.cancelAll();
                } catch (_) {
                  _message(
                    'Could not clear this device’s reminders. Please try signing out again.',
                  );
                  return;
                }
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(
    IconData icon,
    String title,
    Color textColor, {
    bool isRed = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isRed ? Colors.red : const Color(0xFF6C63FF),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isRed ? Colors.red : textColor,
              ),
            ),
            const Spacer(),
            if (!isRed)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
