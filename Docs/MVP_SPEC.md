# LockScreen MVP Specification

## Objective

Build a native macOS experience that turns locking into a short, cinematic ritual. The first release is a fullscreen application, not a replacement for the macOS authentication screen.

The user can:

- switch between a tactile wooden door, a living formation gate, and a steel cipher vault;
- experience the selected door as a full-bleed scene that covers the entire display rather than a centered card;
- see the formation gate continuously rotate and pulse;
- knock either of two wooden door rings three times to unlock the wooden door;
- choose a circle, infinity, or triangle trajectory and trace it to charge the formation gate;
- see charge, activation, and trajectory feedback directly in the formation artwork;
- enter a configured 4–8 digit ritual code using a focused secure field or accessible keypad;
- watch both door leaves open after the puzzle succeeds;
- return automatically to the original desktop after the opening reveal;
- leave the borderless immersive mode safely before completing the puzzle.

## Tech Stack

- Swift 6
- SwiftUI and AppKit from the macOS SDK
- Swift Package Manager
- Minimum deployment target: macOS 14
- No third-party dependencies and no raster asset requirement

## Commands

```sh
swift run LockScreen
swift build
swift test
swift format lint --recursive Sources Tests
sh Scripts/build-app.sh
```

## Project Structure

```text
Sources/LockScreenCore/       Testable lock-flow and puzzle logic
Sources/LockScreenApp/        SwiftUI application and macOS integration
Sources/LockScreenApp/Views/  Focused visual components
Tests/LockScreenCoreTests/    Swift Testing behavior tests
Docs/                         Product specification and implementation plan
```

## Code Style

Use small value types, explicit state transitions, and focused SwiftUI views. UI state changes happen on the main actor.

```swift
@MainActor
func chooseRune(_ rune: Rune) {
    guard phase == .awaitingSequence else { return }
    puzzle.choose(rune)
}
```

Names use `UpperCamelCase` for types and `lowerCamelCase` for values. Layout uses an 8-point spacing rhythm. Source files should remain focused enough to review independently.

## Testing Strategy

- Test the lock-flow state machine and trajectory matcher as deterministic Swift value types.
- Verify incomplete and complete wooden-door knock counts.
- Verify rejected, partial, and activating formation traces for every configurable trajectory.
- Verify theme selection and reset behavior.
- Run `swift test` and `swift build` after meaningful increments.
- Launch the final executable and inspect both themes, keyboard controls, puzzle feedback, and the unlock animation on the local Mac.

## Boundaries

- Always: provide a visible exit/fullscreen control, support keyboard interaction, return to the desktop after a successful ritual, avoid credential storage, and let macOS own real authentication.
- Ask first: add dependencies, install a `.saver` module, invoke system lock automatically, or change the minimum macOS version.
- Never: imitate or collect a macOS password, claim to replace system security, use private authentication APIs, or commit/push without explicit permission.

## Success Criteria

- `swift build` succeeds on the local Mac.
- `swift test` passes tests covering all puzzle and lock-flow transitions.
- The app offers `Wooden Door`, `Formation Gate`, and `Cipher Vault` themes.
- The door artwork extends edge-to-edge across the active display without a surrounding card frame.
- The formation gate visibly changes over time through rotation and pulse effects.
- Either wooden door ring opens the door after exactly three knocks.
- Circle, infinity, and triangle trajectories are selectable and visibly rendered.
- Drawing along the configured trajectory charges the formation; an accurate trace fills the energy and activates the gate.
- The cipher vault rejects an incorrect code and opens with the configured code (default `1024`).
- Successful input triggers a distinct two-leaf opening animation and revealed scene.
- After the reveal, the app hides and closes without an intermediate window, restoring the user's previous workspace directly.
- Reset returns the selected theme to a sealed state.
- The app uses a borderless overlay on the current Space for instant dismissal and exposes an obvious way to return to windowed mode.
- VoiceOver labels describe theme, rune, reset, and fullscreen controls.

## Open Questions

- A future release may package the passive visuals as a `.saver` module. macOS will continue to own the secure password/Touch ID interface.
- Automatic launch and system-lock invocation are intentionally deferred because they introduce permissions, lifecycle, and distribution decisions.
