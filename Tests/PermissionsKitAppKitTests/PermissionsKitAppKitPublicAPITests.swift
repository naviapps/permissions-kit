import Combine
import PermissionsKit
import PermissionsKitAppKit
import XCTest

@MainActor
final class PermissionsKitAppKitPublicAPITests: XCTestCase {
  func testDocumentationSampleEntrypointsCompileFromPublicImport() async {
    let checker = PermissionChecker()
    let store = SystemPermissionsStore(
      trackedTypes: [.accessibility, .screenRecording],
      permissionChecker: PublicPermissionChecker()
    )

    assertSendable(checker)
    assertObservableObject(store)

    XCTAssertEqual(store.trackedTypes, [.accessibility, .screenRecording])
    _ = await store.refreshAll()
    _ = await store.refresh(.screenRecording)
    _ = await store.requestAccess(for: .accessibility)
    _ = store.status(for: .screenRecording)
    _ = store.allowsAccess(.accessibility)
  }
}

private func assertSendable<Value: Sendable>(_: Value) {}

private func assertObservableObject<Value: ObservableObject>(_: Value) {}

private struct PublicPermissionChecker: PermissionChecking {
  func status(
    for _: PermissionType,
    options _: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    .supported(.unknown)
  }

  func requestAccess(
    for _: PermissionType,
    options _: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    .supported(.unknown)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}
