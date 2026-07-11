/// Options that affect permission status checks, requests, and metadata lookup.
public enum PermissionOptions: Sendable, Hashable {
  /// Use the default behavior for the permission type.
  case none
  /// Options for notification authorization.
  case notifications(NotificationRequestOptions)
  /// Access level for Photos authorization.
  case photos(PhotoAccessLevel)

  /// Returns whether these options apply to the given permission type.
  ///
  /// ``none`` is valid for every permission and resolves to the permission's default behavior.
  public func applies(to type: PermissionType) -> Bool {
    switch (self, type) {
    case (.none, _), (.notifications, .notifications), (.photos, .photos):
      true
    default:
      false
    }
  }
}

extension PermissionOptions: Codable {
  private enum CodingKeys: String, CodingKey, CaseIterable {
    case kind
    case notificationOptions
    case photoAccessLevel
  }

  private enum Kind: String, Codable {
    case none
    case notifications
    case photos
  }

  /// Decodes permission options from an explicit option kind and payload, rejecting invalid
  /// payload shapes.
  public init(from decoder: Decoder) throws {
    try Self.rejectUnknownKeys(in: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)

    switch try container.decode(Kind.self, forKey: .kind) {
    case .none:
      try Self.requireNoPayload(in: container)
      self = .none
    case .notifications:
      try Self.requireOnlyPayload(.notificationOptions, in: container)
      let options = try container.decode(
        NotificationRequestOptions.self,
        forKey: .notificationOptions
      )
      self = .notifications(options)
    case .photos:
      try Self.requireOnlyPayload(.photoAccessLevel, in: container)
      let accessLevel = try container.decode(PhotoAccessLevel.self, forKey: .photoAccessLevel)
      self = .photos(accessLevel)
    }
  }

  /// Encodes permission options with an explicit option kind and payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .none:
      try container.encode(Kind.none, forKey: .kind)
    case .notifications(let options):
      try container.encode(Kind.notifications, forKey: .kind)
      try container.encode(options, forKey: .notificationOptions)
    case .photos(let level):
      try container.encode(Kind.photos, forKey: .kind)
      try container.encode(level, forKey: .photoAccessLevel)
    }
  }

  private static func requireNoPayload(
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    try requireOnlyPayload(nil, in: container)
  }

  private static func requireOnlyPayload(
    _ expectedKey: CodingKeys?,
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    for key in [CodingKeys.notificationOptions, .photoAccessLevel] where key != expectedKey {
      guard container.contains(key) else { continue }
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Unexpected payload key for permission options."
      )
    }
  }

  private static func rejectUnknownKeys(in decoder: Decoder) throws {
    try AnyPermissionCodingKey.rejectUnknownKeys(
      in: decoder,
      allowedKeys: CodingKeys.self,
      debugDescription: "Unknown permission options key."
    )
  }
}
