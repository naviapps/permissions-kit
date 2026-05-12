/// User-facing strings for AppKit permission guidance dialogs.
public struct SystemPermissionGuidanceStrings: Sendable, Equatable {
  /// Title and message for a single permission guidance dialog.
  public struct PermissionGuidance: Sendable, Equatable {
    /// Dialog title.
    public let title: String
    /// Dialog message.
    public let message: String

    /// Creates guidance text for one permission.
    public init(title: String, message: String) {
      self.title = title
      self.message = message
    }
  }

  /// Guidance for Accessibility permission.
  public let accessibility: PermissionGuidance
  /// Guidance for Automation permission.
  public let automation: PermissionGuidance
  /// Guidance for Screen Recording permission.
  public let screenRecording: PermissionGuidance
  /// Label for the button that opens System Settings.
  public let openSettingsLabel: String
  /// Label for the cancellation button.
  public let cancelLabel: String

  /// Creates guidance strings for AppKit permission flows.
  public init(
    accessibility: PermissionGuidance,
    automation: PermissionGuidance,
    screenRecording: PermissionGuidance,
    openSettingsLabel: String,
    cancelLabel: String
  ) {
    self.accessibility = accessibility
    self.automation = automation
    self.screenRecording = screenRecording
    self.openSettingsLabel = openSettingsLabel
    self.cancelLabel = cancelLabel
  }

  /// English default strings.
  public static let english = SystemPermissionGuidanceStrings(
    accessibility: .init(
      title: "Accessibility permission required",
      message: "Enable Accessibility in System Settings to continue."
    ),
    automation: .init(
      title: "Automation permission required",
      message: "Allow automation in System Settings to continue."
    ),
    screenRecording: .init(
      title: "Screen Recording permission required",
      message: "Enable Screen Recording in System Settings to continue."
    ),
    openSettingsLabel: "Open Settings",
    cancelLabel: "Cancel"
  )
}

/// Logger used by permission guidance flows.
public protocol SystemPermissionLogger: Sendable {
  /// Records a warning message.
  func warning(_ message: String)
}

/// Logger implementation that discards warnings.
public struct NoopSystemPermissionLogger: SystemPermissionLogger {
  /// Creates a no-op logger.
  public init() {}
  /// Discards the warning message.
  public func warning(_: String) {}
}
