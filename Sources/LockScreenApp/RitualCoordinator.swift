import AppKit
import LockScreenCore
import SwiftUI

enum RitualTiming {
  static let unlockDuration = Duration.milliseconds(1_400)
  static let revealDuration = Duration.milliseconds(180)
}

@MainActor
struct RitualPresentationClient {
  let fadeOut: () async -> Void
  let retreatToBackground: () -> Void
  let terminate: () -> Void

  static let live = RitualPresentationClient(
    fadeOut: {
      await WindowPresentation.fadeOut(WindowPresentation.mainRitualWindow())
    },
    retreatToBackground: {
      WindowPresentation.retreatToBackground(WindowPresentation.mainRitualWindow())
    },
    terminate: {
      NSApp.hide(nil)
      DispatchQueue.main.async {
        NSApp.terminate(nil)
      }
    }
  )
}

@MainActor
final class RitualCoordinator: ObservableObject {
  typealias Sleep = @MainActor (Duration) async throws -> Void

  @Published private(set) var flow: LockFlow

  private let backgroundMode: Bool
  private let vaultPasscodeStore: VaultPasscodeStore
  private let presentation: RitualPresentationClient
  private let sleep: Sleep
  private var unlockTask: Task<Void, Never>?

  init(
    initialTheme: DoorTheme = .solar,
    vaultPasscode: String = LockFlow.defaultVaultPasscode,
    backgroundMode: Bool = false,
    vaultPasscodeStore: VaultPasscodeStore = VaultPasscodeStore(),
    presentation: RitualPresentationClient = .live,
    sleep: @escaping Sleep = { duration in try await Task.sleep(for: duration) }
  ) {
    flow = LockFlow(theme: initialTheme, vaultPasscode: vaultPasscode)
    self.backgroundMode = backgroundMode
    self.vaultPasscodeStore = vaultPasscodeStore
    self.presentation = presentation
    self.sleep = sleep
  }

  func selectTheme(_ theme: DoorTheme) {
    cancelUnlockSequence()
    flow.selectTheme(theme)
  }

  func reset() {
    cancelUnlockSequence()
    flow.reset()
  }

  func activateSolarSystem() {
    guard flow.activateSolarSystem() == .completed else { return }
    beginUnlockSequence()
  }

  func knockWoodDoor() {
    guard flow.knockWoodDoor() == .completed else { return }
    beginUnlockSequence()
  }

  func selectFormationTrajectory(_ trajectory: FormationTrajectory) {
    flow.selectFormationTrajectory(trajectory)
  }

  func traceFormation(_ score: Double) {
    guard flow.applyFormationTrace(score: score) == .activated else { return }
    beginUnlockSequence()
  }

  func submitVaultPasscode(_ passcode: String) -> VaultPasscodeResult {
    let result = flow.submitVaultPasscode(passcode)
    if result == .completed {
      beginUnlockSequence()
    }
    return result
  }

  func updateVaultPasscode(_ passcode: String) -> Bool {
    guard flow.theme == .vault, flow.phase == .sealed,
      LockFlow.isValidVaultPasscode(passcode), vaultPasscodeStore.save(passcode)
    else { return false }

    return flow.updateVaultPasscode(passcode)
  }

  func cancel() {
    cancelUnlockSequence()
  }

  private func beginUnlockSequence() {
    cancelUnlockSequence()
    unlockTask = Task { @MainActor [weak self] in
      guard let self else { return }

      do {
        try await sleep(RitualTiming.unlockDuration)
      } catch {
        return
      }
      guard flow.phase == .unlocking else { return }
      flow.finishUnlockAnimation()

      do {
        try await sleep(RitualTiming.revealDuration)
      } catch {
        return
      }
      guard flow.phase == .open else { return }
      flow.finishReveal()
      await presentation.fadeOut()

      if backgroundMode {
        flow.reset()
        presentation.retreatToBackground()
      } else {
        presentation.terminate()
      }
    }
  }

  private func cancelUnlockSequence() {
    unlockTask?.cancel()
    unlockTask = nil
  }
}
