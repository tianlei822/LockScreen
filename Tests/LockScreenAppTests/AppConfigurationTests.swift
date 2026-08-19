import Foundation
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

  func testPackagedAppRegistersAsAUIElementFromProcessLaunch() throws {
    let projectRoot = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let infoPlist = projectRoot.appending(path: "Support/Info.plist")
    let data = try Data(contentsOf: infoPlist)
    let values = try XCTUnwrap(
      PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    )

    XCTAssertEqual(values["LSUIElement"] as? Bool, true)
  }
}
