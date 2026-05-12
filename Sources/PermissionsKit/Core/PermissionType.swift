import Foundation

/// Custom permission descriptor for host-defined permission entries.
public struct CustomPermission: Sendable, Hashable {
  /// Stable ASCII identifier used by `PermissionType.custom`.
  public let id: String
  /// Capability metadata supplied by the host app.
  public let capability: PermissionCapability

  /// Creates a custom permission descriptor.
  public init(id: String, capability: PermissionCapability) {
    precondition(id.isEmpty == false, "CustomPermission id must not be empty.")
    precondition(
      id.unicodeScalars.allSatisfy { scalar in
        scalar.isASCII
          && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_" || scalar == "-"
            || scalar == ".")
      },
      "CustomPermission id must be ASCII and contain only letters, numbers, underscore, dash, or dot."
    )
    self.id = id
    self.capability = capability
  }
}

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
  /// Calendar access.
  case calendars
  /// Reminder access.
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
  /// Host-defined permission metadata.
  case custom(CustomPermission)

  /// Built-in permission types in display order.
  public static let builtIn: [PermissionType] = [
    .accessibility,
    .inputMonitoring,
    .screenRecording,
    .camera,
    .microphone,
    .contacts,
    .calendars,
    .reminders,
    .photos,
    .speechRecognition,
    .notifications,
    .location,
    .bluetooth,
    .localNetwork,
    .mediaLibrary,
    .systemAudioCapture,
    .desktopFolder,
    .documentsFolder,
    .downloadsFolder,
    .networkVolumes,
    .removableVolumes,
    .fileProviderDomain,
    .fullDiskAccess,
    .automation,
  ]

  /// Identifier for logs, analytics, and UI test IDs.
  public var id: String {
    switch self {
    case .accessibility: "accessibility"
    case .inputMonitoring: "input_monitoring"
    case .screenRecording: "screen_recording"
    case .camera: "camera"
    case .microphone: "microphone"
    case .contacts: "contacts"
    case .calendars: "calendars"
    case .reminders: "reminders"
    case .photos: "photos"
    case .speechRecognition: "speech_recognition"
    case .notifications: "notifications"
    case .location: "location"
    case .bluetooth: "bluetooth"
    case .localNetwork: "local_network"
    case .mediaLibrary: "media_library"
    case .systemAudioCapture: "system_audio_capture"
    case .desktopFolder: "desktop_folder"
    case .documentsFolder: "documents_folder"
    case .downloadsFolder: "downloads_folder"
    case .networkVolumes: "network_volumes"
    case .removableVolumes: "removable_volumes"
    case .fileProviderDomain: "file_provider_domain"
    case .fullDiskAccess: "full_disk_access"
    case .automation: "automation"
    case .custom(let custom): custom.id
    }
  }
}

extension PermissionType {
  /// Default request options for this permission type.
  public var defaultRequestOptions: PermissionRequestOptions {
    switch self {
    case .notifications:
      .notifications(.default)
    case .photos:
      .photos(.default)
    default:
      .none
    }
  }

  /// True when macOS only exposes this permission through System Settings.
  public var isSettingsOnly: Bool {
    switch self {
    case .custom(let custom):
      !(custom.capability.supportsStatusCheck || custom.capability.supportsRequest)
    case .inputMonitoring,
      .location,
      .bluetooth,
      .localNetwork,
      .mediaLibrary,
      .systemAudioCapture,
      .desktopFolder,
      .documentsFolder,
      .downloadsFolder,
      .networkVolumes,
      .removableVolumes,
      .fileProviderDomain,
      .fullDiskAccess,
      .automation:
      true
    default:
      false
    }
  }

  /// True when the system provides a reliable status API for this permission type.
  public var supportsStatusCheck: Bool {
    switch self {
    case .custom(let custom):
      custom.capability.supportsStatusCheck
    default:
      isSettingsOnly == false
    }
  }

  /// True when the system provides a request API for this permission type.
  public var supportsRequest: Bool {
    switch self {
    case .custom(let custom):
      custom.capability.supportsRequest
    default:
      isSettingsOnly == false
    }
  }

