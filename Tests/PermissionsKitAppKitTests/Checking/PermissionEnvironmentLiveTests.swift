import PermissionsKitAppKit
import XCTest

import PermissionsKit

final class PermissionEnvironmentLiveTests: XCTestCase {
  func testLiveStatusClosureReturnsResultsForCLISafeTypes() async throws {
    let checker = PermissionChecker()
    let results = await [
      checker.status(for: .accessibility),
      checker.status(for: .screenRecording),
      checker.status(for: .camera),
      checker.status(for: .microphone),
      checker.status(for: .speechRecognition),
      checker.status(for: .notifications),
    ]

    XCTAssertEqual(results.count, 6)
    for result in results {
      switch result {
      case .supported(let status):
        switch status {
        case .granted, .limited, .provisional, .ephemeral, .denied, .restricted, .notDetermined,
          .unknown:
          break
        }
      case .failed(.apiUnavailable):
        break
      case .failed, .unsupported:
        XCTFail("Unexpected live status result: \(result)")
      }
    }
  }
}
