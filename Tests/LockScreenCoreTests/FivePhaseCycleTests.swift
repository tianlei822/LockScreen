import XCTest

@testable import LockScreenCore

final class FivePhaseCycleTests: XCTestCase {
  func testCycleOrderIsMetalWoodWaterFireEarth() {
    XCTAssertEqual(FivePhaseElement.allCases, [.metal, .wood, .water, .fire, .earth])
  }

  func testCycleAdvancesThroughTheFivePhasesInOrder() {
    let elements = (0..<5).map { stage in
      FivePhaseCycleState(time: Double(stage) * FivePhaseCycleState.stageDuration).current
    }

    XCTAssertEqual(elements, [.metal, .wood, .water, .fire, .earth])
  }

  func testCycleReturnsToMetalAfterEarth() {
    let cycle = FivePhaseCycleState(time: FivePhaseCycleState.stageDuration * 5)

    XCTAssertEqual(cycle.current, .metal)
    XCTAssertEqual(cycle.next, .wood)
  }
}
