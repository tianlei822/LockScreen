import Foundation
import LockScreenCore

enum ProductMetadata {
  static let fallbackDisplayName = "Threshold"
  static let fallbackBundleIdentifier = "com.tianlei.threshold"

  static var displayName: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? fallbackDisplayName
  }

  static var bundleIdentifier: String {
    Bundle.main.bundleIdentifier ?? fallbackBundleIdentifier
  }
}

enum AppConfiguration {
  /// `--background`: lurk windowless and summon the ritual with the configured shortcut.
  static let backgroundMode = ProcessInfo.processInfo.arguments.contains("--background")

  static var initialTheme: DoorTheme {
    resolveInitialTheme(arguments: ProcessInfo.processInfo.arguments)
  }

  static func resolveInitialTheme(arguments: [String]) -> DoorTheme {
    for argument in arguments {
      if let theme = DoorTheme.allCases.first(where: {
        $0.descriptor.launchArgument == argument
      }) {
        return theme
      }
    }
    return .solar
  }

  static var vaultPasscode: String {
    resolveVaultPasscode(
      arguments: ProcessInfo.processInfo.arguments,
      storedPasscode: VaultPasscodeStore().load()
    )
  }

  static func resolveVaultPasscode(arguments: [String], storedPasscode: String) -> String {
    let prefix = "--passcode="
    let fallback =
      LockFlow.isValidVaultPasscode(storedPasscode)
      ? storedPasscode : LockFlow.defaultVaultPasscode
    guard
      let argument = arguments.first(where: { $0.hasPrefix(prefix) })
    else {
      return fallback
    }

    let passcode = String(argument.dropFirst(prefix.count))
    return LockFlow.isValidVaultPasscode(passcode) ? passcode : fallback
  }
}
