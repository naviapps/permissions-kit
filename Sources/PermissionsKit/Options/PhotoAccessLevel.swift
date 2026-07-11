/// Access level for Photos authorization.
public enum PhotoAccessLevel: String, Codable, Hashable, Sendable {
  /// Read and write access to the user's photo library.
  case readWrite
  /// Add-only access to the user's photo library.
  case addOnly

  /// Default Photos access level used by `PermissionType.photos`.
  public static let `default`: PhotoAccessLevel = .readWrite
}