  /// Deep link to the System Settings pane for this permission, when available.
  public var systemSettingsURL: URL? {
    switch self {
    case .custom(let custom):
      custom.capability.systemSettingsURL
    case .accessibility:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    case .inputMonitoring:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    case .screenRecording:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    case .camera:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
    case .microphone:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    case .contacts:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts")
    case .calendars:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
    case .reminders:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")
    case .photos:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos")
    case .speechRecognition:
      URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
    case .notifications:
      URL(string: "x-apple.systempreferences:com.apple.preference.notifications?Notifications")
    case .location:
      URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")
    case .bluetooth:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")
    case .localNetwork:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocalNetwork")
    case .mediaLibrary:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media")
    case .systemAudioCapture:
      URL(
        string:
          "x-apple.systempreferences:com.apple.preference.security?Privacy_SystemAudioRecording")
    case .desktopFolder,
      .documentsFolder,
      .downloadsFolder,
      .networkVolumes,
      .removableVolumes,
      .fileProviderDomain:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")
    case .fullDiskAccess:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    case .automation:
      URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }
  }

  /// True when macOS typically requires an app relaunch after enabling access.
  public var requiresRelaunch: Bool {
    switch self {
    case .custom(let custom):
      custom.capability.requiresRelaunch
    case .inputMonitoring, .screenRecording, .fullDiskAccess:
      true
    default:
      false
    }
  }

  /// Capability metadata for host apps and flows.
  public var capability: PermissionCapability {
    switch self {
    case .custom(let custom):
      custom.capability
    default:
      PermissionCapability(
        supportsStatusCheck: supportsStatusCheck,
        supportsRequest: supportsRequest,
        systemSettingsURL: systemSettingsURL,
        requiresRelaunch: requiresRelaunch,
        usageDescriptionKeys: usageDescriptionKeys
      )
    }
  }

  /// Usage description keys required for this permission type.
  public var usageDescriptionKeys: [UsageDescriptionKey] {
    usageDescriptionKeys(for: defaultRequestOptions)
  }

  /// Usage description keys required for this permission type and request options.
  public func usageDescriptionKeys(for options: PermissionRequestOptions) -> [UsageDescriptionKey] {
    switch self {
    case .custom(let custom):
      custom.capability.usageDescriptionKeys
    case .camera:
      [.camera]
    case .microphone:
      [.microphone]
    case .contacts:
      [.contacts]
    case .calendars:
      [.calendarsFullAccess]
    case .reminders:
      [.remindersFullAccess]
    case .photos:
      if case .photos(.addOnly) = options {
        [.photosAddOnly]
      } else {
        [.photos]
      }
    case .speechRecognition:
      [.speechRecognition]
    case .location:
      [.location]
    case .bluetooth:
      [.bluetooth]
    case .localNetwork:
      [.localNetwork]
    case .mediaLibrary:
      [.mediaLibrary]
    case .systemAudioCapture:
      [.systemAudioCapture]
    case .desktopFolder:
      [.desktopFolder]
    case .documentsFolder:
      [.documentsFolder]
    case .downloadsFolder:
      [.downloadsFolder]
    case .networkVolumes:
      [.networkVolumes]
    case .removableVolumes:
      [.removableVolumes]
    case .fileProviderDomain:
      [.fileProviderDomain]
    case .automation:
      [.appleEvents]
    case .accessibility,
      .inputMonitoring,
      .screenRecording,
      .notifications,
      .fullDiskAccess:
      []
    }
  }

  /// True when the permission type requires Info.plist usage descriptions.
  public var requiresUsageDescription: Bool {
    usageDescriptionKeys.isEmpty == false
  }

  /// Returns missing usage description keys in the provided bundle.
  public func missingUsageDescriptions(
    in bundle: Bundle = .main,
    options: PermissionRequestOptions = .none
  ) -> [UsageDescriptionKey] {
    let info = bundle.infoDictionary ?? [:]
    return usageDescriptionKeys(for: options).filter { info[$0.rawValue] == nil }
  }
}
