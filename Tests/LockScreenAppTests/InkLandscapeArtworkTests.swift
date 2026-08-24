import XCTest

@testable import LockScreenApp

final class InkLandscapeArtworkTests: XCTestCase {
  func testBoatHoverTargetFollowsTheVisibleBoatInsteadOfTheCenterOfThePainting() {
    let target = InkLandscapeBoatInteraction.normalizedTarget

    XCTAssertFalse(target.contains(CGPoint(x: 0.55, y: 0.75)))
    XCTAssertTrue(target.contains(CGPoint(x: 0.75, y: 0.85)))
  }

  func testWideCompositionKeepsTheEntireFishingBoatVisible() {
    let canvasSize = CGSize(width: 1_836, height: 768)
    let viewport = InkLandscapeViewport(
      canvasSize: canvasSize,
      imageSize: CGSize(width: 1_672, height: 941)
    )

    let fishingBoatBounds = viewport.rect(for: InkLandscapeBoatInteraction.normalizedTarget)

    XCTAssertLessThanOrEqual(fishingBoatBounds.maxY, canvasSize.height)
    XCTAssertGreaterThan(fishingBoatBounds.minY, canvasSize.height * 0.64)
  }
}
