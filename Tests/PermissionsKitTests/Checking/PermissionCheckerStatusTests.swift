import XCTest

import PermissionsKit

final class PermissionCheckerStatusTests: XCTestCase {
  func testStatusUsesExplicitOptions() async {
    let recorder = StatusInvocationRecorder()
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        await recorder.append(type: type, options: options)
        return .supported(.granted)
      }))

    let notificationOptions: NotificationRequestOptions = [.alert]
    let notificationResult = await checker.status(
      for: .notifications,
      options: .notifications(notificationOptions)
    )
    let photoResult = await checker.status(for: .photos, options: .photos(.addOnly))
    let explicitNoneResult = await checker.status(for: .notifications, options: .none)
    XCTAssertEqual(notificationResult, .supported(.granted))
    XCTAssertEqual(photoResult, .supported(.granted))
    XCTAssertEqual(explicitNoneResult, .supported(.granted))

    let invocations = await recorder.snapshot()
    XCTAssertEqual(invocations.map(\.type), [.notifications, .photos, .notifications])
    XCTAssertEqual(
      invocations.map(\.options), [.notifications(notificationOptions), .photos(.addOnly), .none])
  }

  func testStatusDelegatesSupportedPermissionToEnvironment() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(statuses: [.contacts: .restricted])
    )

    let result = await checker.status(for: .contacts, options: .none)

    XCTAssertEqual(result, .supported(.restricted))
  }

  func testStatusPropagatesEnvironmentFailure() async {
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        XCTAssertEqual(type, .camera)
        XCTAssertEqual(options, .none)
        return .failed(.apiUnavailable)
      }))

    let result = await checker.status(for: .camera, options: .none)

    XCTAssertEqual(result, .failed(.apiUnavailable))
  }

  func testStatusRejectsOptionsForAnotherPermissionWithoutCallingEnvironment() async {
    let recorder = StatusInvocationRecorder()
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { type, options in
        await recorder.append(type: type, options: options)
        return .supported(.granted)
      }))

    let result = await checker.status(for: .camera, options: .photos(.addOnly))

    XCTAssertEqual(result, .failed(.invalidOptions))
    let invocations = await recorder.snapshot()
    XCTAssertTrue(invocations.isEmpty)
  }

  func testSettingsOnlyStatusIsUnsupported() async {
    let checker = PermissionChecker(environment: makeEnvironment(statuses: [:]))

    let status = await checker.status(for: .automation, options: .none)

    XCTAssertEqual(status, .unsupported(PermissionType.automation.capability))
  }

  func testCustomStatusUnsupportedReturnsCustomCapability() async throws {
    let capability = PermissionCapability(
      supportsStatusCheck: false,
      supportsRequest: true,
      systemSettingsURL: URL(string: "x-test:settings"),
      requiresRelaunch: true
    )
    let type = PermissionType.custom(
      try CustomPermission(identifier: "custom.status", capability: capability)
    )
    let checker = PermissionChecker(environment: makeEnvironment(statuses: [:]))

    let status = await checker.status(for: type, options: .none)

    XCTAssertEqual(status, .unsupported(capability))
  }

  func testCustomStatusSupportedUsesEnvironment() async throws {
    let capability = PermissionCapability(
      supportsStatusCheck: true,
      supportsRequest: false,
      systemSettingsURL: nil,
      requiresRelaunch: false
    )
    let type = PermissionType.custom(
      try CustomPermission(identifier: "custom.status", capability: capability)
    )
    let checker = PermissionChecker(
      environment: makeEnvironment(status: { receivedType, options in
        XCTAssertEqual(receivedType, type)
        XCTAssertEqual(options, .none)
        return .supported(.granted)
      }))

    let status = await checker.status(for: type, options: .none)

    XCTAssertEqual(status, .supported(.granted))
  }
}

private func makeEnvironment(
  status:
    @escaping @Sendable (PermissionType, PermissionOptions) async ->
    PermissionOperationResult<PermissionStatus>
) -> PermissionEnvironment {
  PermissionEnvironment(
    status: status,
    requestAccess: { _, _ in .failed(.apiUnavailable) },
    openURL: { _ in true }
  )
}

private func makeEnvironment(statuses: [PermissionType: PermissionStatus]) -> PermissionEnvironment
{
  PermissionEnvironment(
    status: { type, _ in .supported(statuses[type] ?? .unknown) },
    requestAccess: { _, _ in .failed(.apiUnavailable) },
    openURL: { _ in true }
  )
}

private actor StatusInvocationRecorder {
  private var invocations: [(type: PermissionType, options: PermissionOptions)] = []

  func append(type: PermissionType, options: PermissionOptions) {
    invocations.append((type, options))
  }

  func snapshot() -> [(type: PermissionType, options: PermissionOptions)] {
    invocations
  }
}
