import Foundation

/// Polls for permission status changes and emits a stream of updates.
public enum PermissionStatusObserver {
  /// A single change event emitted by the observer.
  public struct Change: Sendable, Equatable, Hashable {
    /// Permission type that changed.
    public let type: PermissionType
    /// Previously observed status-check result.
    public let previousResult: PermissionOperationResult<PermissionStatus>
    /// Newly observed status-check result.
    public let currentResult: PermissionOperationResult<PermissionStatus>

    /// Creates a change event.
    public init(
      type: PermissionType,
      previousResult: PermissionOperationResult<PermissionStatus>,
      currentResult: PermissionOperationResult<PermissionStatus>
    ) {
      self.type = type
      self.previousResult = previousResult
      self.currentResult = currentResult
    }
  }

  /// Builds a stream that yields whenever a permission status changes.
  ///
  /// When `options` is omitted, each permission type uses its `defaultOptions`.
  /// Polling intervals below 250 milliseconds are clamped to 250 milliseconds.
  public static func changes(
    for types: [PermissionType],
    using checker: any PermissionChecking,
    pollingInterval: Duration = .seconds(2),
    options: @Sendable @escaping (PermissionType) -> PermissionOptions = {
      $0.defaultOptions
    }
  ) -> AsyncStream<Change> {
    guard types.isEmpty == false else {
      return AsyncStream { continuation in
        continuation.finish()
      }
    }

    let observedTypes = PermissionStatusObservation.uniqueTypes(types)
    let interval = PermissionStatusObservation.clampedInterval(pollingInterval)

    return AsyncStream(bufferingPolicy: .bufferingNewest(observedTypes.count)) { continuation in
      let task = Task {
        var lastResults: [PermissionType: PermissionOperationResult<PermissionStatus>] = [:]

        while !Task.isCancelled {
          for type in observedTypes {
            let currentResult = await checker.status(for: type, options: options(type))
            if let previousResult = lastResults[type], previousResult != currentResult {
              continuation.yield(
                .init(type: type, previousResult: previousResult, currentResult: currentResult)
              )
            }
            lastResults[type] = currentResult
          }
          try? await Task.sleep(for: interval)
        }
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }
}

private enum PermissionStatusObservation {
  static func uniqueTypes(_ types: [PermissionType]) -> [PermissionType] {
    var seen: Set<PermissionType> = []
    var unique: [PermissionType] = []
    for type in types where seen.insert(type).inserted {
      unique.append(type)
    }
    return unique
  }

  static func clampedInterval(_ interval: Duration) -> Duration {
    let minimum: Duration = .milliseconds(250)
    return interval < minimum ? minimum : interval
  }
}
