import XCTest

import PermissionsKit

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

  func testStreamDeduplicatesTypes() async {
    let checker = SequenceChecker(
      sequences: [
        .contacts: [.supported(.denied), .supported(.granted)]
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.contacts, .contacts],
      using: checker,
      pollingInterval: .milliseconds(10)
    )

    let firstChange = expectation(description: "received first change")

    let task = Task {
      for await change in stream where change.type == .contacts {
        XCTAssertEqual(change.previousResult, .supported(.denied))
        XCTAssertEqual(change.currentResult, .supported(.granted))
        firstChange.fulfill()
        break
      }
    }

    try? await Task.sleep(for: .milliseconds(100))
    XCTAssertEqual(checker.observedOptions(for: .contacts).count, 1)

    await fulfillment(of: [firstChange], timeout: 1.0)
    task.cancel()
  }

  func testStreamUsesCustomOptions() async {
    let checker = SequenceChecker(
      sequences: [
        .photos: [.supported(.denied), .supported(.granted)]
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.photos],
      using: checker,
      pollingInterval: .milliseconds(10),
      options: { type in
        type == .photos ? .photos(.addOnly) : .none
      }
    )

    let exp = expectation(description: "received change")
    let task = Task {
      for await change in stream where change.type == .photos {
        XCTAssertEqual(change.previousResult, .supported(.denied))
        XCTAssertEqual(change.currentResult, .supported(.granted))
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

  func testStreamUsesPermissionDefaultOptionsWhenProviderIsOmitted() async {
    let checker = SequenceChecker(
      sequences: [
        .photos: [.supported(.denied), .supported(.granted)],
        .notifications: [.supported(.notDetermined), .supported(.granted)],
      ]
    )
    let stream = PermissionStatusObserver.changes(
      for: [.photos, .notifications],
      using: checker,
      pollingInterval: .milliseconds(10)
    )

    let exp = expectation(description: "received changes")
    exp.expectedFulfillmentCount = 2
    let task = Task {
      var received: Set<PermissionType> = []
      for await change in stream {
        received.insert(change.type)
        exp.fulfill()
        if received.count == 2 { break }
      }
    }

    await fulfillment(of: [exp], timeout: 1.0)
    task.cancel()

    XCTAssertGreaterThanOrEqual(checker.observedOptions(for: .photos).count, 2)
    XCTAssertGreaterThanOrEqual(checker.observedOptions(for: .notifications).count, 2)
    XCTAssertTrue(checker.observedOptions(for: .photos).allSatisfy { $0 == .photos(.default) })
    XCTAssertTrue(
      checker.observedOptions(for: .notifications).allSatisfy { $0 == .notifications(.default) })
  }
}

private final class SequenceChecker: PermissionChecking, @unchecked Sendable {
  private let lock = NSLock()
  private var sequences: [PermissionType: [PermissionOperationResult<PermissionStatus>]]
  private var indices: [PermissionType: Int] = [:]
  private var options: [PermissionType: [PermissionOptions]] = [:]

  init(sequences: [PermissionType: [PermissionOperationResult<PermissionStatus>]]) {
    self.sequences = sequences
  }

  func status(for type: PermissionType, options permissionOptions: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
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
    -> PermissionOperationResult<PermissionStatus>
  {
    .unsupported(type.capability)
  }

  func openSystemSettings(for _: PermissionType) -> PermissionOperationResult<Bool> {
    .supported(true)
  }
}
