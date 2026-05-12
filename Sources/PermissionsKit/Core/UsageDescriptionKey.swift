/// Info.plist usage description keys required by certain permissions.
public enum UsageDescriptionKey: String, Sendable, CaseIterable {
  /// `NSCameraUsageDescription`.
  case camera = "NSCameraUsageDescription"
  /// `NSMicrophoneUsageDescription`.
  case microphone = "NSMicrophoneUsageDescription"
  /// `NSContactsUsageDescription`.
  case contacts = "NSContactsUsageDescription"
  /// `NSCalendarsFullAccessUsageDescription`.
  case calendarsFullAccess = "NSCalendarsFullAccessUsageDescription"
  /// `NSRemindersFullAccessUsageDescription`.
  case remindersFullAccess = "NSRemindersFullAccessUsageDescription"
  /// `NSPhotoLibraryUsageDescription`.
  case photos = "NSPhotoLibraryUsageDescription"
  /// `NSPhotoLibraryAddUsageDescription`.
  case photosAddOnly = "NSPhotoLibraryAddUsageDescription"
  /// `NSSpeechRecognitionUsageDescription`.
  case speechRecognition = "NSSpeechRecognitionUsageDescription"
  /// `NSLocationUsageDescription`.
  case location = "NSLocationUsageDescription"
  /// `NSBluetoothAlwaysUsageDescription`.
  case bluetooth = "NSBluetoothAlwaysUsageDescription"
  /// `NSLocalNetworkUsageDescription`.
  case localNetwork = "NSLocalNetworkUsageDescription"
  /// `NSAppleMusicUsageDescription`.
  case mediaLibrary = "NSAppleMusicUsageDescription"
  /// `NSAudioCaptureUsageDescription`.
  case systemAudioCapture = "NSAudioCaptureUsageDescription"
  /// `NSDesktopFolderUsageDescription`.
  case desktopFolder = "NSDesktopFolderUsageDescription"
  /// `NSDocumentsFolderUsageDescription`.
  case documentsFolder = "NSDocumentsFolderUsageDescription"
  /// `NSDownloadsFolderUsageDescription`.
  case downloadsFolder = "NSDownloadsFolderUsageDescription"
  /// `NSNetworkVolumesUsageDescription`.
  case networkVolumes = "NSNetworkVolumesUsageDescription"
  /// `NSRemovableVolumesUsageDescription`.
  case removableVolumes = "NSRemovableVolumesUsageDescription"
  /// `NSFileProviderDomainUsageDescription`.
  case fileProviderDomain = "NSFileProviderDomainUsageDescription"
  /// `NSAppleEventsUsageDescription`.
  case appleEvents = "NSAppleEventsUsageDescription"
}
