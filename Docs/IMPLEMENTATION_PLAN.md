# LockScreen MVP Implementation Plan

- [x] Expand Threshold into a four-page lock-screen gallery.
  - Acceptance: Solar Atlas is the default, shows eight animated planets, and unlocks by double-clicking the sun; the formation, wooden-door, and vault rituals remain selectable and distinct.
  - Verify: core flow tests, release build, signed local bundle, and runtime inspection of all four themes.
  - Files: `Docs/LOCK_SCREEN_GALLERY_PLAN.md`, `Sources/LockScreenCore/LockFlow.swift`, `Sources/LockScreenApp/Views/SolarSystemArtwork.swift`, `Sources/LockScreenApp/Views/LockScreenView.swift`.

- [x] Build the package skeleton and test-drive the deterministic puzzle/state model.
  - Acceptance: correct, wrong, reset, and theme-change transitions are covered.
  - Verify: `swift test`.
  - Files: `Package.swift`, `Sources/LockScreenCore/`, `Tests/LockScreenCoreTests/`.

- [x] Add the application shell and wooden door vertical slice.
  - Acceptance: the app launches, presents the clock and wooden door, and accepts puzzle input.
  - Verify: `swift build` plus local launch.
  - Files: `Sources/LockScreenApp/LockScreenApp.swift`, `Sources/LockScreenApp/Views/`.

- [x] Add the animated formation gate and shared opening reveal.
  - Acceptance: formation geometry rotates/pulses and successful input opens either theme.
  - Verify: local visual inspection of both themes.
  - Files: `Sources/LockScreenApp/Views/`.

- [x] Add macOS fullscreen behavior, accessibility, usage documentation, and final checks.
  - Acceptance: fullscreen can be entered/exited, controls are keyboard accessible and labeled, and run instructions are documented.
  - Verify: `swift format lint --recursive Sources Tests`, `swift test`, `swift build`, and final launch.
  - Files: `Sources/LockScreenApp/`, `README.md`.

- [x] Replace the centered door card with a full-bleed scene.
  - Acceptance: both door leaves cover the display behind floating controls at fullscreen and windowed sizes.
  - Verify: local visual inspection of both themes.
  - Files: `Sources/LockScreenApp/Views/LockScreenView.swift`, `Sources/LockScreenApp/Views/DoorStageView.swift`.

- [x] Return to the desktop after a successful unlock.
  - Acceptance: the model requests dismissal after the reveal; the app exits fullscreen and terminates.
  - Verify: `swift test` plus a live successful ritual where `Threshold` is no longer running afterward.
  - Files: `Sources/LockScreenCore/LockFlow.swift`, `Sources/LockScreenApp/RitualCoordinator.swift`, `Tests/LockScreenAppTests/RitualCoordinatorTests.swift`.

- [x] Add the wooden-door ring ritual.
  - Acceptance: two animated rings are visible and either ring contributes to a three-knock unlock.
  - Verify: model tests and a live three-click desktop-return run.
  - Files: `Sources/LockScreenCore/LockFlow.swift`, `Sources/LockScreenApp/Views/WoodDoorRingView.swift`, `Sources/LockScreenApp/Views/LockScreenView.swift`.

- [x] Add configurable formation tracing and charging.
  - Acceptance: circle, infinity, and triangle tracks can be selected; tracing charges the artwork and an accurate trace activates the gate.
  - Verify: matcher/model tests plus live formation drawing and desktop return.
  - Files: `Sources/LockScreenCore/FormationTrajectory.swift`, `Sources/LockScreenApp/Views/FormationTraceView.swift`, `Sources/LockScreenApp/Views/FormationDoorArtwork.swift`.

- [x] Add the cipher-vault passcode ritual.
  - Acceptance: the centered steel safe accepts a configured 4–8 digit code, rejects incorrect input, and unlocks with the configured code.
  - Verify: passcode state tests, release build, and local vault launch.
  - Files: `Sources/LockScreenCore/LockFlow.swift`, `Sources/LockScreenApp/Views/VaultPasscodeView.swift`, `Sources/LockScreenApp/Views/VaultDoorArtwork.swift`.

- [x] Remove the staged fullscreen-exit pause.
  - Acceptance: successful unlock hides the app and restores the previous workspace without shrinking into an intermediate window or waiting 700/900 ms.
  - Verify: source inspection, complete tests, and local process-exit check where UI automation permission is available.
  - Files: `Sources/LockScreenApp/Views/LockScreenView.swift`.

- [x] Generalize configuration, lifecycle, and accessibility behavior.
  - Acceptance: ritual metadata has one descriptor source, lifecycle side effects live in a coordinator, the global shortcut is selectable, controls localize to Simplified Chinese, and reduced-motion/transparency settings are respected.
  - Verify: configuration, coordinator, hot-key, and render-policy tests plus a signed bundle and runtime inspection.
  - Files: `Sources/LockScreenApp/AppConfiguration.swift`, `Sources/LockScreenApp/RitualCoordinator.swift`, `Sources/LockScreenApp/StatusItemController.swift`, `Sources/LockScreenApp/Resources/*.lproj/Localizable.strings`.

- [x] Bound live formation sampling and split oversized visual sources.
  - Acceptance: drag sampling stays bounded while preserving completion and recognition, and each large scene is separated into focused source files.
  - Verify: `FormationTrajectoryTests`, `swift build`, and live tracing in the formation theme.
  - Files: `Sources/LockScreenCore/FormationTrajectory.swift`, `Sources/LockScreenApp/Views/FormationTraceView.swift`, `Sources/LockScreenApp/Views/FivePhase*.swift`, `Sources/LockScreenApp/Views/*Formation*.swift`.
