import SwiftUI

private struct RitualAnimationsPausedKey: EnvironmentKey {
  static let defaultValue = false
}

private struct RitualMotionReducedKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var ritualAnimationsPaused: Bool {
    get { self[RitualAnimationsPausedKey.self] }
    set { self[RitualAnimationsPausedKey.self] = newValue }
  }

  var ritualMotionReduced: Bool {
    get { self[RitualMotionReducedKey.self] }
    set { self[RitualMotionReducedKey.self] = newValue }
  }
}
