import Foundation

// MARK: - BaseResponseProtocol

protocol BaseResponseProtocol: Decodable, Sendable {
    associatedtype Payload: Codable & Sendable
    var isSuccess: Bool { get }
    var message: String { get }
    var result: ShieldedResponse<Payload> { get }
}

// MARK: - ShieldedResponse

struct ShieldedResponse<T: Codable & Sendable>: Codable, Sendable {
    let value: T

    init(from decoder: Decoder) throws {
        let decodePath = decoder.userInfo[.decodePath] as? [String] ?? []

        do {
            let targetDecoder = try Self.navigate(to: decodePath, from: decoder)
            try Self.validateTopLevelStructure(for: T.self, in: targetDecoder)
            self.value = try T(from: targetDecoder)
        } catch NavigationSignal.pathValueIsNull {
            if let safeType = T.self as? SafeValue.Type,
               let defaultValue = safeType.defaultValue as? T {
                self.value = defaultValue
                let path = decodePath.joined(separator: " -> ")
                demoLog("  🛡️ [Null 路徑救災] 路徑「\(path)」值為 null，補上預設值")
            } else {
                throw DecodingError.valueNotFound(
                    T.self,
                    .init(codingPath: decoder.codingPath, debugDescription: "Path value is null")
                )
            }
        }
    }

    private static func validateTopLevelStructure<V>(for type: V.Type, in decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: AnyCodingKey.self)
        let unkeyedContainer = try? decoder.unkeyedContainer()
        let isJSONMap = container != nil
        let isJSONArray = unkeyedContainer != nil
        let expectedIsArray = String(describing: V.self).hasPrefix("Array")

        if expectedIsArray, isJSONMap {
            demoLog("  ❌ [結構處刑] 預期 Array，但收到 Map")
            throw DecodingError.typeMismatch(V.self, .init(
                codingPath: decoder.codingPath,
                debugDescription: "預期 Array，但收到 Map"
            ))
        }
        if !expectedIsArray, isJSONArray {
            demoLog("  ❌ [結構處刑] 預期 \(V.self)，但收到 Array")
            throw DecodingError.typeMismatch(V.self, .init(
                codingPath: decoder.codingPath,
                debugDescription: "預期 \(V.self)，但收到 Array"
            ))
        }
    }

    private static func navigate(to keys: [String], from decoder: Decoder) throws -> Decoder {
        var currentDecoder = decoder
        for keyString in keys {
            let container = try currentDecoder.container(keyedBy: AnyCodingKey.self)
            let key = AnyCodingKey(keyString)
            if container.contains(key) {
                if try container.decodeNil(forKey: key) {
                    throw NavigationSignal.pathValueIsNull
                }
                currentDecoder = try container.superDecoder(forKey: key)
            } else {
                throw DecodingError.keyNotFound(
                    key,
                    .init(
                        codingPath: currentDecoder.codingPath,
                        debugDescription: "找不到路徑節點: \(keyString)"
                    )
                )
            }
        }
        return currentDecoder
    }
}

// MARK: - Supporting Types

struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

extension CodingUserInfoKey {
    static let decodePath: CodingUserInfoKey = .init(rawValue: "decodePath")!
    static let responseCode: CodingUserInfoKey = .init(rawValue: "responseCode")!
}

private enum NavigationSignal: Error {
    case pathValueIsNull
}
