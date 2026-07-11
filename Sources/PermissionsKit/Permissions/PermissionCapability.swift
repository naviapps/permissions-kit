import Foundation

/// Describes what the system can do for a permission type.
public struct PermissionCapability: Codable, Hashable, Sendable {
  /// Whether a public or reliable status API is available.
  public let supportsStatusCheck: Bool
  /// Whether a public request API is available.
  public let supportsRequest: Bool
  /// System Settings URL for manual changes, when known.
  public let systemSettingsURL: URL?
  /// Whether macOS commonly requires app relaunch after a change.
  public let requiresRelaunch: Bool

  /// Creates capability metadata for a permission type.
  public init(
    supportsStatusCheck: Bool,
    supportsRequest: Bool,
    systemSettingsURL: URL?,
    requiresRelaunch: Bool
  ) {
    self.supportsStatusCheck = supportsStatusCheck
    self.supportsRequest = supportsRequest
    self.systemSettingsURL = systemSettingsURL
    self.requiresRelaunch = requiresRelaunch
  }
}
