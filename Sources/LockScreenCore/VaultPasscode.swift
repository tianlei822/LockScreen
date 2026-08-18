public struct VaultPasscode: Equatable, Sendable {
  public static let lengthRange = 4...8
  public static let defaultValue = VaultPasscode(uncheckedValue: "1024")

  public let value: String

  public init?(_ value: String) {
    guard Self.lengthRange.contains(value.utf8.count),
      value.utf8.allSatisfy({ (48...57).contains($0) })
    else { return nil }

    self.value = value
  }

  public static func filteredInput(_ input: String) -> String {
    let digits = input.filter { character in
      guard character.unicodeScalars.count == 1,
        let scalar = character.unicodeScalars.first
      else { return false }
      return (48...57).contains(scalar.value)
    }
    return String(digits.prefix(lengthRange.upperBound))
  }

  private init(uncheckedValue: String) {
    value = uncheckedValue
  }
}
