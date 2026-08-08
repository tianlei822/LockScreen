import SwiftUI

private struct RitualAnimationsPausedKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var ritualAnimationsPaused: Bool {
    get { self[RitualAnimationsPausedKey.self] }
    set { self[RitualAnimationsPausedKey.self] = newValue }
  }
}
