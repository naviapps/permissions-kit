import Contacts
import EventKit
import XCTest

@testable import PermissionsKit

@MainActor
final class PermissionStatusObserverStreamTests: XCTestCase {
  func testStreamFinishesImmediatelyForEmptyTypes() async {
    let stream = PermissionStatusObserver.changes(
      for: [],
      using: SequenceChecker(sequences: [:])
    )

    var iterator = stream.makeAsyncIterator()
    let change = await iterator.next()
    XCTAssertNil(change)
  }

  func testStreamEmitsChangeAndCustomLog() async {
    let checker = SequenceChecker(
      sequences: [
        .accessibility: [.supported(.denied), .supported(.granted)]
      ]
    )
    let logSink = LogSink()
    let stream = PermissionStatusObserver.changes(
      for: [.accessibility],
      using: checker,
      configuration: .init(
        pollingInterval: .milliseconds(10),
        logHandler: { value in
          Task { await logSink.append(value) }
        }
      )
    )

    let exp = expectation(description: "received change")
    let task = Task {
      for await change in stream {
        XCTAssertEqual(change.type, .accessibility)
        XCTAssertEqual(change.oldStatus, .supported(.denied))
        XCTAssertEqual(change.newStatus, .supported(.granted))
        exp.fulfill()
        break
      }
    }

    await fulfillment(of: [exp], timeout: 1.0)
    task.cancel()
    let entries = await logSink.snapshot()
    XCTAssertEqual(entries.count, 1)
    XCTAssertTrue(entries[0].contains("[PermissionsKit] accessibility changed:"))
  }

  func testCustomLogUsesStableTypeID() async {
    let custom = PermissionType.custom(
      .init(
        id: "custom.permission",
        capability: .init(
          supportsStatusCheck: true,
          supportsRequest: false,
          systemSettingsURL: nil,
          requiresRelaunch: false,
          usageDescriptionKeys: []
        )))
    let checker = SequenceChecker(
      sequences: [
        custom: [.supported(.denied), .supported(.granted)]
      ]
    )
    let logSink = LogSink()
    let stream = PermissionStatusObserver.changes(
      for: [custom],
      using: checker,
      configuration: .init(
        pollingInterval: .milliseconds(10),
        logHandler: { value in
          Task { await logSink.append(value) }
        }
      )
    )

    let exp = expectation(description: "received change")
    let task = Task {
      for await change in stream where change.type == custom {
        XCTAssertEqual(change.oldStatus, .supported(.denied))
        XCTAssertEqual(change.newStatus, .supported(.granted))
        exp.fulfill()
        break
      }
    }

    await fulfillment(of: [exp], timeout: 1.0)
    task.cancel()
    let entries = await logSink.snapshot()
    XCTAssertEqual(entries.count, 1)
    XCTAssertTrue(entries[0].contains("[PermissionsKit] custom.permission changed:"))
  }

  func testStreamRespondsToNotificationHooks() async {
    let checker = SequenceChecker(
      sequences: [
        .contacts: [.supported(.denied), .supported(.granted)],
        .calendars: [.supported(.granted), .supported(.denied)],
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.contacts, .calendars],
      using: checker,
      configuration: .init(pollingInterval: .seconds(60))
    )

    let exp = expectation(description: "received notification changes")
    exp.expectedFulfillmentCount = 2

    let task = Task {
      var received = 0
      for await change in stream {
        if change.type == .contacts || change.type == .calendars {
          received += 1
          exp.fulfill()
          if received == 2 { break }
        }
      }
    }

    try? await Task.sleep(for: .milliseconds(50))
    NotificationCenter.default.post(name: .CNContactStoreDidChange, object: nil)
    NotificationCenter.default.post(name: .EKEventStoreChanged, object: nil)

    await fulfillment(of: [exp], timeout: 1.0)
    task.cancel()
  }

  func testStreamDeduplicatesTypes() async {
    let checker = SequenceChecker(
      sequences: [
        .contacts: [.supported(.denied), .supported(.granted), .supported(.denied)]
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.contacts, .contacts],
      using: checker,
      configuration: .init(pollingInterval: .seconds(60))
    )

    let firstChange = expectation(description: "received first change")
    let duplicateChange = expectation(description: "did not receive duplicate change")
    duplicateChange.isInverted = true

    let task = Task {
      var received = 0
      for await change in stream where change.type == .contacts {
        received += 1
        if received == 1 {
          XCTAssertEqual(change.oldStatus, .supported(.denied))
          XCTAssertEqual(change.newStatus, .supported(.granted))
          firstChange.fulfill()
        } else {
          duplicateChange.fulfill()
        }
      }
    }

    try? await Task.sleep(for: .milliseconds(50))
    NotificationCenter.default.post(name: .CNContactStoreDidChange, object: nil)

    await fulfillment(of: [firstChange], timeout: 1.0)
    await fulfillment(of: [duplicateChange], timeout: 0.2)
    task.cancel()
  }

  func testStreamUsesOptionsProvider() async {
    let checker = SequenceChecker(
      sequences: [
        .photos: [.supported(.denied), .supported(.granted)]
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.photos],
      using: checker,
      configuration: .init(pollingInterval: .milliseconds(10)),
      optionsProvider: { type in
        type == .photos ? .photos(.addOnly) : .none
      }
    )

    let exp = expectation(description: "received change")
    let task = Task {
      for await change in stream where change.type == .photos {
        XCTAssertEqual(change.oldStatus, .supported(.denied))
        XCTAssertEqual(change.newStatus, .supported(.granted))
        exp.fulfill()
        break
      }
    }

    await fulfillment(of: [exp], timeout: 1.0)
    task.cancel()
    let options = checker.observedOptions(for: .photos)
    XCTAssertGreaterThanOrEqual(options.count, 2)
    XCTAssertTrue(options.allSatisfy { $0 == .photos(.addOnly) })
  }
}

private actor LogSink {
  private var entries: [String] = []

  func append(_ value: String) {
    entries.append(value)
  }

  func snapshot() -> [String] {
    entries
  }
}

private final class SequenceChecker: PermissionChecking, @unchecked Sendable {
  private let lock = NSLock()
  private var sequences: [PermissionType: [PermissionStatusResult]]
  private var indices: [PermissionType: Int] = [:]
  private var options: [PermissionType: [PermissionOptions]] = [:]

  init(sequences: [PermissionType: [PermissionStatusResult]]) {
    self.sequences = sequences
  }

  func status(for type: PermissionType, options permissionOptions: PermissionOptions) async
    -> PermissionStatusResult
  {
    lock.withLock {
      options[type, default: []].append(permissionOptions)
      let values = sequences[type] ?? [.supported(.unknown)]
      let index = indices[type, default: 0]
      let value = values[min(index, values.count - 1)]
      indices[type] = index + 1
      return value
    }
  }

  func observedOptions(for type: PermissionType) -> [PermissionOptions] {
    lock.withLock {
      options[type, default: []]
    }
  }

  func requestAccess(for type: PermissionType, options _: PermissionOptions) async
    -> PermissionRequestResult
  {
    .unsupported(type.capability)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOpenSettingsResult {
    .supported(.opened)
  }
}
