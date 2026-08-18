import XCTest

@testable import LockScreenCore

final class RitualRenderStateTests: XCTestCase {
  func testAnimationsArePausedUntilTheRitualIsPresented() {
    let state = RitualRenderState()

    XCTAssertFalse(state.isPresented)
    XCTAssertTrue(state.pausesAnimations)
  }

  func testPresentingAndRetreatingControlsAnimationActivity() {
    var state = RitualRenderState()

    state.present()
    XCTAssertTrue(state.isPresented)
    XCTAssertFalse(state.pausesAnimations)

    state.retreat()
    XCTAssertFalse(state.isPresented)
    XCTAssertTrue(state.pausesAnimations)
  }

  func testVisualEffectsPauseForReducedMotionEvenWhilePresented() {
    XCTAssertTrue(
      RitualMotionPolicy.pausesVisualEffects(
        renderingPaused: false,
        reduceMotion: true
      )
    )
    XCTAssertFalse(
      RitualMotionPolicy.pausesVisualEffects(
        renderingPaused: false,
        reduceMotion: false
      )
    )
  }
}
