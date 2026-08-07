import XCTest

@testable import LockScreenCore

final class LockFlowTests: XCTestCase {
  func testConfiguredVaultPasscodeStartsUnlocking() {
    var flow = LockFlow(theme: .vault, vaultPasscode: "2580")

    XCTAssertEqual(flow.submitVaultPasscode("2580"), .completed)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testVaultUses1024AsItsDefaultPasscode() {
    var flow = LockFlow(theme: .vault)

    XCTAssertEqual(flow.submitVaultPasscode("1024"), .completed)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testWrongVaultPasscodeStaysSealed() {
    var flow = LockFlow(theme: .vault, vaultPasscode: "2580")

    XCTAssertEqual(flow.submitVaultPasscode("1024"), .incorrect)
    XCTAssertEqual(flow.phase, .awaitingSequence)
  }

  func testVaultPasscodeIsIgnoredForOtherThemes() {
    var flow = LockFlow(theme: .wood, vaultPasscode: "2580")

    XCTAssertEqual(flow.submitVaultPasscode("2580"), .ignored)
    XCTAssertEqual(flow.phase, .awaitingSequence)
  }

  func testThirdWoodKnockStartsUnlocking() {
    var flow = LockFlow(theme: .wood)

    XCTAssertEqual(flow.knockWoodDoor(), .knocked(count: 1))
    XCTAssertEqual(flow.knockWoodDoor(), .knocked(count: 2))
    XCTAssertEqual(flow.phase, .awaitingSequence)

    XCTAssertEqual(flow.knockWoodDoor(), .completed)
    XCTAssertEqual(flow.woodKnockCount, 3)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testWoodKnockIsIgnoredForFormationGate() {
    var flow = LockFlow(theme: .formation)

    XCTAssertEqual(flow.knockWoodDoor(), .ignored)
    XCTAssertEqual(flow.woodKnockCount, 0)
  }

  func testAccurateFormationTraceActivatesGate() {
    var flow = LockFlow(theme: .formation)

    XCTAssertEqual(flow.applyFormationTrace(score: 0.9), .activated)
    XCTAssertEqual(flow.formationEnergy, 1)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testModeratelyAccurateFormationTraceActivatesGate() {
    var flow = LockFlow(theme: .formation)

    XCTAssertEqual(flow.applyFormationTrace(score: 0.66), .activated)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testPartialFormationTraceChargesWithoutOpening() {
    var flow = LockFlow(theme: .formation)

    XCTAssertEqual(flow.applyFormationTrace(score: 0.5), .charged(energy: 0.5))
    XCTAssertEqual(flow.formationEnergy, 0.5)
    XCTAssertEqual(flow.phase, .awaitingSequence)
  }

  func testChangingFormationTrajectoryClearsCharge() {
    var flow = LockFlow(theme: .formation)
    _ = flow.applyFormationTrace(score: 0.5)

    flow.selectFormationTrajectory(.infinity)

    XCTAssertEqual(flow.formationTrajectory, .infinity)
    XCTAssertEqual(flow.formationEnergy, 0)
  }

  func testCorrectSequenceStartsUnlocking() {
    var flow = LockFlow(theme: .wood)

    let moves = flow.requiredSequence.map { flow.chooseRune($0) }

    XCTAssertEqual(
      moves.dropLast(), [.advanced(current: 1, total: 3), .advanced(current: 2, total: 3)])
    XCTAssertEqual(moves.last, .completed)
    XCTAssertEqual(flow.phase, .unlocking)
    XCTAssertEqual(flow.progress, 3)
  }

  func testWrongRuneResetsPuzzleProgress() {
    var flow = LockFlow(theme: .wood)
    _ = flow.chooseRune(flow.requiredSequence[0])

    let move = flow.chooseRune(.moon)

    XCTAssertEqual(move, .incorrect)
    XCTAssertEqual(flow.phase, .awaitingSequence)
    XCTAssertEqual(flow.progress, 0)
  }

  func testSelectingThemeChangesSequenceAndResetsState() {
    var flow = LockFlow(theme: .wood)
    _ = flow.chooseRune(flow.requiredSequence[0])
    let woodenSequence = flow.requiredSequence

    flow.selectTheme(.formation)

    XCTAssertEqual(flow.theme, .formation)
    XCTAssertNotEqual(flow.requiredSequence, woodenSequence)
    XCTAssertEqual(flow.phase, .awaitingSequence)
    XCTAssertEqual(flow.progress, 0)
    XCTAssertNil(flow.lastMove)
  }

  func testFinishingUnlockAnimationOpensDoor() {
    var flow = LockFlow(theme: .formation)
    for rune in flow.requiredSequence {
      flow.chooseRune(rune)
    }

    flow.finishUnlockAnimation()

    XCTAssertEqual(flow.phase, .open)
  }

  func testResetReturnsCurrentThemeToSealedState() {
    var flow = LockFlow(theme: .formation)
    for rune in flow.requiredSequence {
      flow.chooseRune(rune)
    }
    flow.finishUnlockAnimation()

    flow.reset()

    XCTAssertEqual(flow.theme, .formation)
    XCTAssertEqual(flow.phase, .awaitingSequence)
    XCTAssertEqual(flow.progress, 0)
    XCTAssertNil(flow.lastMove)
  }

  func testFinishingRevealRequestsReturnToDesktop() {
    var flow = LockFlow(theme: .formation)
    for rune in flow.requiredSequence {
      flow.chooseRune(rune)
    }
    flow.finishUnlockAnimation()

    flow.finishReveal()

    XCTAssertEqual(flow.phase, .returningToDesktop)
  }

  func testRevealCannotFinishBeforeDoorIsOpen() {
    var flow = LockFlow(theme: .wood)

    flow.finishReveal()

    XCTAssertEqual(flow.phase, .awaitingSequence)
  }

  func testInputIsIgnoredAfterPuzzleCompletes() {
    var flow = LockFlow(theme: .wood)
    for rune in flow.requiredSequence {
      flow.chooseRune(rune)
    }

    let move = flow.chooseRune(.sun)

    XCTAssertEqual(move, .ignored)
    XCTAssertEqual(flow.phase, .unlocking)
  }
}
