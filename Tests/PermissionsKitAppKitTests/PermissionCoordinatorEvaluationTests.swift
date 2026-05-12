import ApplicationServices
import PermissionsKit
import XCTest

@testable import PermissionsKitAppKit

final class PermissionCoordinatorEvaluationTests: XCTestCase {
  func testEvaluateAccessibilityPermissionForGrantedStatusResetsFlags() {
    let evaluation = evaluateAccessibilityPermission(
      status: .granted,
      hasPrompted: true,
      hasPresentedGuidance: true,
      userInitiated: true
    )

    XCTAssertTrue(evaluation.shouldResetPrompt)
    XCTAssertTrue(evaluation.shouldResetGuidance)
    XCTAssertFalse(evaluation.shouldPrompt)
    XCTAssertFalse(evaluation.shouldOpenSettingsImmediately)
    XCTAssertFalse(evaluation.shouldPresentGuidance)
    XCTAssertEqual(evaluation.initialResult, PermissionResult.granted)
  }

  func testEvaluateAccessibilityPermissionForDeniedUserInitiatedPromptsAndGuides() {
    let evaluation = evaluateAccessibilityPermission(
      status: .denied,
      hasPrompted: false,
      hasPresentedGuidance: false,
      userInitiated: true
    )

    XCTAssertTrue(evaluation.shouldPrompt)
    XCTAssertTrue(evaluation.shouldOpenSettingsImmediately)
    XCTAssertTrue(evaluation.shouldPresentGuidance)
    XCTAssertFalse(evaluation.shouldResetPrompt)
    XCTAssertFalse(evaluation.shouldResetGuidance)
    XCTAssertEqual(evaluation.initialResult, PermissionResult.pending)
  }

  func testEvaluateAccessibilityPermissionForRepeatedDeniedBackgroundRunSkipsUI() {
    let evaluation = evaluateAccessibilityPermission(
      status: .denied,
      hasPrompted: true,
      hasPresentedGuidance: true,
      userInitiated: false
    )

    XCTAssertFalse(evaluation.shouldPrompt)
    XCTAssertFalse(evaluation.shouldOpenSettingsImmediately)
    XCTAssertFalse(evaluation.shouldPresentGuidance)
    XCTAssertFalse(evaluation.shouldResetPrompt)
    XCTAssertFalse(evaluation.shouldResetGuidance)
    XCTAssertEqual(evaluation.initialResult, PermissionResult.pending)
  }

  func testEvaluateAccessibilityPermissionTracksPromptAndGuidanceSeparately() {
    let promptedWithoutGuidance = evaluateAccessibilityPermission(
      status: .denied,
      hasPrompted: true,
      hasPresentedGuidance: false,
      userInitiated: true
    )
    XCTAssertFalse(promptedWithoutGuidance.shouldPrompt)
    XCTAssertFalse(promptedWithoutGuidance.shouldOpenSettingsImmediately)
    XCTAssertTrue(promptedWithoutGuidance.shouldPresentGuidance)
    XCTAssertEqual(promptedWithoutGuidance.initialResult, PermissionResult.pending)

    let unpromptedWithGuidance = evaluateAccessibilityPermission(
      status: .denied,
      hasPrompted: false,
      hasPresentedGuidance: true,
      userInitiated: true
    )
    XCTAssertTrue(unpromptedWithGuidance.shouldPrompt)
    XCTAssertTrue(unpromptedWithGuidance.shouldOpenSettingsImmediately)
    XCTAssertFalse(unpromptedWithGuidance.shouldPresentGuidance)
    XCTAssertEqual(unpromptedWithGuidance.initialResult, PermissionResult.pending)
  }

  func testEvaluateAutomationPermissionForCachedStates() {
    let granted = evaluateAutomationPermission(
      currentState: .granted,
      status: noErr,
      procNotFound: OSStatus(-600),
      userInitiated: true
    )
    XCTAssertEqual(granted.nextState, AutomationPermissionState.granted)
    XCTAssertFalse(granted.shouldPresentGuidance)
    XCTAssertEqual(granted.result, PermissionResult.granted)

    let denied = evaluateAutomationPermission(
      currentState: .denied,
      status: noErr,
      procNotFound: OSStatus(-600),
      userInitiated: true
    )
    XCTAssertEqual(denied.nextState, AutomationPermissionState.denied)
    XCTAssertTrue(denied.shouldPresentGuidance)
    XCTAssertEqual(denied.result, PermissionResult.denied)

    let backgroundDenied = evaluateAutomationPermission(
      currentState: .denied,
      status: noErr,
      procNotFound: OSStatus(-600),
      userInitiated: false
    )
    XCTAssertEqual(backgroundDenied.nextState, AutomationPermissionState.denied)
    XCTAssertFalse(backgroundDenied.shouldPresentGuidance)
    XCTAssertEqual(backgroundDenied.result, PermissionResult.denied)
  }

