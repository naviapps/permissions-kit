import Combine
import PermissionsKit
import PermissionsKitAppKit
import XCTest

final class SystemPermissionsStoreTests: XCTestCase {
  @MainActor
  func testInitializerDoesNotRefreshUntilRequestedAndDeduplicatesTrackedTypes() {
    let permissions = CountingPermissionChecker()
    let store = SystemPermissionsStore(
      trackedTypes: [.accessibility, .screenRecording, .accessibility],
      permissionChecker: permissions
    )

    XCTAssertEqual(store.trackedTypes, [.accessibility, .screenRecording])
    XCTAssertEqual(store.status(for: .accessibility), .supported(.unknown))
    XCTAssertNil(store.status(for: .notifications))
    XCTAssertEqual(store.allowsAccess(.accessibility), false)
    XCTAssertNil(store.allowsAccess(.notifications))
    XCTAssertTrue(permissions.statusCalls.isEmpty)
  }

  @MainActor
  func testRefreshAllUsesTrackedTypes() async {
    let permissions = StubPermissionChecker(statuses: [
      .accessibility: .granted,
      .screenRecording: .denied,
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.accessibility, .screenRecording],
      permissionChecker: permissions
    )

    let refreshed = await store.refreshAll()

    XCTAssertEqual(refreshed[.accessibility], .supported(.granted))
    XCTAssertEqual(refreshed[.screenRecording], .supported(.denied))
    XCTAssertEqual(store.allowsAccess(.accessibility), true)
    XCTAssertEqual(store.allowsAccess(.screenRecording), false)
    XCTAssertEqual(store.status(for: .screenRecording), .supported(.denied))
  }

  @MainActor
  func testRefreshSelectedTypesLeavesOtherTrackedStateUnknown() async {
    let permissions = StubPermissionChecker(statuses: [
      .accessibility: .granted,
      .screenRecording: .granted,
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.accessibility, .screenRecording],
      permissionChecker: permissions
    )

    let result = await store.refresh(.screenRecording)

    XCTAssertEqual(result, .supported(.granted))
    XCTAssertEqual(store.status(for: .accessibility), .supported(.unknown))
    XCTAssertEqual(store.status(for: .screenRecording), .supported(.granted))
  }

