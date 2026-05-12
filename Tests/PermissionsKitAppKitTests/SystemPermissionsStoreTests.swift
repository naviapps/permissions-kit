import AppKit
import ApplicationServices
import PermissionsKit
import XCTest

@testable import PermissionsKitAppKit

final class SystemPermissionsStoreTests: XCTestCase {
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

    store.refreshAll()
    try? await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
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

    store.refreshAll()
    try? await Task.sleep(nanoseconds: 100_000_000)

    XCTAssertTrue(store.notificationsGranted)
  }

  @MainActor
  func testRequestNotificationPermissionUpdatesGranted() async {
    let permissions = StubPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await waitForStoreTasks()
    store.requestNotificationPermission()
    await waitForStoreTasks()

    XCTAssertTrue(store.notificationsGranted)
  }

  @MainActor
  func testRequestScreenRecordingUpdatesStatus() async {
    let permissions = StubPermissionChecker(statuses: [.screenRecording: .granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await waitForStoreTasks()
    store.requestScreenRecordingPermission()
    await waitForStoreTasks()

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

    await fulfillment(of: [refreshStarted], timeout: 1.0)
    store.requestScreenRecordingPermission()
    try? await Task.sleep(nanoseconds: 300_000_000)

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

    await waitForStoreTasks()
    store.requestScreenRecordingPermission()
    await waitForStoreTasks()

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

    await waitForStoreTasks()
    store.requestInputMonitoringPermission()
    await waitForStoreTasks()

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

    await waitForStoreTasks()
    store.requestInputMonitoringPermission()
    await waitForStoreTasks()

    XCTAssertTrue(store.inputMonitoringGranted)
  }

  @MainActor
  func testRequestAutomationPermissionUpdatesGranted() {
    let store = SystemPermissionsStore(
      permissions: StubPermissionChecker(),
      coordinator: makeAutomationCoordinator(status: noErr)
    )

    store.requestAutomationPermission()

    XCTAssertTrue(store.automationGranted)
  }

  @MainActor
  func testRequestAutomationPermissionSetsFalseWhenDenied() {
    let store = SystemPermissionsStore(
      permissions: StubPermissionChecker(),
      coordinator: makeAutomationCoordinator(status: OSStatus(errAEEventNotPermitted))
    )

    store.requestAutomationPermission()

    XCTAssertFalse(store.automationGranted)
  }

  @MainActor
  func testRequestAccessibilityPermissionUpdatesGranted() async {
    let permissions = AccessibilitySequencePermissionChecker(statuses: [.granted])
    let store = SystemPermissionsStore(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator()
    )

    await waitForStoreTasks()
    store.requestAccessibilityPermission()
    await waitForStoreTasks()

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

    await waitForStoreTasks()
    XCTAssertTrue(store.notificationsGranted)

    store.requestNotificationPermission()
    await waitForStoreTasks()

    XCTAssertFalse(store.notificationsGranted)
  }

  @MainActor
  func testInitializerSeedsPublishedStateFromProviders() async {
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

    try? await Task.sleep(nanoseconds: 100_000_000)

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

    await waitForStoreTasks()

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
  }
}

private func waitForStoreTasks() async {
  try? await Task.sleep(nanoseconds: 100_000_000)
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

  func status(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    .supported(statuses[type] ?? .denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
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

private final class TrackingPermissionChecker: PermissionChecking, @unchecked Sendable {
  let requestResults: [PermissionType: PermissionRequestResult]
  private(set) var openedSettingsTypes: [PermissionType] = []

  init(requestResults: [PermissionType: PermissionRequestResult]) {
    self.requestResults = requestResults
  }

  func status(for _: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    .supported(.denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
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

  func status(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    if type == .accessibility {
      refreshStarted.fulfill()
      try? await Task.sleep(nanoseconds: 150_000_000)
    }
    return .supported(.denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
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

  func status(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionStatusResult
  {
    guard type == .accessibility else { return .supported(.denied) }
    let status = index < statuses.count ? statuses[index] : (statuses.last ?? .denied)
    index += 1
    return .supported(status)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
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
