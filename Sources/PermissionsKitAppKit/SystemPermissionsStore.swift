import Combine
import PermissionsKit

/// Observable store for common app-facing macOS permission state.
@MainActor
public final class SystemPermissionsStore: ObservableObject, SystemPermissionsStoreProviding {
  /// Current Accessibility grant state.
  @Published public private(set) var accessibilityGranted: Bool = false
  /// Current Automation grant state.
  @Published public private(set) var automationGranted: Bool = false
  /// Current Screen Recording grant state.
  @Published public private(set) var screenRecordingGranted: Bool = false
  /// Current notification grant state.
  @Published public private(set) var notificationsGranted: Bool = false
  /// Current Input Monitoring grant state.
  @Published public private(set) var inputMonitoringGranted: Bool = false

  private let permissions: any PermissionChecking
  private let automationStatusProvider: (() -> Bool)?
  private let notificationStatusProvider: (() -> Bool)?
  private let coordinator: SystemPermissionCoordinator
  private var stateVersions: [PermissionType: Int] = [:]

  /// Creates a store using the shared coordinator.
  public convenience init(
    permissions: any PermissionChecking = PermissionChecker(),
    automationStatusProvider: (() -> Bool)? = nil,
    notificationStatusProvider: (() -> Bool)? = nil
  ) {
    self.init(
      permissions: permissions,
      coordinator: SystemPermissionCoordinator.shared,
      automationStatusProvider: automationStatusProvider,
      notificationStatusProvider: notificationStatusProvider
    )
  }

  /// Creates a store with an explicit coordinator and optional status providers.
  public init(
    permissions: any PermissionChecking = PermissionChecker(),
    coordinator: SystemPermissionCoordinator,
    automationStatusProvider: (() -> Bool)? = nil,
    notificationStatusProvider: (() -> Bool)? = nil
  ) {
    self.permissions = permissions
    self.coordinator = coordinator
    self.automationStatusProvider = automationStatusProvider
    self.notificationStatusProvider = notificationStatusProvider
    refreshAll()
  }

  /// Refreshes all tracked permission states.
  public func refreshAll() {
    Task { @MainActor in
      await refreshAllAsync()
    }
  }

  private func refreshAllAsync() async {
    let accessibilityVersion = nextStateVersion(for: .accessibility)
    let automationVersion = nextStateVersion(for: .automation)
    let screenRecordingVersion = nextStateVersion(for: .screenRecording)
    let inputMonitoringVersion = nextStateVersion(for: .inputMonitoring)
    let notificationsVersion = nextStateVersion(for: .notifications)

    let accessibilityGranted =
      await permissions.status(for: .accessibility, options: .none).status == .granted
    let automationGranted =
      automationStatusProvider?() ?? coordinator.ensureAutomationPermission(userInitiated: false)
    let screenRecordingGranted =
      await permissions.status(for: .screenRecording, options: .none).status == .granted
    let inputMonitoringGranted =
      await permissions.status(for: .inputMonitoring, options: .none).status == .granted
    let notificationsGranted = await notificationStatus()

    apply(accessibilityGranted, for: .accessibility, version: accessibilityVersion) {
      self.accessibilityGranted = $0
    }
    apply(automationGranted, for: .automation, version: automationVersion) {
      self.automationGranted = $0
    }
    apply(screenRecordingGranted, for: .screenRecording, version: screenRecordingVersion) {
      self.screenRecordingGranted = $0
    }
    apply(inputMonitoringGranted, for: .inputMonitoring, version: inputMonitoringVersion) {
      self.inputMonitoringGranted = $0
    }
    apply(notificationsGranted, for: .notifications, version: notificationsVersion) {
      self.notificationsGranted = $0
    }

    handleResetIfGranted(self.accessibilityGranted) {
      coordinator.resetAccessibilityGuidance()
    }
    handleResetIfGranted(self.automationGranted) {
      coordinator.resetAutomationGuidance()
    }
    handleResetIfGranted(self.screenRecordingGranted) {
      coordinator.resetScreenRecordingGuidance()
    }
  }

  /// Requests Input Monitoring access and updates the published state.
  public func requestInputMonitoringPermission() {
    let version = nextStateVersion(for: .inputMonitoring)
    Task { @MainActor in
      let result = await permissions.requestAccess(for: .inputMonitoring, options: .none)
      if case .supported(let status) = result {
        apply(status == .granted, for: .inputMonitoring, version: version) {
          inputMonitoringGranted = $0
        }
        return
      }
      _ = permissions.openSystemSettings(for: .inputMonitoring)
      apply(false, for: .inputMonitoring, version: version) {
        inputMonitoringGranted = $0
      }
    }
  }

  /// Requests Accessibility access and updates the published state.
  public func requestAccessibilityPermission() {
    let version = nextStateVersion(for: .accessibility)
    Task { @MainActor in
      let granted =
        await coordinator
        .ensureAccessibilityPermission(using: permissions, userInitiated: true)
      let didApply = apply(granted, for: .accessibility, version: version) {
        accessibilityGranted = $0
      }
      handleResetIfGranted(didApply && granted) {
        coordinator.resetAccessibilityGuidance()
      }
    }
  }

  /// Requests Automation access and updates the published state.
  public func requestAutomationPermission() {
    let version = nextStateVersion(for: .automation)
    let granted = coordinator.ensureAutomationPermission(userInitiated: true)
    let didApply = apply(granted, for: .automation, version: version) {
      automationGranted = $0
    }
    handleResetIfGranted(didApply && granted) {
      coordinator.resetAutomationGuidance()
    }
  }

  /// Requests Screen Recording access and updates the published state.
  public func requestScreenRecordingPermission() {
    let version = nextStateVersion(for: .screenRecording)
    Task { @MainActor in
      let result = await permissions.requestAccess(for: .screenRecording, options: .none)
      let granted: Bool
      if case .supported(let status) = result {
        granted = status == .granted
      } else {
        granted = false
      }
      let didApply = apply(granted, for: .screenRecording, version: version) {
        screenRecordingGranted = $0
      }
      handleResetIfGranted(didApply && granted) {
        coordinator.resetScreenRecordingGuidance()
      }
    }
  }

  /// Requests notification authorization and updates the published state.
  public func requestNotificationPermission() {
    let version = nextStateVersion(for: .notifications)
    Task { @MainActor in
      let result = await permissions.requestAccess(
        for: .notifications, options: .notifications(.default))
      if case .supported(let status) = result {
        apply(status == .granted, for: .notifications, version: version) {
          notificationsGranted = $0
        }
        return
      }
      apply(false, for: .notifications, version: version) {
        notificationsGranted = $0
      }
    }
  }

  private func notificationStatus() async -> Bool {
    if let notificationStatusProvider {
      return notificationStatusProvider()
    }
    let status = await permissions.status(for: .notifications, options: .notifications(.default))
    return status.status == .granted
  }

  private func nextStateVersion(for type: PermissionType) -> Int {
    let version = (stateVersions[type] ?? 0) + 1
    stateVersions[type] = version
    return version
  }

  @discardableResult
  private func apply(_ granted: Bool, for type: PermissionType, version: Int, set: (Bool) -> Void)
    -> Bool
  {
    guard stateVersions[type] == version else { return false }
    set(granted)
    return true
  }

  private func handleResetIfGranted(_ granted: Bool, reset: () -> Void) {
    guard granted else { return }
    reset()
  }
}