  @MainActor
  func testRefreshIgnoresUntrackedTypes() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [
      .notifications: .granted,
      .screenRecording: .granted,
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.screenRecording],
      permissionChecker: permissions
    )

    let result = await store.refresh(.notifications)

    XCTAssertNil(result)
    XCTAssertNil(store.status(for: .notifications))
    XCTAssertEqual(store.status(for: .screenRecording), .supported(.unknown))
    XCTAssertNil(permissions.statusOptions[.notifications])
  }

  @MainActor
  func testRefreshUsesPermissionDefaultOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      trackedTypes: [.notifications],
      permissionChecker: permissions
    )

    await store.refreshAll()

    XCTAssertEqual(permissions.statusOptions[.notifications], .notifications(.default))
  }

  @MainActor
  func testRequestUpdatesStatusAndUsesDefaultOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      trackedTypes: [.notifications],
      permissionChecker: permissions
    )

    let result = await store.requestAccess(for: .notifications)

    XCTAssertEqual(result, .supported(.granted))
    XCTAssertEqual(store.allowsAccess(.notifications), true)
    XCTAssertEqual(permissions.permissionOptions[.notifications], .notifications(.default))
  }

  @MainActor
  func testRequestCanOverrideOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.photos: .granted])
    let store = SystemPermissionsStore(
      trackedTypes: [.photos],
      permissionChecker: permissions
    )

    await store.requestAccess(for: .photos, options: .photos(.addOnly))

    XCTAssertEqual(permissions.permissionOptions[.photos], .photos(.addOnly))
  }

  @MainActor
  func testRequestCanUseExplicitNoOptions() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      trackedTypes: [.notifications],
      permissionChecker: permissions
    )

    await store.requestAccess(for: .notifications, options: PermissionOptions.none)

    XCTAssertEqual(permissions.permissionOptions[.notifications], PermissionOptions.none)
  }

  @MainActor
  func testPartiallyAuthorizedStatusesAllowAccess() async {
    let permissions = StubPermissionChecker(statuses: [
      .photos: .limited,
      .notifications: .provisional,
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.photos, .notifications],
      permissionChecker: permissions
    )

    await store.refreshAll()

    XCTAssertEqual(store.allowsAccess(.photos), true)
    XCTAssertEqual(store.allowsAccess(.notifications), true)
  }

  @MainActor
  func testRequestIgnoresUntrackedTypes() async {
    let permissions = OptionRecordingPermissionChecker(statuses: [.notifications: .granted])
    let store = SystemPermissionsStore(
      trackedTypes: [.screenRecording],
      permissionChecker: permissions
    )

    let result = await store.requestAccess(for: .notifications)

    XCTAssertNil(store.status(for: .notifications))
    XCTAssertNil(result)
    XCTAssertNil(permissions.permissionOptions[.notifications])
  }

  @MainActor
  func testUnsupportedOrFailedRequestStoresResult() async {
    let permissions = StubPermissionChecker(requestResults: [
      .automation: .unsupported(PermissionType.automation.capability),
      .screenRecording: .failed(.apiUnavailable),
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.automation, .screenRecording],
      permissionChecker: permissions
    )

    await store.requestAccess(for: .automation)
    await store.requestAccess(for: .screenRecording)

    XCTAssertEqual(
      store.status(for: .automation),
      .unsupported(PermissionType.automation.capability)
    )
    XCTAssertEqual(store.status(for: .screenRecording), .failed(.apiUnavailable))
    XCTAssertNil(store.allowsAccess(.automation))
    XCTAssertNil(store.allowsAccess(.screenRecording))
  }

  @MainActor
  func testStateChangePublishesObjectWillChange() async {
    let permissions = StubPermissionChecker(requestResults: [
      .screenRecording: .failed(.apiUnavailable)
    ])
    let store = SystemPermissionsStore(
      trackedTypes: [.screenRecording],
      permissionChecker: permissions
    )
    var didPublishChange = false
    let cancellable = store.objectWillChange.sink {
      didPublishChange = true
    }

    await store.requestAccess(for: .screenRecording)

    XCTAssertTrue(didPublishChange)
    XCTAssertEqual(store.status(for: .screenRecording), .failed(.apiUnavailable))
    withExtendedLifetime(cancellable) {}
  }
}

private struct StubPermissionChecker: PermissionChecking {
  let statuses: [PermissionType: PermissionStatus]
  let requestResults: [PermissionType: PermissionOperationResult<PermissionStatus>]

  init(
    statuses: [PermissionType: PermissionStatus] = [:],
    requestResults: [PermissionType: PermissionOperationResult<PermissionStatus>] = [:]
  ) {
    self.statuses = statuses
    self.requestResults = requestResults
  }

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    .supported(statuses[type] ?? .denied)
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    requestResults[type] ?? .supported(statuses[type] ?? .denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}

private final class CountingPermissionChecker: PermissionChecking, @unchecked Sendable {
  private(set) var statusCalls: [PermissionType] = []

  func status(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    statusCalls.append(type)
    return .supported(.denied)
  }

  func requestAccess(for _: PermissionType, options _: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    .supported(.denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}

private final class OptionRecordingPermissionChecker: PermissionChecking, @unchecked Sendable {
  let statuses: [PermissionType: PermissionStatus]
  private(set) var statusOptions: [PermissionType: PermissionOptions] = [:]
  private(set) var permissionOptions: [PermissionType: PermissionOptions] = [:]

  init(statuses: [PermissionType: PermissionStatus]) {
    self.statuses = statuses
  }

  func status(for type: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    statusOptions[type] = options
    return .supported(statuses[type] ?? .denied)
  }

  func requestAccess(for type: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  {
    permissionOptions[type] = options
    return .supported(statuses[type] ?? .denied)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}
