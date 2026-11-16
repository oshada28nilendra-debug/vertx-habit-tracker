import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A dark, quiet header above a rounded sheet. Both parts scroll on small phones.
class FlowLayout extends StatelessWidget {
  const FlowLayout(
      {super.key,
      required this.header,
      required this.children,
      this.padding = const EdgeInsets.fromLTRB(24, 26, 24, 24)});
  final Widget header;
  final List<Widget> children;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(child: header),
        SliverLayoutBuilder(
            builder: (context, constraints) => SliverToBoxAdapter(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: math.max(
                            0,
                            constraints.viewportMainAxisExtent -
                                constraints.precedingScrollExtent)),
                    child: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(36))),
                        padding: padding,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: children))))),
      ]);
}

class FlowHeader extends StatelessWidget {
  const FlowHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.child,
      this.onBack,
      this.compact = false});
  final String title;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onBack;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
      padding:
          EdgeInsets.fromLTRB(24, compact ? 16 : 24, 24, compact ? 24 : 30),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          const SizedBox(width: double.infinity, height: 40),
          const Text('VERTX',
              style: TextStyle(
                  color: FlowColors.ivory,
                  fontSize: 13,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w500)),
          if (onBack != null)
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    onPressed: onBack,
                    tooltip: 'Back',
                    icon: const Icon(Icons.chevron_left,
                        color: FlowColors.ivory))),
        ]),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: FlowColors.ivory,
                fontSize: compact ? 23 : 24,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w400)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFCEC7BF), fontSize: 12, letterSpacing: 0.5))
        ],
        if (child != null) ...[const SizedBox(height: 24), child!],
      ]));
}

/// Functional progress ornament, used only on Today and Goals.
class FlowPebble extends StatelessWidget {
  const FlowPebble(
      {super.key,
      required this.value,
      required this.label,
      this.progress = 0,
      this.width = 258,
      this.height = 164});
  final String value, label;
  final double progress, width, height;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$value $label',
      child: ExcludeSemantics(
          child: SizedBox(
              width: width,
              height: height,
              child: CustomPaint(
                  painter: _PebblePainter(progress),
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 8),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(value,
                                    style: const TextStyle(
                                        color: FlowColors.ivory,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 1))),
                            const SizedBox(height: 3),
                            Text(label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: FlowColors.ivory,
                                    fontSize: 11,
                                    letterSpacing: 0.6)),
                          ])))))));
}

class _PebblePainter extends CustomPainter {
  _PebblePainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * .07, h * .48)
      ..cubicTo(w * .17, h * .19, w * .43, h * .34, w * .64, h * .12)
      ..cubicTo(w * .89, -h * .10, w * 1.01, h * .11, w * .94, h * .49)
      ..cubicTo(w * .86, h * .93, w * .63, h * 1.02, w * .30, h * .89)
      ..cubicTo(w * .08, h * .82, -w * .01, h * .65, w * .07, h * .48)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawPath(
        path,
        Paint()
          ..shader = const RadialGradient(
              center: Alignment(.1, .1),
              radius: .95,
              colors: [Color(0xFF3F3A39), Color(0xFF756660), Color(0xFFB4A49A)],
              stops: [0, .62, 1]).createShader(rect));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = FlowColors.ivory.withValues(alpha: .85));
    // Marker moves a little as the goal advances, while keeping the text clear.
    final dot = Offset(w * (.80 + .035 * progress.clamp(0, 1)),
        h * (.20 - .035 * progress.clamp(0, 1)));
    canvas.drawCircle(dot, 10, Paint()..color = FlowColors.ivory);
  }

  @override
  bool shouldRepaint(covariant _PebblePainter old) => old.progress != progress;
}

class FlowFocusDial extends StatelessWidget {
  const FlowFocusDial(
      {super.key,
      required this.remaining,
      required this.total,
      required this.label});
  final int remaining, total;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$remaining seconds remaining, $label',
      child: ExcludeSemantics(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                      painter: _FocusPainter(1 - remaining / total),
                      child: Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                            '${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: FlowColors.ivory,
                                fontSize: 48,
                                fontWeight: FontWeight.w300)),
                        Text(label,
                            style: const TextStyle(
                                color: Color(0xFFD6CEC6),
                                fontSize: 12,
                                letterSpacing: .6)),
                      ])))))));
}

class _FocusPainter extends CustomPainter {
  _FocusPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero), radius = size.shortestSide / 2 - 9;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = FlowColors.ivory.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    if (value > 0) {
      canvas.drawArc(
          rect,
          -math.pi / 2,
          math.pi * 2 * value.clamp(0, 1),
          false,
          Paint()
            ..color = FlowColors.taupe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _FocusPainter old) => old.value != value;
}

class FlowPill extends StatelessWidget {
  const FlowPill(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.semanticLabel});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
        selected: selected,
        label: semanticLabel,
        button: true,
        child: Material(
            color: selected ? scheme.onSurface : scheme.primaryContainer,
            shape: const StadiumBorder(),
            child: InkWell(
                onTap: onTap,
                customBorder: const StadiumBorder(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 17, vertical: 12),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? scheme.surface
                                : scheme.onSurface))))));
  }
}

class FlowNavigationBar extends StatelessWidget {
  const FlowNavigationBar(
      {super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onChanged,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.layers_outlined),
                selectedIcon: Icon(Icons.layers),
                label: 'Habits'),
            NavigationDestination(
                icon: Icon(Icons.radio_button_unchecked),
                selectedIcon: Icon(Icons.adjust),
                label: 'Focus'),
            NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                selectedIcon: Icon(Icons.spa),
                label: 'Grow'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'You'),
          ]);
}
