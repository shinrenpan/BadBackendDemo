import Foundation

// MARK: - APIError

enum APIError: Error {
    case serverError(code: Int, message: String)

    var localizedDescription: String {
        switch self {
        case let .serverError(code, message): "\(message) (\(code))"
        }
    }
}

// MARK: - BaseResponse

struct BaseResponse<T: Codable & Sendable>: BaseResponseProtocol, Sendable {
    let isSuccess: Bool
    let message: String
    let result: ShieldedResponse<T>

    enum CodingKeys: String, CodingKey {
        case message
    }

    init(from decoder: Decoder, statusCode: Int) throws {
        self.isSuccess = (statusCode == 200)
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        self.message = (try? container?.decodeIfPresent(String.self, forKey: .message))
            ?? (isSuccess ? "Success." : "Unknown error.")

        if !isSuccess {
            demoLog("  🚨 [快速熔斷] HTTP \(statusCode)：\(message)，不嘗試解析 data")
            throw APIError.serverError(code: statusCode, message: message)
        }

        self.result = try ShieldedResponse<T>(from: decoder)
    }

    init(from decoder: Decoder) throws {
        let responseCode = decoder.userInfo[.responseCode] as? Int ?? 200
        try self.init(from: decoder, statusCode: responseCode)
    }
}
