# Vertx: approved Flow update

The approved Flow design is implemented for Android and iPhone using native Flutter layouts. Navigation is Today, Habits, Focus, Grow and You.

## Included

- Charcoal headers, rounded ivory sheets, taupe accents, pill controls and bundled Poppins fonts. The font license is included under assets/fonts.
- Your edited mockups are respected: no decorative pebble in Habits, Add Habit or Profile. Today and Grow retain a code-drawn progress shape. Focus uses a thin circular countdown.
- Habits supports working category filters. All six existing categories remain available; the form shows additional categories under More.
- Add and edit share one form for the name, category, repeat days, reminder, target and icon. Optional habit ideas retain the original keyword-based recommendation logic.
- Profile controls, photo picker and support dialogs share the neutral palette. Splash, Sign In and Sign Up fully implement the approved authentication layouts. Dark appearance switches the lower sheets to graphite.
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

- Flutter 3.38.9: offline dependency resolution completed; no package versions changed for the Flow redesign.
- `flutter analyze`: no issues found.
- `flutter test`: all 25 tests pass. Checks cover calendar/streak/undo behavior, nonempty weekday selection, category filtering, creating a habit with selected weekdays, focus controls, and small-phone layouts with larger text. The preview test renders production panels and forms in light/dark appearance without Firebase.
- Previews use the same bundled Poppins font and production widgets as the app, with demo data. See the [six-screen overview](design/flow-overview.jpg) and [full gallery](design/flow-gallery.html). Set VERTX_GENERATE_PREVIEWS=1 when running the preview test to regenerate the individual PNGs.
- Android bundle build was attempted but blocked by the absent Android SDK. A Linux bundle attempt also lacks clang++. No APK, IPA, signed device build or live Firebase/notification verification is claimed. iOS requires macOS/Xcode.
- The new form follows the selected appearance. Headers remain charcoal in both modes. Compact phones, larger text and the on-screen keyboard can scroll the full page to reach every control.


## Review scope

This change updates the existing draft pull request; main and deployed Firebase rules remain unchanged. The redesign does not add a new Firestore schema. Existing reminders and focus-session persistence are retained. Native Android/iOS packaging, live sign-in, camera access and scheduled notification delivery still require the Firebase configuration and physical-device acceptance checks above; no new APK or IPA is claimed.


## Approved authentication screens

Splash, Sign In and Sign Up now fully implement the approved Flow authentication layouts, including the V monogram, rounded ivory form sheets, filled pill fields, password visibility, Google sign-in and account-switching links. Password reset uses the same styling. The [implemented authentication overview](design/auth-overview.jpg) and [full gallery](design/flow-gallery.html) use production widgets without live credentials.

The existing Firebase Auth and Google Sign-In services and pinned SDK versions remain. Email and display name are trimmed; passwords are submitted exactly as typed. Signup retains the existing minimum-six-character, uppercase-letter and number policy. A shared busy state prevents overlapping email and Google requests, Google cancellation returns to the form, and disposed screens ignore late asynchronous responses.

Splash waits for the first restored Firebase auth-state event before choosing Home or Sign In, with a short minimum branding interval. Failure to restore a session presents Retry rather than silently treating a signed-in user as signed out. Password reset validates the email and uses a neutral confirmation for an unknown account.

Authentication tests use an injected AuthActions boundary to exercise the production forms and navigation without contacting Firebase. Added checks cover validation, password preservation, visibility toggles, failed and duplicate requests, Google cancellation, signup confirmation, reset handling, restored sessions, retry, late responses, account-creation routing, and a small viewport with keyboard insets and larger text. The combined suite has 25 passing tests. Live provider/OAuth and physical-device checks remain pending project configuration; no deployed Firebase settings or security rules were changed.

Generate authentication PNG previews with:

```sh
VERTX_GENERATE_AUTH_PREVIEWS=1 flutter test test/auth_preview_test.dart
```
