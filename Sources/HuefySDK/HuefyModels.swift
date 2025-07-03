import Foundation

// MARK: - Email Provider
public enum EmailProvider: String, CaseIterable, Codable {
    case ses = "ses"
    case sendgrid = "sendgrid"
    case mailgun = "mailgun"
    case mailchimp = "mailchimp"
}

// MARK: - Send Email Request
public struct SendEmailRequest: Codable {
    public let templateKey: String
    public let data: [String: Any]
    public let recipient: String
    public let provider: EmailProvider?
    
    private enum CodingKeys: String, CodingKey {
        case templateKey = "template_key"
        case data
        case recipient
        case provider
    }
    
    public init(
        templateKey: String,
        data: [String: Any],
        recipient: String,
        provider: EmailProvider? = nil
    ) {
        self.templateKey = templateKey
        self.data = data
        self.recipient = recipient
        self.provider = provider
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateKey, forKey: .templateKey)
        try container.encode(recipient, forKey: .recipient)
        try container.encodeIfPresent(provider, forKey: .provider)
        
        // Encode [String: Any] manually
        let dataContainer = try encoder.container(keyedBy: DynamicCodingKey.self)
        try data.forEach { key, value in
            let codingKey = DynamicCodingKey(stringValue: key)!
            try dataContainer.encodeAnyValue(value, forKey: codingKey)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templateKey = try container.decode(String.self, forKey: .templateKey)
        recipient = try container.decode(String.self, forKey: .recipient)
        provider = try container.decodeIfPresent(EmailProvider.self, forKey: .provider)
        
        // Decode [String: Any] manually
        let dataContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedData: [String: Any] = [:]
        
        for key in dataContainer.allKeys {
            if let value = try? dataContainer.decodeAnyValue(forKey: key) {
                decodedData[key.stringValue] = value
            }
        }
        data = decodedData
    }
}

// MARK: - Send Email Response
public struct SendEmailResponse: Codable {
    public let messageId: String
    public let provider: String
    public let status: String
    public let timestamp: Date
    
    private enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case provider
        case status
        case timestamp
    }
}

// MARK: - Bulk Email Request
public struct BulkEmailRequest: Codable {
    public let emails: [SendEmailRequest]
    
    public init(emails: [SendEmailRequest]) {
        self.emails = emails
    }
}

// MARK: - Bulk Email Response
public struct BulkEmailResponse: Codable {
    public let results: [BulkEmailResult]
    public let successCount: Int
    public let failureCount: Int
    public let totalCount: Int
    
    private enum CodingKeys: String, CodingKey {
        case results
        case successCount = "success_count"
        case failureCount = "failure_count"
        case totalCount = "total_count"
    }
}

public struct BulkEmailResult: Codable {
    public let email: String
    public let success: Bool
    public let messageId: String?
    public let error: String?
    
    private enum CodingKeys: String, CodingKey {
        case email
        case success
        case messageId = "message_id"
        case error
    }
}

// MARK: - Health Response
public struct HealthResponse: Codable {
    public let status: String
    public let version: String?
    public let uptime: TimeInterval?
    public let timestamp: Date
    public let providers: [String: String]?
}

// MARK: - Validate Template Request
public struct ValidateTemplateRequest: Codable {
    public let templateKey: String
    public let testData: [String: Any]
    
    private enum CodingKeys: String, CodingKey {
        case templateKey = "template_key"
        case testData = "test_data"
    }
    
    public init(templateKey: String, testData: [String: Any]) {
        self.templateKey = templateKey
        self.testData = testData
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateKey, forKey: .templateKey)
        
        // Encode [String: Any] manually
        let dataContainer = try encoder.container(keyedBy: DynamicCodingKey.self)
        try testData.forEach { key, value in
            let codingKey = DynamicCodingKey(stringValue: key)!
            try dataContainer.encodeAnyValue(value, forKey: codingKey)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templateKey = try container.decode(String.self, forKey: .templateKey)
        
        // Decode [String: Any] manually
        let dataContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedData: [String: Any] = [:]
        
        for key in dataContainer.allKeys {
            if let value = try? dataContainer.decodeAnyValue(forKey: key) {
                decodedData[key.stringValue] = value
            }
        }
        testData = decodedData
    }
}

// MARK: - Validate Template Response
public struct ValidateTemplateResponse: Codable {
    public let valid: Bool
    public let errors: [String]?
}

// MARK: - Provider Response
public struct ProvidersResponse: Codable {
    public let providers: [Provider]
}

public struct Provider: Codable {
    public let name: String
    public let status: String
    public let description: String?
    public let features: [String]?
}

// MARK: - Helper Types
private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Codable Extensions for Any
private extension KeyedEncodingContainer where K == DynamicCodingKey {
    mutating func encodeAnyValue(_ value: Any, forKey key: K) throws {
        if let stringValue = value as? String {
            try encode(stringValue, forKey: key)
        } else if let intValue = value as? Int {
            try encode(intValue, forKey: key)
        } else if let doubleValue = value as? Double {
            try encode(doubleValue, forKey: key)
        } else if let boolValue = value as? Bool {
            try encode(boolValue, forKey: key)
        } else if let arrayValue = value as? [Any] {
            var nestedContainer = nestedUnkeyedContainer(forKey: key)
            for item in arrayValue {
                try nestedContainer.encodeAnyValue(item)
            }
        } else if let dictValue = value as? [String: Any] {
            var nestedContainer = nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key)
            for (nestedKey, nestedValue) in dictValue {
                let nestedCodingKey = DynamicCodingKey(stringValue: nestedKey)!
                try nestedContainer.encodeAnyValue(nestedValue, forKey: nestedCodingKey)
            }
        }
    }
}

private extension KeyedDecodingContainer where K == DynamicCodingKey {
    func decodeAnyValue(forKey key: K) throws -> Any? {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        } else if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        } else if let doubleValue = try? decode(Double.self, forKey: key) {
            return doubleValue
        } else if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue
        }
        return nil
    }
}

private extension UnkeyedEncodingContainer {
    mutating func encodeAnyValue(_ value: Any) throws {
        if let stringValue = value as? String {
            try encode(stringValue)
        } else if let intValue = value as? Int {
            try encode(intValue)
        } else if let doubleValue = value as? Double {
            try encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try encode(boolValue)
        }
    }
}