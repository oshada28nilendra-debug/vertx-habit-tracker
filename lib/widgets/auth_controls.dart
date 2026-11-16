import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'flow_layout.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.heading,
      required this.children});
  final String title, subtitle, heading;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          bottom: false,
          child: FlowLayout(
            header: FlowHeader(
                compact: true,
                title: title,
                subtitle: subtitle,
                child: const SizedBox(height: 6)),
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
            children: [
              Text(heading,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 22),
              ...children
            ],
          )));
}

class AuthField extends StatefulWidget {
  const AuthField(
      {super.key,
      required this.id,
      required this.label,
      required this.controller,
      required this.validator,
      this.hint,
      this.password = false,
      this.enabled = true,
      this.autofillHints,
      this.keyboardType = TextInputType.text,
      this.action = TextInputAction.next,
      this.onSubmitted});
  final String id, label;
  final String? hint;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool password, enabled;
  final Iterable<String>? autofillHints;
  final TextInputType keyboardType;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _show = false;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.label,
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 7),
          TextFormField(
              key: ValueKey(widget.id),
              controller: widget.controller,
              enabled: widget.enabled,
              validator: widget.validator,
              obscureText: widget.password && !_show,
              autocorrect: !widget.password &&
                  widget.keyboardType != TextInputType.emailAddress,
              enableSuggestions: !widget.password,
              keyboardType: widget.password
                  ? TextInputType.visiblePassword
                  : widget.keyboardType,
              textCapitalization: widget.id == 'name'
                  ? TextCapitalization.words
                  : TextCapitalization.none,
              autofillHints: widget.autofillHints,
              textInputAction: widget.action,
              onFieldSubmitted: widget.onSubmitted,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                isDense: true,
                filled: true,
                fillColor: scheme.primaryContainer,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none),
                enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    borderSide: BorderSide.none),
                errorMaxLines: 3,
                suffixIcon: widget.password
                    ? IconButton(
                        tooltip:
                            '${_show ? 'Hide' : 'Show'} ${widget.label.toLowerCase()}',
                        onPressed: widget.enabled
                            ? () => setState(() => _show = !_show)
                            : null,
                        icon: Icon(
                            _show
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 21))
                    : null,
              )),
        ]));
  }
}

class AuthSubmit extends StatelessWidget {
  const AuthSubmit(
      {super.key,
      required this.label,
      required this.busyLabel,
      required this.busy,
      required this.onPressed});
  final String label, busyLabel;
  final bool busy;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
      onPressed: onPressed,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      color: Theme.of(context).colorScheme.surface)),
              const SizedBox(width: 10)
            ],
            Flexible(
                child: Text(busy ? busyLabel : label,
                    textAlign: TextAlign.center)),
          ]));
}

class AuthError extends StatelessWidget {
  const AuthError({super.key, required this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Semantics(
          liveRegion: true,
          child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(message!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12))));
}

class VertxMonogram extends StatelessWidget {
  const VertxMonogram({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Vertx',
      image: true,
      child:
          CustomPaint(size: const Size(80, 80), painter: _MonogramPainter()));
}

class _MonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()
          ..moveTo(4, 5)
          ..lineTo(size.width / 2, size.height - 5)
          ..lineTo(size.width - 4, 5),
        Paint()
          ..color = FlowColors.ivory
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.square);
  }

  @override
  bool shouldRepaint(covariant _MonogramPainter old) => false;
}
