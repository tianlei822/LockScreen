import LockScreenCore
import XCTest

@testable import LockScreenApp

final class AppConfigurationTests: XCTestCase {
  func testEveryRitualDescriptorResolvesItsLaunchArgument() {
    for theme in DoorTheme.allCases {
      XCTAssertEqual(
        AppConfiguration.resolveInitialTheme(
          arguments: ["LockScreen", theme.descriptor.launchArgument]
        ),
        theme
      )
    }
  }

  func testFirstThemeLaunchArgumentWins() {
    XCTAssertEqual(
      AppConfiguration.resolveInitialTheme(
        arguments: ["LockScreen", "--wood", "--formation"]
      ),
      .wood
    )
  }

  func testUnknownLaunchArgumentsKeepSolarAsTheDefault() {
    XCTAssertEqual(
      AppConfiguration.resolveInitialTheme(arguments: ["LockScreen", "--unknown"]),
      .solar
    )
  }
}
