import Foundation

extension PermissionType {
  /// Default permission options for this permission type.
  public var defaultOptions: PermissionOptions {
    metadata.defaultOptions
  }

  /// Capability metadata for host apps and flows.
  public var capability: PermissionCapability {
    metadata.capability
  }
}

private enum PermissionPrivacySettingsPane: String {
  case accessibility = "Privacy_Accessibility"
  case inputMonitoring = "Privacy_ListenEvent"
  case screenRecording = "Privacy_ScreenCapture"
  case camera = "Privacy_Camera"
  case microphone = "Privacy_Microphone"
  case contacts = "Privacy_Contacts"
  case calendars = "Privacy_Calendars"
  case reminders = "Privacy_Reminders"
  case photos = "Privacy_Photos"
  case speechRecognition = "Privacy_SpeechRecognition"
  case locationServices = "Privacy_LocationServices"
  case bluetooth = "Privacy_Bluetooth"
  case localNetwork = "Privacy_LocalNetwork"
  case media = "Privacy_Media"
  case systemAudioRecording = "Privacy_SystemAudioRecording"
  case filesAndFolders = "Privacy_FilesAndFolders"
  case fullDiskAccess = "Privacy_AllFiles"
  case automation = "Privacy_Automation"
}

private enum PermissionSettingsDestination {
  case privacy(PermissionPrivacySettingsPane)
  case notifications

  var url: URL? {
    URL(string: urlString)
  }

  var urlString: String {
    switch self {
    case .privacy(let pane):
      "x-apple.systempreferences:com.apple.preference.security?\(pane.rawValue)"
    case .notifications:
      "x-apple.systempreferences:com.apple.preference.notifications?Notifications"
    }
  }
}

private enum PermissionBuiltInCapabilityProfile {
  case direct
  case settingsOnly

  func capability(systemSettingsURL: URL?, requiresRelaunch: Bool) -> PermissionCapability {
    switch self {
    case .direct:
      PermissionCapability(
        supportsStatusCheck: true,
        supportsRequest: true,
        systemSettingsURL: systemSettingsURL,
        requiresRelaunch: requiresRelaunch
      )
    case .settingsOnly:
      PermissionCapability(
        supportsStatusCheck: false,
        supportsRequest: false,
        systemSettingsURL: systemSettingsURL,
        requiresRelaunch: requiresRelaunch
      )
    }
  }
}

private extension PermissionType {
  struct Metadata {
    let defaultOptions: PermissionOptions
    let usageDescriptionKeys: [UsageDescriptionKey]
    let capability: PermissionCapability

    init(
      defaultOptions: PermissionOptions = .none,
      usageDescriptionKeys: [UsageDescriptionKey] = [],
      capability: PermissionCapability
    ) {
      self.defaultOptions = defaultOptions
      self.usageDescriptionKeys = usageDescriptionKeys
      self.capability = capability
    }

    init(
      defaultOptions: PermissionOptions = .none,
      usageDescriptionKeys: [UsageDescriptionKey] = [],
      capabilityProfile: PermissionBuiltInCapabilityProfile = .direct,
      settingsDestination: PermissionSettingsDestination,
      requiresRelaunch: Bool = false
    ) {
      self.defaultOptions = defaultOptions
      self.usageDescriptionKeys = usageDescriptionKeys
      capability = capabilityProfile.capability(
        systemSettingsURL: settingsDestination.url,
        requiresRelaunch: requiresRelaunch
      )
    }

    static func settingsOnly(
      usageDescriptionKeys: [UsageDescriptionKey] = [],
      settingsDestination: PermissionSettingsDestination,
      requiresRelaunch: Bool = false
    ) -> Self {
      Self(
        usageDescriptionKeys: usageDescriptionKeys,
        capabilityProfile: .settingsOnly,
        settingsDestination: settingsDestination,
        requiresRelaunch: requiresRelaunch
      )
    }

    static func fileAccess(
      usageDescriptionKey: UsageDescriptionKey
    ) -> Self {
      settingsOnly(
        usageDescriptionKeys: [usageDescriptionKey],
        settingsDestination: .privacy(.filesAndFolders)
      )
    }
  }

  var metadata: Metadata {
    switch self {
    case .accessibility:
      Metadata(
        settingsDestination: .privacy(.accessibility)
      )
    case .inputMonitoring:
      Metadata.settingsOnly(
        settingsDestination: .privacy(.inputMonitoring),
        requiresRelaunch: true
      )
    case .screenRecording:
      Metadata(
        settingsDestination: .privacy(.screenRecording),
        requiresRelaunch: true
      )
    case .camera:
      Metadata(
        usageDescriptionKeys: [.camera],
        settingsDestination: .privacy(.camera)
      )
    case .microphone:
      Metadata(
        usageDescriptionKeys: [.microphone],
        settingsDestination: .privacy(.microphone)
      )
    case .contacts:
      Metadata(
        usageDescriptionKeys: [.contacts],
        settingsDestination: .privacy(.contacts)
      )
    case .calendars:
      Metadata(
        usageDescriptionKeys: [.calendarsFullAccess],
        settingsDestination: .privacy(.calendars)
      )
    case .reminders:
      Metadata(
        usageDescriptionKeys: [.remindersFullAccess],
        settingsDestination: .privacy(.reminders)
      )
    case .photos:
      Metadata(
        defaultOptions: .photos(.default),
        usageDescriptionKeys: [.photos],
        settingsDestination: .privacy(.photos)
      )
    case .speechRecognition:
      Metadata(
        usageDescriptionKeys: [.speechRecognition],
        settingsDestination: .privacy(.speechRecognition)
      )
    case .notifications:
      Metadata(
        defaultOptions: .notifications(.default),
        settingsDestination: .notifications
      )
    case .location:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.location],
        settingsDestination: .privacy(.locationServices)
      )
    case .bluetooth:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.bluetooth],
        settingsDestination: .privacy(.bluetooth)
      )
    case .localNetwork:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.localNetwork],
        settingsDestination: .privacy(.localNetwork)
      )
    case .mediaLibrary:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.mediaLibrary],
        settingsDestination: .privacy(.media)
      )
    case .systemAudioCapture:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.systemAudioCapture],
        settingsDestination: .privacy(.systemAudioRecording)
      )
    case .desktopFolder:
      Metadata.fileAccess(
        usageDescriptionKey: .desktopFolder
      )
    case .documentsFolder:
      Metadata.fileAccess(
        usageDescriptionKey: .documentsFolder
      )
    case .downloadsFolder:
      Metadata.fileAccess(
        usageDescriptionKey: .downloadsFolder
      )
    case .networkVolumes:
      Metadata.fileAccess(
        usageDescriptionKey: .networkVolumes
      )
    case .removableVolumes:
      Metadata.fileAccess(
        usageDescriptionKey: .removableVolumes
      )
    case .fileProviderDomain:
      Metadata.fileAccess(
        usageDescriptionKey: .fileProviderDomain
      )
    case .fullDiskAccess:
      Metadata.settingsOnly(
        settingsDestination: .privacy(.fullDiskAccess),
        requiresRelaunch: true
      )
    case .automation:
      Metadata.settingsOnly(
        usageDescriptionKeys: [.appleEvents],
        settingsDestination: .privacy(.automation)
      )
    case .custom(let custom):
      Metadata(
        usageDescriptionKeys: custom.usageDescriptionKeys,
        capability: custom.capability
      )
    }
  }
}

extension PermissionType {
  var metadataUsageDescriptionKeys: [UsageDescriptionKey] {
    metadata.usageDescriptionKeys
  }
}
