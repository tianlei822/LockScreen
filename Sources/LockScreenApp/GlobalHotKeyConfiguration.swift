import Carbon.HIToolbox
import Foundation

enum GlobalHotKeyPreset: String, CaseIterable, Identifiable {
  case commandL
  case commandShiftL
  case controlOptionL

  static let defaultValue = GlobalHotKeyPreset.commandL

  var id: Self { self }
  var keyCode: UInt32 { UInt32(kVK_ANSI_L) }

  var modifiers: UInt32 {
    switch self {
    case .commandL:
      UInt32(cmdKey)
    case .commandShiftL:
      UInt32(cmdKey | shiftKey)
    case .controlOptionL:
      UInt32(controlKey | optionKey)
    }
  }

  var title: String {
    switch self {
    case .commandL:
      "⌘L"
    case .commandShiftL:
      "⇧⌘L"
    case .controlOptionL:
      "⌃⌥L"
    }
  }
}

struct GlobalHotKeyPreferenceStore {
  private static let storageKey = "globalHotKeyPreset"

  let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func load() -> GlobalHotKeyPreset {
    guard let rawValue = defaults.string(forKey: Self.storageKey),
      let preset = GlobalHotKeyPreset(rawValue: rawValue)
    else {
      return .defaultValue
    }
    return preset
  }

  func save(_ preset: GlobalHotKeyPreset) {
    defaults.set(preset.rawValue, forKey: Self.storageKey)
  }
}
