import Combine

/// Type-erased observable wrapper for passing a system permissions store through SwiftUI environments.
@MainActor
public final class AnySystemPermissionsStore: ObservableObject, SystemPermissionsStoreProviding {
  private var snapshot: SystemPermissionsStoreSnapshot
  private let wrappedStore: any SystemPermissionsStoreProviding
  private var cancellables: Set<AnyCancellable> = []

  /// Creates a type-erased wrapper around an observable system permissions store.
  public init(_ wrappedStore: some SystemPermissionsStoreProviding) {
    self.wrappedStore = wrappedStore
    snapshot = SystemPermissionsStoreSnapshot(wrappedStore)

    wrappedStore.objectWillChange
      .sink { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.syncFromWrappedStore()
        }
      }
      .store(in: &cancellables)
  }

  /// Current Accessibility grant state.
  public var accessibilityGranted: Bool {
    snapshot.accessibilityGranted
  }

  /// Current Automation grant state.
  public var automationGranted: Bool {
    snapshot.automationGranted
  }

  /// Current Screen Recording grant state.
  public var screenRecordingGranted: Bool {
    snapshot.screenRecordingGranted
  }

  /// Current notification grant state.
  public var notificationsGranted: Bool {
    snapshot.notificationsGranted
  }

  /// Current Input Monitoring grant state.
  public var inputMonitoringGranted: Bool {
    snapshot.inputMonitoringGranted
  }

  /// Refreshes all tracked permission states.
  public func refreshAll() async {
    await wrappedStore.refreshAll()
    syncFromWrappedStore()
  }

  /// Requests Input Monitoring access.
  public func requestInputMonitoringPermission() async {
    await wrappedStore.requestInputMonitoringPermission()
    syncFromWrappedStore()
  }

  /// Requests Accessibility access.
  public func requestAccessibilityPermission() async {
    await wrappedStore.requestAccessibilityPermission()
    syncFromWrappedStore()
  }

  /// Requests Automation access.
  public func requestAutomationPermission() async {
    await wrappedStore.requestAutomationPermission()
    syncFromWrappedStore()
  }

  /// Requests Screen Recording access.
  public func requestScreenRecordingPermission() async {
    await wrappedStore.requestScreenRecordingPermission()
    syncFromWrappedStore()
  }

  /// Requests notification authorization.
  public func requestNotificationPermission() async {
    await wrappedStore.requestNotificationPermission()
    syncFromWrappedStore()
  }

  private func syncFromWrappedStore() {
    let nextSnapshot = SystemPermissionsStoreSnapshot(wrappedStore)
    guard nextSnapshot != snapshot else { return }
    objectWillChange.send()
    snapshot = nextSnapshot
  }
}

private struct SystemPermissionsStoreSnapshot: Equatable {
  let accessibilityGranted: Bool
  let automationGranted: Bool
  let screenRecordingGranted: Bool
  let notificationsGranted: Bool
  let inputMonitoringGranted: Bool

  @MainActor
  init(_ store: some SystemPermissionsStoreProviding) {
    accessibilityGranted = store.accessibilityGranted
    automationGranted = store.automationGranted
    screenRecordingGranted = store.screenRecordingGranted
    notificationsGranted = store.notificationsGranted
    inputMonitoringGranted = store.inputMonitoringGranted
  }
}
