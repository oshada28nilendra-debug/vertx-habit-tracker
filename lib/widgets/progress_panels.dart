import 'package:flutter/material.dart';
import '../models/habit_progress.dart';
import 'flow_layout.dart';
import 'habit_tile.dart';

class TodayPanel extends StatelessWidget {
  const TodayPanel(
      {super.key,
      required this.name,
      required this.habits,
      required this.cards,
      required this.onAdd,
      required this.onFocus,
      required this.onGoals});
  final String name;
  final List<Map<String, dynamic>> habits;
  final List<Widget> cards;
  final VoidCallback onAdd, onFocus, onGoals;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(),
        done = habits
            .where((h) => HabitProgress.completed(h, DateTime.now()))
            .length;
    return FlowLayout(
        header: FlowHeader(
            title: 'A little progress, daily',
            child: FlowPebble(
                value: '$done of ${habits.length}',
                label: 'habits complete',
                progress: habits.isEmpty ? 0 : done / habits.length)),
        children: [
          Row(children: [
            Expanded(
                child: Text('Your rhythm',
                    style: Theme.of(context).textTheme.headlineSmall)),
            IconButton(
                onPressed: onAdd,
                tooltip: 'Add habit',
                icon: const Icon(Icons.add_circle_outline))
          ]),
          const SizedBox(height: 14),
          Row(
              children: List.generate(7, (i) {
            final day =
                DateTime(now.year, now.month, now.day - now.weekday + 1 + i);
            final selected = day.weekday == now.weekday;
            return Expanded(
                child: Semantics(
                    label: '${const [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday'
                    ][i]}${selected ? ', today' : ''}',
                    selected: selected,
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                            borderRadius: BorderRadius.circular(24)),
                        child: Text(
                            const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ][i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? Theme.of(context).colorScheme.surface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface)))));
          })),
          const SizedBox(height: 18),
          if (cards.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(children: [
                  const Icon(Icons.spa_outlined, size: 30),
                  const SizedBox(height: 12),
                  Text('A little space to grow.',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'No habits scheduled today. Enjoy a rest, or plant a new habit.',
                      textAlign: TextAlign.center),
                  TextButton(
                      onPressed: onAdd, child: const Text('Plant a new habit')),
                ])),
          ...cards,
          if (habits.isNotEmpty && done == habits.length)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Today’s rhythm is complete. Well done.',
                    textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: TextButton.icon(
                    onPressed: onFocus,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Find your flow'))),
            Expanded(
                child: TextButton.icon(
                    onPressed: onGoals,
                    icon: const Icon(Icons.bar_chart_outlined),
                    label: const Text('Your progress')))
          ]),
        ]);
  }
}

class HabitListPanel extends StatefulWidget {
  const HabitListPanel(
      {super.key,
      required this.habits,
      required this.cards,
      required this.onAdd});
  final List<Map<String, dynamic>> habits;
  final List<Widget> cards;
  final VoidCallback onAdd;
  @override
  State<HabitListPanel> createState() => _HabitListPanelState();
}

class _HabitListPanelState extends State<HabitListPanel> {
  String _category = 'All';
  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...widget.habits
          .map((h) => h['category'] as String? ?? 'Health')
          .toSet()
          .toList()
        ..sort()
    ];
    final selected = categories.contains(_category) ? _category : 'All';
    final indices = List.generate(widget.habits.length, (i) => i)
        .where((i) =>
            selected == 'All' || widget.habits[i]['category'] == selected)
        .toList();
    return FlowLayout(
        header: FlowHeader(
            title: 'Your habits',
            subtitle: 'Build a rhythm that lasts.',
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('${widget.habits.length} active habits',
                    style: const TextStyle(
                        color: Color(0xFFEAE2D8),
                        fontSize: 14,
                        letterSpacing: 1)))),
        children: [
          Row(children: [
            Expanded(
                child: Text('All habits',
                    style: Theme.of(context).textTheme.headlineSmall)),
            IconButton.filled(
                onPressed: widget.onAdd,
                tooltip: 'Add habit',
                icon: Icon(Icons.add,
                    color: Theme.of(context).colorScheme.surface))
          ]),
          const SizedBox(height: 18),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((category) => FlowPill(
                      label: category,
                      selected: selected == category,
                      onTap: () => setState(() => _category = category)))
                  .toList()),
          const SizedBox(height: 24),
          if (indices.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(children: [
                  const Text('Your next rhythm starts here.',
                      textAlign: TextAlign.center),
                  TextButton(
                      onPressed: widget.onAdd,
                      child: const Text('Add your first habit'))
                ])),
          ...indices.map((i) => widget.cards[i]),
          if (indices.isNotEmpty)
            const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('Long press a habit to edit. Swipe left to delete.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10))),
        ]);
  }
}

