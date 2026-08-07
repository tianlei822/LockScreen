import LockScreenCore
import SwiftUI

struct FormationVisualStyle {
  let primary: Color
  let secondary: Color
  let flare: Color
}

extension FormationTrajectory {
  var visualStyle: FormationVisualStyle {
    switch self {
    case .circle:
      FormationVisualStyle(
        primary: Color(red: 0.42, green: 0.96, blue: 0.58),
        secondary: Color(red: 1, green: 0.72, blue: 0.24),
        flare: Color(red: 1, green: 0.39, blue: 0.18)
      )
    case .infinity:
      FormationVisualStyle(
        primary: Color(red: 0.18, green: 0.91, blue: 0.84),
        secondary: Color(red: 0.52, green: 0.95, blue: 0.71),
        flare: .white
      )
    case .triangle:
      FormationVisualStyle(
        primary: Color(red: 0.34, green: 0.68, blue: 1),
        secondary: Color(red: 0.68, green: 0.42, blue: 1),
        flare: Color(red: 0.88, green: 0.95, blue: 1)
      )
    }
  }
}
