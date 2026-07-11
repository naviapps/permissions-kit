import XCTest

final class PermissionsKitAppKitSourceBoundaryTests: XCTestCase {
  func testPlatformFrameworkImportsStayInLiveEnvironmentAdapter() throws {
    let sourceFiles = try Self.swiftSourceFiles(relativeRoot: "Sources/PermissionsKitAppKit")
    let liveEnvironmentPath =
      "Sources/PermissionsKitAppKit/Checking/PermissionEnvironment+Live.swift"
    let platformModules = [
      "AppKit",
      "ApplicationServices",
      "AVFoundation",
      "Contacts",
      "EventKit",
      "Photos",
      "Speech",
      "UserNotifications",
    ]

    for (relativePath, source) in sourceFiles where relativePath != liveEnvironmentPath {
      for module in platformModules {
        XCTAssertFalse(
          source.containsRegex(#"(?m)^import\s+\#(module)\b"#),
          "\(module) imports belong in PermissionEnvironment+Live.swift, not \(relativePath)."
        )
      }
    }
  }

  private static func swiftSourceFiles(relativeRoot: String) throws -> [(String, String)] {
    let root = repositoryRoot().appendingPathComponent(relativeRoot)
    guard
      let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil
      )
    else { return [] }

    return
      try enumerator
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == "swift" }
      .sorted { $0.path < $1.path }
      .map { fileURL in
        let relativePath = fileURL.path.replacingOccurrences(
          of: repositoryRoot().path + "/",
          with: ""
        )
        return (relativePath, try String(contentsOf: fileURL, encoding: .utf8))
      }
  }

  private static func repositoryRoot() -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }

}

private extension String {
  func containsRegex(_ pattern: String) -> Bool {
    range(of: pattern, options: .regularExpression) != nil
  }
}
