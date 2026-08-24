import LockScreenCore
import XCTest

@testable import LockScreenApp

final class ThemePaletteTests: XCTestCase {
  func testInkLandscapeUsesItsOwnRevealPalette() {
    XCTAssertEqual(
      DoorTheme.landscape.presentationPaletteKind,
      .inkLandscape
    )
  }

  func testInkLandscapeHasItsOwnTopLevelLaunchArgument() {
    XCTAssertEqual(DoorTheme.landscape.descriptor.launchArgument, "--landscape")
  }

  func testFormationKeepsItsFormationRevealPalette() {
    XCTAssertEqual(DoorTheme.formation.presentationPaletteKind, .formation)
  }
}
