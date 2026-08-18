public enum DoorTheme: String, CaseIterable, Identifiable, Sendable {
  case solar
  case formation
  case wood
  case vault

  public var id: Self { self }
}

public enum LockPhase: Equatable, Sendable {
  case sealed
  case unlocking
  case open
  case returningToDesktop
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
  public static let defaultVaultPasscode = VaultPasscode.defaultValue.value

  public private(set) var theme: DoorTheme
  public private(set) var phase: LockPhase
  public private(set) var woodKnockCount: Int
  public private(set) var formationEnergy: Double
  public private(set) var formationTrajectory: FormationTrajectory
  private var vaultPasscode: VaultPasscode

  public init(
    theme: DoorTheme = .solar,
    vaultPasscode: String = LockFlow.defaultVaultPasscode
  ) {
    self.theme = theme
    self.vaultPasscode = VaultPasscode(vaultPasscode) ?? .defaultValue
    phase = .sealed
    woodKnockCount = 0
    formationEnergy = 0
    formationTrajectory = .circle
  }

  @discardableResult
  public mutating func activateSolarSystem() -> SolarActivationResult {
    guard theme == .solar, phase == .sealed else { return .ignored }

    phase = .unlocking
    return .completed
  }

  public mutating func selectTheme(_ theme: DoorTheme) {
    self.theme = theme
    reset()
  }

  @discardableResult
  public mutating func knockWoodDoor() -> WoodKnockResult {
    guard theme == .wood, phase == .sealed else { return .ignored }

    woodKnockCount += 1
    if woodKnockCount == 3 {
      phase = .unlocking
      return .completed
    }

    return .knocked(count: woodKnockCount)
  }

  public mutating func selectFormationTrajectory(_ trajectory: FormationTrajectory) {
    guard theme == .formation, phase == .sealed,
      trajectory != formationTrajectory
    else { return }

    formationTrajectory = trajectory
    formationEnergy = 0
  }

  @discardableResult
  public mutating func applyFormationTrace(score: Double) -> FormationTraceResult {
    guard theme == .formation, phase == .sealed, score.isFinite else {
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
    guard theme == .vault, phase == .sealed else { return .ignored }
    guard VaultPasscode(passcode) == vaultPasscode else { return .incorrect }

    phase = .unlocking
    return .completed
  }

  public static func isValidVaultPasscode(_ passcode: String) -> Bool {
    VaultPasscode(passcode) != nil
  }

  @discardableResult
  public mutating func updateVaultPasscode(_ passcode: String) -> Bool {
    guard theme == .vault, phase == .sealed,
      let validatedPasscode = VaultPasscode(passcode)
    else { return false }

    vaultPasscode = validatedPasscode
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
    phase = .sealed
    woodKnockCount = 0
    formationEnergy = 0
  }
}
