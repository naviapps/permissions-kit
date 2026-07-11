/// Supported macOS permission domains exposed by the package.
public enum PermissionType: Sendable, Hashable, Identifiable {
  /// Accessibility access for controlling or inspecting other apps.
  case accessibility
  /// Input Monitoring access for observing keyboard input.
  case inputMonitoring
  /// Screen Recording access.
  case screenRecording
  /// Camera access.
  case camera
  /// Microphone access.
  case microphone
  /// Contacts access.
  case contacts
  /// Calendars access.
  case calendars
  /// Reminders access.
  case reminders
  /// Photos library access.
  case photos
  /// Speech recognition access.
  case speechRecognition
  /// User notification authorization.
  case notifications
  /// Location Services access.
  case location
  /// Bluetooth access.
  case bluetooth
  /// Local network access.
  case localNetwork
  /// Media library access.
  case mediaLibrary
  /// System audio capture access.
  case systemAudioCapture
  /// Desktop folder file access.
  case desktopFolder
  /// Documents folder file access.
  case documentsFolder
  /// Downloads folder file access.
  case downloadsFolder
  /// Network volume file access.
  case networkVolumes
  /// Removable volume file access.
  case removableVolumes
  /// File provider domain access.
  case fileProviderDomain
  /// Full Disk Access.
  case fullDiskAccess
  /// Automation / Apple Events access.
  case automation
  /// Host-defined permission descriptor.
  case custom(CustomPermission)
}
