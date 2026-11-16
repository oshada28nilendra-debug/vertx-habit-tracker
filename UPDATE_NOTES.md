# Vertx: little steps update

A colorful, playful Flutter refresh for Android and iPhone. Navigation is now Today, Habits, Focus, Grow and You.

## Included

- Warm cream backgrounds, lavender progress cards, mint/peach shortcuts and a calmer focus view.
- Today shows only habits scheduled for the current weekday. The full Habits list retains every habit.
- Choose any nonempty combination of weekdays, a reminder time and a goal of 7–100 completed sessions. Use a habit’s tune button to update its routine; long press still edits its name/category.
- Reminders use device-local IANA time zones and repeat on selected weekdays. Notification permission is requested when a reminder or focus session is enabled, rather than at launch. They are rescheduled on launch/resume; reopen the app after changing the device time zone.
- Focus presets of 15, 25 and 45 minutes, pause/resume/reset, persisted end times, completion notification and explicit session saving. A finished focus session does not automatically complete a habit.
- Grow shows recorded weekly progress, scheduled-day streaks, session goals and milestone badges. Rest days do not break streaks.
- Dark appearance is saved across launches. Camera/gallery profile features remain available; iOS usage descriptions are included.

## Data and compatibility

Existing habit documents remain in `users/{uid}/habits/{id}`. New fields are `weekdays` (1 = Monday), `reminderEnabled`, `reminderMinutes` (minutes after midnight), `goalTarget` and `completionDays` (local date keys mapped to true). Legacy `done`, `streak` and `lastCompleted` fields are retained for compatibility. Old clients should be upgraded because they do not maintain the new date-keyed history.

For legacy habits, only the last known completion can be imported; earlier history cannot be recovered. New completions and undo operations are transactional. History determines daily completion without clearing records at midnight. Schedule changes apply to streak calculations using the current selected weekdays. Goals count all recorded completed sessions, including optional completions on rest days.

Focus sessions use `users/{uid}/focusSessions/{sessionId}` with `minutes` and `completedAt`. Local timer recovery is scoped to the signed-in user. Re-saving after a failed operation uses the same session ID. Focus totals are shown on the Focus page.

`firestore.rules` supplies owner-only rules for both collections. Review/merge these with the deployed rules before enabling focus session storage. Rules are not deployed by this update.

## Running and testing

Use Flutter 3.38.9 or newer:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Firebase configuration is intentionally not committed. Android needs the matching `android/app/google-services.json`; iOS needs `ios/Runner/GoogleService-Info.plist`, Firebase setup and Google Sign-In URL schemes for the existing authentication flow. Configure these for the existing `com.example.vertx` bundle/application ID, or update IDs and Firebase together. iOS builds require macOS/Xcode and signing credentials.

Physical-device acceptance checks:

1. Sign in with an existing account; verify its habits, profile and last known completion.
2. Add a weekday habit with a reminder and goal; edit its days and time, then restart. Verify only due habits appear on Today.
3. Enable notifications on Android and iOS; test permission denial, reminder delivery, edits, deletion, reboot and sign-out. Signing out cancels this device’s pending notifications.
4. Start/pause/resume focus, switch tabs, background/kill/reopen the app, save a completed session and verify totals. Reset an unfinished session and verify it is not counted.
5. Complete/undo a habit; verify goal counts, badges and weekly progress. Verify rollover and rest-day streaks.
6. Check a small phone, larger accessibility text, dark mode and the keyboard on the schedule sheet.

Android reminders are inexact and may be delayed by power management; the focus countdown itself uses an absolute deadline. iOS has a pending notification limit: scheduling is capped at 60 requests to leave capacity for the focus timer. Daily habits use one repeating request, custom schedules one per selected weekday. Failure to schedule displays a notice; the habit remains saved. Reminders are local to the device where configured, not remote push notifications.

Date-keyed history is stored in the habit document for this initial release. Long-lived, high-volume use should move history into dated subcollections before approaching Firestore document limits. No backend migration or deployment is performed automatically.

## Validation of this change

- Flutter 3.38.9: `flutter pub get` completed and the lockfile is updated.
- `flutter analyze`: no issues found.
- `flutter test`: all five tests pass, including weekday/streak/undo cases, month boundaries, schedule selection and narrow-screen accessibility layout. The optional preview test renders the real dashboard and goals widgets with demo data.
- Preview images: [Today](design/today-demo.png) and [Grow](design/goals-demo.png). Typography uses Roboto in the test renderer; the app uses Poppins.
- Android bundle build was attempted but blocked by the absent Android SDK. A Linux bundle attempt also lacks clang++. No APK, IPA, signed device build or live Firebase/notification verification is claimed. iOS requires macOS/Xcode.
- The existing add-habit form currently uses a light surface even when dark appearance is selected.
