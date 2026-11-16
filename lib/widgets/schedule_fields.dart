import 'package:flutter/material.dart';

class ScheduleFields extends StatefulWidget {
  const ScheduleFields({
    super.key,
    required this.initial,
    required this.onChanged,
  });
  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onChanged;
  @override
  State<ScheduleFields> createState() => _ScheduleFieldsState();
}

class _ScheduleFieldsState extends State<ScheduleFields> {
  late Set<int> _days;
  late int _goal;
  late bool _remind;
  late TimeOfDay _time;
  @override
  void initState() {
    super.initState();
    _days = Set<int>.from(widget.initial['weekdays'] ?? [1, 2, 3, 4, 5, 6, 7]);
    _goal = widget.initial['goalTarget'] ?? 21;
    _remind = widget.initial['reminderEnabled'] ?? false;
    final minutes = widget.initial['reminderMinutes'] as int? ?? 540;
    _time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  void _emit() => widget.onChanged({
        'weekdays': _days.toList()..sort(),
        'goalTarget': _goal,
        'reminderEnabled': _remind,
        'reminderMinutes': _time.hour * 60 + _time.minute,
      });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Make it your routine',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Choose your days. Rest days won’t break your streak.'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              7,
              (i) => FilterChip(
                label: Text(
                  const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                ),
                selected: _days.contains(i + 1),
                onSelected: (selected) {
                  if (!selected && _days.length == 1) return;
                  setState(
                      () => selected ? _days.add(i + 1) : _days.remove(i + 1));
                  _emit();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _goal,
            decoration: const InputDecoration(
              labelText: 'Goal • completed sessions',
            ),
            items: ({7, 14, 21, 30, 60, 100, _goal}.toList()..sort())
                .map((n) =>
                    DropdownMenuItem(value: n, child: Text('$n sessions')))
                .toList(),
            onChanged: (value) {
              setState(() => _goal = value!);
              _emit();
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('A little nudge'),
            subtitle: const Text('Remind me on my selected days'),
            value: _remind,
            onChanged: (value) {
              setState(() => _remind = value);
              _emit();
            },
          ),
          if (_remind)
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule_rounded),
              label: Text('Reminder at ${_time.format(context)}'),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _time,
                );
                if (time == null || !mounted) return;
                setState(() => _time = time);
                _emit();
              },
            ),
        ],
      );
}
