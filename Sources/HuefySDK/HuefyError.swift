import Foundation

/// Errors that can occur when using the Huefy SDK
public enum HuefyError: Error, LocalizedError, Equatable {
    case invalidApiKey
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case templateNotFound(String)
    case validationError(String, [String: Any]?)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case providerError(String, String?)
    case serverError(Int, String?)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidApiKey:
            return "Invalid API key provided"
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .templateNotFound(let templateKey):
            return "Template '\(templateKey)' not found"
        case .validationError(let message, _):
            return "Validation error: \(message)"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Retry after \(retryAfter) seconds"
            }
            return "Rate limit exceeded"
        case .providerError(let provider, let code):
            return "Provider '\(provider)' error" + (code.map { " (\($0))" } ?? "")
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode)" + (message.map { ": \($0)" } ?? "")
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    public static func == (lhs: HuefyError, rhs: HuefyError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidApiKey, .invalidApiKey),
             (.invalidURL, .invalidURL):
            return true
        case (.templateNotFound(let lhsKey), .templateNotFound(let rhsKey)):
            return lhsKey == rhsKey
        case (.validationError(let lhsMsg, _), .validationError(let rhsMsg, _)):
            return lhsMsg == rhsMsg
        case (.rateLimitExceeded(let lhsRetry), .rateLimitExceeded(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.providerError(let lhsProv, let lhsCode), .providerError(let rhsProv, let rhsCode)):
            return lhsProv == rhsProv && lhsCode == rhsCode
        case (.serverError(let lhsCode, let lhsMsg), .serverError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        case (.unknown(let lhsMsg), .unknown(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}