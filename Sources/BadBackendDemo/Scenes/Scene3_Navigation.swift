import Foundation

// MARK: - Demo DTO

private struct UserDTO: DomainConvertible {
    @SafeBox var name: String
    @SafeBox var email: String

    static func defaultInstance() -> UserDTO {
        .init(name: "", email: "")
    }

    func toDomain() -> String? {
        "name=\"\(name)\"  email=\"\(email)\""
    }
}

// MARK: - Scene

struct Scene3_Navigation {
    static func run() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🗺  Scene 3：ShieldedResponse + decodePath 路徑導航")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        test1_DirectDecode()
        test2_SingleLevel()
        test3_TwoLevels()
    }

    private static func decode(_ json: String, path: [String]) -> UserDTO? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.userInfo[.decodePath] = path
        return try? decoder.decode(ShieldedResponse<UserDTO>.self, from: data).value
    }

    private static func test1_DirectDecode() {
        print("\n[測試 3-1] decodePath = []（直球對決）")
        let json = """
        { "name": "Joe", "email": "joe@example.com" }
        """
        print("  輸入:", json)
        print("  decodePath: []")
        if let result = decode(json, path: [])?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }

    private static func test2_SingleLevel() {
        print("\n[測試 3-2] decodePath = [\"data\"]（標準殼）")
        let json = """
        { "data": { "name": "Joe", "email": "joe@example.com" } }
        """
        print("  輸入:", json)
        print("  decodePath: [\"data\"]")
        if let result = decode(json, path: ["data"])?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }

    private static func test3_TwoLevels() {
        print("\n[測試 3-3] decodePath = [\"data\", \"user\"]（腦袋抽風多一層）")
        let json = """
        { "data": { "user": { "name": "Joe", "email": "joe@example.com" } } }
        """
        print("  輸入:", json)
        print("  decodePath: [\"data\", \"user\"]")
        if let result = decode(json, path: ["data", "user"])?.toDomain() {
            print("  輸出:", result, "✅")
        }
    }
}
