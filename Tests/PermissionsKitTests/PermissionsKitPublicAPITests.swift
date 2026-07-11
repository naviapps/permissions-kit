import Foundation
import PermissionsKit
import XCTest

final class PermissionsKitPublicAPITests: XCTestCase {
  func testCorePublicAPIsAreReachableFromPublicImport() async throws {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: true,
      systemSettingsURL: URL(string: "x-test:settings"),
      requiresRelaunch: false
    )
    let customPermission = try CustomPermission(
      identifier: "com.example.permission",
      capability: capability,
      usageDescriptionKeys: [.camera]
    )
    let type = PermissionType.custom(customPermission)
    let checker = PermissionChecker(
      environment: PermissionEnvironment(
        status: { _, _ in .supported(.granted) },
        requestAccess: { _, _ in .supported(.granted) },
        openURL: { _ in true }
      )
    )
    let change = PermissionStatusObserver.Change(
      type: .camera,
      previousResult: .supported(.denied),
      currentResult: .supported(.granted)
    )
    let validationError: CustomPermission.IdentifierValidationError = .empty
    let operationError: any Error = PermissionError.invalidOptions
    let _: NotificationRequestOptions = [.alert, .badge, .sound]

    assertSendable(checker)
    assertHashable(customPermission)
    assertHashable(change)
    assertHashable(validationError)
    withExtendedLifetime(operationError) {}
    assertCodableRoundTrip(PermissionStatus.granted)
    assertCodableRoundTrip(UsageDescriptionKey.camera)
    assertCodableRoundTrip(PermissionError.apiUnavailable)
    assertCodableRoundTrip(PermissionOptions.photos(.addOnly))
    assertCodableRoundTrip(NotificationRequestOptions.default)
    assertCodableRoundTrip(PhotoAccessLevel.default)
    assertCodableRoundTrip(PermissionOperationResult<PermissionStatus>.supported(.granted))

    XCTAssertEqual(customPermission.identifier, "com.example.permission")
    XCTAssertNil(CustomPermission.validationError(for: customPermission.identifier))
    XCTAssertTrue(PermissionOptions.photos(.addOnly).applies(to: .photos))
    XCTAssertTrue(PermissionStatus.limited.allowsAccess)

    let status = await checker.status(for: type)
    let request = await checker.requestAccess(for: type)
    let settings = checker.openSystemSettings(for: type)
    let changes = PermissionStatusObserver.changes(for: [], using: PublicPermissionChecker())

    guard case .supported(.granted) = status else {
      return XCTFail("Expected public status API to return a supported value.")
    }
    guard case .supported(.granted) = request else {
      return XCTFail("Expected public request API to return a supported value.")
    }
    guard case .supported(true) = settings else {
      return XCTFail("Expected public settings API to return a supported value.")
    }
    withExtendedLifetime(changes) {}
  }

  func testDocumentationSampleEntrypointsCompileFromPublicImport() async {
    let checker = PermissionChecker(
      environment: PermissionEnvironment(
        status: { _, _ in .supported(.granted) },
        requestAccess: { _, _ in .supported(.granted) },
        openURL: { _ in true }
      )
    )

    _ = await checker.status(for: .camera)
    _ = await checker.requestAccess(for: .camera)
    _ = checker.openSystemSettings(for: .screenRecording)
    _ = PermissionType.screenRecording.capability
    _ = PermissionType.camera.missingUsageDescriptions()
    _ = PermissionType.photos.missingUsageDescriptions(options: .photos(.addOnly))
    _ = PermissionStatusObserver.changes(
      for: [.camera, .microphone, .contacts],
      using: PublicPermissionChecker()
    )
  }

  private func assertHashable<Value: Hashable>(_: Value) {}

  private func assertSendable<Value: Sendable>(_: Value) {}

  private func assertCodableRoundTrip<Value: Codable & Equatable>(_ value: Value) {
    XCTAssertEqual(try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value)), value)
  }
}

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
    .failed(.apiUnavailable)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .unsupported(PermissionType.automation.capability)
  }
}
