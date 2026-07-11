import XCTest

import PermissionsKit

final class PermissionCheckerRequestAccessTests: XCTestCase {
  func testRequestAccessUsesExplicitOptions() async {
    let recorder = RequestInvocationRecorder()
    let checker = PermissionChecker(
      environment: makeEnvironment(requestAccess: { type, options in
        await recorder.append(type: type, options: options)
        return .supported(.granted)
      }))

    let notificationOptions: NotificationRequestOptions = [.alert]
    let notificationResult = await checker.requestAccess(
      for: .notifications,
      options: .notifications(notificationOptions)
    )
    let photoResult = await checker.requestAccess(for: .photos, options: .photos(.addOnly))
    let explicitNoneResult = await checker.requestAccess(for: .notifications, options: .none)
    XCTAssertEqual(notificationResult, .supported(.granted))
    XCTAssertEqual(photoResult, .supported(.granted))
    XCTAssertEqual(explicitNoneResult, .supported(.granted))

    let invocations = await recorder.snapshot()
    XCTAssertEqual(invocations.map(\.type), [.notifications, .photos, .notifications])
    XCTAssertEqual(
      invocations.map(\.options), [.notifications(notificationOptions), .photos(.addOnly), .none])
  }

  func testRequestAccessUnsupportedReturnsUnsupported() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(requestAccess: { _, _ in
        .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .automation, options: .none)
    XCTAssertEqual(result, .unsupported(PermissionType.automation.capability))
  }

  func testRequestAccessRejectsOptionsForAnotherPermissionWithoutCallingEnvironment() async {
    let recorder = RequestInvocationRecorder()
    let checker = PermissionChecker(
      environment: makeEnvironment(requestAccess: { type, options in
        await recorder.append(type: type, options: options)
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: .notifications, options: .photos(.addOnly))

    XCTAssertEqual(result, .failed(.invalidOptions))
    let invocations = await recorder.snapshot()
    XCTAssertTrue(invocations.isEmpty)
  }

  func testCustomRequestAccessUnsupportedReturnsCustomCapability() async throws {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: false,
      systemSettingsURL: URL(string: "x-test:settings"),
      requiresRelaunch: true
    )
    let type = PermissionType.custom(
      try CustomPermission(identifier: "custom.request", capability: capability)
    )
    let checker = PermissionChecker(
      environment: makeEnvironment(requestAccess: { _, _ in
        .supported(.granted)
      }))

    let result = await checker.requestAccess(for: type, options: .none)

    XCTAssertEqual(result, .unsupported(capability))
  }

  func testCustomRequestAccessSupportedUsesEnvironment() async throws {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: true,
      systemSettingsURL: nil,
      requiresRelaunch: false
    )
    let type = PermissionType.custom(
      try CustomPermission(identifier: "custom.request", capability: capability)
    )
    let checker = PermissionChecker(
      environment: makeEnvironment(requestAccess: { receivedType, options in
        XCTAssertEqual(receivedType, type)
        XCTAssertEqual(options, .none)
        return .supported(.granted)
      }))

    let result = await checker.requestAccess(for: type, options: .none)

    XCTAssertEqual(result, .supported(.granted))
  }
}

private func makeEnvironment(
  status:
    @escaping @Sendable (PermissionType, PermissionOptions) async ->
    PermissionOperationResult<PermissionStatus> =
    { _, _ in
      .supported(.notDetermined)
    },
  requestAccess:
    @escaping @Sendable (
      PermissionType,
      PermissionOptions
    ) async -> PermissionOperationResult<PermissionStatus> =
    { _, _ in
      .failed(.apiUnavailable)
    }
) -> PermissionEnvironment {
  PermissionEnvironment(
    status: status,
    requestAccess: requestAccess,
    openURL: { _ in true }
  )
}

private actor RequestInvocationRecorder {
  private var invocations: [(type: PermissionType, options: PermissionOptions)] = []

  func append(type: PermissionType, options: PermissionOptions) {
    invocations.append((type, options))
  }

  func snapshot() -> [(type: PermissionType, options: PermissionOptions)] {
    invocations
  }
}
