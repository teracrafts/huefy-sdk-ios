import Foundation

/// Request to send a single email via the Huefy API.
public struct SendEmailRequest: Codable, Sendable {
    /// The template key identifying the email template (1-100 characters).
    public let templateKey: String

    /// Template data variables to merge into the email.
    public let data: [String: String]

    /// The recipient email address.
    public let recipient: String

    /// The email provider to use. Defaults to SES if not specified.
    public let providerType: EmailProvider?

    public init(
        templateKey: String,
        data: [String: String],
        recipient: String,
        providerType: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.data = data
        self.recipient = recipient
        self.providerType = providerType
    }

    enum CodingKeys: String, CodingKey {
        case templateKey = "template_key"
        case data
        case recipient
        case providerType = "provider_type"
    }
}

/// Status of a single recipient in an email send or bulk send operation.
public struct RecipientStatus: Codable, Sendable {
    public let email: String
    public let status: String
    public let messageId: String?
    public let error: String?
    public let sentAt: String?
}

/// Data payload from the send email response.
public struct SendEmailResponseData: Codable, Sendable {
    public let emailId: String
    public let status: String
    public let recipients: [RecipientStatus]
    public let scheduledAt: String?
    public let sentAt: String?
}

/// Response from the send email endpoint.
public struct SendEmailResponse: Codable, Sendable {
    public let success: Bool
    public let data: SendEmailResponseData
    public let correlationId: String
}

/// A recipient entry for bulk email sending.
public struct BulkRecipient: Codable, Sendable {
    public let email: String
    public let type: String
    public let data: [String: String]?

    public init(email: String, type: String = "to", data: [String: String]? = nil) {
        self.email = email
        self.type = type
        self.data = data
    }
}

/// Request body for the send-bulk endpoint.
public struct SendBulkEmailsRequest: Codable, Sendable {
    public let templateKey: String
    public let recipients: [BulkRecipient]
    public let providerType: EmailProvider?

    public init(
        templateKey: String,
        recipients: [BulkRecipient],
        providerType: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.recipients = recipients
        self.providerType = providerType
    }
}

/// Data payload from the send-bulk response.
public struct SendBulkEmailsResponseData: Codable, Sendable {
    public let batchId: String
    public let status: String
    public let templateKey: String
    public let totalRecipients: Int
    public let successCount: Int
    public let failureCount: Int
    public let suppressedCount: Int
    public let startedAt: String
    public let completedAt: String?
    public let recipients: [RecipientStatus]
}

/// Response from the send-bulk endpoint.
public struct SendBulkEmailsResponse: Codable, Sendable {
    public let success: Bool
    public let data: SendBulkEmailsResponseData
    public let correlationId: String
}


/// Data payload from the health check response.
public struct HealthResponseData: Codable, Sendable {
    public let status: String
    public let timestamp: String
    public let version: String
}

/// Response from the health check endpoint.
public struct HealthResponse: Codable, Sendable {
    public let success: Bool
    public let data: HealthResponseData
    public let correlationId: String
}
