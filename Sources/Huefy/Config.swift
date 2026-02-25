import Foundation

/// Configuration for retry behaviour on failed requests.
public struct RetryConfig: Sendable {
    /// Maximum number of retry attempts. Default: 3.
    public var maxRetries: Int

    /// Base delay between retries in seconds. Default: 1.0.
    public var baseDelay: TimeInterval

    /// Maximum delay between retries in seconds. Default: 30.0.
    public var maxDelay: TimeInterval

    /// HTTP status codes that trigger a retry.
    public var retryableStatusCodes: [Int]

    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        retryableStatusCodes: [Int] = [429, 500, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.retryableStatusCodes = retryableStatusCodes
    }
}

/// Configuration for the circuit breaker.
public struct CircuitBreakerConfig: Sendable {
    /// Number of consecutive failures before the circuit opens. Default: 5.
    public var failureThreshold: Int

    /// Duration the circuit stays open before transitioning to half-open. Default: 30s.
    public var resetTimeout: TimeInterval

    /// Number of probe requests allowed in the half-open state. Default: 1.
    public var halfOpenRequests: Int

    public init(
        failureThreshold: Int = 5,
        resetTimeout: TimeInterval = 30.0,
        halfOpenRequests: Int = 1
    ) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
        self.halfOpenRequests = halfOpenRequests
    }
}

/// Default production base URL.
public let defaultBaseUrl = "https://api.huefy.dev/api/v1/sdk"

/// Base URL used when running in local development mode.
public let localBaseUrl = "https://api.huefy.on/api/v1/sdk"

/// Resolves the base URL by checking the ``HUEFY_MODE`` environment
/// variable. Returns ``localBaseUrl`` when the value is `"local"`;
/// otherwise returns ``defaultBaseUrl``.
public func resolveBaseUrl() -> String {
    if let mode = ProcessInfo.processInfo.environment["HUEFY_MODE"],
       mode == "local" {
        return localBaseUrl
    }
    return defaultBaseUrl
}

/// Configuration for the Huefy client.
public struct HuefyConfig: Sendable {

    /// Primary API key for authentication.
    public let apiKey: String

    /// Base URL of the Huefy API.
    public var baseUrl: String

    /// HTTP request timeout in seconds.
    public var timeout: TimeInterval

    /// Retry configuration.
    public var retryConfig: RetryConfig

    /// Circuit breaker configuration.
    public var circuitBreakerConfig: CircuitBreakerConfig

    /// Optional secondary API key for key rotation.
    public var secondaryApiKey: String?

    /// Enable HMAC request signing.
    public var enableRequestSigning: Bool

    /// Enable sanitisation of sensitive data in error messages.
    public var enableErrorSanitization: Bool

    public init(
        apiKey: String,
        baseUrl: String? = nil,
        timeout: TimeInterval = 30.0,
        retryConfig: RetryConfig = RetryConfig(),
        circuitBreakerConfig: CircuitBreakerConfig = CircuitBreakerConfig(),
        secondaryApiKey: String? = nil,
        enableRequestSigning: Bool = false,
        enableErrorSanitization: Bool = false
    ) {
        self.apiKey = apiKey
        self.baseUrl = baseUrl ?? resolveBaseUrl()
        self.timeout = timeout
        self.retryConfig = retryConfig
        self.circuitBreakerConfig = circuitBreakerConfig
        self.secondaryApiKey = secondaryApiKey
        self.enableRequestSigning = enableRequestSigning
        self.enableErrorSanitization = enableErrorSanitization
    }
}
