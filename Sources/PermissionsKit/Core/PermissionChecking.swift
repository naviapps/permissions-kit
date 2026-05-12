/// Contract for permission status, request, and deep-link behavior.
public protocol PermissionChecking: Sendable {
  /// Returns the current status for a permission type.
  func status(for type: PermissionType, options: PermissionRequestOptions) async
    -> PermissionStatusResult
  /// Requests access and returns the resulting status.
  func requestAccess(for type: PermissionType, options: PermissionRequestOptions) async
    -> PermissionRequestResult
  /// Attempts to open System Settings for the permission type.
  func openSystemSettings(for type: PermissionType) -> PermissionOpenSettingsResult
}

extension PermissionChecking {
  /// Convenience overload that uses the default options for the permission type.
  public func status(for type: PermissionType) async -> PermissionStatusResult {
    await status(for: type, options: type.defaultRequestOptions)
  }

  /// Convenience overload that uses the default options for the permission type.
  public func requestAccess(for type: PermissionType) async -> PermissionRequestResult {
    await requestAccess(for: type, options: type.defaultRequestOptions)
  }
}
