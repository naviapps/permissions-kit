/// Errors surfaced by permission operations.
public enum PermissionError: String, Codable, Error, Hashable, Sendable {
  /// The supplied options do not apply to the requested permission type.
  case invalidOptions
  /// Opening System Settings failed.
  case openFailed
  /// The underlying system API is unavailable.
  case apiUnavailable
}
