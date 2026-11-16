import 'package:flutter/material.dart';
import '../../models/habit_progress.dart';
import '../../utils/app_theme.dart';
import '../../widgets/flow_layout.dart';
import '../../widgets/habit_tile.dart';
import '../../widgets/schedule_fields.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key, this.initial});
  final Map<String, dynamic>? initial;
  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  String _selectedCategory = 'Health';
  IconData _selectedIcon = Icons.menu_book_outlined;
  late Map<String, dynamic> _schedule;
  bool _showMoreIcons = false;
  bool _showAllCategories = false;
  bool _isLoadingAI = false;
  List<Map<String, dynamic>> _aiSuggestions = [];
  static const _categories = [
    'Health',
    'Learning',
    'Mindfulness',
    'Fitness',
    'Finance',
    'Social'
  ];
  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? <String, dynamic>{};
    _nameController.text = initial['name'] as String? ?? '';
    _selectedCategory = initial['category'] as String? ?? 'Health';
    _showAllCategories = !_categories.take(3).contains(_selectedCategory);
    if (initial['iconCode'] != null) {
      _selectedIcon = habitIcon(initial['iconCode'] as int);
    }
    _schedule = {
      'weekdays': HabitProgress.weekdays(initial),
      'goalTarget': HabitProgress.goal(initial),
      'reminderEnabled': initial['reminderEnabled'] ?? false,
      'reminderMinutes': initial['reminderMinutes'] ?? 540
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'icon': _selectedIcon,
      'color': Color(widget.initial?['colorValue'] as int? ??
          FlowColors.charcoal.toARGB32()),
      'frequency': 'Custom',
      ..._schedule
    });
  }

  void _selectIdea(Map<String, dynamic> idea) {
    setState(() {
      _nameController.text = idea['name'] as String;
      _selectedCategory = idea['category'] as String;
      _showAllCategories = !_categories.take(3).contains(_selectedCategory);
      _selectedIcon = _selectedCategory == 'Learning'
          ? Icons.menu_book_outlined
          : _selectedCategory == 'Fitness'
              ? Icons.directions_run_outlined
              : Icons.spa_outlined;
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final icons = [
      Icons.menu_book_outlined,
      Icons.spa_outlined,
      Icons.water_drop_outlined,
      if (_showMoreIcons) ...[
        Icons.directions_run_outlined,
        Icons.self_improvement_outlined,
        Icons.bedtime_outlined,
        Icons.favorite_outline,
        Icons.star_outline,
        Icons.music_note_outlined,
        Icons.code_outlined,
        Icons.brush_outlined,
        Icons.restaurant_outlined
      ],
      if (!_showMoreIcons &&
          !const [
            Icons.menu_book_outlined,
            Icons.spa_outlined,
            Icons.water_drop_outlined
          ].contains(_selectedIcon))
        _selectedIcon
    ];
    return Scaffold(
        body: SafeArea(
            bottom: false,
            child: Form(
                key: _formKey,
                child: FlowLayout(
                    header: FlowHeader(
                        compact: true,
                        onBack: () => Navigator.pop(context),
                        title:
                            editing ? 'Shape your habit' : 'Plant a new habit',
                        subtitle: 'Make a little space for yourself.',
                        child: const SizedBox(height: 20)),
                    children: [
                      const Text('Habit name',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 80,
                          decoration: const InputDecoration(
                              hintText: 'e.g. Read 10 pages', counterText: ''),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Give your habit a name.'
                                  : null),
                      const SizedBox(height: 22),
                      Row(children: [
                        const Expanded(
                            child: Text('Category',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500))),
                        TextButton(
                            onPressed: () => setState(
                                () => _showAllCategories = !_showAllCategories),
                            child: Text(_showAllCategories ? 'Fewer' : 'More',
                                style: const TextStyle(fontSize: 11)))
                      ]),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_showAllCategories
                                  ? _categories
                                  : _categories.take(3))
                              .map((category) => FlowPill(
                                  label: category,
                                  selected: _selectedCategory == category,
                                  onTap: () => setState(
                                      () => _selectedCategory = category)))
                              .toList()),
                      const SizedBox(height: 24),
                      ScheduleFields(
                          initial: _schedule,
                          onChanged: (value) => _schedule = value),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Expanded(child: Text('Icon')),
                        TextButton(
                            onPressed: () => setState(
                                () => _showMoreIcons = !_showMoreIcons),
                            child: Text(
                                _showMoreIcons ? 'Fewer icons' : 'More icons',
                                style: const TextStyle(fontSize: 11)))
                      ]),
                      Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: icons.map((icon) {
                            final selected = icon == _selectedIcon;
                            return IconButton.filledTonal(
                                onPressed: () =>
                                    setState(() => _selectedIcon = icon),
                                isSelected: selected,
                                tooltip: icon == Icons.menu_book_outlined
                                    ? 'Book'
                                    : icon == Icons.spa_outlined
                                        ? 'Leaf'
                                        : icon == Icons.water_drop_outlined
                                            ? 'Water'
                                            : 'Habit icon',
                                style: IconButton.styleFrom(
                                    backgroundColor: selected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                    foregroundColor: selected
                                        ? Theme.of(context).colorScheme.surface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                icon: Icon(icon));
                          }).toList()),
                      const SizedBox(height: 28),
                      FilledButton(
                          onPressed: _save,
                          child:
                              Text(editing ? 'Save changes' : 'Create habit')),
                      if (!editing) ...[
                        const SizedBox(height: 14),
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: const Text('Need a starting point?',
                                style: TextStyle(fontSize: 12)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text(
                                      'Describe your goal for a few habit ideas.',
                                      style: TextStyle(fontSize: 12))),
                              TextField(
                                  controller: _goalController,
                                  decoration: const InputDecoration(
                                      hintText: 'e.g. Learn something new')),
                              TextButton(
                                  onPressed:
                                      _isLoadingAI ? null : _getAISuggestions,
                                  child: const Text('Find habit ideas')),
                              ..._aiSuggestions.map((idea) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(idea['name'] as String,
                                      style: const TextStyle(fontSize: 12)),
                                  subtitle: Text(idea['reason'] as String,
                                      style: const TextStyle(fontSize: 10)),
                                  trailing: const Icon(Icons.add, size: 18),
                                  onTap: () => _selectIdea(idea))),
                            ]),
                      ],
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ]))));
  }

  Future<void> _getAISuggestions() async {
    if (_goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your goal first!'),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAI = true;
      _aiSuggestions = [];
    });

    final goal = _goalController.text.toLowerCase();
    List<Map<String, dynamic>> suggestions = [];

    if (goal.contains('weight') ||
        goal.contains('fit') ||
        goal.contains('health')) {
      suggestions = [
        {
          'name': 'Exercise 30 mins daily',
          'category': 'Fitness',
          'reason': 'Burns calories and builds strength',
        },
        {
          'name': 'Drink 8 glasses of water',
          'category': 'Health',
          'reason': 'Keeps metabolism active',
        },
        {
          'name': 'Eat vegetables every meal',
          'category': 'Health',
          'reason': 'Provides essential nutrients',
        },
        {
          'name': 'Sleep 7-8 hours',
          'category': 'Health',
          'reason': 'Recovery is key to fitness',
        },
      ];
    } else if (goal.contains('learn') ||
        goal.contains('study') ||
        goal.contains('read')) {
      suggestions = [
        {
          'name': 'Read 20 pages daily',
          'category': 'Learning',
          'reason': 'Builds knowledge consistently',
        },
        {
          'name': 'Watch 1 tutorial video',
          'category': 'Learning',
          'reason': 'Visual learning is effective',
        },
        {
          'name': 'Practice for 30 mins',
          'category': 'Learning',
          'reason': 'Repetition builds mastery',
        },
        {
          'name': 'Review notes before bed',
          'category': 'Learning',
          'reason': 'Consolidates memory during sleep',
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
          'reason': 'Reduces stress and anxiety',
        },
        {
          'name': 'Write in journal',
          'category': 'Mindfulness',
          'reason': 'Processes emotions effectively',
        },
        {
          'name': 'Take a walk in nature',
          'category': 'Mindfulness',
          'reason': 'Clears mind naturally',
        },
        {
          'name': 'Deep breathing exercises',
          'category': 'Mindfulness',
          'reason': 'Activates calm response',
        },
      ];
    } else if (goal.contains('money') ||
        goal.contains('sav') ||
        goal.contains('financ')) {
      suggestions = [
        {
          'name': 'Track daily expenses',
          'category': 'Finance',
          'reason': 'Awareness leads to better spending',
        },
        {
          'name': 'Save 10% of income',
          'category': 'Finance',
          'reason': 'Builds emergency fund over time',
        },
        {
          'name': 'Review budget weekly',
          'category': 'Finance',
          'reason': 'Keeps finances on track',
        },
        {
          'name': 'Avoid impulse purchases',
          'category': 'Finance',
          'reason': 'Saves money long term',
        },
      ];
    } else if (goal.contains('social') ||
        goal.contains('friend') ||
        goal.contains('connect')) {
      suggestions = [
        {
          'name': 'Call a friend daily',
          'category': 'Social',
          'reason': 'Maintains meaningful relationships',
        },
        {
          'name': 'Compliment someone today',
          'category': 'Social',
          'reason': 'Builds positive connections',
        },
        {
          'name': 'Join a group activity',
          'category': 'Social',
          'reason': 'Expands social circle',
        },
        {
          'name': 'Send a thank you message',
          'category': 'Social',
          'reason': 'Strengthens bonds',
        },
      ];
    } else {
      // Default suggestions for any goal
      suggestions = [
        {
          'name': 'Wake up at 6 AM',
          'category': 'Health',
          'reason': 'Start the day with intention',
        },
        {
          'name': 'Plan your day each morning',
          'category': 'Mindfulness',
          'reason': 'Increases productivity',
        },
        {
          'name': 'Exercise 20 mins',
          'category': 'Fitness',
          'reason': 'Boosts energy and focus',
        },
        {
          'name': 'Read for 15 mins',
          'category': 'Learning',
          'reason': 'Continuous self-improvement',
        },
      ];
    }

    setState(() {
      _aiSuggestions = suggestions;
      _isLoadingAI = false;
    });
  }
}
