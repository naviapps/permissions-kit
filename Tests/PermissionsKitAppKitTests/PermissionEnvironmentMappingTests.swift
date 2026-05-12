import AVFoundation
import Contacts
import EventKit
import PermissionsKit
import Photos
import Speech
import UserNotifications
import XCTest

@testable import PermissionsKitAppKit

final class PermissionEnvironmentMappingTests: XCTestCase {
  func testMapAVStatus() {
    XCTAssertEqual(mapAVStatus(AVAuthorizationStatus.authorized), PermissionStatus.granted)
    XCTAssertEqual(mapAVStatus(AVAuthorizationStatus.denied), PermissionStatus.denied)
    XCTAssertEqual(mapAVStatus(AVAuthorizationStatus.restricted), PermissionStatus.restricted)
    XCTAssertEqual(mapAVStatus(AVAuthorizationStatus.notDetermined), PermissionStatus.notDetermined)
  }

  func testMapContactsStatus() {
    XCTAssertEqual(mapCNStatus(CNAuthorizationStatus.authorized), PermissionStatus.granted)
    XCTAssertEqual(mapCNStatus(CNAuthorizationStatus.denied), PermissionStatus.denied)
    XCTAssertEqual(mapCNStatus(CNAuthorizationStatus.restricted), PermissionStatus.restricted)
    XCTAssertEqual(mapCNStatus(CNAuthorizationStatus.notDetermined), PermissionStatus.notDetermined)
  }

  func testMapEventKitStatus() {
    XCTAssertEqual(mapEKStatus(EKAuthorizationStatus.fullAccess), PermissionStatus.granted)
    XCTAssertEqual(mapEKStatus(EKAuthorizationStatus.writeOnly), PermissionStatus.restricted)
    XCTAssertEqual(mapEKStatus(EKAuthorizationStatus.denied), PermissionStatus.denied)
    XCTAssertEqual(mapEKStatus(EKAuthorizationStatus.restricted), PermissionStatus.restricted)
    XCTAssertEqual(mapEKStatus(EKAuthorizationStatus.notDetermined), PermissionStatus.notDetermined)
  }

  func testMapPhotosStatus() {
    XCTAssertEqual(mapPHStatus(PHAuthorizationStatus.authorized), PermissionStatus.granted)
    XCTAssertEqual(mapPHStatus(PHAuthorizationStatus.limited), PermissionStatus.granted)
    XCTAssertEqual(mapPHStatus(PHAuthorizationStatus.denied), PermissionStatus.denied)
    XCTAssertEqual(mapPHStatus(PHAuthorizationStatus.restricted), PermissionStatus.restricted)
    XCTAssertEqual(mapPHStatus(PHAuthorizationStatus.notDetermined), PermissionStatus.notDetermined)
  }

  func testMapSpeechStatus() {
    XCTAssertEqual(
      mapSpeechStatus(SFSpeechRecognizerAuthorizationStatus.authorized), PermissionStatus.granted)
    XCTAssertEqual(
      mapSpeechStatus(SFSpeechRecognizerAuthorizationStatus.denied), PermissionStatus.denied)
    XCTAssertEqual(
      mapSpeechStatus(SFSpeechRecognizerAuthorizationStatus.restricted), PermissionStatus.restricted
    )
    XCTAssertEqual(
      mapSpeechStatus(SFSpeechRecognizerAuthorizationStatus.notDetermined),
      PermissionStatus.notDetermined)
  }

  func testResolvedPhotoAccessLevelUsesDefault() {
    XCTAssertEqual(resolvedPhotoAccessLevel(.none), PhotoAccessLevel.default)
    XCTAssertEqual(resolvedPhotoAccessLevel(.photos(.addOnly)), PhotoAccessLevel.addOnly)
  }

  func testResolvedNotificationOptionsUsesDefault() {
    XCTAssertEqual(resolvedNotificationOptions(.none), NotificationRequestOptions.default)
    XCTAssertEqual(
      resolvedNotificationOptions(.notifications([.alert, .sound])),
      NotificationRequestOptions([.alert, .sound])
    )
  }

  func testNotificationOptionsSystemValueIncludesRequestedOptions() {
    let options: NotificationRequestOptions = [
      .alert,
      .badge,
      .sound,
      .criticalAlert,
      .provisional,
      .providesAppNotificationSettings,
    ]
    let system = options.systemValue
    XCTAssertTrue(system.contains(UNAuthorizationOptions.alert))
    XCTAssertTrue(system.contains(UNAuthorizationOptions.badge))
    XCTAssertTrue(system.contains(UNAuthorizationOptions.sound))
    XCTAssertTrue(system.contains(UNAuthorizationOptions.criticalAlert))
    XCTAssertTrue(system.contains(UNAuthorizationOptions.provisional))
    XCTAssertTrue(system.contains(UNAuthorizationOptions.providesAppNotificationSettings))
  }

  func testNotificationOptionsSystemValueOmitsUnrequestedOptions() {
    let system = NotificationRequestOptions.alert.systemValue

    XCTAssertFalse(system.contains(UNAuthorizationOptions.badge))
    XCTAssertFalse(system.contains(UNAuthorizationOptions.sound))
    XCTAssertFalse(system.contains(UNAuthorizationOptions.criticalAlert))
    XCTAssertFalse(system.contains(UNAuthorizationOptions.provisional))
    XCTAssertFalse(system.contains(UNAuthorizationOptions.providesAppNotificationSettings))
  }

  func testPhotoAccessLevelSystemValueMapping() {
    XCTAssertEqual(PhotoAccessLevel.readWrite.systemValue, PHAccessLevel.readWrite)
    XCTAssertEqual(PhotoAccessLevel.addOnly.systemValue, PHAccessLevel.addOnly)
  }
}
