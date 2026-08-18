import XCTest

@testable import LockScreenApp

final class SolarOrbitDepthTests: XCTestCase {
  func testLowerNearSideOfOrbitRendersInFrontOfSun() {
    XCTAssertEqual(SolarOrbitDepth(angle: .pi / 2), .inFrontOfSun)
  }

  func testUpperFarSideOfOrbitRendersBehindSun() {
    XCTAssertEqual(SolarOrbitDepth(angle: .pi * 1.5), .behindSun)
  }
}
