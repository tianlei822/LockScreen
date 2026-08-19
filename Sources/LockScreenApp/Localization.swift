import Foundation

enum L10n {
  private static let resourceBundleName = "LockScreen_LockScreenApp"

  private static let resources =
    packagedResourceBundle(in: .main) ?? .module

  static func packagedResourceBundle(in mainBundle: Bundle) -> Bundle? {
    guard
      let url = mainBundle.url(
        forResource: resourceBundleName,
        withExtension: "bundle"
      )
    else { return nil }

    return Bundle(url: url)
  }

  static func text(
    _ key: String,
    locale: Locale? = nil
  ) -> String {
    let preferences = locale.map { [$0.identifier] } ?? Locale.preferredLanguages
    let localization = Bundle.preferredLocalizations(
      from: resources.localizations,
      forPreferences: preferences
    ).first

    guard let localization,
      let path = resources.path(forResource: localization, ofType: "lproj"),
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
