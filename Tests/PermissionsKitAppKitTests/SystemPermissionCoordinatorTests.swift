import AppKit
import PermissionsKit
import XCTest

@testable import PermissionsKitAppKit

@MainActor
final class SystemPermissionCoordinatorTests: XCTestCase {
  func testEnsureAccessibilityPermissionReturnsTrueWhenAlreadyGranted() async {
    let checker = StatusSequencePermissionChecker(statuses: [.granted])
    let coordinator = SystemPermissionCoordinator()

    let result = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: false)

    XCTAssertTrue(result)
    let requests = checker.requestCount
    XCTAssertEqual(requests, 0)
  }

  func testEnsureAccessibilityPermissionReturnsFalseWhenDenied() async {
    let checker = StatusSequencePermissionChecker(statuses: [.denied, .denied])
    let coordinator = SystemPermissionCoordinator()

    let result = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: false)

    XCTAssertFalse(result)
    let requests = checker.requestCount
    XCTAssertEqual(requests, 1)
  }

  func testEnsureAccessibilityPermissionReturnsTrueAfterGrant() async {
    let checker = StatusSequencePermissionChecker(statuses: [.denied, .granted])
    let coordinator = SystemPermissionCoordinator()

    let result = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: false)

    XCTAssertTrue(result)
    let requests = checker.requestCount
    XCTAssertEqual(requests, 1)
  }

  func testEnsureAccessibilityPermissionUserInitiatedPresentsGuidanceAndOpensSettings() async {
    let checker = StatusSequencePermissionChecker(statuses: [.denied, .denied])
    let recorder = DependencyRecorder()
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: recorder.dependencies(alertResponse: .alertSecondButtonReturn)
    )

    let result = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: true)

    XCTAssertFalse(result)
    XCTAssertEqual(recorder.presentedAlerts.map(\.title), ["Accessibility permission required"])
    XCTAssertEqual(
      recorder.openedSettingsURLs,
      ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]
    )
  }

  func testResetAccessibilityGuidanceAllowsGuidanceToBePresentedAgain() async {
    let checker = StatusSequencePermissionChecker(statuses: [.denied])
    let recorder = DependencyRecorder()
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: recorder.dependencies(alertResponse: .alertSecondButtonReturn)
    )

    let firstResult = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: true)
    let secondResult = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: true)

    coordinator.resetAccessibilityGuidance()

    let thirdResult = await coordinator.ensureAccessibilityPermission(
      using: checker, userInitiated: true)

    XCTAssertFalse(firstResult)
    XCTAssertFalse(secondResult)
    XCTAssertFalse(thirdResult)
    XCTAssertEqual(
      recorder.presentedAlerts.map(\.title),
      ["Accessibility permission required", "Accessibility permission required"]
    )
    XCTAssertEqual(checker.requestCount, 1)
  }

  func testEnsureAutomationPermissionDeniedPresentsGuidanceOnlyOnce() {
    let recorder = DependencyRecorder()
    var dependencies = recorder.dependencies(alertResponse: .alertFirstButtonReturn)
    dependencies.determineAutomationPermission = { _ in OSStatus(errAEEventNotPermitted) }
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: dependencies
    )

    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: true))
    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: false))

    XCTAssertEqual(recorder.presentedAlerts.map(\.title), ["Automation permission required"])
    XCTAssertEqual(
      recorder.openedSettingsURLs,
      ["x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"]
    )
  }

  func testResetAutomationGuidanceAllowsGuidanceToBePresentedAgain() {
    let recorder = DependencyRecorder()
    var dependencies = recorder.dependencies(alertResponse: .alertSecondButtonReturn)
    dependencies.determineAutomationPermission = { _ in OSStatus(errAEEventNotPermitted) }
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: dependencies
    )

    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: true))
    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: true))

    coordinator.resetAutomationGuidance()

    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: true))
    XCTAssertEqual(
      recorder.presentedAlerts.map(\.title),
      ["Automation permission required", "Automation permission required"]
    )
  }

  func testAutomationPendingConsentIsNotCachedAsDenied() {
    let recorder = DependencyRecorder()
    var statuses = [OSStatus(errAEEventWouldRequireUserConsent), noErr]
    var dependencies = recorder.dependencies(alertResponse: .alertSecondButtonReturn)
    dependencies.determineAutomationPermission = { _ in
      statuses.removeFirst()
    }
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: dependencies
    )

    XCTAssertFalse(coordinator.ensureAutomationPermission(userInitiated: false))
    XCTAssertTrue(coordinator.ensureAutomationPermission(userInitiated: true))
    XCTAssertTrue(recorder.presentedAlerts.isEmpty)
  }

  func testPresentAutomationGuidanceForcesAlertAndOpensSettings() {
    let recorder = DependencyRecorder()
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: recorder.dependencies(alertResponse: .alertFirstButtonReturn)
    )

    coordinator.presentAutomationGuidance()

    XCTAssertEqual(recorder.presentedAlerts.map(\.title), ["Automation permission required"])
    XCTAssertEqual(
      recorder.openedSettingsURLs,
      ["x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"]
    )
  }

  func testEnsureScreenRecordingPermissionRunsGuidanceFlow() async {
    let recorder = DependencyRecorder()
    var dependencies = recorder.dependencies(alertResponse: .alertFirstButtonReturn)
    dependencies.preflightScreenRecording = { false }
    dependencies.requestScreenRecordingPermission = {
      recorder.screenRecordingRequestCount += 1
      return false
    }
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: dependencies
    )

    await coordinator.ensureScreenRecordingPermission()

    XCTAssertEqual(recorder.presentedAlerts.map(\.title), ["Screen Recording permission required"])
    XCTAssertEqual(recorder.screenRecordingRequestCount, 1)
    XCTAssertEqual(
      recorder.openedSettingsURLs,
      ["x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"]
    )
  }

  func testResetScreenRecordingGuidanceAllowsGuidanceToBePresentedAgain() async {
    let recorder = DependencyRecorder()
    var dependencies = recorder.dependencies(alertResponse: .alertSecondButtonReturn)
    dependencies.preflightScreenRecording = { false }
    let coordinator = SystemPermissionCoordinator(
      guidance: .english,
      logger: NoopSystemPermissionLogger(),
      dependencies: dependencies
    )

    await coordinator.ensureScreenRecordingPermission()
    await coordinator.ensureScreenRecordingPermission()

    coordinator.resetScreenRecordingGuidance()

    await coordinator.ensureScreenRecordingPermission()
    XCTAssertEqual(
      recorder.presentedAlerts.map(\.title),
      ["Screen Recording permission required", "Screen Recording permission required"]
    )
    XCTAssertEqual(recorder.screenRecordingRequestCount, 3)
  }
}

