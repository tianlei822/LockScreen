import LockScreenCore
import SwiftUI

struct FormationVisualStyle {
  let primary: Color
  let secondary: Color
  let flare: Color
}

struct FormationDescriptor {
  let title: String
  let symbol: String
  let invocation: String
  let visualStyle: FormationVisualStyle
}

extension FormationTrajectory {
  var descriptor: FormationDescriptor {
    switch self {
    case .circle:
      FormationDescriptor(
        title: L10n.text("Five Phases"),
        symbol: "五",
        invocation: L10n.text("FIVE PHASES · GENERATION CYCLE"),
        visualStyle: FormationVisualStyle(
          primary: Color(red: 0.42, green: 0.96, blue: 0.58),
          secondary: Color(red: 1, green: 0.72, blue: 0.24),
          flare: Color(red: 1, green: 0.39, blue: 0.18)
        )
      )
    case .infinity:
      FormationDescriptor(
        title: L10n.text("Bagua Flow"),
        symbol: "卦",
        invocation: L10n.text("QIAN · KUN · ZHEN · XUN · KAN · LI · GEN · DUI"),
        visualStyle: FormationVisualStyle(
          primary: Color(red: 0.18, green: 0.91, blue: 0.84),
          secondary: Color(red: 0.52, green: 0.95, blue: 0.71),
          flare: .white
        )
      )
    case .triangle:
      FormationDescriptor(
        title: L10n.text("Thunder Seal"),
        symbol: "ϟ",
        invocation: L10n.text("CALL THE NINEFOLD THUNDER"),
        visualStyle: FormationVisualStyle(
          primary: Color(red: 0.34, green: 0.68, blue: 1),
          secondary: Color(red: 0.68, green: 0.42, blue: 1),
          flare: Color(red: 0.88, green: 0.95, blue: 1)
        )
      )
    }
  }

  var title: String { descriptor.title }
  var symbol: String { descriptor.symbol }
  var invocation: String { descriptor.invocation }
  var visualStyle: FormationVisualStyle { descriptor.visualStyle }
}
