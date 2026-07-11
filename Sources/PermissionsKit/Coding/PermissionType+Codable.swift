import Foundation

extension PermissionType: Codable {
  private enum CodingKeys: String, CodingKey, CaseIterable {
    case kind
    case id
    case custom
  }

  private enum Kind: String, Codable {
    case builtIn
    case custom
  }

  private struct CustomPayload: Codable {
    private enum CodingKeys: String, CodingKey, CaseIterable {
      case identifier
      case capability
      case usageDescriptionKeys
    }

    let identifier: String
    let capability: CapabilityPayload
    let usageDescriptionKeys: [UsageDescriptionKey]

    init(
      identifier: String,
      capability: CapabilityPayload,
      usageDescriptionKeys: [UsageDescriptionKey]
    ) {
      self.identifier = identifier
      self.capability = capability
      self.usageDescriptionKeys = usageDescriptionKeys
    }

    init(from decoder: Decoder) throws {
      try Self.rejectUnknownKeys(in: decoder)
      let container = try decoder.container(keyedBy: CodingKeys.self)

      identifier = try container.decode(String.self, forKey: .identifier)
      capability = try container.decode(CapabilityPayload.self, forKey: .capability)
      usageDescriptionKeys = try container.decode(
        [UsageDescriptionKey].self,
        forKey: .usageDescriptionKeys
      )
      try Self.requireUniqueUsageDescriptionKeys(usageDescriptionKeys, in: container)
    }

    private static func rejectUnknownKeys(in decoder: Decoder) throws {
      try AnyPermissionCodingKey.rejectUnknownKeys(
        in: decoder,
        allowedKeys: CodingKeys.self,
        debugDescription: "Unknown custom permission payload key."
      )
    }

    private static func requireUniqueUsageDescriptionKeys(
      _ keys: [UsageDescriptionKey],
      in container: KeyedDecodingContainer<CodingKeys>
    ) throws {
      var seen: Set<UsageDescriptionKey> = []
      for key in keys where seen.insert(key).inserted == false {
        throw DecodingError.dataCorruptedError(
          forKey: .usageDescriptionKeys,
          in: container,
          debugDescription: "Duplicate custom permission usage description key."
        )
      }
    }
  }

  private struct CapabilityPayload: Codable {
    private enum CodingKeys: String, CodingKey, CaseIterable {
      case supportsStatusCheck
      case supportsRequest
      case systemSettingsURL
      case requiresRelaunch
    }

    let supportsStatusCheck: Bool
    let supportsRequest: Bool
    let systemSettingsURL: URL?
    let requiresRelaunch: Bool

    var permissionCapability: PermissionCapability {
      PermissionCapability(
        supportsStatusCheck: supportsStatusCheck,
        supportsRequest: supportsRequest,
        systemSettingsURL: systemSettingsURL,
        requiresRelaunch: requiresRelaunch
      )
    }

    init(permissionCapability capability: PermissionCapability) {
      supportsStatusCheck = capability.supportsStatusCheck
      supportsRequest = capability.supportsRequest
      systemSettingsURL = capability.systemSettingsURL
      requiresRelaunch = capability.requiresRelaunch
    }

    init(from decoder: Decoder) throws {
      try Self.rejectUnknownKeys(in: decoder)
      let container = try decoder.container(keyedBy: CodingKeys.self)

      supportsStatusCheck = try container.decode(Bool.self, forKey: .supportsStatusCheck)
      supportsRequest = try container.decode(Bool.self, forKey: .supportsRequest)
      systemSettingsURL =
        if container.contains(.systemSettingsURL) {
          try container.decode(URL.self, forKey: .systemSettingsURL)
        } else {
          nil
        }
      requiresRelaunch = try container.decode(Bool.self, forKey: .requiresRelaunch)
    }

    private static func rejectUnknownKeys(in decoder: Decoder) throws {
      try AnyPermissionCodingKey.rejectUnknownKeys(
        in: decoder,
        allowedKeys: CodingKeys.self,
        debugDescription: "Unknown permission capability payload key."
      )
    }
  }

  /// Decodes a permission type from an explicit type kind and payload, rejecting invalid payload
  /// shapes.
  public init(from decoder: Decoder) throws {
    try Self.rejectUnknownKeys(in: decoder)
    let container = try decoder.container(keyedBy: CodingKeys.self)

    switch try container.decode(Kind.self, forKey: .kind) {
    case .builtIn:
      try Self.requireOnlyTopLevelPayload(.id, in: container)
      let id = try container.decode(String.self, forKey: .id)
      guard let type = Self.builtInByID[id] else {
        throw DecodingError.dataCorruptedError(
          forKey: .id,
          in: container,
          debugDescription: "Unknown built-in permission type identifier."
        )
      }
      self = type
    case .custom:
      try Self.requireOnlyTopLevelPayload(.custom, in: container)
      let payload = try container.decode(CustomPayload.self, forKey: .custom)
      do {
        let custom = try CustomPermission(
          identifier: payload.identifier,
          capability: payload.capability.permissionCapability,
          usageDescriptionKeys: payload.usageDescriptionKeys
        )
        self = .custom(custom)
      } catch {
        throw DecodingError.dataCorruptedError(
          forKey: .custom,
          in: container,
          debugDescription: "Invalid custom permission payload."
        )
      }
    }
  }

  /// Encodes a permission type with an explicit type kind and payload.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .custom(let custom):
      try container.encode(Kind.custom, forKey: .kind)
      try container.encode(
        CustomPayload(
          identifier: custom.identifier,
          capability: CapabilityPayload(permissionCapability: custom.capability),
          usageDescriptionKeys: custom.usageDescriptionKeys
        ),
        forKey: .custom
      )
    default:
      try container.encode(Kind.builtIn, forKey: .kind)
      try container.encode(id, forKey: .id)
    }
  }

  private static let builtInByID = Dictionary(uniqueKeysWithValues: builtIn.map { ($0.id, $0) })

  private static func requireOnlyTopLevelPayload(
    _ expectedKey: CodingKeys,
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    for key in [CodingKeys.id, .custom] where key != expectedKey {
      guard container.contains(key) else { continue }
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "Unexpected payload key for permission type."
      )
    }
  }

  private static func rejectUnknownKeys(in decoder: Decoder) throws {
    try AnyPermissionCodingKey.rejectUnknownKeys(
      in: decoder,
      allowedKeys: CodingKeys.self,
      debugDescription: "Unknown permission type key."
    )
  }
}
