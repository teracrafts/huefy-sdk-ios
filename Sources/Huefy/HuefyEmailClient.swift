import Foundation

/// Email-focused client for the Huefy SDK.
///
/// Extends ``HuefyClient`` with email-specific operations including single
/// and bulk email sending with input validation.
///
/// ```swift
/// let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "your-api-key"))
///
/// // Send a single email
/// let response = try await client.sendEmail(
///     templateKey: "welcome",
///     data: ["name": "John"],
///     recipient: "john@example.com"
/// )
///
/// // Send with a specific provider
/// let response = try await client.sendEmail(
///     templateKey: "welcome",
///     data: ["name": "John"],
///     recipient: "john@example.com",
///     provider: .sendgrid
/// )
/// ```
public final class HuefyEmailClient: @unchecked Sendable {

    private static let emailsSendPath = "/emails/send"
    private static let emailsBulkPath = "/emails/bulk"

    private let httpClient: HttpClient
    private let config: HuefyConfig
    private var _closed: Bool = false

    // MARK: - Initialisation

    /// Creates a new email client with the given configuration.
    ///
    /// - Parameter config: The client configuration including the API key.
    /// - Throws: A ``HuefyError`` with code ``ErrorCode/authMissingKey``
    ///   when the API key is empty.
    public init(config: HuefyConfig) throws {
        guard !config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw HuefyError(
                code: .authMissingKey,
                message: "API key is required"
            )
        }

        self.config = config
        self.httpClient = HttpClient(apiKey: config.apiKey, config: config)
    }

    // MARK: - Send Email

    /// Sends a single email using the default provider (SES).
    ///
    /// - Parameters:
    ///   - templateKey: The template key identifying the email template.
    ///   - data: Template data variables to merge into the email.
    ///   - recipient: The recipient email address.
    /// - Returns: A ``SendEmailResponse`` describing the result.
    /// - Throws: A ``HuefyError`` on validation or network failures.
    public func sendEmail(
        templateKey: String,
        data: [String: String],
        recipient: String
    ) async throws -> SendEmailResponse {
        return try await sendEmail(
            templateKey: templateKey,
            data: data,
            recipient: recipient,
            provider: nil
        )
    }

    /// Sends a single email using the specified provider.
    ///
    /// - Parameters:
    ///   - templateKey: The template key identifying the email template.
    ///   - data: Template data variables to merge into the email.
    ///   - recipient: The recipient email address.
    ///   - provider: The email provider to use. Pass `nil` for the default (SES).
    /// - Returns: A ``SendEmailResponse`` describing the result.
    /// - Throws: A ``HuefyError`` on validation or network failures.
    public func sendEmail(
        templateKey: String,
        data: [String: String],
        recipient: String,
        provider: EmailProvider?
    ) async throws -> SendEmailResponse {
        guard !_closed else {
            throw HuefyError(code: .initFailed, message: "Client has been closed")
        }

        let errors = EmailValidators.validateSendEmailInput(
            templateKey: templateKey,
            data: data,
            recipient: recipient
        )

        if !errors.isEmpty {
            throw HuefyError(
                code: .validationError,
                message: "Validation failed: \(errors.joined(separator: "; "))"
            )
        }

        // Warn if template data contains fields that look like PII
        Security.warnIfPotentialPII(data as [String: Any], dataType: "email template")

        let request = SendEmailRequest(
            templateKey: templateKey.trimmingCharacters(in: .whitespaces),
            recipient: recipient.trimmingCharacters(in: .whitespaces),
            data: data,
            providerType: provider
        )

        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        let responseData = try await httpClient.request(
            method: "POST",
            path: Self.emailsSendPath,
            body: body
        )

        let decoder = JSONDecoder()
        return try decoder.decode(SendEmailResponse.self, from: responseData)
    }

    // MARK: - Bulk Emails

    /// Sends multiple emails in bulk.
    ///
    /// Each request is sent independently. Failures for individual emails
    /// do not prevent remaining emails from being sent.
    ///
    /// - Parameter requests: The list of email requests to send.
    /// - Returns: An array of ``BulkEmailResult`` for each email.
    /// - Throws: A ``HuefyError`` if bulk count validation fails.
    public func sendBulkEmails(_ requests: [SendEmailRequest]) async throws -> [BulkEmailResult] {
        guard !_closed else {
            throw HuefyError(code: .initFailed, message: "Client has been closed")
        }

        if let err = EmailValidators.validateBulkCount(requests.count) {
            throw HuefyError(
                code: .validationError,
                message: err
            )
        }

        var results: [BulkEmailResult] = []

        for request in requests {
            do {
                let response = try await sendEmail(
                    templateKey: request.templateKey,
                    data: request.data,
                    recipient: request.recipient,
                    provider: request.providerType
                )
                results.append(BulkEmailResult(
                    email: request.recipient,
                    success: true,
                    result: response,
                    error: nil
                ))
            } catch let error as HuefyError {
                results.append(BulkEmailResult(
                    email: request.recipient,
                    success: false,
                    result: nil,
                    error: BulkEmailError(
                        message: error.message,
                        code: error.code.rawValue
                    )
                ))
            } catch {
                results.append(BulkEmailResult(
                    email: request.recipient,
                    success: false,
                    result: nil,
                    error: BulkEmailError(
                        message: error.localizedDescription,
                        code: ErrorCode.networkError.rawValue
                    )
                ))
            }
        }

        return results
    }

    // MARK: - Health Check

    /// Performs a health check against the Huefy API.
    ///
    /// - Returns: A ``HealthResponse`` describing the API status.
    /// - Throws: A ``HuefyError`` on network or authentication failures.
    public func healthCheck() async throws -> HealthResponse {
        let data = try await httpClient.request(method: "GET", path: "/health")
        let decoder = JSONDecoder()
        return try decoder.decode(HealthResponse.self, from: data)
    }

    /// Releases any resources held by the client.
    public func close() {
        _closed = true
        httpClient.close()
    }
}
