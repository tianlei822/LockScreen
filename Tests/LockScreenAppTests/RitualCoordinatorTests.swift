import LockScreenCore
import XCTest

@testable import LockScreenApp

final class RitualCoordinatorTests: XCTestCase {
  @MainActor
  func testResetAndThemeSelectionStartFreshViewSessions() {
    let coordinator = RitualCoordinator()
    let initialSession = coordinator.sessionID
    coordinator.reset()
    XCTAssertNotEqual(coordinator.sessionID, initialSession)
    let resetSession = coordinator.sessionID
    coordinator.selectTheme(.vault)
    XCTAssertNotEqual(coordinator.sessionID, resetSession)
    let vaultSession = coordinator.sessionID
    coordinator.selectTheme(.vault)
    XCTAssertNotEqual(coordinator.sessionID, vaultSession)
  }

  @MainActor
  func testResetDuringFadeDoesNotDismissTheNextRitual() async {
    for backgroundMode in [false, true] {
      let fading = expectation(description: "fade started")
      let dismissed = expectation(description: "cancelled ritual dismissed")
      dismissed.isInverted = true
      var resumeFade: CheckedContinuation<Void, Never>?
      let coordinator = RitualCoordinator(
        backgroundMode: backgroundMode,
        presentation: RitualPresentationClient(
          fadeOut: {
            await withCheckedContinuation { continuation in
              resumeFade = continuation
              fading.fulfill()
            }
          },
          retreatToBackground: { dismissed.fulfill() },
          terminate: { dismissed.fulfill() }
        ),
        sleep: { _ in }
      )

      coordinator.activateSolarSystem()
      await fulfillment(of: [fading], timeout: 1)
      coordinator.selectTheme(.wood)
      coordinator.knockWoodDoor()
      resumeFade?.resume()

      await fulfillment(of: [dismissed], timeout: 0.05)
      XCTAssertEqual(coordinator.flow.theme, .wood)
      XCTAssertEqual(coordinator.flow.phase, .sealed)
      XCTAssertEqual(coordinator.flow.woodKnockCount, 1)
    }
  }

  @MainActor
  func testCancellationIsCheckedEvenWhenSleepReturnsNormally() async {
    let sleeping = expectation(description: "unlock delay started")
    let faded = expectation(description: "cancelled ritual faded")
    faded.isInverted = true
    var resumeSleep: CheckedContinuation<Void, Never>?
    var sleepCount = 0
    let coordinator = RitualCoordinator(
      presentation: RitualPresentationClient(
        fadeOut: { faded.fulfill() },
        retreatToBackground: {},
        terminate: {}
      ),
      sleep: { _ in
        sleepCount += 1
        guard sleepCount == 1 else { return }
        await withCheckedContinuation { continuation in
          resumeSleep = continuation
          sleeping.fulfill()
        }
      }
    )

    coordinator.activateSolarSystem()
    await fulfillment(of: [sleeping], timeout: 1)
    coordinator.cancel()
    resumeSleep?.resume()

    await fulfillment(of: [faded], timeout: 0.05)
    XCTAssertEqual(coordinator.flow.phase, .unlocking)
  }

  @MainActor
  func testSuccessfulForegroundRitualCompletesThenTerminates() async {
    let terminated = expectation(description: "foreground ritual terminated")
    let coordinator = RitualCoordinator(
      initialTheme: .solar,
      backgroundMode: false,
      presentation: RitualPresentationClient(
        fadeOut: {},
        retreatToBackground: { XCTFail("Foreground ritual must not retreat") },
        terminate: { terminated.fulfill() }
      ),
      sleep: { _ in }
    )

    coordinator.activateSolarSystem()

    await fulfillment(of: [terminated], timeout: 1)
    XCTAssertEqual(coordinator.flow.phase, .returningToDesktop)
  }

  @MainActor
  func testSuccessfulBackgroundRitualResealsBeforeRetreating() async {
    let retreated = expectation(description: "background ritual retreated")
    let coordinator = RitualCoordinator(
      initialTheme: .wood,
      backgroundMode: true,
      presentation: RitualPresentationClient(
        fadeOut: {},
        retreatToBackground: { retreated.fulfill() },
        terminate: { XCTFail("Background ritual must not terminate") }
      ),
      sleep: { _ in }
    )

    coordinator.knockWoodDoor()
    coordinator.knockWoodDoor()
    coordinator.knockWoodDoor()

    await fulfillment(of: [retreated], timeout: 1)
    XCTAssertEqual(coordinator.flow.phase, .sealed)
    XCTAssertEqual(coordinator.flow.woodKnockCount, 0)
  }

  @MainActor
  func testInkLandscapeBoatActivationCompletesTheBackgroundRitual() async {
    let retreated = expectation(description: "ink landscape retreated")
    let coordinator = RitualCoordinator(
      initialTheme: .landscape,
      backgroundMode: true,
      presentation: RitualPresentationClient(
        fadeOut: {},
        retreatToBackground: { retreated.fulfill() },
        terminate: { XCTFail("Background ritual must not terminate") }
      ),
      sleep: { _ in }
    )

    coordinator.activateInkLandscape()

    await fulfillment(of: [retreated], timeout: 1)
    XCTAssertEqual(coordinator.flow.phase, .sealed)
  }
}
