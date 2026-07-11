/// Generic result for permission-related operations.
public enum PermissionOperationResult<Value: Sendable>: Sendable {
  /// The operation is supported and returned a value.
  case supported(Value)
  /// The operation is not supported; capability metadata is provided for fallback UI.
  case unsupported(PermissionCapability)
  /// The operation failed.
  case failed(PermissionError)
}

extension PermissionOperationResult: Codable where Value: Codable {
  private enum CodingKeys: String, CodingKey, CaseIterable {
    case kind
    case value
    case capability
    case error
  }

  private enum Kind: String, Codable {
    case supported
    case unsupported
    case failed
  }

  /// Decodes a permission operation result from explicit case and payload keys, rejecting invalid
  /// payload shapes.
  public init(from decoder: Decoder) throws {
    try Self.rejectUnknownKeys(in: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)

    switch try container.decode(Kind.self, forKey: .kind) {
    case .supported:
      try Self.requireOnlyPayload(.value, in: container)
      self = .supported(try container.decode(Value.self, forKey: .value))
    case .unsupported:
      try Self.requireOnlyPayload(.capability, in: container)
      self = .unsupported(try container.decode(PermissionCapability.self, forKey: .capability))
    case .failed:
      try Self.requireOnlyPayload(.error, in: container)
      self = .failed(try container.decode(PermissionError.self, forKey: .error))
    }
  }

  /// Encodes a permission operation result with explicit case and payload keys.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .supported(let value):
      try container.encode(Kind.supported, forKey: .kind)
      try container.encode(value, forKey: .value)
    case .unsupported(let capability):
      try container.encode(Kind.unsupported, forKey: .kind)
      try container.encode(capability, forKey: .capability)
    case .failed(let error):
      try container.encode(Kind.failed, forKey: .kind)
      try container.encode(error, forKey: .error)
    }
  }

  private static func requireOnlyPayload(
    _ expectedKey: CodingKeys,
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    for key in [CodingKeys.value, .capability, .error] where key != expectedKey {
      guard container.contains(key) else { continue }
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Unexpected payload key for permission operation result."
      )
    }
  }

  private static func rejectUnknownKeys(in decoder: Decoder) throws {
    try AnyPermissionCodingKey.rejectUnknownKeys(
      in: decoder,
      allowedKeys: CodingKeys.self,
      debugDescription: "Unknown permission operation result key."
    )
  }
}

extension PermissionOperationResult: Equatable where Value: Equatable {}
extension PermissionOperationResult: Hashable where Value: Hashable {}
