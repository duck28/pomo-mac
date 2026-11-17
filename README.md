# Pomo for Mac

Native SwiftUI, macOS 14+, no third-party dependencies. All six companion illustrations are vector artwork rendered using SwiftUI Canvas, with gentle motion and Reduce Motion support.

## Build and run

Install Apple's Xcode Command Line Tools (`xcode-select --install`) if needed. Full Xcode and an Apple Developer account are not required.

```sh
./build.sh
open build/Pomo.app
```

The script builds for the current Mac's architecture and packages an ad-hoc signed `.app`. Use `./build.sh debug` for a development build. Open `Package.swift` in Xcode if desired. Run `./test.sh` (no XCTest or full Xcode needed) for the timer, persistence format, and progression tests.

Local builds can run without paid membership. This build is not Developer ID signed or notarized. Copies downloaded on other Macs may be blocked by Gatekeeper and need explicit approval in macOS Privacy & Security. Do not disable Gatekeeper. Public Developer ID signing and notarization require the appropriate Apple Developer membership: https://developer.apple.com/developer-id/.

## Use

Choose and name one of six companions on first launch. Start/pause from the main window or menu bar; Command-Shift-P also toggles the timer. Restart discards the unfinished interval without awarding treats. Completed focus sessions earn one treat per five minutes, with leftover minutes carried over. Feed your companion to grow its bond. A soft sound marks completion. The menu bar can reopen the window after it is closed.

Progress stays on this Mac in `~/Library/Application Support/Pomo/progress.json`. Writes are atomic. If the saved file cannot be read, the app preserves it and reports the error rather than overwriting progress.

This initial version does not include cloud sync, notifications, auto-updates, or a notarized installer.

## Settings

Open Settings with Command-comma, the Settings button in the main window footer, or the labeled Settings row in the menu-bar popover. Menu-bar-only mode hides the Dock icon immediately and is remembered across launches. Restore it using the same toggle. All six companions can be selected in Settings without resetting the active timer, bond level, earned treats, nickname, or focus history. Growth belongs to your shared journey and carries over to every companion. Rename your companion using Save name or Return.

The menu-bar Settings row opens preferences directly inside the popover; Back returns to the companion and timer.

## Companion expressions

All six companions blink and occasionally wink while idle, and rest their eyes during focus. Feeding plays a 1.2-second chewing reaction followed by a happy smile and hearts. A feed that increases the bond level instead leads into a longer bounce, delighted expression, and sparkle celebration. Pip bounces faster; Nook sways more. Both the main window and menu-bar popover share the same reaction timing. Repeated feeding restarts the reaction while retaining any pending growth celebration. Reactions are temporary and never alter stored growth or timer progress.

At bond level two, each character gains its own detail (flowers, leaves, feather marks, a cozy roof motif, or flame highlights); existing level-three details remain. Reduce Motion replaces movement with static happy/growth expressions. The reaction timing checks run with `./test.sh`.

## Focus durations

Use the Focus duration dropdown beneath the timer in the main window or menu-bar popover. Defaults are 10, 15, 25, 30, 45, and 60 minutes. Custom duration accepts 1–180 whole minutes. Settings (including inside the menu-bar popover) lets you edit and save up to eight unique quick durations or restore defaults. Presets and duration choices persist alongside progress.

A fresh timer changes immediately. A running or paused focus session keeps its duration and deadline; the new selection applies to the next focus session. Restarting explicitly discards the unfinished interval and uses the new duration. Break lengths stay unchanged. Completed focus minutes are credited using the duration actually completed. Existing save files load with the default shortcuts.

## GitHub builds

The `macOS build` GitHub Actions workflow runs on pushes to `main`, version tags (`v*`), pull requests, and manual dispatch. It runs the behavior checks, builds and verifies an ad-hoc-signed app, and uploads separate `Pomo-arm64` and `Pomo-x86_64` ZIP artifacts (retained for 14 days). ZIP packaging preserves the app bundle permissions. Download the matching architecture from a successful Actions run.

CI requires no Apple Developer credentials and does not notarize or publish a GitHub Release. Build products, local previews, and Swift caches are excluded from Git.
