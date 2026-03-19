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
    public let fromEmail: String?
    public let fromName: String?
    public let providerType: String?
    public let batchSize: Int?
    public let correlationId: String?

    public init(
        templateKey: String,
        recipients: [BulkRecipient],
        fromEmail: String? = nil,
        fromName: String? = nil,
        providerType: String? = nil,
        batchSize: Int? = nil,
        correlationId: String? = nil
    ) {
        self.templateKey = templateKey
        self.recipients = recipients
        self.fromEmail = fromEmail
        self.fromName = fromName
        self.providerType = providerType
        self.batchSize = batchSize
        self.correlationId = correlationId
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

/// Options for bulk email sending.
public struct BulkEmailOptions: Sendable {
    public let fromEmail: String?
    public let fromName: String?
    public let providerType: String?
    public let batchSize: Int?
    public let correlationId: String?

    public init(
        fromEmail: String? = nil,
        fromName: String? = nil,
        providerType: String? = nil,
        batchSize: Int? = nil,
        correlationId: String? = nil
    ) {
        self.fromEmail = fromEmail
        self.fromName = fromName
        self.providerType = providerType
        self.batchSize = batchSize
        self.correlationId = correlationId
    }
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
