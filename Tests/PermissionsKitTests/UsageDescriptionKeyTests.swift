import XCTest

@testable import PermissionsKit

final class UsageDescriptionKeyTests: XCTestCase {
  func testAllCasesAreStable() {
    XCTAssertEqual(
      UsageDescriptionKey.allCases,
      [
        .camera,
        .microphone,
        .contacts,
        .calendarsFullAccess,
        .remindersFullAccess,
        .photos,
        .photosAddOnly,
        .speechRecognition,
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
        .appleEvents,
      ]
    )
  }

  func testRawValuesAreStable() {
    XCTAssertEqual(UsageDescriptionKey.camera.rawValue, "NSCameraUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.microphone.rawValue, "NSMicrophoneUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.contacts.rawValue, "NSContactsUsageDescription")
    XCTAssertEqual(
      UsageDescriptionKey.calendarsFullAccess.rawValue,
      "NSCalendarsFullAccessUsageDescription"
    )
    XCTAssertEqual(
      UsageDescriptionKey.remindersFullAccess.rawValue,
      "NSRemindersFullAccessUsageDescription"
    )
    XCTAssertEqual(UsageDescriptionKey.photos.rawValue, "NSPhotoLibraryUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.photosAddOnly.rawValue, "NSPhotoLibraryAddUsageDescription")
    XCTAssertEqual(
      UsageDescriptionKey.speechRecognition.rawValue,
      "NSSpeechRecognitionUsageDescription"
    )
    XCTAssertEqual(UsageDescriptionKey.location.rawValue, "NSLocationUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.bluetooth.rawValue, "NSBluetoothAlwaysUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.localNetwork.rawValue, "NSLocalNetworkUsageDescription")
    XCTAssertEqual(UsageDescriptionKey.mediaLibrary.rawValue, "NSAppleMusicUsageDescription")
    XCTAssertEqual(
      UsageDescriptionKey.systemAudioCapture.rawValue,
      "NSAudioCaptureUsageDescription"
    )
    XCTAssertEqual(UsageDescriptionKey.desktopFolder.rawValue, "NSDesktopFolderUsageDescription")
    XCTAssertEqual(
      UsageDescriptionKey.documentsFolder.rawValue,
      "NSDocumentsFolderUsageDescription"
    )
    XCTAssertEqual(
      UsageDescriptionKey.downloadsFolder.rawValue,
      "NSDownloadsFolderUsageDescription"
    )
    XCTAssertEqual(UsageDescriptionKey.networkVolumes.rawValue, "NSNetworkVolumesUsageDescription")
    XCTAssertEqual(
      UsageDescriptionKey.removableVolumes.rawValue,
      "NSRemovableVolumesUsageDescription"
    )
    XCTAssertEqual(
      UsageDescriptionKey.fileProviderDomain.rawValue,
      "NSFileProviderDomainUsageDescription"
    )
    XCTAssertEqual(UsageDescriptionKey.appleEvents.rawValue, "NSAppleEventsUsageDescription")
  }
}
