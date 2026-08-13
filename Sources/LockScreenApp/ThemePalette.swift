import LockScreenCore
import SwiftUI

struct ThemePalette {
  let backdrop: Color
  let haze: Color
  let accent: Color
  let accentSoft: Color
  let detail: Color
  let primaryText: Color
  let secondaryText: Color

  static let solar = ThemePalette(
    backdrop: Color(red: 0.006, green: 0.009, blue: 0.025),
    haze: Color(red: 0.07, green: 0.12, blue: 0.25),
    accent: Color(red: 1, green: 0.68, blue: 0.22),
    accentSoft: Color(red: 0.58, green: 0.2, blue: 0.055),
    detail: Color(red: 0.64, green: 0.78, blue: 0.95),
    primaryText: Color(red: 0.96, green: 0.97, blue: 1),
    secondaryText: Color(red: 0.59, green: 0.68, blue: 0.82)
  )

  static let wood = ThemePalette(
    backdrop: Color(red: 0.055, green: 0.032, blue: 0.02),
    haze: Color(red: 0.34, green: 0.16, blue: 0.055),
    accent: Color(red: 0.98, green: 0.64, blue: 0.24),
    accentSoft: Color(red: 0.64, green: 0.29, blue: 0.09),
    detail: Color(red: 0.88, green: 0.71, blue: 0.42),
    primaryText: Color(red: 0.97, green: 0.93, blue: 0.84),
    secondaryText: Color(red: 0.78, green: 0.69, blue: 0.55)
  )

  static let formation = ThemePalette(
    backdrop: Color(red: 0.018, green: 0.028, blue: 0.052),
    haze: Color(red: 0.02, green: 0.25, blue: 0.29),
    accent: Color(red: 0.18, green: 0.91, blue: 0.84),
    accentSoft: Color(red: 0.05, green: 0.42, blue: 0.44),
    detail: Color(red: 0.62, green: 0.89, blue: 0.78),
    primaryText: Color(red: 0.88, green: 1.0, blue: 0.98),
    secondaryText: Color(red: 0.51, green: 0.71, blue: 0.72)
  )

  static let vault = ThemePalette(
    backdrop: Color(red: 0.025, green: 0.032, blue: 0.038),
    haze: Color(red: 0.12, green: 0.16, blue: 0.18),
    accent: Color(red: 0.92, green: 0.61, blue: 0.2),
    accentSoft: Color(red: 0.42, green: 0.25, blue: 0.08),
    detail: Color(red: 0.68, green: 0.73, blue: 0.72),
    primaryText: Color(red: 0.94, green: 0.94, blue: 0.9),
    secondaryText: Color(red: 0.58, green: 0.63, blue: 0.63)
  )
}

extension DoorTheme {
  var palette: ThemePalette {
    switch self {
    case .solar:
      .solar
    case .wood:
      .wood
    case .formation:
      .formation
    case .vault:
      .vault
    }
  }
}
