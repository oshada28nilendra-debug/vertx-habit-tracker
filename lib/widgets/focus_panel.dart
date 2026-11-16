import 'package:flutter/material.dart';
import 'flow_layout.dart';

class FocusPanel extends StatelessWidget {
  const FocusPanel(
      {super.key,
      required this.minutes,
      required this.remaining,
      required this.hasSession,
      required this.running,
      required this.busy,
      required this.onDuration,
      required this.onToggle,
      required this.onSave,
      required this.onReset,
      required this.summary});
  final int minutes, remaining;
  final bool hasSession, running, busy;
  final ValueChanged<int> onDuration;
  final VoidCallback onToggle, onSave, onReset;
  final Widget summary;
  @override
  Widget build(BuildContext context) {
    final finished = hasSession && remaining == 0;
    return FlowLayout(
        header: FlowHeader(
            title: 'Find your flow',
            child: FlowFocusDial(
                remaining: remaining,
                total: minutes * 60,
                label: finished
                    ? 'Session complete'
                    : running
                        ? 'In focus'
                        : hasSession
                            ? 'Ready when you are'
                            : 'Focus session')),
        children: [
          Text('Stay with one thing',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 22),
          Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [15, 25, 45]
                  .map((n) => FlowPill(
                      label: '$n min',
                      selected: minutes == n,
                      onTap: hasSession || busy ? null : () => onDuration(n)))
                  .toList()),
          const SizedBox(height: 28),
          FilledButton(
              onPressed: busy
                  ? null
                  : finished
                      ? onSave
                      : onToggle,
              child: Text(busy
                  ? 'Saving…'
                  : finished
                      ? 'Save session'
                      : running
                          ? 'Pause focus'
                          : hasSession
                              ? 'Resume focus'
                              : 'Start focus')),
          if (hasSession)
            TextButton(
                onPressed: busy ? null : onReset,
                child: const Text('Reset session',
                    style: TextStyle(fontSize: 12))),
          const SizedBox(height: 12),
          summary,
          const SizedBox(height: 8),
          const Text('Focus sessions are separate from habit completions.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
        ]);
  }
}
