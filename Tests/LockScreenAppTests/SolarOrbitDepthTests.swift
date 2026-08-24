import XCTest

@testable import LockScreenApp

final class SolarOrbitDepthTests: XCTestCase {
  func testSplitDepthLayersCommitSynchronously() {
    XCTAssertFalse(SolarOrbitRenderPolicy.rendersAsynchronously)
  }

  func testLowerNearSideOfOrbitRendersInFrontOfSun() {
    XCTAssertEqual(SolarOrbitDepth(angle: .pi / 2), .inFrontOfSun)
  }

  func testUpperFarSideOfOrbitRendersBehindSun() {
    XCTAssertEqual(SolarOrbitDepth(angle: .pi * 1.5), .behindSun)
  }

  func testSatelliteOnLowerNearSideRendersInFrontOfItsPlanet() {
    XCTAssertEqual(SolarSatelliteDepth(angle: .pi / 2), .inFrontOfPlanet)
  }

  func testSatelliteOnUpperFarSideRendersBehindItsPlanet() {
    XCTAssertEqual(SolarSatelliteDepth(angle: .pi * 1.5), .behindPlanet)
  }

  func testEarthRotationMovesContinentsInOneDirection() {
    let quarterTurn = SolarEarthRotation.horizontalOffset(spin: .pi / 2, width: 100)
    let halfTurn = SolarEarthRotation.horizontalOffset(spin: .pi, width: 100)

    XCTAssertEqual(quarterTurn, -25, accuracy: 0.001)
    XCTAssertEqual(halfTurn, -50, accuracy: 0.001)
  }

  func testEarthRotationWrapsWithoutReversingDirection() {
    XCTAssertEqual(
      SolarEarthRotation.horizontalOffset(spin: 2 * .pi, width: 100),
      0,
      accuracy: 0.001
    )
  }
}
