# PRD: Squint

## Problem
macOS auto-brightness is useful most of the time but disruptive during specific activities (presenting, watching video, color work, photography). Toggling it manually in System Settings is friction. Users want Amphetamine-style temporary suppression.

## Solution
A menu bar app that disables auto-brightness for a chosen duration, then re-enables it automatically. Survives crashes.

## Scope (v1)

**In:**
- Menu bar icon (sun, with state indicator when active)
- Click → menu with durations: 15 min / 30 min / 1 hr / 2 hr / Indefinite
- Active session shows remaining time in menu; click to cancel early
- Auto-reverts on timer expiry, graceful quit (app termination), or relaunch-after-crash
- Auto-brightness state check: dynamic query of system state on menu click. If auto-brightness is already disabled in macOS settings, show a warning in the menu ("You don't have auto-brightness enabled") and disable duration selection.
- Launch at login (toggle in menu)
- Pauses timer during sleep; resumes on wake

**Out (explicit non-goals):**
- Per-app rules, schedules, brightness presets, custom durations, keyboard shortcuts, external display support, statistics, onboarding, preferences window, dark mode theming, localization, True Tone control, Night Shift control

## Technical
- Swift + SwiftUI `MenuBarExtra` with `@NSApplicationDelegateAdaptor` for application lifecycle handling
- Private `DisplayServices.framework` APIs (dynamically loaded via `dlopen`/`dlsym` for stability):
  - `DisplayServicesEnableAmbientLightCompensation` (to set state)
  - `DisplayServicesAmbientLightCompensationEnabled` (to get state)
- Crash recovery: local sentinel file in Application Support with target end time (or an "indefinite" flag). On app startup (including launch-at-login), check if the sentinel exists:
  - If it is a timed session and the end time has passed, immediately restore auto-brightness.
  - If it is an "indefinite" session, keep auto-brightness disabled and resume the session.
- Launch at Login: `SMAppService.mainApp` API (macOS 13+)
- Min target: macOS 13 (Ventura)

## Distribution
Open-source on GitHub, notarized DMG in releases. MIT license. No App Store.

## Done when
Install → click menu → pick "1 hour" → auto-brightness disables → 1 hour later it re-enables. Kill the app mid-session → relaunch or wait → auto-brightness still gets re-enabled.