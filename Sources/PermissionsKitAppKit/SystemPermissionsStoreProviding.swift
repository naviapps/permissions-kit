import Combine

/// Common observable system-permission state and actions for UI integration and type erasure.
@MainActor
public protocol SystemPermissionsStoreProviding: ObservableObject {
  /// Current Accessibility grant state.
  var accessibilityGranted: Bool { get }
  /// Current Automation grant state.
  var automationGranted: Bool { get }
  /// Current Screen Recording grant state.
  var screenRecordingGranted: Bool { get }
  /// Current notification grant state.
  var notificationsGranted: Bool { get }
  /// Current Input Monitoring grant state.
  var inputMonitoringGranted: Bool { get }

  /// Refreshes all tracked permission states.
  func refreshAll() async
  /// Starts the Input Monitoring permission flow and updates tracked state.
  func requestInputMonitoringPermission() async
  /// Starts the Accessibility permission flow and updates tracked state.
  func requestAccessibilityPermission() async
  /// Starts the Automation permission flow and updates tracked state.
  func requestAutomationPermission() async
  /// Starts the Screen Recording permission flow and updates tracked state.
  func requestScreenRecordingPermission() async
  /// Starts the notification authorization flow and updates tracked state.
  func requestNotificationPermission() async
}
