/// Contract for permission status, request, and System Settings opening behavior.
public protocol PermissionChecking: Sendable {
  /// Returns the current status for a permission type.
  func status(for type: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  /// Requests access and returns the resulting status.
  func requestAccess(for type: PermissionType, options: PermissionOptions) async
    -> PermissionOperationResult<PermissionStatus>
  /// Attempts to open System Settings for the permission type.
  func openSystemSettings(for type: PermissionType) -> PermissionOperationResult<Bool>
}

extension PermissionChecking {
  /// Convenience overload that uses the default options for the permission type.
  public func status(for type: PermissionType) async -> PermissionOperationResult<PermissionStatus>
  {
    await status(for: type, options: type.defaultOptions)
  }

  /// Convenience overload that uses the default options for the permission type.
  public func requestAccess(for type: PermissionType) async -> PermissionOperationResult<
    PermissionStatus
  > {
    await requestAccess(for: type, options: type.defaultOptions)
  }
}
