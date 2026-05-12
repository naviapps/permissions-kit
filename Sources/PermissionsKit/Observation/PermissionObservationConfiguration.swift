/// Configuration for `PermissionStatusObserver.changes(for:using:configuration:statusOptionsProvider:)`.
public struct PermissionObservationConfiguration: Sendable {
  /// Polling interval used to re-check permission status.
  public var pollingInterval: Duration {
    didSet {
      pollingInterval = Self.clampedInterval(pollingInterval)
    }
  }

  /// Optional hook for observer diagnostic messages.
  public let logHandler: (@Sendable (String) -> Void)?

  /// Creates observer configuration.
  public init(
    pollingInterval: Duration = .seconds(2),
    logHandler: (@Sendable (String) -> Void)? = nil
  ) {
    self.pollingInterval = Self.clampedInterval(pollingInterval)
    self.logHandler = logHandler
  }

  private static func clampedInterval(_ interval: Duration) -> Duration {
    let minimum: Duration = .milliseconds(250)
    return interval < minimum ? minimum : interval
  }
}