class GoalsPanel extends StatelessWidget {
  const GoalsPanel({super.key, required this.habits, required this.onEdit});
  final List<Map<String, dynamic>> habits;
  final ValueChanged<int> onEdit;
  @override
  Widget build(BuildContext context) {
    final featured = habits.isEmpty ? null : habits.first;
    final style = Theme.of(context).textTheme;
    return FlowLayout(
        header: FlowHeader(
            title: 'Watch your rhythm grow',
            subtitle: 'Every session counts.',
            child: featured == null
                ? null
                : FlowPebble(
                    value:
                        '${HabitProgress.total(featured)} / ${HabitProgress.goal(featured)}',
                    label: '${featured['name']} sessions',
                    progress: HabitProgress.total(featured) /
                        HabitProgress.goal(featured))),
        children: [
          Text('Your milestones', style: style.headlineSmall),
          const SizedBox(height: 20),
          if (habits.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Add a habit to start your first goal.',
                    textAlign: TextAlign.center)),
          ...List.generate(habits.length, (i) {
            final habit = habits[i],
                total = HabitProgress.total(habit),
                goal = HabitProgress.goal(habit);
            final milestones = ({1, if (goal >= 7) 7, goal}.toList()..sort());
            return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Icon(
                                    habitIcon(habit['iconCode'] as int?),
                                    size: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(habit['name'] as String? ?? '',
                                      style: style.titleMedium),
                                  Text('$total of $goal sessions',
                                      style: style.bodySmall),
                                ])),
                            IconButton(
                                onPressed: () => onEdit(i),
                                tooltip: 'Edit goal and schedule',
                                icon: const Icon(Icons.tune_outlined, size: 20))
                          ]),
                      const SizedBox(height: 12),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                              value: (total / goal).clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer)),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: milestones
                              .map((n) => Semantics(
                                  label:
                                      '$n sessions${total >= n ? ', reached' : ', upcoming'}',
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 11, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: total >= n
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                              : Colors.transparent,
                                          border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline),
                                          borderRadius:
                                              BorderRadius.circular(22)),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (total >= n) ...[
                                              Icon(Icons.check,
                                                  size: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface),
                                              const SizedBox(width: 3)
                                            ],
                                            Text('$n',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: total >= n
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .surface
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onSurface)),
                                          ]))))
                              .toList()),
                      if (total >= goal)
                        const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Goal reached. Celebrate your rhythm.',
                                style: TextStyle(fontSize: 12))),
                      const SizedBox(height: 18),
                      const Divider(),
                    ]));
          }),
          Text('This week', style: style.titleLarge),
          const SizedBox(height: 18),
          Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final now = DateTime.now(),
                    day = DateTime(DateTime.now().year, DateTime.now().month,
                        DateTime.now().day - 6 + i);
                final due = habits
                    .where((h) =>
                        HabitProgress.isDue(h, day) &&
                        (h['createdDay'] == null ||
                            (h['createdDay'] as String)
                                    .compareTo(HabitProgress.dayKey(day)) <=
                                0))
                    .toList();
                final count = due
                        .where((h) => HabitProgress.completed(h, day))
                        .length,
                    ratio = due.isEmpty ? 0.0 : count / due.length;
                return Expanded(
                    child: Semantics(
                        label: '${HabitProgress.dayKey(day)}: $count completed',
                        child: Column(children: [
                          Text('$count', style: style.labelSmall),
                          const SizedBox(height: 6),
                          SizedBox(
                              width: 17,
                              height: 64,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ColoredBox(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: FractionallySizedBox(
                                              heightFactor: ratio,
                                              child: ColoredBox(
                                                  color: day.day == now.day
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                      : const Color(0xFFAA9B91),
                                                  child: const SizedBox
                                                      .expand())))))),
                          const SizedBox(height: 8),
                          Text(
                              const [
                                'M',
                                'T',
                                'W',
                                'T',
                                'F',
                                'S',
                                'S'
                              ][day.weekday - 1],
                              style: style.labelSmall),
                        ])));
              })),
          const SizedBox(height: 16),
          const Text('Completed sessions on your scheduled days.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
        ]);
  }
}
