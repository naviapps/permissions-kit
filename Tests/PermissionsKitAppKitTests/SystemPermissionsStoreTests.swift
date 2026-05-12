import AppKit
import ApplicationServices
import PermissionsKit
import XCTest

@testable import PermissionsKitAppKit

final class SystemPermissionsStoreTests: XCTestCase {
  @MainActor
  func testInitializerDoesNotRefreshUntilRequested() {
    let permissions = CountingPermissionChecker()
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { true },
      notificationStatusProvider: { true }
    )

    XCTAssertFalse(store.accessibilityGranted)
    XCTAssertFalse(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertFalse(store.notificationsGranted)
    XCTAssertFalse(store.inputMonitoringGranted)
    XCTAssertTrue(permissions.statusCalls.isEmpty)
  }

  @MainActor
  func testRefreshAllUsesProviders() async {
    let permissions = StubPermissionChecker(statuses: [
      .accessibility: .granted,
      .screenRecording: .denied,
      .inputMonitoring: .granted,
      .notifications: .denied,
    ])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { true },
      notificationStatusProvider: { true }
    )

    await store.refreshAll()

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
  }

  @MainActor
  func testRefreshAllUsesAutomationCoordinatorWhenProviderMissing() async {
    let store = SystemPermissionsStore(
      permissions: StubPermissionChecker(),
      coordinator: makeAutomationCoordinator(status: noErr)
    )

    await store.refreshAll()

    XCTAssertTrue(store.automationGranted)
  }

  @MainActor
  func testRefreshAllUsesNotificationStatusWhenProviderMissing() async {
    let permissions = StubPermissionChecker(statuses: [
      .notifications: .granted
    ])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { false }
    )

    await store.refreshAll()

    XCTAssertTrue(store.notificationsGranted)
  }

  @MainActor
  func testRefreshAllUsesDefaultNotificationOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { false }
    )

    await store.refreshAll()

    XCTAssertEqual(permissions.observedOptions[.notifications], .notifications(.default))
  }

  @MainActor
  func testRequestNotificationPermissionUpdatesGranted() async {
    let permissions = StubPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestNotificationPermission()

    XCTAssertTrue(store.notificationsGranted)
  }

  @MainActor
  func testRequestNotificationPermissionUsesDefaultOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestNotificationPermission()

    XCTAssertEqual(permissions.permissionOptions[.notifications], .notifications(.default))
  }

  @MainActor
  func testRequestScreenRecordingUpdatesStatus() async {
    let permissions = StubPermissionChecker(statuses: [.screenRecording: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestScreenRecordingPermission()

    XCTAssertTrue(store.screenRecordingGranted)
  }

  @MainActor
  func testRequestResultIsNotOverwrittenByOlderRefresh() async {
    let refreshStarted = expectation(description: "refresh started")
    let permissions = RefreshRacePermissionChecker(refreshStarted: refreshStarted)
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { false },
      notificationStatusProvider: { false }
    )

    async let refresh: Void = store.refreshAll()
    await fulfillment(of: [refreshStarted], timeout: 1.0)
    await store.requestScreenRecordingPermission()
    await refresh

    XCTAssertTrue(store.screenRecordingGranted)
  }

  @MainActor
  func testRequestScreenRecordingSetsFalseWhenFailed() async {
    let permissions = StubPermissionChecker(requestResults: [
      .screenRecording: .failed(.apiUnavailable)
    ])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestScreenRecordingPermission()

    XCTAssertFalse(store.screenRecordingGranted)
  }

  @MainActor
  func testRequestInputMonitoringSetsFalseWhenFailed() async {
    let permissions = TrackingPermissionChecker(
      requestResults: [.inputMonitoring: .failed(.apiUnavailable)]
    )
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestInputMonitoringPermission()

    XCTAssertFalse(store.inputMonitoringGranted)
    XCTAssertEqual(permissions.openedSettingsTypes, [.inputMonitoring])
  }

  @MainActor
  func testRequestInputMonitoringSetsTrueWhenGranted() async {
    let permissions = StubPermissionChecker(
      statuses: [.inputMonitoring: .granted],
      requestResults: [.inputMonitoring: .supported(.granted)]
    )
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestInputMonitoringPermission()

    XCTAssertTrue(store.inputMonitoringGranted)
  }

  @MainActor
  func testRequestAutomationPermissionUpdatesGranted() async {
    let store = SystemPermissionsStore(
      permissions: StubPermissionChecker(),
      coordinator: makeAutomationCoordinator(status: noErr)
    )

    await store.requestAutomationPermission()

    XCTAssertTrue(store.automationGranted)
  }

  @MainActor
  func testRequestAutomationPermissionSetsFalseWhenDenied() async {
    let store = SystemPermissionsStore(
      permissions: StubPermissionChecker(),
      coordinator: makeAutomationCoordinator(status: OSStatus(errAEEventNotPermitted))
    )

    await store.requestAutomationPermission()

    XCTAssertFalse(store.automationGranted)
  }

  @MainActor
  func testRequestAccessibilityPermissionUpdatesGranted() async {
    let permissions = AccessibilitySequencePermissionChecker(statuses: [.granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.requestAccessibilityPermission()

    XCTAssertTrue(store.accessibilityGranted)
  }

  @MainActor
  func testRequestNotificationPermissionSetsFalseWhenFailed() async {
    let permissions = StubPermissionChecker(
      statuses: [.notifications: .granted],
      requestResults: [
        .notifications: .failed(.apiUnavailable)
      ])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await store.refreshAll()
    XCTAssertTrue(store.notificationsGranted)

    await store.requestNotificationPermission()

    XCTAssertFalse(store.notificationsGranted)
  }

  @MainActor
  func testRefreshAllSeedsPublishedStateFromProviders() async {
    let permissions = StubPermissionChecker(
      statuses: [
        .accessibility: .granted,
        .inputMonitoring: .granted,
        .screenRecording: .granted,
      ]
    )
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator(),
      automationStatusProvider: { true },
      notificationStatusProvider: { true }
    )

    await store.refreshAll()

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertTrue(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
  }

  @MainActor
  func testConvenienceInitializerUsesInjectedProviders() async {
    let permissions = StubPermissionChecker(statuses: [
      .accessibility: .granted,
      .inputMonitoring: .granted,
      .screenRecording: .denied,
    ])
    let store = SystemPermissionsStore(
      permissions: permissions,
      automationStatusProvider: { true },
      notificationStatusProvider: { true }
    )

    await store.refreshAll()

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
  }
}

@MainActor
private func makeAutomationCoordinator(status: OSStatus) -> SystemPermissionCoordinator {
  return SystemPermissionCoordinator(
    guidance: .english,
    logger: NoopSystemPermissionLogger(),
    dependencies: .init(
      presentAlert: { _ in .alertSecondButtonReturn },
      openSettings: { _ in },
      determineAutomationPermission: { _ in status },
      preflightScreenRecording: { false },
      requestScreenRecordingPermission: { false }
    )
  )
}

private struct StubPermissionChecker: PermissionChecking {
  let statuses: [PermissionType: PermissionStatus]
  let requestResults: [PermissionType: PermissionRequestResult]

  init(
    statuses: [PermissionType: PermissionStatus] = [:],
    requestResults: [PermissionType: PermissionRequestResult] = [:]
  ) {
    self.statuses = statuses
    self.requestResults = requestResults
  }

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionStatusResult
  {
    .supported(statuses[type] ?? .denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    if let result = requestResults[type] {
      return result
    }
    return .supported(statuses[type] ?? .denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}

private final class CountingPermissionChecker: PermissionChecking, @unchecked Sendable {
  private(set) var statusCalls: [PermissionType] = []

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionStatusResult
  {
    statusCalls.append(type)
    return .supported(.denied)
  }

  func requestAccess(for _: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    .supported(.denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}

private final class OptionRecordingPermissionChecker: PermissionChecking, @unchecked Sendable {
  let statuses: [PermissionType: PermissionStatus]
  private(set) var observedOptions: [PermissionType: PermissionOptions] = [:]
  private(set) var permissionOptions: [PermissionType: PermissionOptions] = [:]

  init(statuses: [PermissionType: PermissionStatus]) {
    self.statuses = statuses
  }

  func status(for type: PermissionType, options: PermissionOptions) async
    -> PermissionStatusResult
  {
    observedOptions[type] = options
    return .supported(statuses[type] ?? .denied)
  }

  func requestAccess(for type: PermissionType, options: PermissionOptions) async
    -> PermissionRequestResult
  {
    permissionOptions[type] = options
    return .supported(statuses[type] ?? .denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}

private final class TrackingPermissionChecker: PermissionChecking, @unchecked Sendable {
  let requestResults: [PermissionType: PermissionRequestResult]
  private(set) var openedSettingsTypes: [PermissionType] = []

  init(requestResults: [PermissionType: PermissionRequestResult]) {
    self.requestResults = requestResults
  }

  func status(for _: PermissionType, options _: PermissionOptions) async
    -> PermissionStatusResult
  {
    .supported(.denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    requestResults[type] ?? .failed(.apiUnavailable)
  }

  func openSystemSettings(for type: PermissionType) -> PermissionOpenSettingsResult {
    openedSettingsTypes.append(type)
    return .supported(.opened)
  }
}

private final class RefreshRacePermissionChecker: PermissionChecking, @unchecked Sendable {
  private let refreshStarted: XCTestExpectation

  init(refreshStarted: XCTestExpectation) {
    self.refreshStarted = refreshStarted
  }

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionStatusResult
  {
    if type == .accessibility {
      refreshStarted.fulfill()
      try? await Task.sleep(nanoseconds: 150_000_000)
    }
    return .supported(.denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    type == .screenRecording ? .supported(.granted) : .supported(.denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}

private final class AccessibilitySequencePermissionChecker: PermissionChecking, @unchecked Sendable
{
  private let statuses: [PermissionStatus]
  private var index = 0

  init(statuses: [PermissionStatus]) {
    self.statuses = statuses
  }

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionStatusResult
  {
    guard type == .accessibility else { return .supported(.denied) }
    let status = index < statuses.count ? statuses[index] : (statuses.last ?? .denied)
    index += 1
    return .supported(status)
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    guard type == .accessibility else { return .unsupported(type.capability) }
    let status = index < statuses.count ? statuses[index] : (statuses.last ?? .denied)
    index += 1
    return .supported(status)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}
