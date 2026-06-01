import Foundation

// MARK: - Demo DTO

private struct MeDTO: DomainConvertible {
    @SafeBox var id: Int
    @SafeBox var username: String

    static func defaultInstance() -> MeDTO {
        .init(id: 0, username: "")
    }

    func toDomain() -> String? {
        "id=\(id)  username=\"\(username)\""
    }
}

// MARK: - Scene

struct Scene4_Fuse {
    static func run() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("⚡ Scene 4：BaseResponse 快速熔斷")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        test1_Success()
        test2_Unauthorized()
        test3_ServerError()
    }

    private static func decode(_ json: String, statusCode: Int, path: [String] = ["data"]) -> Result<MeDTO, Error> {
        guard let data = json.data(using: .utf8) else {
            return .failure(NSError(domain: "", code: -1))
        }
        let decoder = JSONDecoder()
        decoder.userInfo[.responseCode] = statusCode
        decoder.userInfo[.decodePath] = path
        do {
            let response = try decoder.decode(BaseResponse<MeDTO>.self, from: data)
            return .success(response.result.value)
        } catch {
            return .failure(error)
        }
    }

    private static func test1_Success() {
        print("\n[測試 4-1] HTTP 200 → 正常解析")
        let json = """
        { "data": { "id": 42, "username": "shinren.pan" } }
        """
        print("  HTTP: 200")
        print("  輸入:", json)
        switch decode(json, statusCode: 200) {
        case let .success(dto):
            print("  輸出:", dto.toDomain() ?? "nil", "✅")
        case let .failure(error):
            print("  錯誤:", error.localizedDescription, "❌")
        }
    }

    private static func test2_Unauthorized() {
        print("\n[測試 4-2] HTTP 401 → 熔斷（data 欄位根本不存在也沒事）")
        let json = """
        { "message": "Unauthorized" }
        """
        print("  HTTP: 401")
        print("  輸入:", json, "← 沒有 data 欄位")
        switch decode(json, statusCode: 401) {
        case let .success(dto):
            print("  輸出:", dto.toDomain() ?? "nil", "❌（不應走到這）")
        case let .failure(error as APIError):
            print("  拋出 APIError：", error.localizedDescription, "✅")
        case let .failure(error):
            print("  拋出錯誤：", error.localizedDescription)
        }
    }

    private static func test3_ServerError() {
        print("\n[測試 4-3] HTTP 500 → 熔斷並帶回後端訊息")
        let json = """
        { "message": "Internal Server Error" }
        """
        print("  HTTP: 500")
        print("  輸入:", json)
        switch decode(json, statusCode: 500) {
        case let .success(dto):
            print("  輸出:", dto.toDomain() ?? "nil", "❌（不應走到這）")
        case let .failure(error as APIError):
            print("  拋出 APIError：", error.localizedDescription, "✅")
        case let .failure(error):
            print("  拋出錯誤：", error.localizedDescription)
        }
    }
}
