/// Generic result for permission-related operations.
public enum PermissionOperationResult<Value: Sendable & Equatable>: Sendable, Equatable {
  /// The operation is supported and returned a value.
  case supported(Value)
  /// The operation is not supported; capability metadata is provided for fallback UI.
  case unsupported(PermissionCapability)
  /// The operation failed.
  case failed(PermissionError)

  /// The associated value when supported.
  public var value: Value? {
    switch self {
    case .supported(let value): value
    case .unsupported, .failed: nil
    }
  }

  /// The capability payload when unsupported.
  public var capability: PermissionCapability? {
    switch self {
    case .unsupported(let capability): capability
    case .supported, .failed: nil
    }
  }

  /// The error payload when failed.
  public var error: PermissionError? {
    switch self {
    case .failed(let error): error
    case .supported, .unsupported: nil
    }
  }

  /// Convenience flag for supported vs unsupported.
  public var isSupported: Bool {
    if case .supported = self { return true }
    return false
  }

  /// Convenience flag for unsupported results.
  public var isUnsupported: Bool {
    if case .unsupported = self { return true }
    return false
  }

  /// Convenience flag for failures.
  public var isFailed: Bool {
    if case .failed = self { return true }
    return false
  }
}

/// Outcome for opening System Settings.
public enum PermissionOpenSettingsOutcome: Sendable, Equatable {
  /// System Settings was opened.
  case opened
}

/// Result of a status fetch.
public typealias PermissionStatusResult = PermissionOperationResult<PermissionStatus>

/// Result of a request attempt.
public typealias PermissionRequestResult = PermissionOperationResult<PermissionStatus>

/// Result of opening System Settings.
public typealias PermissionOpenSettingsResult = PermissionOperationResult<
  PermissionOpenSettingsOutcome
>

extension PermissionOperationResult where Value == PermissionStatus {
  /// The status value when supported.
  public var status: PermissionStatus? {
    value
  }
}
