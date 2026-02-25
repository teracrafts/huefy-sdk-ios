import Foundation

/// Internal HTTP client that wraps `URLSession` with retry logic and
/// circuit breaking for the Huefy Swift SDK.
final class HttpClient: @unchecked Sendable {

    private let apiKey: String
    private let baseUrl: String
    private let timeout: TimeInterval
    private let retryHandler: RetryHandler
    private let circuitBreaker: CircuitBreaker
    private let session: URLSession
    private let config: HuefyConfig

    // MARK: - Initialisation

    init(apiKey: String, config: HuefyConfig) {
        self.apiKey = apiKey
        self.baseUrl = config.baseUrl.hasSuffix("/")
            ? String(config.baseUrl.dropLast())
            : config.baseUrl
        self.timeout = config.timeout
        self.config = config

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.timeoutIntervalForResource = config.timeout * 2
        self.session = URLSession(configuration: sessionConfig)

        self.retryHandler = RetryHandler(config: config.retryConfig)
        self.circuitBreaker = CircuitBreaker(config: config.circuitBreakerConfig)
    }

    // MARK: - Public API

    /// Sends an HTTP request to the API, wrapped with circuit breaker and
    /// retry logic.
    ///
    /// - Parameters:
    ///   - method: HTTP method (GET, POST, PUT, PATCH, DELETE).
    ///   - path: API path relative to the base URL.
    ///   - body: Optional request body data.
    ///   - headers: Additional headers to include.
    /// - Returns: The raw response data.
    /// - Throws: ``HuefyError`` on failure.
    func request(
        method: String,
        path: String,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> Data {
        let fullPath = path.hasPrefix("/") ? path : "/\(path)"
        let urlString = "\(baseUrl)\(fullPath)"

        guard let url = URL(string: urlString) else {
            throw HuefyError(
                code: .configInvalidUrl,
                message: "Invalid URL: \(urlString)"
            )
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.timeoutInterval = timeout

        // Standard headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue(sdkVersion, forHTTPHeaderField: "X-SDK-Version")
        urlRequest.setValue(
            "huefy-swift/\(sdkVersion)",
            forHTTPHeaderField: "User-Agent"
        )
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        // Request signing
        if config.enableRequestSigning {
            let timestamp = String(Int(Date().timeIntervalSince1970))
            urlRequest.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
            urlRequest.setValue(
                String(apiKey.prefix(8)),
                forHTTPHeaderField: "X-Key-Id"
            )
            let payload = [method, fullPath, timestamp, body.map { String(data: $0, encoding: .utf8) ?? "" } ?? ""]
                .joined(separator: "\n")
            let signature = Security.generateHMACSHA256(message: payload, key: apiKey)
            urlRequest.setValue(signature, forHTTPHeaderField: "X-Signature")
        }

        // Merge caller-supplied headers
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            urlRequest.httpBody = body
        }

        // Execute with retry + circuit breaker
        return try await retryHandler.execute { [self] in
            try await circuitBreaker.execute {
                try await self.performRequest(urlRequest, method: method, path: fullPath)
            }
        }
    }

    /// Resets the circuit breaker to its initial closed state.
    func close() {
        Task {
            await circuitBreaker.reset()
        }
    }

    // MARK: - Private

    private func performRequest(
        _ request: URLRequest,
        method: String,
        path: String
    ) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw HuefyError.timeoutError(
                    "Request to \(method) \(path) timed out after \(Int(timeout))s"
                )
            case .notConnectedToInternet, .networkConnectionLost:
                throw HuefyError.networkError(
                    "Network error during \(method) \(path)",
                    cause: error
                )
            default:
                throw HuefyError.networkError(
                    "Request failed: \(error.localizedDescription)",
                    cause: error
                )
            }
        } catch {
            throw HuefyError.networkError(
                "Unexpected error during \(method) \(path)",
                cause: error
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuefyError(
                code: .networkError,
                message: "Invalid response type"
            )
        }

        let statusCode = httpResponse.statusCode

        guard (200...299).contains(statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw HuefyError.fromResponse(statusCode: statusCode, body: bodyString)
        }

        // 204 No Content
        if statusCode == 204 {
            return Data("{}".utf8)
        }

        return data
    }
}
