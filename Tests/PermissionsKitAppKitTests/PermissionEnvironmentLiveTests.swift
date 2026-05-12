import PermissionsKitAppKit
import XCTest

@testable import PermissionsKit

final class PermissionEnvironmentLiveTests: XCTestCase {
  func testPermissionCheckerDefaultInitializerCreatesLiveChecker() {
    _ = PermissionChecker()
  }

  func testLiveStatusClosureReturnsValues() async throws {
    guard ProcessInfo.processInfo.environment["RUN_LIVE_TESTS"] == "1" else {
      throw XCTSkip("Set RUN_LIVE_TESTS=1 to run live environment checks.")
    }
    let env = PermissionEnvironment.live
    _ = await env.status(.accessibility, .none)
    _ = await env.status(.screenRecording, .none)
    _ = await env.status(.camera, .none)
    _ = await env.status(.microphone, .none)
    _ = await env.status(.contacts, .none)
    _ = await env.status(.calendars, .none)
    _ = await env.status(.reminders, .none)
    _ = await env.status(.photos, .none)
    _ = await env.status(.speechRecognition, .none)
    _ = await env.status(.notifications, .none)
  }
}
