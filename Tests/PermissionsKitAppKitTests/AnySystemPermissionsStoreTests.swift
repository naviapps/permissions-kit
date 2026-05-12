import Combine
import PermissionsKitAppKit
import XCTest

final class AnySystemPermissionsStoreTests: XCTestCase {
  @MainActor
  func testMirrorsWrappedStoreChangesAfterObjectWillChange() async {
    let wrappedStore = MutablePermissionsStore()
    let store = AnySystemPermissionsStore(wrappedStore)

    XCTAssertFalse(store.accessibilityGranted)
    XCTAssertFalse(store.automationGranted)
    XCTAssertFalse(store.screenRecordingGranted)
    XCTAssertFalse(store.notificationsGranted)
    XCTAssertFalse(store.inputMonitoringGranted)

    wrappedStore.accessibilityGranted = true
    wrappedStore.automationGranted = true
    wrappedStore.screenRecordingGranted = true
    wrappedStore.notificationsGranted = true
    wrappedStore.inputMonitoringGranted = true
    await Task.yield()

    XCTAssertTrue(store.accessibilityGranted)
    XCTAssertTrue(store.automationGranted)
    XCTAssertTrue(store.screenRecordingGranted)
    XCTAssertTrue(store.notificationsGranted)
    XCTAssertTrue(store.inputMonitoringGranted)
  }

  @MainActor
  func testIgnoresWrappedStoreNotificationsWhenValuesDoNotChange() async {
    let wrappedStore = MutablePermissionsStore()
    let store = AnySystemPermissionsStore(wrappedStore)
    var changeCount = 0
    let cancellable = store.objectWillChange.sink {
      changeCount += 1
    }

    wrappedStore.sendUnchangedObjectWillChange()
    await Task.yield()

    XCTAssertEqual(changeCount, 0)
    withExtendedLifetime(cancellable) {}
  }

  @MainActor
  func testForwardsActionsToWrappedStore() {
    let wrappedStore = MutablePermissionsStore()
    let store = AnySystemPermissionsStore(wrappedStore)

    store.refreshAll()
    store.requestInputMonitoringPermission()
    store.requestAccessibilityPermission()
    store.requestAutomationPermission()
    store.requestScreenRecordingPermission()
    store.requestNotificationPermission()

    XCTAssertEqual(
      wrappedStore.calls,
      [
        "refreshAll",
        "requestInputMonitoringPermission",
        "requestAccessibilityPermission",
        "requestAutomationPermission",
        "requestScreenRecordingPermission",
        "requestNotificationPermission",
      ])
  }
}

@MainActor
private final class MutablePermissionsStore: ObservableObject, SystemPermissionsStoreProviding {
  @Published var accessibilityGranted = false
  @Published var automationGranted = false
  @Published var screenRecordingGranted = false
  @Published var notificationsGranted = false
  @Published var inputMonitoringGranted = false
  private(set) var calls: [String] = []

  func sendUnchangedObjectWillChange() {
    objectWillChange.send()
  }

  func refreshAll() {
    calls.append("refreshAll")
  }

  func requestInputMonitoringPermission() {
    calls.append("requestInputMonitoringPermission")
  }

  func requestAccessibilityPermission() {
    calls.append("requestAccessibilityPermission")
  }

  func requestAutomationPermission() {
    calls.append("requestAutomationPermission")
  }

  func requestScreenRecordingPermission() {
    calls.append("requestScreenRecordingPermission")
  }

  func requestNotificationPermission() {
    calls.append("requestNotificationPermission")
  }
}
