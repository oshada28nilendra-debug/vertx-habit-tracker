import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'flow_layout.dart';

class ProfilePanel extends StatelessWidget {
  const ProfilePanel(
      {super.key,
      required this.name,
      required this.dark,
      required this.onDarkChanged,
      required this.onPhoto,
      required this.onNotifications,
      required this.onPrivacy,
      required this.onHelp,
      required this.onSignOut,
      this.image});
  final String name;
  final bool dark;
  final ValueChanged<bool> onDarkChanged;
  final VoidCallback onPhoto, onNotifications, onPrivacy, onHelp, onSignOut;
  final ImageProvider? image;
  @override
  Widget build(BuildContext context) => FlowLayout(
          header: FlowHeader(
              title: 'Your space',
              child: Column(children: [
                Semantics(
                    label: 'Change profile photo',
                    button: true,
                    child: InkWell(
                        onTap: onPhoto,
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                            radius: 44,
                            backgroundColor: FlowColors.ivory,
                            backgroundImage: image,
                            child: image == null
                                ? const Icon(Icons.person_outline,
                                    size: 46, color: FlowColors.ink)
                                : null))),
                const SizedBox(height: 15),
                Text(name,
                    style:
                        const TextStyle(color: FlowColors.ivory, fontSize: 22)),
                const SizedBox(height: 4),
                const Text('Your rhythm, your way.',
                    style: TextStyle(
                        color: Color(0xFFD2CAC2),
                        fontSize: 12,
                        letterSpacing: .5)),
                const SizedBox(height: 12),
              ])),
          children: [
            Text('Preferences',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            Row(children: [
              const Icon(Icons.dark_mode_outlined, size: 24),
              const SizedBox(width: 18),
              const Expanded(child: Text('Dark appearance')),
              Switch.adaptive(value: dark, onChanged: onDarkChanged)
            ]),
            const Divider(),
            _row(Icons.notifications_none, 'Notifications', onNotifications),
            _row(Icons.person_outline, 'Profile photo', onPhoto),
            _row(Icons.lock_outline, 'Privacy', onPrivacy),
            _row(Icons.help_outline, 'Help & support', onHelp),
            const SizedBox(height: 26),
            OutlinedButton(onPressed: onSignOut, child: const Text('Sign out')),
            const SizedBox(height: 12),
          ]);
  Widget _row(IconData icon, String title, VoidCallback onTap) =>
      Column(children: [
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, size: 24),
            title: Text(title, style: const TextStyle(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: onTap,
            minVerticalPadding: 16),
        const Divider(),
      ]);
}
