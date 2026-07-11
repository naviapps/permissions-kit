import Foundation

/// Dependency container for permission status, request, and System Settings side effects.
///
/// Pass custom closures when tests or host apps need a controlled permission backend.
public struct PermissionEnvironment: Sendable {
  private let statusHandler:
    @Sendable (PermissionType, PermissionOptions) async -> PermissionOperationResult<
      PermissionStatus
    >
  private let requestAccessHandler:
    @Sendable (PermissionType, PermissionOptions) async -> PermissionOperationResult<
      PermissionStatus
    >
  private let openURLHandler: @Sendable (URL) -> Bool

  /// Creates an environment from side-effect closures.
  public init(
    status:
      @escaping @Sendable (PermissionType, PermissionOptions) async ->
      PermissionOperationResult<PermissionStatus>,
    requestAccess:
      @escaping @Sendable (PermissionType, PermissionOptions) async ->
      PermissionOperationResult<PermissionStatus>,
    openURL: @escaping @Sendable (URL) -> Bool
  ) {
    self.statusHandler = status
    self.requestAccessHandler = requestAccess
    self.openURLHandler = openURL
  }

  func status(
    for type: PermissionType,
    options: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    await statusHandler(type, options)
  }

  func requestAccess(
    for type: PermissionType,
    options: PermissionOptions
  ) async -> PermissionOperationResult<PermissionStatus> {
    await requestAccessHandler(type, options)
  }

  func openURL(_ url: URL) -> Bool {
    openURLHandler(url)
  }
}