  func testEvaluateAutomationPermissionForAllSystemStatuses() {
    let procNotFound = OSStatus(-600)

    let notPermitted = evaluateAutomationPermission(
      currentState: .unknown,
      status: OSStatus(errAEEventNotPermitted),
      procNotFound: procNotFound,
      userInitiated: true
    )
    XCTAssertEqual(notPermitted.nextState, AutomationPermissionState.denied)
    XCTAssertTrue(notPermitted.shouldPresentGuidance)
    XCTAssertEqual(notPermitted.result, PermissionResult.denied)

    let backgroundNotPermitted = evaluateAutomationPermission(
      currentState: .unknown,
      status: OSStatus(errAEEventNotPermitted),
      procNotFound: procNotFound,
      userInitiated: false
    )
    XCTAssertEqual(backgroundNotPermitted.nextState, AutomationPermissionState.denied)
    XCTAssertFalse(backgroundNotPermitted.shouldPresentGuidance)
    XCTAssertEqual(backgroundNotPermitted.result, PermissionResult.denied)

    let consent = evaluateAutomationPermission(
      currentState: .unknown,
      status: OSStatus(errAEEventWouldRequireUserConsent),
      procNotFound: procNotFound,
      userInitiated: false
    )
    XCTAssertEqual(consent.nextState, AutomationPermissionState.unknown)
    XCTAssertFalse(consent.shouldPresentGuidance)
    XCTAssertEqual(consent.result, PermissionResult.pending)

    let userInitiatedConsent = evaluateAutomationPermission(
      currentState: .unknown,
      status: OSStatus(errAEEventWouldRequireUserConsent),
      procNotFound: procNotFound,
      userInitiated: true
    )
    XCTAssertEqual(userInitiatedConsent.nextState, AutomationPermissionState.unknown)
    XCTAssertTrue(userInitiatedConsent.shouldPresentGuidance)
    XCTAssertEqual(userInitiatedConsent.result, PermissionResult.pending)

    let missingTarget = evaluateAutomationPermission(
      currentState: .unknown,
      status: procNotFound,
      procNotFound: procNotFound,
      userInitiated: false
    )
    XCTAssertEqual(missingTarget.nextState, AutomationPermissionState.unknown)
    XCTAssertFalse(missingTarget.shouldPresentGuidance)
    XCTAssertEqual(missingTarget.result, PermissionResult.pending)

    let userInitiatedMissingTarget = evaluateAutomationPermission(
      currentState: .unknown,
      status: procNotFound,
      procNotFound: procNotFound,
      userInitiated: true
    )
    XCTAssertEqual(userInitiatedMissingTarget.nextState, AutomationPermissionState.unknown)
    XCTAssertTrue(userInitiatedMissingTarget.shouldPresentGuidance)
    XCTAssertEqual(userInitiatedMissingTarget.result, PermissionResult.pending)

    let granted = evaluateAutomationPermission(
      currentState: .unknown,
      status: noErr,
      procNotFound: procNotFound,
      userInitiated: true
    )
    XCTAssertEqual(granted.nextState, AutomationPermissionState.granted)
    XCTAssertFalse(granted.shouldPresentGuidance)
    XCTAssertEqual(granted.result, PermissionResult.granted)

    let fallback = evaluateAutomationPermission(
      currentState: .unknown,
      status: OSStatus(-1),
      procNotFound: procNotFound,
      userInitiated: true
    )
    XCTAssertEqual(fallback.nextState, AutomationPermissionState.unknown)
    XCTAssertTrue(fallback.shouldPresentGuidance)
    XCTAssertEqual(fallback.result, PermissionResult.pending)
  }

  func testEvaluateScreenRecordingPermissionForGrantedAndDeniedStates() {
    let granted = evaluateScreenRecordingPermission(granted: true)
    XCTAssertTrue(granted.shouldResetGuidance)
    XCTAssertFalse(granted.shouldPresentGuidance)
    XCTAssertFalse(granted.shouldRequestPermission)
    XCTAssertEqual(granted.result, PermissionResult.granted)

    let denied = evaluateScreenRecordingPermission(granted: false)
    XCTAssertFalse(denied.shouldResetGuidance)
    XCTAssertTrue(denied.shouldPresentGuidance)
    XCTAssertTrue(denied.shouldRequestPermission)
    XCTAssertEqual(denied.result, PermissionResult.pending)
  }
}
