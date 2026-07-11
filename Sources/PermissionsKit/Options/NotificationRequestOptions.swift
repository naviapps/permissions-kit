/// Notification authorization request options.
public struct NotificationRequestOptions: OptionSet, Codable, Hashable, Sendable {
  /// Stable bitmask storage used for raw-value and Codable round trips.
  public let rawValue: Int

  /// Creates notification authorization options from a raw value.
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
  public static let providesAppNotificationSettings =
    NotificationRequestOptions(rawValue: 1 << 5)

  /// Standard alert, badge, and sound authorization request.
  public static let `default`: NotificationRequestOptions = [.alert, .badge, .sound]
}
