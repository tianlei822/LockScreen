public enum DoorTheme: String, CaseIterable, Identifiable, Sendable {
  case solar
  case formation
  case wood
  case vault

  public var id: Self { self }

  public var title: String {
    switch self {
    case .solar:
      "Solar Atlas"
    case .wood:
      "Wooden Door"
    case .formation:
      "Five-Phase Formation"
    case .vault:
      "Cipher Vault"
    }
  }

  public var subtitle: String {
    switch self {
    case .solar:
      "Orbit · Light · Helios"
    case .wood:
      "Oak · Brass · Ember"
    case .formation:
      "Cycle · Trace · Aether"
    case .vault:
      "Steel · Code · Relay"
    }
  }
}

public enum Rune: Int, CaseIterable, Identifiable, Sendable {
  case sun
  case river
  case mountain
  case moon

  public var id: Self { self }

  public var symbol: String {
    switch self {
    case .sun:
      "☼"
    case .river:
      "≋"
    case .mountain:
      "△"
    case .moon:
      "◐"
    }
  }

  public var name: String {
    switch self {
    case .sun:
      "Sun"
    case .river:
      "River"
    case .mountain:
      "Mountain"
    case .moon:
      "Moon"
    }
  }

  public var keyboardNumber: Int { rawValue + 1 }
}

public enum LockPhase: Equatable, Sendable {
  case awaitingSequence
  case unlocking
  case open
  case returningToDesktop
}

public enum PuzzleMove: Equatable, Sendable {
  case advanced(current: Int, total: Int)
  case incorrect
  case completed
  case ignored
}

public enum WoodKnockResult: Equatable, Sendable {
  case knocked(count: Int)
  case completed
  case ignored
}

public enum SolarActivationResult: Equatable, Sendable {
  case completed
  case ignored
}

public enum FormationTraceResult: Equatable, Sendable {
  case charged(energy: Double)
  case rejected
  case activated
  case ignored
}

public enum VaultPasscodeResult: Equatable, Sendable {
  case incorrect
  case completed
  case ignored

  public var clearsPasscodeEntry: Bool {
    switch self {
    case .incorrect, .completed:
      true
    case .ignored:
      false
    }
  }
}

public struct LockFlow: Equatable, Sendable {
  public static let defaultVaultPasscode = "1024"

  public private(set) var theme: DoorTheme
  public private(set) var phase: LockPhase
  public private(set) var progress: Int
  public private(set) var lastMove: PuzzleMove?
  public private(set) var woodKnockCount: Int
  public private(set) var formationEnergy: Double
  public private(set) var formationTrajectory: FormationTrajectory
  private var vaultPasscode: String

  public var requiredSequence: [Rune] {
    switch theme {
    case .solar, .vault:
      []
    case .wood:
      [.sun, .river, .mountain]
    case .formation:
      [.moon, .mountain, .sun]
    }
  }

  public init(theme: DoorTheme = .solar, vaultPasscode: String = "1024") {
    self.theme = theme
    self.vaultPasscode =
      Self.isValidVaultPasscode(vaultPasscode) ? vaultPasscode : Self.defaultVaultPasscode
    phase = .awaitingSequence
    progress = 0
    lastMove = nil
    woodKnockCount = 0
    formationEnergy = 0
    formationTrajectory = .circle
  }

  @discardableResult
  public mutating func chooseRune(_ rune: Rune) -> PuzzleMove {
    guard !requiredSequence.isEmpty, phase == .awaitingSequence else {
      return .ignored
    }

    guard rune == requiredSequence[progress] else {
      progress = 0
      lastMove = .incorrect
      return .incorrect
    }

    progress += 1
    if progress == requiredSequence.count {
      phase = .unlocking
      lastMove = .completed
      return .completed
    }

    let move = PuzzleMove.advanced(current: progress, total: requiredSequence.count)
    lastMove = move
    return move
  }

  @discardableResult
  public mutating func activateSolarSystem() -> SolarActivationResult {
    guard theme == .solar, phase == .awaitingSequence else { return .ignored }

    phase = .unlocking
    return .completed
  }

  public mutating func selectTheme(_ theme: DoorTheme) {
    guard theme != self.theme else { return }
    self.theme = theme
    reset()
  }

  @discardableResult
  public mutating func knockWoodDoor() -> WoodKnockResult {
    guard theme == .wood, phase == .awaitingSequence else { return .ignored }

    woodKnockCount += 1
    if woodKnockCount == 3 {
      phase = .unlocking
      return .completed
    }

    return .knocked(count: woodKnockCount)
  }

  public mutating func selectFormationTrajectory(_ trajectory: FormationTrajectory) {
    guard theme == .formation, phase == .awaitingSequence,
      trajectory != formationTrajectory
    else { return }

    formationTrajectory = trajectory
    formationEnergy = 0
  }

  @discardableResult
  public mutating func applyFormationTrace(score: Double) -> FormationTraceResult {
    guard theme == .formation, phase == .awaitingSequence, score.isFinite else {
      return .ignored
    }

    let boundedScore = max(0, min(1, score))
    if boundedScore >= FormationTrajectoryMatcher.activationThreshold {
      formationEnergy = 1
      phase = .unlocking
      return .activated
    }

    if boundedScore >= 0.35 {
      formationEnergy = max(formationEnergy, boundedScore)
      return .charged(energy: formationEnergy)
    }

    formationEnergy = max(0, formationEnergy - 0.1)
    return .rejected
  }

  @discardableResult
  public mutating func submitVaultPasscode(_ passcode: String) -> VaultPasscodeResult {
    guard theme == .vault, phase == .awaitingSequence else { return .ignored }
    guard passcode == vaultPasscode else { return .incorrect }

    phase = .unlocking
    return .completed
  }

  public static func isValidVaultPasscode(_ passcode: String) -> Bool {
    (4...8).contains(passcode.count) && passcode.allSatisfy(\.isNumber)
  }

  @discardableResult
  public mutating func updateVaultPasscode(_ passcode: String) -> Bool {
    guard theme == .vault, phase == .awaitingSequence,
      Self.isValidVaultPasscode(passcode)
    else { return false }

    vaultPasscode = passcode
    return true
  }

  public mutating func finishUnlockAnimation() {
    guard phase == .unlocking else { return }
    phase = .open
  }

  public mutating func finishReveal() {
    guard phase == .open else { return }
    phase = .returningToDesktop
  }

  public mutating func reset() {
    phase = .awaitingSequence
    progress = 0
    lastMove = nil
    woodKnockCount = 0
    formationEnergy = 0
  }
}
