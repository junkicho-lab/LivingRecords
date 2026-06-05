# Living Record — v3 Vertical Slice Plan (Capture Reachability)

> English translation. Korean original: `v3-slices.md`.

> Written: 2026-06-04 · Basis: `concept.md` §3-4 (capture = one action · trigger), `사용설명서.md`
> Platform: iOS 26+ · Workflow: implement → verify on a real device → commit (`feat(S12): …`)

## 0. Goal — Capture in One Action, Outside the App

v1+v2 capture **only if you open the app**. v3 actually realizes concept §3-4's "trigger = one action, zero decisions."
- **Firm decision (concept §3-4):** widget/trigger one tap → capture. Seal = absorbed into the trigger (tap = normal / press-and-hold = sealed). Always-listening is rejected (a deliberate act).
- **This decision:** on trigger, **the app opens to the capture screen and starts recording automatically** (the instant it opens). The mic requires the app to be active → entering the foreground is unavoidable, but the user action is a single one.

## 1. Slices

### S12 · App Intent Capture ⭐ (the biggest reach, zero new targets)
- **Goal**: Expose "start capture" as a system action → **Action Button · Siri · AirPods ("Hey Siri, capture")** all at once. The app opens to the capture tab and starts recording automatically.
- **Includes**:
  - `AppLaunchState` (@Observable singleton): `startCapture`/`startSealed` signals. Injected into the app environment.
  - `StartCaptureIntent` / `StartSealedCaptureIntent` (`openAppWhenRun=true`) → set the signal.
  - `AppShortcutsProvider`: "capture" · "sealed capture" phrases (exposed to Siri/Shortcuts/Action Button).
  - ContentView: on signal, switch to the capture tab (0). CaptureView: after consuming the signal, automatically start `toggleRecord()` (duplicate guard).
- **Verification**: "capture" appears in the Shortcuts app; running it makes the app start recording. Assign to the Action Button → pressing it records. (Real device.)
- **Depends on**: v1 capture. **No new Xcode target needed.**

### S13 · Evening Retrospective Reminder
- **Goal**: A gentle local notification, "Today in one line?" Tapping it goes to capture (or the daily digest).
- **Includes**: notification permission request, toggle + time in settings, `UNUserNotificationCenter` daily schedule, deep link on tap (reuses AppLaunchState).
- **Verification**: notification at the set time, tap → capture screen. (Real device.)
- **Depends on**: S12 (shares the deep-link signal).

### S14 · Home/Lock Screen Widget
- **Goal**: Widget one tap → capture screen (auto-record). Sealed variant.
- **Includes**: **a new Widget Extension target** (added by the user in Xcode) + an **App Group** (SwiftData sharing isn't needed for v1, but will be needed later if the widget shows recent state) + the widget button runs an App Intent/deep link.
- **Verification**: tap the home screen widget → record. (Real device.)
- **Depends on**: S12. ⚠️ **Adding a new target is a user task** (as with app creation).

## 2. v3 Boundary
- **v3**: triggers (App Intent/Action Button/Siri/AirPods) · reminder · widget.
- **post-v3**: search · semantic exploration, iCloud sync · encrypted backup · MLX fallback bundle · two-way Obsidian, custom templates, visualization, Android.

## 3. Starting Point
- Begin with **S12 (App Intent)**. With no new target, the Action Button · Siri · AirPods all open it in one action.

## Status
- **S12 ✅ Done (2026-06-04)**: App Intent capture. AppLaunchState singleton + Start(Sealed)CaptureIntent (openAppWhenRun) + LivingRecordShortcuts. ContentView tab switch + CaptureView auto-record (guard). Build · metadata extraction · launch confirmed. Action Button/Siri real behavior on a real device.
- **S13 ✅ Done (2026-06-04)**: Evening retrospective reminder. ReminderStore (toggle + time default 21:00, permission, UNCalendar daily repeat) + NotificationDelegate (foreground banner + tap → openCapture) + AppLaunchState.openCapture (navigation only). Settings 'Reminder' section. Build · launch OK. Permission · firing · tap on a real device.
- **S14 ✅ Done (2026-06-04)**: Capture widget. CaptureWidgetExtension target (user-added) + CaptureWidget (home systemSmall 🎙️/🔒, lock screen accessoryCircular · Rectangular, Button(intent:)) + CaptureWidgetControl (Control Center). Static launcher (no App Group needed), openAppWhenRun → app process → AppLaunchState auto-record. CaptureIntents.swift shared with the widget target. Build · .appex embed · launch OK. Widget add · tap real behavior on a real device.
- **→ v3 "capture reachability" complete (S12–S14). Action Button · Siri · AirPods · reminder · widget all capture in one action.**
