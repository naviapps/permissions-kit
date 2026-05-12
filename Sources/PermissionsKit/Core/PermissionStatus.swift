/// Normalized permission state reported by `PermissionChecker`.
public enum PermissionStatus: String, Sendable, CaseIterable {
  /// Access is granted.
  case granted
  /// Access is denied.
  case denied
  /// Access is restricted by system or policy.
  case restricted
  /// The user has not made a choice yet.
  case notDetermined
  /// Status could not be determined.
  case unknown

  /// True when the status is `granted`.
  public var isGranted: Bool {
    self == .granted
  }

  /// True when the status is `denied`.
  public var isDenied: Bool {
    self == .denied
  }

  /// True when the status is `restricted`.
  public var isRestricted: Bool {
    self == .restricted
  }

  /// True when the status is `notDetermined`.
  public var isNotDetermined: Bool {
    self == .notDetermined
  }

  /// True when the status is `unknown`.
  public var isUnknown: Bool {
    self == .unknown
  }
}
