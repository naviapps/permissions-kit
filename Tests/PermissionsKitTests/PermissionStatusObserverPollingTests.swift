import XCTest
import os

@testable import PermissionsKit

final class PermissionStatusObserverPollingTests: XCTestCase {
  func testStreamEmitsChangeAfterPollingStatusChange() async {
    let checker = MutableStatusPermissionChecker(initial: .notDetermined)
    let expect = expectation(description: "handler called")

    let stream = PermissionStatusObserver.changes(
      for: [.notifications],
      using: checker,
      configuration: .init(pollingInterval: .milliseconds(50))
    )

    let task = Task {
      for await change in stream {
        XCTAssertEqual(change.type, .notifications)
        XCTAssertEqual(change.oldStatus, .supported(.notDetermined))
        XCTAssertEqual(change.newStatus, .supported(.granted))
        expect.fulfill()
        break
      }
    }

    // Flip status after a short delay to trigger the observer.
    Task {
      try? await Task.sleep(for: .milliseconds(120))
      checker.statusValue = .granted
    }

    await fulfillment(of: [expect], timeout: 1.0)
    task.cancel()
  }

  func testStreamDoesNotEmitInitialStatusAsChange() async {
    let checker = MutableStatusPermissionChecker(initial: .notDetermined)
    let expect = expectation(description: "no initial change")
    expect.isInverted = true

    let stream = PermissionStatusObserver.changes(
      for: [.notifications],
      using: checker,
      configuration: .init(pollingInterval: .milliseconds(50))
    )

    let task = Task {
      for await _ in stream {
        expect.fulfill()
        break
      }
    }

    await fulfillment(of: [expect], timeout: 0.2)
    task.cancel()
  }
}

/// Simple mutable checker for change-observer testing.
private final class MutableStatusPermissionChecker: PermissionChecking, Sendable {
  private let statusLock: OSAllocatedUnfairLock<PermissionStatus>

  var statusValue: PermissionStatus {
    get { statusLock.withLock { $0 } }
    set { statusLock.withLock { $0 = newValue } }
  }

  init(initial: PermissionStatus) {
    statusLock = OSAllocatedUnfairLock(initialState: initial)
  }

  func status(
    for _: PermissionType,
    options _: PermissionRequestOptions
  ) async -> PermissionStatusResult {
    .supported(statusValue)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }

  func requestAccess(for type: PermissionType, options _: PermissionRequestOptions) async
    -> PermissionRequestResult
  {
    .unsupported(type.capability)
  }
}