private final class StatusSequencePermissionChecker: PermissionChecking, @unchecked Sendable {
  private let statuses: [PermissionStatus]
  private var statusIndex = 0
  private var requestCounter = 0

  init(statuses: [PermissionStatus]) {
    self.statuses = statuses
  }

  func status(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    guard type == .accessibility else { return .supported(.denied) }
    let status = statusIndex < statuses.count ? statuses[statusIndex] : (statuses.last ?? .denied)
    statusIndex += 1
    return .supported(status)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionRequestResult
  {
    guard type == .accessibility else { return .unsupported(type.capability) }
    requestCounter += 1
    let status = statusIndex < statuses.count ? statuses[statusIndex] : (statuses.last ?? .denied)
    statusIndex += 1
    return .supported(status)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }

  var requestCount: Int {
    requestCounter
  }
}

@MainActor
private final class DependencyRecorder {
  private(set) var presentedAlerts: [SystemPermissionAlertContent] = []
  private(set) var openedSettingsURLs: [String] = []
  var screenRecordingRequestCount = 0

  func dependencies(
    alertResponse: NSApplication.ModalResponse
  ) -> SystemPermissionCoordinatorDependencies {
    .init(
      presentAlert: { content in
        self.presentedAlerts.append(content)
        return alertResponse
      },
      openSettings: { urlString in
        self.openedSettingsURLs.append(urlString)
      },
      determineAutomationPermission: { _ in OSStatus(-600) },
      preflightScreenRecording: { true },
      requestScreenRecordingPermission: {
        self.screenRecordingRequestCount += 1
        return true
      }
    )
  }
}
