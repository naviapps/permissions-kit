import Foundation

/// Dependency container for permission request side effects.
///
/// Import `PermissionsKitAppKit` for `.live` and pass custom closures in tests.
public struct PermissionEnvironment: Sendable {
  /// Reads the current status for a permission type using the supplied permission options.
  public let status: @Sendable (PermissionType, PermissionOptions) async -> PermissionStatus
  /// Requests access for a permission type using the supplied permission options.
  public let request: @Sendable (PermissionType, PermissionOptions) async -> PermissionRequestResult
  /// Opens a system URL, usually a System Settings deep link.
  public let openURL: @Sendable (URL) -> Bool

  /// Creates an environment from side-effect closures.
  public init(
    status:
      @escaping @Sendable (PermissionType, PermissionOptions) async -> PermissionStatus,
    request:
      @escaping @Sendable (PermissionType, PermissionOptions) async ->
      PermissionRequestResult,
    openURL: @escaping @Sendable (URL) -> Bool
  ) {
    self.status = status
    self.request = request
    self.openURL = openURL
  }
}
