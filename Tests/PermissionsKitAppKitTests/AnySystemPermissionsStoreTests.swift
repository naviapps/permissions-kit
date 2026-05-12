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
  func testSendsObjectWillChangeWhenSnapshotChanges() async {
    let wrappedStore = MutablePermissionsStore()
    let store = AnySystemPermissionsStore(wrappedStore)
    var changeCount = 0
    let cancellable = store.objectWillChange.sink {
      changeCount += 1
    }

    wrappedStore.accessibilityGranted = true
    await Task.yield()

    XCTAssertEqual(changeCount, 1)
    XCTAssertTrue(store.accessibilityGranted)
    withExtendedLifetime(cancellable) {}
  }

  @MainActor
  func testForwardsActionsToWrappedStore() async {
    let wrappedStore = MutablePermissionsStore()
    let store = AnySystemPermissionsStore(wrappedStore)

    await store.refreshAll()
    await store.requestInputMonitoringPermission()
    await store.requestAccessibilityPermission()
    await store.requestAutomationPermission()
    await store.requestScreenRecordingPermission()
    await store.requestNotificationPermission()

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

  @MainActor
  func testForwardedActionSynchronizesSnapshotBeforeReturning() async {
    let wrappedStore = MutablePermissionsStore()
    wrappedStore.refreshAllAccessibilityValue = true
    let store = AnySystemPermissionsStore(wrappedStore)

    await store.refreshAll()

    XCTAssertTrue(store.accessibilityGranted)
  }

  @MainActor
  func testForwardedActionSendsSingleChangeNotification() async {
    let wrappedStore = MutablePermissionsStore()
    wrappedStore.refreshAllAccessibilityValue = true
    let store = AnySystemPermissionsStore(wrappedStore)
    var changeCount = 0
    let cancellable = store.objectWillChange.sink {
      changeCount += 1
    }

    await store.refreshAll()
    await Task.yield()

    XCTAssertEqual(changeCount, 1)
    withExtendedLifetime(cancellable) {}
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
  var refreshAllAccessibilityValue: Bool?

  func sendUnchangedObjectWillChange() {
    objectWillChange.send()
  }

  func refreshAll() async {
    calls.append("refreshAll")
    if let refreshAllAccessibilityValue {
      accessibilityGranted = refreshAllAccessibilityValue
    }
  }

  func requestInputMonitoringPermission() async {
    calls.append("requestInputMonitoringPermission")
  }

  func requestAccessibilityPermission() async {
    calls.append("requestAccessibilityPermission")
  }

  func requestAutomationPermission() async {
    calls.append("requestAutomationPermission")
  }

  func requestScreenRecordingPermission() async {
    calls.append("requestScreenRecordingPermission")
  }

  func requestNotificationPermission() async {
    calls.append("requestNotificationPermission")
  }
}
