import Combine

/// Observable system-permission state and request actions for host UI integration.
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
  func refreshAll()
  /// Requests Input Monitoring access.
  func requestInputMonitoringPermission()
  /// Requests Accessibility access.
  func requestAccessibilityPermission()
  /// Requests Automation access.
  func requestAutomationPermission()
  /// Requests Screen Recording access.
  func requestScreenRecordingPermission()
  /// Requests notification authorization.
  func requestNotificationPermission()
}
