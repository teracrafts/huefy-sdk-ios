import Foundation
#if canImport(Combine)
import Combine
#endif

/// Configuration for the Huefy client
public struct HuefyConfiguration {
    /// Production and local endpoints
    public static let productionHTTPEndpoint = "https://api.huefy.dev/api/v1/sdk"
    public static let localHTTPEndpoint = "http://localhost:8080/api/v1/sdk"

    public let apiKey: String
    public let customBaseURL: URL?
    public let local: Bool
    public let timeout: TimeInterval
    public let retryAttempts: Int
    public let retryDelay: TimeInterval

    /// The resolved base URL based on configuration
    public var baseURL: URL {
        if let custom = customBaseURL {
            return custom
        }
        let urlString = local ? Self.localHTTPEndpoint : Self.productionHTTPEndpoint
        return URL(string: urlString)!
    }

    public init(
        apiKey: String,
        baseURL: URL? = nil,
        local: Bool = false,
        timeout: TimeInterval = 30.0,
        retryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.apiKey = apiKey
        self.customBaseURL = baseURL
        self.local = local
        self.timeout = timeout
        self.retryAttempts = retryAttempts
        self.retryDelay = retryDelay
    }
}

/// Main Huefy SDK client for sending template-based emails
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public final class HuefyClient {
    
    private let configuration: HuefyConfiguration
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    /// Initialize a new Huefy client
    /// - Parameter configuration: Client configuration
    public init(configuration: HuefyConfiguration) {
        self.configuration = configuration
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout
        self.session = URLSession(configuration: sessionConfig)
        
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
        
        // Configure date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
    }
    
    /// Convenience initializer with API key
    /// - Parameter apiKey: Your Huefy API key
    public convenience init(apiKey: String) {
        let config = HuefyConfiguration(apiKey: apiKey)
        self.init(configuration: config)
    }
    
    // MARK: - Public API Methods
    
    /// Send a single email using a template
    /// - Parameters:
    ///   - templateKey: The template identifier
    ///   - data: Template variables as key-value pairs
    ///   - recipient: Recipient email address
    ///   - provider: Optional email provider (defaults to SES)
    /// - Returns: Send email response
    public func sendEmail(
        templateKey: String,
        data: [String: Any],
        recipient: String,
        provider: EmailProvider? = nil
    ) async throws -> SendEmailResponse {
        let request = SendEmailRequest(
            templateKey: templateKey,
            data: data,
            recipient: recipient,
            provider: provider
        )
        
        return try await performRequest(
            endpoint: "/emails/send",
            method: .POST,
            body: request,
            responseType: SendEmailResponse.self
        )
    }
    
    /// Send multiple emails in bulk
    /// - Parameter emails: Array of email requests
    /// - Returns: Bulk email response with results
    public func sendBulkEmails(emails: [SendEmailRequest]) async throws -> BulkEmailResponse {
        let request = BulkEmailRequest(emails: emails)
        
        return try await performRequest(
            endpoint: "/emails/bulk",
            method: .POST,
            body: request,
            responseType: BulkEmailResponse.self
        )
    }
    
    /// Check API health status
    /// - Returns: Health response with status information
    public func healthCheck() async throws -> HealthResponse {
        return try await performRequest(
            endpoint: "/health",
            method: .GET,
            responseType: HealthResponse.self
        )
    }
    
    /// Validate a template with test data
    /// - Parameters:
    ///   - templateKey: The template identifier
    ///   - testData: Test data for validation
    /// - Returns: Validation response
    public func validateTemplate(
        templateKey: String,
        testData: [String: Any]
    ) async throws -> ValidateTemplateResponse {
        let request = ValidateTemplateRequest(
            templateKey: templateKey,
            testData: testData
        )
        
        return try await performRequest(
            endpoint: "/templates/validate",
            method: .POST,
            body: request,
            responseType: ValidateTemplateResponse.self
        )
    }
    
    /// Get available email providers
    /// - Returns: List of available providers
    public func getProviders() async throws -> ProvidersResponse {
        return try await performRequest(
            endpoint: "/providers",
            method: .GET,
            responseType: ProvidersResponse.self
        )
    }
}

