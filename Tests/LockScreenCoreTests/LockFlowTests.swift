import XCTest

@testable import LockScreenCore

final class LockFlowTests: XCTestCase {
  func testDefaultFlowStartsWithSolarAtlas() {
    let flow = LockFlow()

    XCTAssertEqual(flow.theme, .solar)
    XCTAssertEqual(flow.formationTrajectory, .circle)
  }

  func testGalleryOrderingStartsWithSolarAtlasThenThreeDistinctRituals() {
    XCTAssertEqual(DoorTheme.allCases, [.solar, .formation, .wood, .vault])
    XCTAssertEqual(FormationTrajectory.allCases, [.circle, .infinity, .triangle])
  }

  func testSolarActivationStartsUnlocking() {
    var flow = LockFlow(theme: .solar)

    XCTAssertEqual(flow.activateSolarSystem(), .completed)
    XCTAssertEqual(flow.phase, .unlocking)
  }

  func testSolarActivationIsIgnoredForOtherThemes() {
    var flow = LockFlow(theme: .formation)

    XCTAssertEqual(flow.activateSolarSystem(), .ignored)
    XCTAssertEqual(flow.phase, .sealed)
  }

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

  func testCompletedVaultSubmissionClearsTheEnteredPasscode() {
    XCTAssertTrue(VaultPasscodeResult.completed.clearsPasscodeEntry)
  }

  func testWrongVaultPasscodeStaysSealed() {
    var flow = LockFlow(theme: .vault, vaultPasscode: "2580")

    XCTAssertEqual(flow.submitVaultPasscode("1024"), .incorrect)
    XCTAssertEqual(flow.phase, .sealed)
  }

  func testVaultPasscodeCanBeUpdatedWhileTheVaultIsSealed() {
    var flow = LockFlow(theme: .vault, vaultPasscode: "2580")

    XCTAssertTrue(flow.updateVaultPasscode("7531"))
    XCTAssertEqual(flow.submitVaultPasscode("2580"), .incorrect)
    XCTAssertEqual(flow.submitVaultPasscode("7531"), .completed)
  }

  func testVaultPasscodeUpdateRejectsInvalidCodes() {
    var flow = LockFlow(theme: .vault, vaultPasscode: "2580")

    XCTAssertFalse(flow.updateVaultPasscode("123"))
    XCTAssertFalse(flow.updateVaultPasscode("123456789"))
    XCTAssertFalse(flow.updateVaultPasscode("25A0"))
    XCTAssertEqual(flow.submitVaultPasscode("2580"), .completed)
  }

  func testVaultPasscodeUsesTheSameASCIIDigitsAsTheKeypadAndLaunchArguments() {
    XCTAssertTrue(LockFlow.isValidVaultPasscode("01234567"))
    XCTAssertFalse(LockFlow.isValidVaultPasscode("١٢٣٤"))
    XCTAssertFalse(LockFlow.isValidVaultPasscode("１２３４"))
  }

  func testVaultPasscodeIsIgnoredForOtherThemes() {
    var flow = LockFlow(theme: .wood, vaultPasscode: "2580")

    XCTAssertEqual(flow.submitVaultPasscode("2580"), .ignored)
    XCTAssertEqual(flow.phase, .sealed)
  }

  func testThirdWoodKnockStartsUnlocking() {
    var flow = LockFlow(theme: .wood)

    XCTAssertEqual(flow.knockWoodDoor(), .knocked(count: 1))
    XCTAssertEqual(flow.knockWoodDoor(), .knocked(count: 2))
    XCTAssertEqual(flow.phase, .sealed)

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
    XCTAssertEqual(flow.phase, .sealed)
  }

  func testChangingFormationTrajectoryClearsCharge() {
    var flow = LockFlow(theme: .formation)
    _ = flow.applyFormationTrace(score: 0.5)

    flow.selectFormationTrajectory(.infinity)

    XCTAssertEqual(flow.formationTrajectory, .infinity)
    XCTAssertEqual(flow.formationEnergy, 0)
  }

  func testSelectingThemeResetsTransientRitualState() {
    var flow = LockFlow(theme: .wood)
    _ = flow.knockWoodDoor()

    flow.selectTheme(.formation)

    XCTAssertEqual(flow.theme, .formation)
    XCTAssertEqual(flow.phase, .sealed)
    XCTAssertEqual(flow.woodKnockCount, 0)
  }

  func testSelectingTheCurrentThemeRestartsItsRitual() {
    var flow = LockFlow(theme: .wood)
    _ = flow.knockWoodDoor()

    flow.selectTheme(.wood)

    XCTAssertEqual(flow.theme, .wood)
    XCTAssertEqual(flow.phase, .sealed)
    XCTAssertEqual(flow.woodKnockCount, 0)
  }

  func testFinishingUnlockAnimationOpensDoor() {
    var flow = LockFlow(theme: .formation)
    _ = flow.applyFormationTrace(score: 1)

    flow.finishUnlockAnimation()

    XCTAssertEqual(flow.phase, .open)
  }

  func testResetReturnsCurrentThemeToSealedState() {
    var flow = LockFlow(theme: .formation)
    _ = flow.applyFormationTrace(score: 1)
    flow.finishUnlockAnimation()

    flow.reset()

    XCTAssertEqual(flow.theme, .formation)
    XCTAssertEqual(flow.phase, .sealed)
    XCTAssertEqual(flow.formationEnergy, 0)
  }

  func testFinishingRevealRequestsReturnToDesktop() {
    var flow = LockFlow(theme: .formation)
    _ = flow.applyFormationTrace(score: 1)
    flow.finishUnlockAnimation()

    flow.finishReveal()

    XCTAssertEqual(flow.phase, .returningToDesktop)
  }

  func testRevealCannotFinishBeforeDoorIsOpen() {
    var flow = LockFlow(theme: .wood)

    flow.finishReveal()

    XCTAssertEqual(flow.phase, .sealed)
  }

  func testInputIsIgnoredAfterRitualCompletes() {
    var flow = LockFlow(theme: .wood)
    _ = flow.knockWoodDoor()
    _ = flow.knockWoodDoor()
    _ = flow.knockWoodDoor()

    let move = flow.knockWoodDoor()

    XCTAssertEqual(move, .ignored)
    XCTAssertEqual(flow.phase, .unlocking)
  }
}
