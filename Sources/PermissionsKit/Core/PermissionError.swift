/// Errors surfaced by permission requests and System Settings deep links.
public enum PermissionError: Error, Equatable, Sendable, CustomStringConvertible {
  /// Opening System Settings failed.
  case openFailed
  /// The underlying system API is unavailable.
  case apiUnavailable
  /// Stable string description for logging or diagnostics.
  public var description: String {
    switch self {
    case .openFailed:
      "open_failed"
    case .apiUnavailable:
      "api_unavailable"
    }
  }
}
