import Foundation

// MARK: - Core Protocols

protocol SafeValue: Codable, Sendable {
    static var defaultValue: Self { get }
}

protocol DefaultProvider {
    static func defaultInstance() -> Self
}

protocol DomainConvertible: Codable, SafeValue, DefaultProvider, Sendable {
    associatedtype DomainModel: Sendable
    func toDomain() -> DomainModel?
}

extension DomainConvertible {
    static var defaultValue: Self { defaultInstance() }
}

// MARK: - SafeValue Conformances

extension String: SafeValue, DefaultProvider {
    static var defaultValue: String { "" }
    static func defaultInstance() -> String { "" }
}

extension Int: SafeValue, DefaultProvider {
    static var defaultValue: Int { 0 }
    static func defaultInstance() -> Int { 0 }
}

extension Double: SafeValue, DefaultProvider {
    static var defaultValue: Double { 0.0 }
    static func defaultInstance() -> Double { 0.0 }
}

extension Bool: SafeValue, DefaultProvider {
    static var defaultValue: Bool { false }
    static func defaultInstance() -> Bool { false }
}

extension Array: SafeValue where Element: SafeValue {
    static var defaultValue: [Element] { [] }
}

extension Array: DefaultProvider {
    static func defaultInstance() -> Self { [] }
}

// MARK: - SafeBox

@propertyWrapper
struct SafeBox<T: SafeValue>: Codable, Sendable {
    var wrappedValue: T

    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let path = decoder.codingPath.map(\.stringValue).joined(separator: " -> ")

        if container.decodeNil() {
            self.wrappedValue = T.defaultValue
            demoLog("  🛡️ [Null 救災] \(path) → 補上預設值「\(T.defaultValue)」")
            return
        }

        if let normal = try? container.decode(T.self) {
            self.wrappedValue = normal
            return
        }

        let (rescuedValue, actualDesc) = Self.performTypeRescue(from: container)

        if let val = rescuedValue {
            self.wrappedValue = val
            demoLog("  ⚠️ [型別錯置] \(path): \(actualDesc) → \(String(describing: T.self))(\(val))")
        } else if let provider = T.self as? DefaultProvider.Type,
                  let instance = provider.defaultInstance() as? T {
            self.wrappedValue = instance
            demoLog("  ⚠️ [結構錯誤] \(path): 結構不符，補上預設實體")
        } else {
            self.wrappedValue = T.defaultValue
            demoLog("  ⚠️ [解析失敗] \(path): 無法修復，使用 defaultValue「\(T.defaultValue)」")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    private static func performTypeRescue(from container: SingleValueDecodingContainer) -> (T?, String) {
        var resultValue: T?
        var actualTypeDesc = "未知型別"

        if T.self is String.Type {
            if let v = try? container.decode(Int.self) {
                resultValue = "\(v)" as? T
                actualTypeDesc = "Int(\(v))"
            } else if let v = try? container.decode(Double.self) {
                resultValue = "\(v)" as? T
                actualTypeDesc = "Double(\(v))"
            }
        } else if T.self is Double.Type {
            if let v = try? container.decode(String.self), let d = Double(v) {
                resultValue = d as? T
                actualTypeDesc = "String(\"\(v)\")"
            } else if let v = try? container.decode(Int.self) {
                resultValue = Double(v) as? T
                actualTypeDesc = "Int(\(v))"
            }
        } else if T.self is Int.Type {
            if let v = try? container.decode(String.self), let i = Int(v) {
                resultValue = i as? T
                actualTypeDesc = "String(\"\(v)\")"
            } else if let v = try? container.decode(Double.self) {
                resultValue = Int(v) as? T
                actualTypeDesc = "Double(\(v))"
            }
        } else if T.self is Bool.Type {
            if let v = try? container.decode(String.self) {
                let truthy = ["1", "y", "yes", "true", "on", "checked"]
                resultValue = truthy.contains(v.lowercased()) as? T
                actualTypeDesc = "String(\"\(v)\")"
            } else if let v = try? container.decode(Int.self) {
                resultValue = (v == 1) as? T
                actualTypeDesc = "Int(\(v))"
            }
        }

        return (resultValue, actualTypeDesc)
    }
}

// MARK: - SafeArray

@propertyWrapper
struct SafeArray<T: SafeValue & DefaultProvider>: Codable, Sendable {
    var wrappedValue: [T]

    init(wrappedValue: [T]) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [T] = []

        while !container.isAtEnd {
            do {
                let value = try container.decode(T.self)
                elements.append(value)
            } catch {
                elements.append(T.defaultInstance())
                _ = try? container.decode(EmptyCodable.self)
                demoLog("  ⚠️ [陣列損毀修復] 發現髒資料，已補上預設物件")
            }
        }
        self.wrappedValue = elements
    }

    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

private struct EmptyCodable: Codable {}

// MARK: - KeyedDecodingContainer Extensions

extension KeyedDecodingContainer {
    func decode<T: SafeValue>(_ type: SafeBox<T>.Type, forKey key: Key) throws -> SafeBox<T> {
        if let box = try decodeIfPresent(type, forKey: key) {
            return box
        }
        let path = (codingPath + [key]).map(\.stringValue).joined(separator: " -> ")
        demoLog("  🧨 [欄位缺失] \(path)：後端省略此 Key，補上預設值「\(T.defaultValue)」")
        return SafeBox(wrappedValue: T.defaultValue)
    }

    func decode<T: SafeValue & DefaultProvider>(_ type: SafeArray<T>.Type, forKey key: Key) throws -> SafeArray<T> {
        if let box = try decodeIfPresent(type, forKey: key) {
            return box
        }
        let path = (codingPath + [key]).map(\.stringValue).joined(separator: " -> ")
        demoLog("  🧨 [陣列缺失] \(path)：補上空陣列 []")
        return SafeArray(wrappedValue: [])
    }
}
