import Foundation

/// Request to send a single email via the Huefy API.
public struct SendEmailRequest: Codable, Sendable {
    /// The template key identifying the email template (1-100 characters).
    public let templateKey: String

    /// Template data variables to merge into the email.
    public let data: [String: JSONValue]

    /// The recipient email address.
    public let recipient: String?

    /// The structured recipient supported by the API.
    public let recipientObject: SendEmailRecipient?

    /// The email provider to use. Defaults to SES if not specified.
    public let providerType: EmailProvider?

    public init(
        templateKey: String,
        data: [String: JSONValue],
        recipient: String,
        providerType: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.data = data
        self.recipient = recipient
        self.recipientObject = nil
        self.providerType = providerType
    }

    public init(
        templateKey: String,
        data: [String: JSONValue],
        recipient: SendEmailRecipient,
        providerType: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.data = data
        self.recipient = nil
        self.recipientObject = recipient
        self.providerType = providerType
    }

    public init(
        templateKey: String,
        data: [String: String],
        recipient: String,
        providerType: EmailProvider?
    ) {
        self.init(
            templateKey: templateKey,
            data: data.mapValues(JSONValue.string),
            recipient: recipient,
            providerType: providerType
        )
    }

    public init(
        templateKey: String,
        data: [String: String],
        recipient: SendEmailRecipient,
        providerType: EmailProvider? = nil
    ) {
        self.init(
            templateKey: templateKey,
            data: data.mapValues(JSONValue.string),
            recipient: recipient,
            providerType: providerType
        )
    }

    enum CodingKeys: String, CodingKey {
        case templateKey
        case data
        case recipient
        case providerType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templateKey = try container.decode(String.self, forKey: .templateKey)
        data = try container.decode([String: JSONValue].self, forKey: .data)
        providerType = try container.decodeIfPresent(EmailProvider.self, forKey: .providerType)

        if let recipientObject = try? container.decode(SendEmailRecipient.self, forKey: .recipient) {
            self.recipient = nil
            self.recipientObject = recipientObject
        } else {
            self.recipient = try container.decode(String.self, forKey: .recipient)
            self.recipientObject = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateKey, forKey: .templateKey)
        try container.encode(data, forKey: .data)
        if let recipientObject {
            try container.encode(recipientObject, forKey: .recipient)
        } else {
            try container.encode(recipient, forKey: .recipient)
        }
        try container.encodeIfPresent(providerType, forKey: .providerType)
    }
}

public struct SendEmailRecipient: Codable, Sendable {
    public let email: String
    public let type: String?
    public let data: [String: JSONValue]?

    public init(email: String, type: String? = nil, data: [String: JSONValue]? = nil) {
        self.email = email
        self.type = type
        self.data = data
    }

    public init(email: String, type: String? = nil, data: [String: String]?) {
        self.init(email: email, type: type, data: data?.mapValues(JSONValue.string))
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
    public let data: [String: JSONValue]?

    public init(email: String, type: String = "to", data: [String: JSONValue]? = nil) {
        self.email = email
        self.type = type
        self.data = data
    }

    public init(email: String, type: String = "to", data: [String: String]?) {
        self.init(email: email, type: type, data: data?.mapValues(JSONValue.string))
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
    public let templateVersion: Int
    public let senderUsed: String
    public let senderVerified: Bool
    public let totalRecipients: Int
    public let processedCount: Int
    public let successCount: Int
    public let failureCount: Int
    public let suppressedCount: Int
    public let startedAt: String
    public let completedAt: String?
    public let recipients: [RecipientStatus]
    public let errors: [SDKEmailError]?
    public let metadata: [String: JSONValue]?
}

public struct SDKEmailError: Codable, Sendable {
    public let code: String
    public let message: String
    public let recipient: String?
    public let details: [String: JSONValue]?
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
