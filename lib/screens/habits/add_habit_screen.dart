import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}
// ============================================================
// ADD HABIT SCREEN — Role 5: AI & Analytics Developer
// Developer: Vidana Rakjitha | GitHub: nethuparakjitha
// Features:
//   - AI Habit Suggestions engine (keyword-based analysis)
//   - Goal-to-habit recommendation system
//   - Category auto-mapping with icons and colors
// ============================================================
class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  String _selectedCategory = 'Health';
  Color _selectedColor = const Color(0xFF6C63FF);
  IconData _selectedIcon = Icons.star_outline;
  String _selectedFrequency = 'Daily';
  bool _isLoadingAI = false;
  List<Map<String, dynamic>> _aiSuggestions = [];

  final List<String> _categories = [
    'Health',
    'Fitness',
    'Learning',
    'Mindfulness',
    'Finance',
    'Social'
  ];

  final List<String> _frequencies = ['Daily', 'Weekly', 'Weekdays'];

  final List<Color> _colors = [
    const Color(0xFF6C63FF),
    const Color(0xFFFF6B6B),
    const Color(0xFF26C6A6),
    const Color(0xFFFFB347),
    const Color(0xFF3D5AF1),
    const Color(0xFFEC407A),
  ];

  final List<IconData> _icons = [
    Icons.water_drop_outlined,
    Icons.fitness_center_outlined,
    Icons.menu_book_outlined,
    Icons.self_improvement_outlined,
    Icons.bedtime_outlined,
    Icons.directions_run_outlined,
    Icons.favorite_outline,
    Icons.star_outline,
    Icons.music_note_outlined,
    Icons.code_outlined,
    Icons.brush_outlined,
    Icons.restaurant_outlined,
  ];

  // Map categories to icons and colors for AI suggestions
  final Map<String, IconData> _categoryIcons = {
    'Health': Icons.favorite_outline,
    'Fitness': Icons.fitness_center_outlined,
    'Learning': Icons.menu_book_outlined,
    'Mindfulness': Icons.self_improvement_outlined,
    'Finance': Icons.attach_money,
    'Social': Icons.people_outline,
  };

  final Map<String, Color> _categoryColors = {
    'Health': const Color(0xFF26C6A6),
    'Fitness': const Color(0xFFFF6B6B),
    'Learning': const Color(0xFF6C63FF),
    'Mindfulness': const Color(0xFF3D5AF1),
    'Finance': const Color(0xFFFFB347),
    'Social': const Color(0xFFEC407A),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }
