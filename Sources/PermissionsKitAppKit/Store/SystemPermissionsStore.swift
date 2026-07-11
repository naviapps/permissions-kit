import Combine
import PermissionsKit

/// Observable store for app-selected macOS permission state.
@MainActor
public final class SystemPermissionsStore: ObservableObject {
  /// Permission types tracked by this store.
  public let trackedTypes: [PermissionType]

  private var statusResults: [PermissionType: PermissionOperationResult<PermissionStatus>] = [:]
  private let permissionChecker: any PermissionChecking
  private let trackedTypeSet: Set<PermissionType>
  private var stateVersions: [PermissionType: Int] = [:]

  /// Creates a store backed by a permission checker.
  public init(
    trackedTypes: [PermissionType] = PermissionType.builtIn,
    permissionChecker: any PermissionChecking = PermissionChecker()
  ) {
    self.trackedTypes = Self.uniqueTypes(trackedTypes)
    trackedTypeSet = Set(self.trackedTypes)
    self.permissionChecker = permissionChecker
  }

  /// Current result for a tracked permission type.
  ///
  /// Tracked permission types return `.supported(.unknown)` until refreshed or requested.
  /// Untracked permission types return `nil`.
  public func status(for type: PermissionType) -> PermissionOperationResult<PermissionStatus>? {
    guard isTracked(type) else { return nil }
    return statusResults[type] ?? .supported(.unknown)
  }

  private func isTracked(_ type: PermissionType) -> Bool {
    trackedTypeSet.contains(type)
  }

  /// Whether the tracked permission currently allows some form of access.
  ///
  /// Tracked permission types return `false` until an access-permitting status is stored.
  /// Failed, unsupported, and untracked permission types return `nil`.
  public func allowsAccess(_ type: PermissionType) -> Bool? {
    switch status(for: type) {
    case .supported(let status):
      status.allowsAccess
    case .unsupported, .failed, nil:
      nil
    }
  }

  /// Refreshes all tracked permission states and returns the stored results.
  @discardableResult
  public func refreshAll() async -> [PermissionType: PermissionOperationResult<PermissionStatus>] {
    let refreshRequests = trackedTypes.map { type in
      (type: type, version: nextStateVersion(for: type))
    }

    return await withTaskGroup(
      of: (
        PermissionType,
        Int,
        PermissionOperationResult<PermissionStatus>
      ).self,
      returning: [PermissionType: PermissionOperationResult<PermissionStatus>].self
    ) { group in
      for request in refreshRequests {
        group.addTask { [permissionChecker] in
          let result = await permissionChecker.status(
            for: request.type,
            options: request.type.defaultOptions
          )
          return (request.type, request.version, result)
        }
      }

      var refreshed: [PermissionType: PermissionOperationResult<PermissionStatus>] = [:]
      var updates: [(type: PermissionType, result: PermissionOperationResult<PermissionStatus>)] =
        []
      for await (type, version, result) in group {
        guard stateVersions[type] == version else {
          refreshed[type] = status(for: type)
          continue
        }
        refreshed[type] = result
        if status(for: type) != result {
          updates.append((type, result))
        }
      }
      applyBatch(updates)
      return refreshed
    }
  }

  /// Refreshes a tracked permission state and returns the stored result.
  @discardableResult
  public func refresh(_ type: PermissionType) async -> PermissionOperationResult<PermissionStatus>?
  {
    guard isTracked(type) else { return nil }
    let version = nextStateVersion(for: type)
    let result = await permissionChecker.status(for: type, options: type.defaultOptions)
    if apply(result, for: type, version: version) {
      return result
    }
    return status(for: type)
  }

  /// Requests access, updates tracked state, and returns the stored result.
  @discardableResult
  public func requestAccess(
    for type: PermissionType,
    options: PermissionOptions? = nil
  ) async -> PermissionOperationResult<PermissionStatus>? {
    guard isTracked(type) else { return nil }
    let version = nextStateVersion(for: type)
    let resolvedOptions = options ?? type.defaultOptions
    let result = await permissionChecker.requestAccess(for: type, options: resolvedOptions)
    if apply(result, for: type, version: version) {
      return result
    }
    return status(for: type)
  }

  private func nextStateVersion(for type: PermissionType) -> Int {
    let version = (stateVersions[type] ?? 0) + 1
    stateVersions[type] = version
    return version
  }

  @discardableResult
  private func apply(
    _ result: PermissionOperationResult<PermissionStatus>,
    for type: PermissionType,
    version: Int
  ) -> Bool {
    guard stateVersions[type] == version else { return false }
    let statusChanged = status(for: type) != result
    if statusChanged {
      objectWillChange.send()
      statusResults[type] = result
    }
    return true
  }

  private func applyBatch(
    _ updates: [(type: PermissionType, result: PermissionOperationResult<PermissionStatus>)]
  ) {
    guard !updates.isEmpty else { return }
    objectWillChange.send()
    for update in updates {
      statusResults[update.type] = update.result
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
