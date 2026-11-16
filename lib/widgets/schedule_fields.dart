import 'package:flutter/material.dart';

class ScheduleFields extends StatefulWidget {
  const ScheduleFields(
      {super.key, required this.initial, required this.onChanged});
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
  static const _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
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
        'reminderMinutes': _time.hour * 60 + _time.minute
      });
  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time == null || !mounted) return;
    setState(() => _time = time);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Repeat on',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Row(
          children: List.generate(7, (i) {
        final selected = _days.contains(i + 1);
        return Expanded(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                    label: _names[i],
                    selected: selected,
                    button: true,
                    child: Material(
                        color: selected
                            ? scheme.onSurface
                            : scheme.primaryContainer,
                        shape: const StadiumBorder(),
                        child: InkWell(
                            key: ValueKey('weekday-${i + 1}'),
                            customBorder: const StadiumBorder(),
                            onTap: () {
                              if (selected && _days.length == 1) return;
                              setState(() => selected
                                  ? _days.remove(i + 1)
                                  : _days.add(i + 1));
                              _emit();
                            },
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 44),
                                child: Center(
                                    child: Text(
                                        const [
                                          'M',
                                          'T',
                                          'W',
                                          'T',
                                          'F',
                                          'S',
                                          'S'
                                        ][i],
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: selected
                                                ? scheme.surface
                                                : scheme.onSurface)))))))));
      })),
      const SizedBox(height: 8),
      Text(
          _days.length == 7
              ? 'Every day'
              : (_days.toList()..sort()).map((d) => _names[d - 1]).join(', '),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10)),
      const SizedBox(height: 18),
      const Divider(),
      LayoutBuilder(builder: (context, constraints) {
        final inline = constraints.maxWidth >= 320 &&
            MediaQuery.textScalerOf(context).scale(12) <= 16;
        final time = TextButton(
            onPressed: _pickTime,
            child: Text(_time.format(context),
                style: const TextStyle(fontSize: 12)));
        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            const Icon(Icons.notifications_none, size: 23),
            const SizedBox(width: 12),
            const Expanded(child: Text('Reminder')),
            if (_remind && inline) time,
            Switch.adaptive(
                value: _remind,
                onChanged: (value) {
                  setState(() => _remind = value);
                  _emit();
                }),
          ]),
          if (_remind && !inline) time,
        ]);
      }),
      const Divider(),
      const SizedBox(height: 8),
      Row(children: [
        const Expanded(child: Text('Session goal')),
        Flexible(
            child: DropdownButton<int>(
                value: _goal,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(22),
                items: ({7, 14, 21, 30, 60, 100, _goal}.toList()..sort())
                    .map((n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n sessions',
                            style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _goal = value);
                  _emit();
                })),
      ]),
      const SizedBox(height: 8),
      const Divider(),
    ]);
  }
}
