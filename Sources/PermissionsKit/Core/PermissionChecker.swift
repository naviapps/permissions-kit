/// Default implementation that delegates permission side effects to an environment.
public struct PermissionChecker: PermissionChecking {
  private let environment: PermissionEnvironment

  /// Creates a checker backed by the given environment.
  public init(environment: PermissionEnvironment) {
    self.environment = environment
  }

  /// Returns the current status for a permission type.
  public func status(
    for type: PermissionType,
    options: PermissionRequestOptions
  ) async -> PermissionStatusResult {
    guard type.supportsStatusCheck else {
      return .unsupported(type.capability)
    }
    let resolvedOptions = options == .none ? type.defaultRequestOptions : options
    let status = await environment.status(type, resolvedOptions)
    return .supported(status)
  }

  /// Requests access to a permission type.
  public func requestAccess(
    for type: PermissionType,
    options: PermissionRequestOptions
  ) async -> PermissionRequestResult {
    guard type.supportsRequest else {
      return .unsupported(type.capability)
    }
    let resolvedOptions = options == .none ? type.defaultRequestOptions : options
    return await environment.request(type, resolvedOptions)
  }

  /// Opens the matching System Settings pane for the permission type.
  public func openSystemSettings(for type: PermissionType) -> PermissionOpenSettingsResult {
    guard let url = type.systemSettingsURL else {
      return .unsupported(type.capability)
    }
    return environment.openURL(url) ? .supported(.opened) : .failed(.openFailed)
  }
}
