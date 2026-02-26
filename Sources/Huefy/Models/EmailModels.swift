import Foundation

/// Request to send a single email via the Huefy API.
public struct SendEmailRequest: Codable, Sendable {
    /// The template key identifying the email template (1-100 characters).
    public let templateKey: String

    /// The recipient email address.
    public let recipient: String

    /// Template data variables to merge into the email.
    public let data: [String: String]

    /// The email provider to use. Defaults to SES if not specified.
    public let providerType: EmailProvider?

    public init(
        templateKey: String,
        recipient: String,
        data: [String: String],
        providerType: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.recipient = recipient
        self.data = data
        self.providerType = providerType
    }

    enum CodingKeys: String, CodingKey {
        case templateKey = "template_key"
        case recipient
        case data
        case providerType = "provider_type"
    }
}

/// Response from the send email endpoint.
public struct SendEmailResponse: Codable, Sendable {
    /// Whether the email was sent successfully.
    public let success: Bool

    /// A human-readable message from the server.
    public let message: String?

    /// The unique identifier for the sent message.
    public let messageId: String?

    /// The provider that was used to deliver the email.
    public let provider: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case messageId = "message_id"
        case provider
    }
}

/// Error details for a single email in a bulk operation.
public struct BulkEmailError: Codable, Sendable {
    /// Error message describing what went wrong.
    public let message: String

    /// Error code string.
    public let code: String
}

/// Result of sending a single email in a bulk operation.
public struct BulkEmailResult: Codable, Sendable {
    /// The recipient email address.
    public let email: String

    /// Whether this individual email was sent successfully.
    public let success: Bool

    /// The response if the email was sent successfully.
    public let result: SendEmailResponse?

    /// The error if the email failed to send.
    public let error: BulkEmailError?
}
