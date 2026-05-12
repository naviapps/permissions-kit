import AppKit
import Foundation
import PermissionsKit

/// Centralises prompting and guidance for macOS Accessibility / Automation / Screen Recording
/// permissions.
@MainActor
public final class SystemPermissionCoordinator {
  /// Shared coordinator using default guidance strings.
  public static let shared = SystemPermissionCoordinator()

  private let accessibilityStrategy: AccessibilityPermissionStrategy
  private let automationStrategy: AutomationPermissionStrategy
  private let screenRecordingStrategy: ScreenRecordingPermissionStrategy

  /// Creates a coordinator with custom guidance strings and logging.
  public convenience init(
    guidance: SystemPermissionGuidanceStrings = .english,
    logger: SystemPermissionLogger = NoopSystemPermissionLogger()
  ) {
    self.init(
      guidance: guidance,
      logger: logger,
      dependencies: .live
    )
  }

  init(
    guidance: SystemPermissionGuidanceStrings,
    logger: SystemPermissionLogger,
    dependencies: SystemPermissionCoordinatorDependencies
  ) {
    accessibilityStrategy = AccessibilityPermissionStrategy(
      guidance: guidance,
      logger: logger,
      dependencies: dependencies
    )
    automationStrategy = AutomationPermissionStrategy(
      guidance: guidance,
      logger: logger,
      dependencies: dependencies
    )
    screenRecordingStrategy = ScreenRecordingPermissionStrategy(
      guidance: guidance,
      logger: logger,
      dependencies: dependencies
    )
  }

  // MARK: Public surface

  /// Ensures Accessibility access, optionally presenting user-initiated guidance.
  @discardableResult
  @MainActor
  public func ensureAccessibilityPermission(
    using permissions: any PermissionChecking,
    userInitiated: Bool = false
  ) async -> Bool {
    await accessibilityStrategy.ensure(permissions: permissions, userInitiated: userInitiated)
      == .granted
  }

  /// Ensures Automation access, optionally presenting user-initiated guidance.
  @MainActor
  @discardableResult
  public func ensureAutomationPermission(userInitiated: Bool = false) -> Bool {
    automationStrategy.ensure(userInitiated: userInitiated) == .granted
  }

  /// Ensures Screen Recording access, presenting guidance when access is required.
  @MainActor
  @discardableResult
  public func ensureScreenRecordingPermission() async -> Bool {
    await screenRecordingStrategy.ensure() == .granted
  }

  /// Allows Accessibility guidance to be shown again.
  @MainActor
  public func resetAccessibilityGuidance() {
    accessibilityStrategy.resetGuidance()
  }

  /// Allows Automation guidance to be shown again.
  @MainActor
  public func resetAutomationGuidance() {
    automationStrategy.resetGuidance()
  }

  /// Allows Screen Recording guidance to be shown again.
  @MainActor
  public func resetScreenRecordingGuidance() {
    screenRecordingStrategy.resetGuidance()
  }

  /// Exposes automation guidance for callers that detect denial mid-flow.
  @MainActor
  public func presentAutomationGuidance() {
    automationStrategy.presentGuidance(force: true)
  }
}

// MARK: - Strategy definitions

enum PermissionResult {
  case granted
  case denied
  case pending
}

enum AutomationPermissionState {
  case unknown
  case granted
  case denied
}

struct AccessibilityPermissionEvaluation {
  let shouldResetPrompt: Bool
  let shouldResetGuidance: Bool
  let shouldPrompt: Bool
  let shouldPresentGuidance: Bool
  let initialResult: PermissionResult
}

func evaluateAccessibilityPermission(
  status: PermissionStatus,
  hasPrompted: Bool,
  hasPresentedGuidance: Bool,
  userInitiated: Bool
) -> AccessibilityPermissionEvaluation {
  if status == .granted {
    return .init(
      shouldResetPrompt: true,
      shouldResetGuidance: true,
      shouldPrompt: false,
      shouldPresentGuidance: false,
      initialResult: .granted
    )
  }

  return .init(
    shouldResetPrompt: false,
    shouldResetGuidance: false,
    shouldPrompt: hasPrompted == false,
    shouldPresentGuidance: userInitiated && hasPresentedGuidance == false,
    initialResult: .pending
  )
}

struct AutomationPermissionEvaluation {
  let nextState: AutomationPermissionState
  let shouldPresentGuidance: Bool
  let result: PermissionResult
}

