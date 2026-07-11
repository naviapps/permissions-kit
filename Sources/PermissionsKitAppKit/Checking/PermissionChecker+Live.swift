import PermissionsKit

extension PermissionChecker {
  /// Creates a checker backed by live macOS framework integrations.
  public init() {
    self.init(environment: .live)
  }
}
