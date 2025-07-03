# Huefy iOS SDK

Swift SDK for sending emails via the Huefy API.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/teracrafts/huefy-sdk-ios.git", from: "1.0.0")
]
```

Or add it via Xcode by going to File → Add Package Dependencies and entering:
```
https://github.com/teracrafts/huefy-sdk-ios.git
```

## Usage

### Basic Usage

```swift
import HuefySDK

// Initialize the client
let client = HuefyClient(apiKey: "your-api-key")

// Send an email
do {
    let response = try await client.sendEmail(
        templateKey: "welcome-email",
        data: ["name": "John Doe", "company": "Acme Inc"],
        recipient: "john@example.com"
    )
    print("Email sent with ID: \(response.messageId)")
} catch {
    print("Failed to send email: \(error)")
}
```

### Advanced Configuration

```swift
import HuefySDK

let config = HuefyConfiguration(
    apiKey: "your-api-key",
    timeout: 30.0,
    retryAttempts: 3,
    retryDelay: 1.0
)

let client = HuefyClient(configuration: config)
```

### Using Specific Providers

```swift
// Send with a specific provider
try await client.sendEmail(
    templateKey: "newsletter",
    data: ["content": "Monthly updates"],
    recipient: "subscriber@example.com",
    provider: .sendgrid
)
```

### Bulk Email Sending

```swift
let emails = [
    SendEmailRequest(
        templateKey: "welcome-email",
        data: ["name": "John"],
        recipient: "john@example.com"
    ),
    SendEmailRequest(
        templateKey: "welcome-email", 
        data: ["name": "Jane"],
        recipient: "jane@example.com"
    )
]

let response = try await client.sendBulkEmails(emails: emails)
print("Sent \(response.successCount) emails successfully")
```

### Combine Integration

```swift
import Combine
import HuefySDK

let client = HuefyClient(apiKey: "your-api-key")

client.sendEmailPublisher(
    templateKey: "welcome-email",
    data: ["name": "John"],
    recipient: "john@example.com"
)
.sink(
    receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Error: \(error)")
        }
    },
    receiveValue: { response in
        print("Email sent: \(response.messageId)")
    }
)
.store(in: &cancellables)
```

### Error Handling

```swift
do {
    let response = try await client.sendEmail(
        templateKey: "welcome-email",
        data: ["name": "John"],
        recipient: "john@example.com"
    )
} catch HuefyError.invalidApiKey {
    print("Invalid API key")
} catch HuefyError.templateNotFound(let templateKey) {
    print("Template not found: \(templateKey)")
} catch HuefyError.validationError(let message, _) {
    print("Validation error: \(message)")
} catch HuefyError.rateLimitExceeded(let retryAfter) {
    print("Rate limited, retry after: \(retryAfter ?? 0) seconds")
} catch {
    print("Unexpected error: \(error)")
}
```

### Template Validation

```swift
let response = try await client.validateTemplate(
    templateKey: "welcome-email",
    testData: ["name": "Test User", "company": "Test Corp"]
)

if response.valid {
    print("Template is valid")
} else {
    print("Template errors: \(response.errors ?? [])")
}
```

### Health Check

```swift
let health = try await client.healthCheck()
print("API Status: \(health.status)")
print("Version: \(health.version ?? "unknown")")
```

## API Reference

### HuefyClient

The main client for interacting with the Huefy API.

#### Methods

- `sendEmail(templateKey:data:recipient:provider:)` - Send a single email
- `sendBulkEmails(emails:)` - Send multiple emails
- `validateTemplate(templateKey:testData:)` - Validate a template
- `healthCheck()` - Check API health
- `getProviders()` - Get available providers

#### Combine Publishers

- `sendEmailPublisher(templateKey:data:recipient:provider:)` - Send email publisher
- `sendBulkEmailsPublisher(emails:)` - Bulk email publisher
- `healthCheckPublisher()` - Health check publisher

### Email Providers

Available email providers:
- `.ses` (default)
- `.sendgrid`
- `.mailgun`
- `.mailchimp`

### Error Types

- `HuefyError.invalidApiKey` - Invalid API key
- `HuefyError.templateNotFound(String)` - Template not found
- `HuefyError.validationError(String, [String: Any]?)` - Validation error
- `HuefyError.rateLimitExceeded(retryAfter: TimeInterval?)` - Rate limit exceeded
- `HuefyError.networkError(Error)` - Network error
- `HuefyError.serverError(Int, String?)` - Server error

## Requirements

- iOS 13.0+
- macOS 10.15+
- tvOS 13.0+
- watchOS 6.0+
- Swift 5.7+

## Support

For issues and questions, please visit our [GitHub repository](https://github.com/teracrafts/huefy-sdk-ios).