func evaluateAutomationPermission(
  currentState: AutomationPermissionState,
  status: OSStatus,
  procNotFound: OSStatus,
  userInitiated: Bool
) -> AutomationPermissionEvaluation {
  switch currentState {
  case .granted:
    return .init(nextState: .granted, shouldPresentGuidance: false, result: .granted)
  case .denied:
    return .init(nextState: .denied, shouldPresentGuidance: userInitiated, result: .denied)
  case .unknown:
    switch status {
    case OSStatus(errAEEventNotPermitted):
      return .init(nextState: .denied, shouldPresentGuidance: userInitiated, result: .denied)
    case OSStatus(errAEEventWouldRequireUserConsent):
      return .init(nextState: .unknown, shouldPresentGuidance: userInitiated, result: .pending)
    case procNotFound:
      return .init(nextState: .unknown, shouldPresentGuidance: userInitiated, result: .pending)
    case noErr:
      return .init(nextState: .granted, shouldPresentGuidance: false, result: .granted)
    default:
      return .init(nextState: .unknown, shouldPresentGuidance: userInitiated, result: .pending)
    }
  }
}

struct ScreenRecordingPermissionEvaluation {
  let shouldResetGuidance: Bool
  let shouldPresentGuidance: Bool
  let shouldRequestPermission: Bool
  let result: PermissionResult
}

func evaluateScreenRecordingPermission(granted: Bool) -> ScreenRecordingPermissionEvaluation {
  if granted {
    return .init(
      shouldResetGuidance: true,
      shouldPresentGuidance: false,
      shouldRequestPermission: false,
      result: .granted
    )
  }

  return .init(
    shouldResetGuidance: false,
    shouldPresentGuidance: true,
    shouldRequestPermission: true,
    result: .pending
  )
}

// MARK: Accessibility

@MainActor
private final class AccessibilityPermissionStrategy {
  private var hasPrompted = false
  private var hasPresentedGuidance = false
  private let guidance: SystemPermissionGuidanceStrings
  private let logger: SystemPermissionLogger
  private let dependencies: SystemPermissionCoordinatorDependencies

  init(
    guidance: SystemPermissionGuidanceStrings,
    logger: SystemPermissionLogger,
    dependencies: SystemPermissionCoordinatorDependencies
  ) {
    self.guidance = guidance
    self.logger = logger
    self.dependencies = dependencies
  }

  func ensure(permissions: any PermissionChecking, userInitiated: Bool) async -> PermissionResult {
    let currentStatus = await permissions.status(for: .accessibility).status ?? .unknown
    let evaluation = evaluateAccessibilityPermission(
      status: currentStatus,
      hasPrompted: hasPrompted,
      hasPresentedGuidance: hasPresentedGuidance,
      userInitiated: userInitiated
    )

    if evaluation.shouldResetPrompt {
      hasPrompted = false
    }
    if evaluation.shouldResetGuidance {
      hasPresentedGuidance = false
    }
    if evaluation.initialResult == PermissionResult.granted {
      return .granted
    }

    if evaluation.shouldPrompt {
      hasPrompted = true
      _ = await permissions.requestAccess(for: .accessibility)
    }

    presentGuidanceIfNeeded(userInitiated: evaluation.shouldPresentGuidance)

    return await permissions.status(for: .accessibility).status == .granted ? .granted : .pending
  }

  func resetGuidance() {
    hasPresentedGuidance = false
  }

  private func presentGuidanceIfNeeded(userInitiated: Bool) {
    guard userInitiated, !hasPresentedGuidance else { return }
    hasPresentedGuidance = true
    logger.warning(guidance.accessibility.message)

    let response = dependencies.presentAlert(
      .init(
        title: guidance.accessibility.title,
        message: guidance.accessibility.message,
        openSettingsLabel: guidance.openSettingsLabel,
        cancelLabel: guidance.cancelLabel
      )
    )
    if response == .alertFirstButtonReturn {
      dependencies.openSettings(SystemPermissionURLs.accessibility)
    }
  }
}

// MARK: Automation

@MainActor
private final class AutomationPermissionStrategy {
  private var automationPermissionState: AutomationPermissionState = .unknown
  private var hasPresentedGuidance = false
  private let guidance: SystemPermissionGuidanceStrings
  private let logger: SystemPermissionLogger
  private let dependencies: SystemPermissionCoordinatorDependencies

  init(
    guidance: SystemPermissionGuidanceStrings,
    logger: SystemPermissionLogger,
    dependencies: SystemPermissionCoordinatorDependencies
  ) {
    self.guidance = guidance
    self.logger = logger
    self.dependencies = dependencies
  }

  func ensure(userInitiated: Bool) -> PermissionResult {
    if case .granted = automationPermissionState {
      hasPresentedGuidance = false
      return .granted
    }
    if case .denied = automationPermissionState {
      if userInitiated {
        presentGuidance()
      }
      return .denied
    }

    let status = dependencies.determineAutomationPermission(userInitiated)

    let procNotFound = OSStatus(-600)  // System Events not found / not running

    return handleAutomationStatus(status, procNotFound: procNotFound, userInitiated: userInitiated)
  }

