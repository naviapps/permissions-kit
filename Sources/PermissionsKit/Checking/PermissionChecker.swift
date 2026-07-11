/// Default implementation that delegates permission operations to an environment.
public struct PermissionChecker: PermissionChecking {
  private let environment: PermissionEnvironment

  /// Creates a checker backed by the given environment.
  public init(environment: PermissionEnvironment) {
    self.environment = environment
  }

  /// Returns the current status for a permission type.
  public func status(
    for type: PermissionType,
    options: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    guard options.applies(to: type) else {
      return .failed(.invalidOptions)
    }
    let capability = type.capability
    guard capability.supportsStatusCheck else {
      return .unsupported(capability)
    }
    return await environment.status(for: type, options: options)
  }

  /// Requests access to a permission type.
  public func requestAccess(
    for type: PermissionType,
    options: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    guard options.applies(to: type) else {
      return .failed(.invalidOptions)
    }
    let capability = type.capability
    guard capability.supportsRequest else {
      return .unsupported(capability)
    }
    return await environment.requestAccess(for: type, options: options)
  }

  /// Opens System Settings for the permission type.
  public func openSystemSettings(for type: PermissionType) -> PermissionOperationResult<Bool> {
    let capability = type.capability
    guard let url = capability.systemSettingsURL else {
      return .unsupported(capability)
    }
    return environment.openURL(url) ? .supported(true) : .failed(.openFailed)
  }
}
