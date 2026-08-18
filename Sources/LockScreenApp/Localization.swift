import Foundation

enum L10n {
  static func text(
    _ key: String,
    locale: Locale? = nil
  ) -> String {
    let preferences = locale.map { [$0.identifier] } ?? Locale.preferredLanguages
    let localization = Bundle.preferredLocalizations(
      from: Bundle.module.localizations,
      forPreferences: preferences
    ).first

    guard let localization,
      let path = Bundle.module.path(forResource: localization, ofType: "lproj"),
      let localizedBundle = Bundle(path: path)
    else {
      return key
    }

    return localizedBundle.localizedString(forKey: key, value: key, table: nil)
  }

  static func format(_ key: String, _ arguments: CVarArg...) -> String {
    String(
      format: text(key),
      locale: Locale.current,
      arguments: arguments
    )
  }
}
