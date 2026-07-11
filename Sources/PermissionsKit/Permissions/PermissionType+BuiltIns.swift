extension PermissionType {
  /// Built-in permission types in display order.
  public static let builtIn: [PermissionType] =
    PermissionBuiltInIdentifier.allCases.map(\.permissionType)

  /// Stable package identifier for this permission type.
  public var id: String {
    switch self {
    case .accessibility: PermissionBuiltInIdentifier.accessibility.rawValue
    case .inputMonitoring: PermissionBuiltInIdentifier.inputMonitoring.rawValue
    case .screenRecording: PermissionBuiltInIdentifier.screenRecording.rawValue
    case .camera: PermissionBuiltInIdentifier.camera.rawValue
    case .microphone: PermissionBuiltInIdentifier.microphone.rawValue
    case .contacts: PermissionBuiltInIdentifier.contacts.rawValue
    case .calendars: PermissionBuiltInIdentifier.calendars.rawValue
    case .reminders: PermissionBuiltInIdentifier.reminders.rawValue
    case .photos: PermissionBuiltInIdentifier.photos.rawValue
    case .speechRecognition: PermissionBuiltInIdentifier.speechRecognition.rawValue
    case .notifications: PermissionBuiltInIdentifier.notifications.rawValue
    case .location: PermissionBuiltInIdentifier.location.rawValue
    case .bluetooth: PermissionBuiltInIdentifier.bluetooth.rawValue
    case .localNetwork: PermissionBuiltInIdentifier.localNetwork.rawValue
    case .mediaLibrary: PermissionBuiltInIdentifier.mediaLibrary.rawValue
    case .systemAudioCapture: PermissionBuiltInIdentifier.systemAudioCapture.rawValue
    case .desktopFolder: PermissionBuiltInIdentifier.desktopFolder.rawValue
    case .documentsFolder: PermissionBuiltInIdentifier.documentsFolder.rawValue
    case .downloadsFolder: PermissionBuiltInIdentifier.downloadsFolder.rawValue
    case .networkVolumes: PermissionBuiltInIdentifier.networkVolumes.rawValue
    case .removableVolumes: PermissionBuiltInIdentifier.removableVolumes.rawValue
    case .fileProviderDomain: PermissionBuiltInIdentifier.fileProviderDomain.rawValue
    case .fullDiskAccess: PermissionBuiltInIdentifier.fullDiskAccess.rawValue
    case .automation: PermissionBuiltInIdentifier.automation.rawValue
    case .custom(let custom): custom.identifier
    }
  }
}

private enum PermissionBuiltInIdentifier: String, CaseIterable {
  case accessibility
  case inputMonitoring = "input_monitoring"
  case screenRecording = "screen_recording"
  case camera
  case microphone
  case contacts
  case calendars
  case reminders
  case photos
  case speechRecognition = "speech_recognition"
  case notifications
  case location
  case bluetooth
  case localNetwork = "local_network"
  case mediaLibrary = "media_library"
  case systemAudioCapture = "system_audio_capture"
  case desktopFolder = "desktop_folder"
  case documentsFolder = "documents_folder"
  case downloadsFolder = "downloads_folder"
  case networkVolumes = "network_volumes"
  case removableVolumes = "removable_volumes"
  case fileProviderDomain = "file_provider_domain"
  case fullDiskAccess = "full_disk_access"
  case automation

  var permissionType: PermissionType {
    switch self {
    case .accessibility: .accessibility
    case .inputMonitoring: .inputMonitoring
    case .screenRecording: .screenRecording
    case .camera: .camera
    case .microphone: .microphone
    case .contacts: .contacts
    case .calendars: .calendars
    case .reminders: .reminders
    case .photos: .photos
    case .speechRecognition: .speechRecognition
    case .notifications: .notifications
    case .location: .location
    case .bluetooth: .bluetooth
    case .localNetwork: .localNetwork
    case .mediaLibrary: .mediaLibrary
    case .systemAudioCapture: .systemAudioCapture
    case .desktopFolder: .desktopFolder
    case .documentsFolder: .documentsFolder
    case .downloadsFolder: .downloadsFolder
    case .networkVolumes: .networkVolumes
    case .removableVolumes: .removableVolumes
    case .fileProviderDomain: .fileProviderDomain
    case .fullDiskAccess: .fullDiskAccess
    case .automation: .automation
    }
  }
}
