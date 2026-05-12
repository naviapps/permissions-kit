/// Options that affect how a permission request is performed.
public enum PermissionRequestOptions: Sendable, Hashable {
  /// Use the default request behavior for the permission type.
  case none
  /// Options for notification requests.
  case notifications(NotificationRequestOptions)
  /// Access level for Photos requests.
  case photos(PhotoAccessLevel)
}

/// Options for requesting notification authorization.
public struct NotificationRequestOptions: OptionSet, Sendable, Hashable {
  /// Raw option-set storage.
  public let rawValue: Int

  /// Creates notification request options from a raw value.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Request permission to show alert notifications.
  public static let alert = NotificationRequestOptions(rawValue: 1 << 0)
  /// Request permission to badge the app icon.
  public static let badge = NotificationRequestOptions(rawValue: 1 << 1)
  /// Request permission to play notification sounds.
  public static let sound = NotificationRequestOptions(rawValue: 1 << 2)
  /// Request permission to send critical alerts.
  public static let criticalAlert = NotificationRequestOptions(rawValue: 1 << 3)
  /// Request provisional notification authorization.
  public static let provisional = NotificationRequestOptions(rawValue: 1 << 4)
  /// Indicate that the app provides its own notification settings UI.
  public static let providesAppNotificationSettings = NotificationRequestOptions(rawValue: 1 << 5)

  /// Standard alert, badge, and sound authorization request.
  public static let `default`: NotificationRequestOptions = [.alert, .badge, .sound]
}

/// Access level for Photos authorization.
public enum PhotoAccessLevel: String, Sendable, Hashable {
  /// Read and write access to the user's photo library.
  case readWrite
  /// Add-only access to the user's photo library.
  case addOnly

  /// Default Photos access level used by `PermissionType.photos`.
  public static let `default`: PhotoAccessLevel = .readWrite
}
