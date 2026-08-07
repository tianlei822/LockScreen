import Foundation
import IOKit.pwr_mgt

/// While the ritual covers the screen, macOS still considers the machine idle
/// (animations are not user activity), so the screen saver / display sleep can
/// fire the real loginwindow underneath us. Hold a display-sleep assertion and
/// periodically declare user activity to keep the session awake.
@MainActor
enum IdleSuppression {
  private static var displaySleepAssertion: IOPMAssertionID = 0
  private static var userActivityAssertion: IOPMAssertionID = 0
  private static var activityTimer: Timer?

  private static let reason = "Threshold lock ritual is covering the screen" as CFString

  static func begin() {
    guard displaySleepAssertion == 0 else { return }

    let result = IOPMAssertionCreateWithName(
      kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason,
      &displaySleepAssertion
    )
    guard result == kIOReturnSuccess else {
      displaySleepAssertion = 0
      return
    }

    declareUserActivity()

    let timer = Timer(timeInterval: 30, repeats: true) { _ in
      Task { @MainActor in
        declareUserActivity()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    activityTimer = timer
  }

  static func end() {
    activityTimer?.invalidate()
    activityTimer = nil

    if userActivityAssertion != 0 {
      IOPMAssertionRelease(userActivityAssertion)
      userActivityAssertion = 0
    }
    if displaySleepAssertion != 0 {
      IOPMAssertionRelease(displaySleepAssertion)
      displaySleepAssertion = 0
    }
  }

  /// Reuse the ID returned by IOKit so this represents continuous activity
  /// instead of a series of assertions that are immediately cancelled.
  private static func declareUserActivity() {
    IOPMAssertionDeclareUserActivity(
      reason,
      kIOPMUserActiveLocal,
      &userActivityAssertion
    )
  }
}
