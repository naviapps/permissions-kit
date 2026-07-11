/// Normalized permission state reported by `PermissionChecker`.
public enum PermissionStatus: String, Codable, Hashable, Sendable {
  /// Access is granted.
  case granted
  /// Access is granted with system-defined limitations.
  case limited
  /// Notification access is provisionally granted for noninterruptive delivery.
  case provisional
  /// Notification access is temporarily granted.
  case ephemeral
  /// Access is denied.
  case denied
  /// Access is restricted by system or policy.
  case restricted
  /// The user has not made a choice yet.
  case notDetermined
  /// Status could not be determined.
  case unknown

  /// Whether the status currently permits some form of access.
  public var allowsAccess: Bool {
    switch self {
    case .granted, .limited, .provisional, .ephemeral:
      true
    case .denied, .restricted, .notDetermined, .unknown:
      false
    }
  }
}
