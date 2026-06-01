import Foundation

// MARK: - Demo DTOs

private struct ArticleDTO: DomainConvertible {
    @SafeBox var title: String
    @SafeBox var views: Int

    static func defaultInstance() -> ArticleDTO {
        .init(title: "（損毀文章）", views: 0)
    }

    func toDomain() -> String? {
        "「\(title)」views=\(views)"
    }
}

private struct FeedDTO: DomainConvertible {
    @SafeArray var articles: [ArticleDTO]

    static func defaultInstance() -> FeedDTO {
        .init(articles: [])
    }

    func toDomain() -> String? {
        articles.map { $0.toDomain() ?? "nil" }.joined(separator: "\n      ")
    }
}

// MARK: - Scene

struct Scene2_SafeArray {
    static func run() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📦  Scene 2：SafeArray 陣列救災")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        test1_CorruptedElement()
        test2_MissingArray()
    }

    private static func decode(_ json: String) -> FeedDTO? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(FeedDTO.self, from: data)
    }

    private static func test1_CorruptedElement() {
        print("\n[測試 2-1] 陣列中有損毀元素（第 2 筆是字串）")
        let json = """
        {
          "articles": [
            { "title": "Swift 教學", "views": 100 },
            "CORRUPTED_DATA",
            { "title": "iOS 架構設計", "views": 200 }
          ]
        }
        """
        print("  輸入: 3 筆，第 2 筆是字串（損毀）")
        if let dto = decode(json) {
            print("  解析出 \(dto.articles.count) 筆（損毀元素補上預設實體）:")
            print("     ", dto.toDomain() ?? "nil")
            print("  ✅ 整個陣列沒有崩潰")
        }
    }

    private static func test2_MissingArray() {
        print("\n[測試 2-2] articles 欄位完全消失")
        let json = "{}"
        print("  輸入:", json)
        if let dto = decode(json) {
            print("  articles.count =", dto.articles.count, "（自動補空陣列）✅")
        }
    }
}
