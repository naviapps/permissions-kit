import Foundation

/// Describes what the system can do for a permission type.
public struct PermissionCapability: Sendable, Hashable {
  /// Whether a public or reliable status API is available.
  public let supportsStatusCheck: Bool
  /// Whether a public request API is available.
  public let supportsRequest: Bool
  /// System Settings deep link for manual changes, when known.
  public let systemSettingsURL: URL?
  /// Whether macOS commonly requires app relaunch after a change.
  public let requiresRelaunch: Bool
  /// Info.plist usage description keys required by this permission.
  public let usageDescriptionKeys: [UsageDescriptionKey]

  /// Creates capability metadata for a permission type.
  public init(
    supportsStatusCheck: Bool,
    supportsRequest: Bool,
    systemSettingsURL: URL?,
    requiresRelaunch: Bool,
    usageDescriptionKeys: [UsageDescriptionKey]
  ) {
    self.supportsStatusCheck = supportsStatusCheck
    self.supportsRequest = supportsRequest
    self.systemSettingsURL = systemSettingsURL
    self.requiresRelaunch = requiresRelaunch
    self.usageDescriptionKeys = usageDescriptionKeys
  }
}
