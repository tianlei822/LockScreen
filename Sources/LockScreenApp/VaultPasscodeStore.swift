import Foundation
import LockScreenCore

struct VaultPasscodeStore {
  private static let storageKey = "vaultRitualPasscode"

  let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> String {
    guard let storedPasscode = defaults.string(forKey: Self.storageKey),
      LockFlow.isValidVaultPasscode(storedPasscode)
    else {
      return LockFlow.defaultVaultPasscode
    }

    return storedPasscode
  }

  @discardableResult
  func save(_ passcode: String) -> Bool {
    guard LockFlow.isValidVaultPasscode(passcode) else { return false }

    defaults.set(passcode, forKey: Self.storageKey)
    return true
  }
}
