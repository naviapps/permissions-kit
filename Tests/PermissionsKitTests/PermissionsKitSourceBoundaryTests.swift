import XCTest

final class PermissionsKitSourceBoundaryTests: XCTestCase {
  func testCoreSourcesRemainPlatformNeutral() throws {
    let sourceText = try Self.sourceFilesText(relativeRoot: "Sources/PermissionsKit")
    let forbiddenImports = [
      "AppKit",
      "AVFoundation",
      "Combine",
      "Contacts",
      "EventKit",
      "Photos",
      "Speech",
      "SwiftUI",
      "UserNotifications",
      "PermissionsKitAppKit",
    ]

    for module in forbiddenImports {
      XCTAssertFalse(
        sourceText.containsRegex(#"(?m)^import\s+\#(module)\b"#),
        "PermissionsKit core sources should stay platform-neutral; \(module) belongs outside the core target."
      )
    }
  }

  private static func repositoryRoot() -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

  private static func sourceFilesText(relativeRoot: String) throws -> String {
    let sourcesURL = repositoryRoot().appendingPathComponent(relativeRoot)
    let fileURLs =
      FileManager.default
      .enumerator(at: sourcesURL, includingPropertiesForKeys: nil)?
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == "swift" } ?? []

    XCTAssertFalse(fileURLs.isEmpty, "\(relativeRoot) should contain source files.")
    return try fileURLs.map { try String(contentsOf: $0, encoding: .utf8) }.joined(separator: "\n")
  }

}

private extension String {
  func containsRegex(_ pattern: String) -> Bool {
    range(of: pattern, options: .regularExpression) != nil
  }
}