// MARK: - Combine Publishers
#if canImport(Combine)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension HuefyClient {
    
    /// Send email publisher for Combine integration
    public func sendEmailPublisher(
        templateKey: String,
        data: [String: Any],
        recipient: String,
        provider: EmailProvider? = nil
    ) -> AnyPublisher<SendEmailResponse, HuefyError> {
        Future { promise in
            Task {
                do {
                    let response = try await self.sendEmail(
                        templateKey: templateKey,
                        data: data,
                        recipient: recipient,
                        provider: provider
                    )
                    promise(.success(response))
                } catch let error as HuefyError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Bulk email publisher for Combine integration
    public func sendBulkEmailsPublisher(emails: [SendEmailRequest]) -> AnyPublisher<BulkEmailResponse, HuefyError> {
        Future { promise in
            Task {
                do {
                    let response = try await self.sendBulkEmails(emails: emails)
                    promise(.success(response))
                } catch let error as HuefyError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Health check publisher for Combine integration
    public func healthCheckPublisher() -> AnyPublisher<HealthResponse, HuefyError> {
        Future { promise in
            Task {
                do {
                    let response = try await self.healthCheck()
                    promise(.success(response))
                } catch let error as HuefyError {
                    promise(.failure(error))
                } catch {
                    promise(.failure(.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
#endif

// MARK: - Private Implementation
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
private extension HuefyClient {
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Codable? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        var attempt = 0
        var lastError: Error?
        
        while attempt < configuration.retryAttempts {
            do {
                return try await executeRequest(
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    responseType: responseType
                )
            } catch let error as HuefyError {
                // Don't retry client errors (4xx)
                switch error {
                case .invalidApiKey, .templateNotFound, .validationError:
                    throw error
                default:
                    lastError = error
                }
            } catch {
                lastError = error
            }
            
            attempt += 1
            if attempt < configuration.retryAttempts {
                let delay = configuration.retryDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        if let error = lastError {
            throw error
        } else {
            throw HuefyError.unknown("Request failed after \(configuration.retryAttempts) attempts")
        }
    }
    
    func executeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Codable? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: endpoint, relativeTo: configuration.baseURL) else {
            throw HuefyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("Huefy-iOS-SDK/1.0.0", forHTTPHeaderField: "User-Agent")
        
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                throw HuefyError.encodingError(error)
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuefyError.networkError(URLError(.badServerResponse))
        }
        
        // Handle HTTP errors
        if httpResponse.statusCode >= 400 {
            try handleHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            return try jsonDecoder.decode(responseType, from: data)
        } catch {
            throw HuefyError.decodingError(error)
        }
    }
    
    func handleHTTPError(statusCode: Int, data: Data) throws {
        let errorMessage: String
        
        if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = errorResponse["message"] as? String {
            errorMessage = message
        } else {
            errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
        }
        
        switch statusCode {
        case 400:
            if errorMessage.lowercased().contains("template") && errorMessage.lowercased().contains("not found") {
                throw HuefyError.templateNotFound(errorMessage)
            }
            throw HuefyError.validationError(errorMessage, nil)
            
        case 401:
            throw HuefyError.invalidApiKey
            
        case 404:
            if errorMessage.lowercased().contains("template") {
                throw HuefyError.templateNotFound(errorMessage)
            }
            throw HuefyError.serverError(statusCode, errorMessage)
            
        case 422:
            throw HuefyError.validationError(errorMessage, nil)
            
        case 429:
            let retryAfter: TimeInterval? = nil // Could parse from headers if needed
            throw HuefyError.rateLimitExceeded(retryAfter: retryAfter)
            
        case 500...599:
            throw HuefyError.serverError(statusCode, errorMessage)
            
        default:
            throw HuefyError.serverError(statusCode, errorMessage)
        }
    }
}