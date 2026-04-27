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
///     data: ["name": "John", "trialDays": 14, "beta": true],
///     recipient: "john@example.com"
/// )
///
/// // Bulk emails
/// let bulk = try await client.sendBulkEmails(
///     templateKey: "welcome",
///     recipients: [BulkRecipient(email: "alice@example.com", data: ["name": "Alice"])]
/// )
/// ```
public final class HuefyEmailClient: @unchecked Sendable {

    private static let emailsSendPath = "/emails/send"
    private static let emailsBulkPath = "/emails/send-bulk"

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

    /// Sends a single email using the specified template.
    ///
    /// - Parameters:
    ///   - templateKey: The template key identifying the email template.
    ///   - data: Template data variables to merge into the email.
    ///   - recipient: The recipient email address.
    ///   - provider: The email provider to use. Defaults to SES when `nil`.
    /// - Returns: A ``SendEmailResponse`` describing the result.
    /// - Throws: A ``HuefyError`` on validation or network failures.
    public func sendEmail(
        templateKey: String,
        data: [String: JSONValue],
        recipient: String,
        provider: EmailProvider? = nil
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
        Security.warnIfPotentialPII(
            data.mapValues(\.foundationValue),
            dataType: "email template"
        )

        let request = SendEmailRequest(
            templateKey: templateKey.trimmingCharacters(in: .whitespaces),
            data: data,
            recipient: recipient.trimmingCharacters(in: .whitespaces),
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

    public func sendEmail(
        templateKey: String,
        data: [String: JSONValue],
        recipient: SendEmailRecipient,
        provider: EmailProvider? = nil
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

        Security.warnIfPotentialPII(
            data.mapValues(\.foundationValue),
            dataType: "email template"
        )
        if let recipientData = recipient.data {
            Security.warnIfPotentialPII(
                recipientData.mapValues(\.foundationValue),
                dataType: "recipient template"
            )
        }

        let request = SendEmailRequest(
            templateKey: templateKey.trimmingCharacters(in: .whitespaces),
            data: data,
            recipient: SendEmailRecipient(
                email: recipient.email.trimmingCharacters(in: .whitespaces),
                type: recipient.type?.trimmingCharacters(in: .whitespaces).lowercased(),
                data: recipient.data
            ),
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

    public func sendEmail(
        templateKey: String,
        data: [String: String],
        recipient: String,
        provider: EmailProvider? = nil
    ) async throws -> SendEmailResponse {
        try await sendEmail(
            templateKey: templateKey,
            data: data.mapValues(JSONValue.string),
            recipient: recipient,
            provider: provider
        )
    }

    public func sendEmail(
        templateKey: String,
        data: [String: String],
        recipient: SendEmailRecipient,
        provider: EmailProvider? = nil
    ) async throws -> SendEmailResponse {
        try await sendEmail(
            templateKey: templateKey,
            data: data.mapValues(JSONValue.string),
            recipient: recipient,
            provider: provider
        )
    }

    // MARK: - Bulk Emails

    /// Sends multiple emails in bulk using a shared template.
    ///
    /// - Parameters:
    ///   - templateKey: The template key to use for all recipients.
    ///   - recipients: The list of recipients to send to.
    ///   - provider: The email provider to use. Defaults to SES when `nil`.
    /// - Returns: A ``SendBulkEmailsResponse`` describing the batch result.
    /// - Throws: A ``HuefyError`` on validation or network failures.
    public func sendBulkEmails(
        templateKey: String,
        recipients: [BulkRecipient],
        provider: EmailProvider? = nil
    ) async throws -> SendBulkEmailsResponse {
        guard !_closed else {
            throw HuefyError(code: .initFailed, message: "Client has been closed")
        }

        if let err = EmailValidators.validateBulkCount(recipients.count) {
            throw HuefyError(code: .validationError, message: err)
        }

        if let err = EmailValidators.validateTemplateKey(templateKey) {
            throw HuefyError(code: .validationError, message: err)
        }

        for (i, recipient) in recipients.enumerated() {
            if let err = EmailValidators.validateBulkRecipient(recipient) {
                throw HuefyError(
                    code: .validationError,
                    message: "recipients[\(i)]: \(err)"
                )
            }
        }

        let request = SendBulkEmailsRequest(
            templateKey: templateKey.trimmingCharacters(in: .whitespaces),
            recipients: recipients.map {
                BulkRecipient(
                    email: $0.email.trimmingCharacters(in: .whitespaces),
                    type: $0.type.trimmingCharacters(in: .whitespaces).lowercased(),
                    data: $0.data
                )
            },
            providerType: provider
        )

        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        let responseData = try await httpClient.request(
            method: "POST",
            path: Self.emailsBulkPath,
            body: body
        )

        let decoder = JSONDecoder()
        return try decoder.decode(SendBulkEmailsResponse.self, from: responseData)
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