// AI Suggestion Engine — Analyses user goal keywords
// and returns personalised habit recommendations
// Developer: Vidana Rakjitha
  Future<void> _getAISuggestions() async {
    if (_goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your goal first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAI = true;
      _aiSuggestions = [];
    });

    // Simulate AI thinking delay
    await Future.delayed(const Duration(seconds: 2));

    final goal = _goalController.text.toLowerCase();
    List<Map<String, dynamic>> suggestions = [];

    if (goal.contains('weight') ||
        goal.contains('fit') ||
        goal.contains('health')) {
      suggestions = [
        {
          'name': 'Exercise 30 mins daily',
          'category': 'Fitness',
          'reason': 'Burns calories and builds strength'
        },
        {
          'name': 'Drink 8 glasses of water',
          'category': 'Health',
          'reason': 'Keeps metabolism active'
        },
        {
          'name': 'Eat vegetables every meal',
          'category': 'Health',
          'reason': 'Provides essential nutrients'
        },
        {
          'name': 'Sleep 7-8 hours',
          'category': 'Health',
          'reason': 'Recovery is key to fitness'
        },
      ];
    } else if (goal.contains('learn') ||
        goal.contains('study') ||
        goal.contains('read')) {
      suggestions = [
        {
          'name': 'Read 20 pages daily',
          'category': 'Learning',
          'reason': 'Builds knowledge consistently'
        },
        {
          'name': 'Watch 1 tutorial video',
          'category': 'Learning',
          'reason': 'Visual learning is effective'
        },
        {
          'name': 'Practice for 30 mins',
          'category': 'Learning',
          'reason': 'Repetition builds mastery'
        },
        {
          'name': 'Review notes before bed',
          'category': 'Learning',
          'reason': 'Consolidates memory during sleep'
        },
      ];
    } else if (goal.contains('stress') ||
        goal.contains('calm') ||
        goal.contains('mind') ||
        goal.contains('meditat')) {
      suggestions = [
        {
          'name': 'Meditate 10 mins',
          'category': 'Mindfulness',
          'reason': 'Reduces stress and anxiety'
        },
        {
          'name': 'Write in journal',
          'category': 'Mindfulness',
          'reason': 'Processes emotions effectively'
        },
        {
          'name': 'Take a walk in nature',
          'category': 'Mindfulness',
          'reason': 'Clears mind naturally'
        },
        {
          'name': 'Deep breathing exercises',
          'category': 'Mindfulness',
          'reason': 'Activates calm response'
        },
      ];
    } else if (goal.contains('money') ||
        goal.contains('sav') ||
        goal.contains('financ')) {
      suggestions = [
        {
          'name': 'Track daily expenses',
          'category': 'Finance',
          'reason': 'Awareness leads to better spending'
        },
        {
          'name': 'Save 10% of income',
          'category': 'Finance',
          'reason': 'Builds emergency fund over time'
        },
        {
          'name': 'Review budget weekly',
          'category': 'Finance',
          'reason': 'Keeps finances on track'
        },
        {
          'name': 'Avoid impulse purchases',
          'category': 'Finance',
          'reason': 'Saves money long term'
        },
      ];
    } else if (goal.contains('social') ||
        goal.contains('friend') ||
        goal.contains('connect')) {
      suggestions = [
        {
          'name': 'Call a friend daily',
          'category': 'Social',
          'reason': 'Maintains meaningful relationships'
        },
        {
          'name': 'Compliment someone today',
          'category': 'Social',
          'reason': 'Builds positive connections'
        },
        {
          'name': 'Join a group activity',
          'category': 'Social',
          'reason': 'Expands social circle'
        },
        {
          'name': 'Send a thank you message',
          'category': 'Social',
          'reason': 'Strengthens bonds'
        },
      ];
    } else {
      // Default suggestions for any goal
      suggestions = [
        {
          'name': 'Wake up at 6 AM',
          'category': 'Health',
          'reason': 'Start the day with intention'
        },
        {
          'name': 'Plan your day each morning',
          'category': 'Mindfulness',
          'reason': 'Increases productivity'
        },
        {
          'name': 'Exercise 20 mins',
          'category': 'Fitness',
          'reason': 'Boosts energy and focus'
        },
        {
          'name': 'Read for 15 mins',
          'category': 'Learning',
          'reason': 'Continuous self-improvement'
        },
      ];
    }

    setState(() {
      _aiSuggestions = suggestions;
      _isLoadingAI = false;
    });
  }
// Auto-fills habit form from selected AI suggestion
// Developer: Vidana Rakjitha
  void _selectAISuggestion(Map<String, dynamic> suggestion) {
    final category = suggestion['category'] as String;
    setState(() {
      _nameController.text = suggestion['name'];
      _selectedCategory = _categories.contains(category) ? category : 'Health';
      _selectedIcon = _categoryIcons[_selectedCategory] ?? Icons.star_outline;
      _selectedColor =
          _categoryColors[_selectedCategory] ?? const Color(0xFF6C63FF);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${suggestion['name']}" selected! Tap Create Habit.'),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A2E),
            size: 20,
          ),
        ),
        title: Text(
          'New Habit',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AI Suggestions Section ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3D5AF1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Habit Suggestions',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _goalController,
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. I want to lose weight and stay healthy',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAI ? null : _getAISuggestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _isLoadingAI
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6C63FF),
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _isLoadingAI
                            ? 'Getting suggestions...'
                            : 'Get AI Suggestions',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── AI Results ──────────────────────────────────────────────
            if (_aiSuggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Tap a suggestion to use it:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ..._aiSuggestions.map((suggestion) {
                final category = suggestion['category'] as String;
                final color =
                    _categoryColors[category] ?? const Color(0xFF6C63FF);
                final icon = _categoryIcons[category] ?? Icons.star_outline;
                return GestureDetector(
                  onTap: () => _selectAISuggestion(suggestion),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                suggestion['reason'],
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 20),

            // ── Manual Entry ────────────────────────────────────────────
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  _selectedIcon,
                  color: _selectedColor,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Habit Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Drink 8 glasses of water',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF6C63FF),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFF6C63FF) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Frequency'),
            const SizedBox(height: 8),
            Row(
              children: _frequencies.map((freq) {
                final isSelected = _selectedFrequency == freq;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFrequency = freq),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFF6C63FF) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        freq,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Color'),
            const SizedBox(height: 8),
            Row(
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Icon'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final icon = _icons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.15)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    Navigator.pop(context, {
                      'name': _nameController.text,
                      'category': _selectedCategory,
                      'color': _selectedColor,
                      'icon': _selectedIcon,
                      'frequency': _selectedFrequency,
                      'done': false,
                      'streak': 0,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Create Habit',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
    );
  }
}
