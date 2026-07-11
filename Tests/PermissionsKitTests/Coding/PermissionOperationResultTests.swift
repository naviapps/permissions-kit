import Foundation
import XCTest

import PermissionsKit

final class PermissionOperationResultTests: XCTestCase {
  private let capability = PermissionCapability(
    supportsStatusCheck: false,
    supportsRequest: false,
    systemSettingsURL: nil,
    requiresRelaunch: false
  )

  func testResultDoesNotRequireEquatableValues() {
    let result: PermissionOperationResult<NonEquatableSendable> = .supported(
      NonEquatableSendable(value: 1)
    )

    guard case .supported(let value) = result else {
      return XCTFail("Expected supported result.")
    }
    XCTAssertEqual(value.value, 1)
  }

  func testResultCodableUsesExplicitCaseAndPayloadKeys() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    XCTAssertEqual(
      String(
        data: try encoder.encode(PermissionOperationResult<PermissionStatus>.supported(.granted)),
        encoding: .utf8
      ),
      #"{"kind":"supported","value":"granted"}"#
    )
    XCTAssertEqual(
      String(
        data: try encoder.encode(
          PermissionOperationResult<PermissionStatus>.unsupported(capability)
        ),
        encoding: .utf8
      ),
      #"{"capability":{"requiresRelaunch":false,"supportsRequest":false,"supportsStatusCheck":false},"kind":"unsupported"}"#
    )
    XCTAssertEqual(
      String(
        data: try encoder.encode(PermissionOperationResult<PermissionStatus>.failed(.openFailed)),
        encoding: .utf8
      ),
      #"{"error":"openFailed","kind":"failed"}"#
    )

    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionOperationResult<PermissionStatus>.self,
        from: Data(#"{"kind":"supported","value":"denied"}"#.utf8)
      ),
      .supported(.denied)
    )
    XCTAssertEqual(
      try JSONDecoder().decode(
        PermissionOperationResult<PermissionStatus>.self,
        from: Data(#"{"error":"apiUnavailable","kind":"failed"}"#.utf8)
      ),
      .failed(.apiUnavailable)
    )
  }

  func testResultCodableRejectsInvalidPayloadShapes() {
    assertOperationResultDecodeFails(
      #"{"kind":"deferred","value":"granted"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"supported"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"unsupported"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"failed"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"supported","value":"granted","error":"openFailed"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"unsupported","capability":{"requiresRelaunch":false,"supportsRequest":false,"supportsStatusCheck":false},"value":"granted"}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"failed","error":"apiUnavailable","capability":{"requiresRelaunch":false,"supportsRequest":false,"supportsStatusCheck":false}}"#
    )
    assertOperationResultDecodeFails(
      #"{"kind":"failed","error":"apiUnavailable","diagnostic":"ignored"}"#
    )
  }

  func testResultIsEquatableAndHashableWhenValueIsHashable() {
    XCTAssertEqual(
      PermissionOperationResult.supported(PermissionStatus.granted),
      .supported(.granted)
    )
    XCTAssertNotEqual(
      PermissionOperationResult.supported(PermissionStatus.granted),
      .supported(.denied)
    )
    XCTAssertEqual(
      Set([
        PermissionOperationResult.supported(PermissionStatus.granted),
        PermissionOperationResult.supported(PermissionStatus.granted),
      ]).count,
      1
    )
  }

  private func assertOperationResultDecodeFails(
    _ json: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(
        PermissionOperationResult<PermissionStatus>.self,
        from: Data(json.utf8)
      ),
      file: file,
      line: line
    )
  }
}

private struct NonEquatableSendable: Sendable {
  let value: Int
}