  func resetGuidance() {
    hasPresentedGuidance = false
  }

  @MainActor
  fileprivate func presentGuidance(force: Bool = false) {
    guard force || !hasPresentedGuidance else { return }
    hasPresentedGuidance = true
    logger.warning(guidance.automation.message)

    let response = dependencies.presentAlert(
      .init(
        title: guidance.automation.title,
        message: guidance.automation.message,
        openSettingsLabel: guidance.openSettingsLabel,
        cancelLabel: guidance.cancelLabel
      )
    )

    if response == .alertFirstButtonReturn,
      URL(string: SystemPermissionURLs.automation) != nil
    {
      dependencies.openSettings(SystemPermissionURLs.automation)
    }
  }

  private func handleAutomationStatus(
    _ status: OSStatus,
    procNotFound: OSStatus,
    userInitiated: Bool
  ) -> PermissionResult {
    let evaluation = evaluateAutomationPermission(
      currentState: automationPermissionState,
      status: status,
      procNotFound: procNotFound,
      userInitiated: userInitiated
    )
    automationPermissionState = evaluation.nextState
    if evaluation.shouldPresentGuidance {
      presentGuidance()
    }
    return evaluation.result
  }
}

// MARK: Screen Recording

@MainActor
private final class ScreenRecordingPermissionStrategy {
  private var hasPresentedGuidance = false
  private let guidance: SystemPermissionGuidanceStrings
  private let logger: SystemPermissionLogger
  private let dependencies: SystemPermissionCoordinatorDependencies

  init(
    guidance: SystemPermissionGuidanceStrings,
    logger: SystemPermissionLogger,
    dependencies: SystemPermissionCoordinatorDependencies
  ) {
    self.guidance = guidance
    self.logger = logger
    self.dependencies = dependencies
  }

  func ensure() async -> PermissionResult {
    let evaluation = evaluateScreenRecordingPermission(
      granted: dependencies.preflightScreenRecording())
    if evaluation.shouldResetGuidance {
      resetGuidance()
      return evaluation.result
    }
    if evaluation.shouldPresentGuidance {
      presentGuidance()
    }
    if evaluation.shouldRequestPermission {
      _ = dependencies.requestScreenRecordingPermission()
    }
    return evaluation.result
  }

  func resetGuidance() {
    hasPresentedGuidance = false
  }

  private func presentGuidance() {
    guard !hasPresentedGuidance else { return }
    hasPresentedGuidance = true
    logger.warning(guidance.screenRecording.message)

    let response = dependencies.presentAlert(
      .init(
        title: guidance.screenRecording.title,
        message: guidance.screenRecording.message,
        openSettingsLabel: guidance.openSettingsLabel,
        cancelLabel: guidance.cancelLabel
      )
    )
    if response == .alertFirstButtonReturn {
      dependencies.openSettings(SystemPermissionURLs.screenRecording)
    }
  }
}

// MARK: - Helpers

struct SystemPermissionAlertContent: Equatable {
  let title: String
  let message: String
  let openSettingsLabel: String
  let cancelLabel: String
}

@MainActor
struct SystemPermissionCoordinatorDependencies {
  var presentAlert: @MainActor (SystemPermissionAlertContent) -> NSApplication.ModalResponse
  var openSettings: @MainActor (String) -> Void
  var determineAutomationPermission: @MainActor (Bool) -> OSStatus
  var preflightScreenRecording: @MainActor () -> Bool
  var requestScreenRecordingPermission: @MainActor () -> Bool

  static let live = SystemPermissionCoordinatorDependencies(
    presentAlert: { content in
      let alert = NSAlert()
      alert.alertStyle = .warning
      alert.messageText = content.title
      alert.informativeText = content.message
      alert.addButton(withTitle: content.openSettingsLabel)
      alert.addButton(withTitle: content.cancelLabel)
      return alert.runModal()
    },
    openSettings: { urlString in
      guard let url = URL(string: urlString) else { return }
      NSWorkspace.shared.open(url)
    },
    determineAutomationPermission: { userInitiated in
      let descriptor = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
      return AEDeterminePermissionToAutomateTarget(
        descriptor.aeDesc,
        typeWildCard,
        typeWildCard,
        userInitiated
      )
    },
    preflightScreenRecording: {
      CGPreflightScreenCaptureAccess()
    },
    requestScreenRecordingPermission: {
      CGRequestScreenCaptureAccess()
    }
  )
}

private enum SystemPermissionURLs {
  static let accessibility =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  static let automation =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
  static let screenRecording =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
}
