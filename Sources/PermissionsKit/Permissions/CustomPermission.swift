/// Host-defined permission descriptor with validated identifier and capability metadata.
public struct CustomPermission: Sendable, Hashable {
  /// Reason a host-defined custom permission identifier is invalid.
  public enum IdentifierValidationError: Error, Equatable, Hashable, Sendable {
    /// The identifier is empty.
    case empty
    /// The identifier matches a built-in ``PermissionType`` identifier.
    case reserved
    /// The identifier does not contain at least two `.`-separated segments.
    case missingNamespace
    /// One or more namespace segments are empty.
    case emptySegment
    /// A segment starts or ends with a character other than a lowercase ASCII letter or digit.
    case invalidSegmentBoundary
    /// The identifier contains a character outside lowercase ASCII letters, digits, `_`, `-`, and `.`.
    case invalidCharacter
  }

  /// Host-owned namespaced ASCII identifier used by ``PermissionType/custom(_:)``.
  public let identifier: String
  /// Capability metadata supplied by the host app.
  public let capability: PermissionCapability
  /// Info.plist usage description keys required by the host-defined permission.
  ///
  /// Duplicate keys are removed during construction while preserving their first occurrence.
  public let usageDescriptionKeys: [UsageDescriptionKey]

  /// Creates a custom permission descriptor or throws ``IdentifierValidationError``.
  ///
  /// Duplicate `usageDescriptionKeys` are removed while preserving their first occurrence.
  public init(
    identifier: String,
    capability: PermissionCapability,
    usageDescriptionKeys: [UsageDescriptionKey] = []
  ) throws {
    if let error = Self.validationError(for: identifier) {
      throw error
    }
    self.identifier = identifier
    self.capability = capability
    self.usageDescriptionKeys = Self.uniqueUsageDescriptionKeys(usageDescriptionKeys)
  }

  /// Returns the first validation error for a custom identifier, or `nil` when valid.
  ///
  /// Validation is intentionally strict and does not trim or normalize input. Callers that accept
  /// user-entered identifiers should trim and canonicalize before asking PermissionsKit to validate
  /// them. Construction uses this same validation.
  public static func validationError(
    for identifier: String
  ) -> IdentifierValidationError? {
    guard identifier.isEmpty == false else { return .empty }
    guard reservedCustomPermissionIdentifiers.contains(identifier) == false else {
      return .reserved
    }
    guard identifier.unicodeScalars.allSatisfy(isAllowedIdentifierScalar) else {
      return .invalidCharacter
    }
    let segments = identifier.split(separator: ".", omittingEmptySubsequences: false)
    guard segments.count >= 2 else { return .missingNamespace }
    guard segments.allSatisfy({ $0.isEmpty == false }) else {
      return .emptySegment
    }
    guard segments.allSatisfy(hasLowercaseASCIIAlphanumericSegmentBoundary) else {
      return .invalidSegmentBoundary
    }
    return nil
  }

  /// Compares permission identity by identifier.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.identifier == rhs.identifier
  }

  /// Hashes permission identity by identifier.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(identifier)
  }

  private static let reservedCustomPermissionIdentifiers = Set(PermissionType.builtIn.map(\.id))

  private static func uniqueUsageDescriptionKeys(
    _ keys: [UsageDescriptionKey]
  ) -> [UsageDescriptionKey] {
    var seen: Set<UsageDescriptionKey> = []
    var unique: [UsageDescriptionKey] = []
    for key in keys where seen.insert(key).inserted {
      unique.append(key)
    }
    return unique
  }

  private static func isAllowedIdentifierScalar(_ scalar: Unicode.Scalar) -> Bool {
    isLowercaseASCIIAlphanumeric(scalar) || scalar == "_" || scalar == "-" || scalar == "."
  }

  private static func hasLowercaseASCIIAlphanumericSegmentBoundary(
    _ segment: Substring
  ) -> Bool {
    guard let first = segment.unicodeScalars.first,
      let last = segment.unicodeScalars.last,
      isLowercaseASCIIAlphanumeric(first),
      isLowercaseASCIIAlphanumeric(last)
    else { return false }
    return true
  }

  private static func isLowercaseASCIIAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
    asciiDigitScalarValues.contains(scalar.value)
      || lowercaseASCIILetterScalarValues.contains(scalar.value)
  }

  private static let asciiDigitScalarValues =
    UInt32(UInt8(ascii: "0"))...UInt32(UInt8(ascii: "9"))
  private static let lowercaseASCIILetterScalarValues =
    UInt32(UInt8(ascii: "a"))...UInt32(UInt8(ascii: "z"))
}
