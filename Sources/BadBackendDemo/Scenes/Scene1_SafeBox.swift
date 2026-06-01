import Foundation

// MARK: - Demo DTO

private struct ProductDTO: DomainConvertible {
    @SafeBox var id: String
    @SafeBox var price: Double
    @SafeBox var inStock: Bool
    @SafeBox var count: Int

    static func defaultInstance() -> ProductDTO {
        .init(id: "", price: 0.0, inStock: false, count: 0)
    }

    func toDomain() -> String? {
        "id=\"\(id)\"  price=\(price)  inStock=\(inStock)  count=\(count)"
    }
}

// MARK: - Scene

struct Scene1_SafeBox {
    static func run() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🛡  Scene 1：SafeBox 型別救災")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        test1_NullValues()
        test2_TypeMismatch()
        test3_MissingKeys()
        test4_BoolRescue()
    }

    private static func decode(_ json: String) -> ProductDTO? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ProductDTO.self, from: data)
    }

    private static func test1_NullValues() {
        print("\n[測試 1-1] null 值與欄位缺失，結果相同")
        let json = """
        { "id": null, "price": null, "inStock": null, "count": null }
        """
        print("  輸入:", json)
        print("  提示: decodeIfPresent 對 null 與 key 缺失的處理相同，皆補上預設值")
        if let result = decode(json)?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }

    private static func test2_TypeMismatch() {
        print("\n[測試 1-2] 型別全部錯置（後端人格分裂）")
        let json = """
        { "id": 123, "price": "49.9", "inStock": 1, "count": "5" }
        """
        print("  輸入:", json)
        if let result = decode(json)?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }

    private static func test3_MissingKeys() {
        print("\n[測試 1-3] 欄位全部消失（薛丁格的 JSON）")
        let json = "{}"
        print("  輸入:", json)
        if let result = decode(json)?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }

    private static func test4_BoolRescue() {
        print("\n[測試 1-4] Bool 創意大賽（\"Y\" / \"on\" / \"checked\"）")
        let cases: [(String, String)] = [
            ("\"Y\"",       #"{ "id": "a", "price": 1.0, "inStock": "Y", "count": 1 }"#),
            ("\"on\"",      #"{ "id": "b", "price": 1.0, "inStock": "on", "count": 1 }"#),
            ("\"checked\"", #"{ "id": "c", "price": 1.0, "inStock": "checked", "count": 1 }"#),
        ]
        for (label, json) in cases {
            print("  inStock =", label)
            if let result = decode(json)?.toDomain() {
                print("  輸出:", result, "✅")
            }
        }
    }
}
