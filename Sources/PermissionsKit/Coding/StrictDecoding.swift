struct AnyPermissionCodingKey: CodingKey {
  let stringValue: String
  let intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    intValue = nil
  }

  init?(intValue: Int) {
    stringValue = String(intValue)
    self.intValue = intValue
  }

  static func rejectUnknownKeys<AllowedKey: CodingKey & CaseIterable>(
    in decoder: Decoder,
    allowedKeys _: AllowedKey.Type,
    debugDescription: String
  ) throws {
    let container = try decoder.container(keyedBy: Self.self)
    let allowedKeyNames = Set(AllowedKey.allCases.map(\.stringValue))

    for key in container.allKeys where !allowedKeyNames.contains(key.stringValue) {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: debugDescription
      )
    }
  }
}
