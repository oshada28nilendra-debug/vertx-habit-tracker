import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../habits/add_habit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _notifDaily = true;
  bool _notifStreak = true;
  bool _notifWeekly = false;
  String? _profileImagePath;

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _displayName {
    final name = _user?.displayName;
    if (name != null && name.isNotEmpty) return name;
    final email = _user?.email ?? '';
    return email.split('@').first;
  }

  CollectionReference get _habitsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user?.uid)
      .collection('habits');

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initNotifications();
    _loadProfileImage();
    _resetHabitsIfNewDay();
  }

  // ── Permissions ────────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.notification,
      Permission.storage,
    ].request();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _sendNotification(String title, String body) async {
    // Request permission first
    final status = await Permission.notification.request();
    if (!status.isGranted) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'vertx_habits',
      'Habit Reminders',
      channelDescription: 'Notifications for habit tracking',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
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
            Text('Change Profile Photo',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color:
                        _isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // Request camera permission explicitly
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Camera permission denied. Enable it in Settings.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

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

  // ── Habits ─────────────────────────────────────────────────────────────────

  Future<void> _toggleHabit(String habitId, bool currentDone) async {
    final doc = await _habitsRef.doc(habitId).get();
    final data = doc.data() as Map<String, dynamic>;

    if (!currentDone) {
      final today = DateTime.now();
      final lastCompleted = data['lastCompleted'] != null
          ? (data['lastCompleted'] as Timestamp).toDate()
          : null;

      int streak = data['streak'] ?? 0;

      if (lastCompleted != null) {
        final difference = DateTime(today.year, today.month, today.day)
            .difference(DateTime(
                lastCompleted.year, lastCompleted.month, lastCompleted.day))
            .inDays;
        if (difference == 1) {
          streak += 1;
        } else if (difference == 0) {
          // already completed today
        } else {
          streak = 1;
        }
      } else {
        streak = 1;
      }

      await _habitsRef.doc(habitId).update({
        'done': true,
        'streak': streak,
        'lastCompleted': Timestamp.fromDate(today),
      });

      if (streak == 7 || streak == 30 || streak == 100) {
        await _sendNotification(
          '🔥 Streak Milestone!',
          '${data['name']} — $streak day streak! Keep it up!',
        );
      }
    } else {
      await _habitsRef.doc(habitId).update({'done': false});
    }
  }

  Future<void> _addHabit(Map<String, dynamic> habit) async {
    await _habitsRef.add({
      'name': habit['name'],
      'iconCode': (habit['icon'] as IconData).codePoint,
      'iconFontFamily': (habit['icon'] as IconData).fontFamily,
      'colorValue': (habit['color'] as Color).value,
      'done': false,
      'streak': 0,
      'category': habit['category'],
      'createdAt': FieldValue.serverTimestamp(),
    });
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
      'Social'
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
              Text('Edit Habit',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(
                    color:
                        _isDarkMode ? Colors.white : const Color(0xFF1A1A2E)),
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Category',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6C63FF),
                              fontWeight: FontWeight.w500)),
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
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await _habitsRef.doc(doc.id).update({
                      'name': nameController.text.trim(),
                      'category': selectedCategory,
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text('Save Changes',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetHabitsIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastReset = prefs.getString('lastResetDate_${_user?.uid}');

    if (lastReset != todayStr) {
      final habits = await _habitsRef.get();
      for (final doc in habits.docs) {
        await doc.reference.update({'done': false});
      }
      await prefs.setString('lastResetDate_${_user?.uid}', todayStr);

      if (_notifDaily) {
        await _sendNotification(
          '⚡ Daily Habit Check-in',
          'Good morning! Time to crush your habits today 💪',
        );
      }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showNotificationsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _isDarkMode
                          ? Colors.white
                          : const Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              _notifTile(
                  'Daily Reminder',
                  'Get reminded to check your habits',
                  _notifDaily,
                  setModalState,
                  (val) => setState(() => _notifDaily = val)),
              _notifTile(
                  'Streak Alerts',
                  'Alert when streak is about to break',
                  _notifStreak,
                  setModalState,
                  (val) => setState(() => _notifStreak = val)),
              _notifTile(
                  'Weekly Summary',
                  'Weekly progress report every Sunday',
                  _notifWeekly,
                  setModalState,
                  (val) => setState(() => _notifWeekly = val)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.notifications_active,
                      color: Colors.white, size: 18),
                  label: Text('Send Test Notification',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                  onPressed: () async {
                    await _sendNotification(
                      '⚡ Test Notification',
                      'Vertx notifications are working perfectly!',
                    );
                    if (mounted) Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notifTile(String title, String subtitle, bool value,
      StateSetter setModalState, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) => setModalState(() => onChanged(val)),
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
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
            Text('Privacy',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        _isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            Text(
              'Your data is stored securely in Firebase and is never shared with third parties. '
              'Only you can access your habits and progress. '
              'You can delete your account and all associated data at any time.',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Got it',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
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
            Text('Help & Support',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        _isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            _helpItem(Icons.add_circle_outline, 'How to add a habit',
                'Tap the + button on the Habits page'),
            _helpItem(Icons.check_circle_outline, 'How to complete a habit',
                'Tap on any habit card to mark it done'),
            _helpItem(Icons.local_fire_department_outlined, 'How streaks work',
                'Complete a habit daily to grow your streak'),
            _helpItem(Icons.camera_alt_outlined, 'Profile photo',
                'Tap your profile picture to change it'),
            _helpItem(Icons.bar_chart, 'Analytics',
                'View your progress and stats on the Analytics page'),
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
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500])),
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
        _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _habitsRef.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          final habits = snapshot.data?.docs ?? [];
          final completedCount =
              habits.where((h) => (h.data() as Map)['done'] == true).length;
          final progress =
              habits.isEmpty ? 0.0 : completedCount / habits.length;

          return IndexedStack(
            index: _currentIndex,
            children: [
              _buildDashboard(habits, completedCount, progress),
              _buildHabitsPage(habits),
              _buildAnalyticsPage(habits),
              _buildProfilePage(),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.check_circle_outline_rounded, 'Habits'),
              _navItem(2, Icons.bar_chart_rounded, 'Analytics'),
              _navItem(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6C63FF).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? const Color(0xFF6C63FF) : Colors.grey[400],
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isActive ? const Color(0xFF6C63FF) : Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(
      List<QueryDocumentSnapshot> habits, int completedCount, double progress) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
    if (hour >= 17) greeting = 'Good evening';
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[500])),
                    Text('${_displayName}!',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                  ],
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D5AF1)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Progress",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$completedCount / ${habits.length}',
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('${(progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress == 1.0
                        ? 'All habits completed! Amazing!'
                        : '${habits.length - completedCount} habits remaining',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Habits",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Text('See all',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (habits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.add_task, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No habits yet!\nTap + to add your first habit.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...habits.map((doc) => _habitCard(doc)),
          ],
        ),
      ),
    );
  }

  Widget _habitCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isDone = data['done'] == true;
    final color = Color(data['colorValue'] ?? 0xFF6C63FF);
    final iconCode = data['iconCode'] ?? Icons.star.codePoint;
    final icon = IconData(iconCode,
        fontFamily: data['iconFontFamily'] ?? 'MaterialIcons');
    final cardColor = _isDarkMode ? const Color(0xFF16213E) : Colors.white;


      // ============================================================
// Role 3 — Habit Management Developer
// Developer: Dambure Geesilu | GitHub: vigee32
// Features:
//   -Habit categories, icons and colors
// ============================================================
      
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
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Habit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text('Are you sure you want to delete "${data['name']}"?',
                style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete',
                    style: GoogleFonts.poppins(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await _habitsRef.doc(doc.id).delete();
      },
      child: GestureDetector(
        onTap: () => _toggleHabit(doc.id, isDone),
        onLongPress: () => _editHabit(doc),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDone ? const Color(0xFF6C63FF).withOpacity(0.08) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF6C63FF).withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1A1A2E),
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 14, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 4),
                        Text('${data['streak'] ?? 0} day streak',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(data['category'] ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFF6C63FF) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? const Color(0xFF6C63FF) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
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
                Text('My Habits',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _isDarkMode
                            ? Colors.white
                            : const Color(0xFF1A1A2E))),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                    );
                    if (result != null) await _addHabit(result);
                  },
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
                            fontSize: 14, color: Colors.grey[400]),
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
  Widget _buildAnalyticsPage(List<QueryDocumentSnapshot> habits) {
    final completedCount =
        habits.where((h) => (h.data() as Map)['done'] == true).length;
    final totalCount = habits.length;
    int bestStreak = 0;
    for (final h in habits) {
      final streak = (h.data() as Map)['streak'] ?? 0;
      if (streak > bestStreak) bestStreak = streak;
    }
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1A1A2E);
    final cardColor = _isDarkMode ? const Color(0xFF16213E) : Colors.white;
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return labels[day.weekday - 1];
    });
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dayValues = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      int completed = 0;
      for (final h in habits) {
        final data = h.data() as Map<String, dynamic>;
        if (dayStr == todayStr) {
          if (data['done'] == true) completed++;
        } else {
          final lastCompleted = data['lastCompleted'] != null
              ? (data['lastCompleted'] as Timestamp).toDate()
              : null;
          if (lastCompleted != null) {
            final lStr =
                '${lastCompleted.year}-${lastCompleted.month.toString().padLeft(2, '0')}-${lastCompleted.day.toString().padLeft(2, '0')}';
            if (lStr == dayStr) completed++;
          }
        }
      }
      return totalCount == 0 ? 0.0 : completed / totalCount;
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Overview',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final value = dayValues[i];
                      final isToday = i == 6;
                      return Column(
                        children: [
                          Text('${(value * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                  fontSize: 9, color: Colors.grey[500])),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400 + i * 100),
                            width: 32,
                            height: value == 0 ? 8 : 100 * value,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? const Color(0xFF6C63FF)
                                  : value >= 0.8
                                      ? const Color(0xFF6C63FF).withOpacity(0.7)
                                      : const Color(0xFF6C63FF)
                                          .withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(days[i],
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? const Color(0xFF6C63FF)
                                      : Colors.grey[500])),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Text("Today's Completion",
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  const SizedBox(height: 16),
                  totalCount == 0
                      ? Text('Add habits to see analytics',
                          style: GoogleFonts.poppins(color: Colors.grey[400]))
                      : Column(
                          children: [
                            Text('$completedCount / $totalCount habits done',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6C63FF))),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: totalCount == 0
                                    ? 0
                                    : completedCount / totalCount,
                                backgroundColor:
                                    const Color(0xFF6C63FF).withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6C63FF)),
                                minHeight: 12,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _statCard(
                    'Best Streak',
                    '$bestStreak days',
                    Icons.local_fire_department,
                    const Color(0xFFFF6B6B),
                    cardColor,
                    textColor),
                const SizedBox(width: 12),
                _statCard(
                    'Total Habits',
                    '$totalCount habits',
                    Icons.check_circle,
                    const Color(0xFF26C6A6),
                    cardColor,
                    textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
// Statistics Calculations — Best Streak & Total Habits
// Developer: Vidana Rakjitha
  Widget _statCard(String title, String value, IconData icon, Color color,
      Color cardColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                      border:
                          Border.all(color: const Color(0xFF6C63FF), width: 2),
                    ),
                    child: _profileImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.file(
                              File(_profileImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.person,
                            color: Colors.white, size: 44),
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
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(_displayName,
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            Text(_user?.email ?? '',
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
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
                  const Icon(Icons.dark_mode_outlined,
                      color: Color(0xFF6C63FF), size: 22),
                  const SizedBox(width: 14),
                  Text('Dark Mode',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  const Spacer(),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (val) => setState(() => _isDarkMode = val),
                    activeColor: const Color(0xFF6C63FF),
                  ),
                ],
              ),
            ),
            _profileItem(
                Icons.notifications_outlined, 'Notifications', textColor,
                onTap: () => _showNotificationsDialog()),
            _profileItem(Icons.shield_outlined, 'Privacy', textColor,
                onTap: () => _showPrivacyDialog()),
            _profileItem(Icons.help_outline, 'Help & Support', textColor,
                onTap: () => _showHelpDialog()),
            const SizedBox(height: 8),
            _profileItem(Icons.logout, 'Sign Out', textColor, isRed: true,
                onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go('/login');
            }),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, Color textColor,
      {bool isRed = false, VoidCallback? onTap}) {
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
            Icon(icon,
                color: isRed ? Colors.red : const Color(0xFF6C63FF), size: 22),
            const SizedBox(width: 14),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isRed ? Colors.red : textColor)),
            const Spacer(),
            if (!isRed)
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
