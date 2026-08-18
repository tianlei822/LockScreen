import LockScreenCore
import XCTest

@testable import LockScreenApp

final class RitualCoordinatorTests: XCTestCase {
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
}
