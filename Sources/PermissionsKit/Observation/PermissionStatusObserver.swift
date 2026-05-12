import Foundation

#if canImport(Contacts)
  import Contacts
#endif
#if canImport(EventKit)
  import EventKit
#endif

/// Polls for permission status changes and emits a stream of updates.
public struct PermissionStatusObserver: Sendable {
  /// A single change event emitted by the observer.
  public struct Change: Sendable, Equatable {
    /// Permission type that changed.
    public let type: PermissionType
    /// Previously observed status.
    public let oldStatus: PermissionStatusResult
    /// Newly observed status.
    public let newStatus: PermissionStatusResult

    /// Creates a change event.
    public init(
      type: PermissionType, oldStatus: PermissionStatusResult, newStatus: PermissionStatusResult
    ) {
      self.type = type
      self.oldStatus = oldStatus
      self.newStatus = newStatus
    }
  }

  /// Builds a stream that yields whenever a permission status changes.
  public static func changes(
    for types: [PermissionType],
    using checker: any PermissionChecking,
    configuration: PermissionObservationConfiguration = .init(),
    statusOptionsProvider: @Sendable @escaping (PermissionType) -> PermissionRequestOptions = { _ in
      .none
    }
  ) -> AsyncStream<Change> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        let state = PermissionStatusObserverState(
          checker: checker,
          types: types,
          configuration: configuration,
          statusOptionsProvider: statusOptionsProvider
        ) { change in
          continuation.yield(change)
        }
        state.start()
        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(60 * 60))
        }
        state.stop()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }
}

@MainActor
private final class PermissionStatusObserverState {
  private let checker: any PermissionChecking
  private let interval: Duration
  private let configuration: PermissionObservationConfiguration
  private let types: [PermissionType]
  private let statusOptionsProvider: @Sendable (PermissionType) -> PermissionRequestOptions
  private let handler: @Sendable (PermissionStatusObserver.Change) -> Void
  private var task: Task<Void, Never>?
  private var lastStatuses: [PermissionType: PermissionStatusResult] = [:]
  private var tokens: [NSObjectProtocol] = []

  init(
    checker: any PermissionChecking,
    types: [PermissionType],
    configuration: PermissionObservationConfiguration,
    statusOptionsProvider: @escaping @Sendable (PermissionType) -> PermissionRequestOptions,
    handler: @escaping @Sendable (PermissionStatusObserver.Change) -> Void
  ) {
    self.checker = checker
    self.types = Self.uniqueTypes(types)
    self.statusOptionsProvider = statusOptionsProvider
    interval = configuration.pollingInterval
    self.configuration = configuration
    self.handler = handler
  }

  func start() {
    guard task == nil else { return }
    registerEventHooks()
    task = Task { [weak self] in
      guard let self else { return }
      await loop()
    }
  }

  func stop() {
    task?.cancel()
    task = nil
    unregisterEventHooks()
  }

  private func loop() async {
    while !Task.isCancelled {
      for type in types {
        let options = statusOptionsProvider(type)
        let newStatus = await checker.status(for: type, options: options)
        let oldStatus = lastStatuses[type]
        if let oldStatus, oldStatus != newStatus {
          emitChange(type: type, oldStatus: oldStatus, newStatus: newStatus)
        }
        lastStatuses[type] = newStatus
      }
      try? await Task.sleep(for: interval)
    }
  }

  private func registerEventHooks() {
    let center = NotificationCenter.default
    for type in types {
      switch type {
      case .contacts:
        #if canImport(Contacts)
          let token = center.addObserver(forName: .CNContactStoreDidChange, object: nil, queue: nil)
          {
            [weak self] _ in
            Task { @MainActor in
              await self?.pollOnce(type: .contacts)
            }
          }
          tokens.append(token)
        #endif
      case .calendars, .reminders:
        #if canImport(EventKit)
          let token = center.addObserver(forName: .EKEventStoreChanged, object: nil, queue: nil) {
            [weak self] _ in
            Task { @MainActor in
              await self?.pollOnce(type: type)
            }
          }
          tokens.append(token)
        #endif
      default:
        break
      }
    }
  }

  private func unregisterEventHooks() {
    let center = NotificationCenter.default
    for token in tokens {
      center.removeObserver(token)
    }
    tokens.removeAll()
  }

  private func pollOnce(type: PermissionType) async {
    let options = statusOptionsProvider(type)
    let newStatus = await checker.status(for: type, options: options)
    let oldStatus = lastStatuses[type]
    if let oldStatus, oldStatus != newStatus {
      emitChange(type: type, oldStatus: oldStatus, newStatus: newStatus)
    }
    lastStatuses[type] = newStatus
  }

  private func emitChange(
    type: PermissionType,
    oldStatus: PermissionStatusResult,
    newStatus: PermissionStatusResult
  ) {
    handler(.init(type: type, oldStatus: oldStatus, newStatus: newStatus))
    if let customLog = configuration.logHandler {
      customLog("[PermissionsKit] \(type) changed: \(oldStatus) -> \(newStatus)")
    }
  }

  private static func uniqueTypes(_ types: [PermissionType]) -> [PermissionType] {
    var seen: Set<PermissionType> = []
    var unique: [PermissionType] = []
    for type in types where seen.insert(type).inserted {
      unique.append(type)
    }
    return unique
  }
}
