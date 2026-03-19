# Huefy (Swift)

Official Swift SDK for [Huefy](https://huefy.dev) — transactional email delivery made simple.

## Installation

### Swift Package Manager

In `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(url: "https://github.com/teracrafts/huefy-swift", from: "1.0.0"),
    ],
    targets: [
        .target(name: "MyApp", dependencies: [
            .product(name: "Huefy", package: "huefy-swift"),
        ]),
    ]
)
```

Or add via Xcode: **File > Add Package Dependencies…** and enter `https://github.com/teracrafts/huefy-swift`.

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+

## Quick Start

```swift
import Huefy

let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_your_api_key"))

let response = try await client.sendEmail(HuefySendEmailRequest(
    templateKey: "welcome-email",
    recipient: HuefyRecipient(email: "alice@example.com", name: "Alice"),
    variables: ["firstName": "Alice", "trialDays": 14]
))

print("Message ID:", response.messageId)
client.close()
```

## Key Features

- **Native async/await** — all network calls use Swift concurrency (`URLSession`)
- **`Codable` types** — all request and response structs conform to `Codable` for seamless JSON handling
- **`actor`-based circuit breaker** — thread-safe state management using Swift actors
- **Retry with exponential backoff** — configurable attempts, base delay, ceiling, and jitter
- **Circuit breaker** — opens after 5 consecutive failures, probes after 30 s
- **HMAC-SHA256 signing** — optional request signing for additional integrity verification
- **Key rotation** — primary + secondary API key with seamless failover
- **Rate limit callbacks** — `onRateLimitUpdate` closure fires whenever rate-limit headers change
- **PII detection** — warns when template variables contain sensitive field patterns

## Configuration Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `apiKey` | — | **Required.** Must have prefix `sdk_`, `srv_`, or `cli_` |
| `baseURL` | `https://api.huefy.dev/api/v1/sdk` | Override the API base URL |
| `timeout` | `30.0` | Request timeout in seconds |
| `retryConfig.maxAttempts` | `3` | Total attempts including the first |
| `retryConfig.baseDelay` | `0.5` | Exponential backoff base delay (seconds) |
| `retryConfig.maxDelay` | `10.0` | Maximum backoff delay (seconds) |
| `retryConfig.jitter` | `0.2` | Random jitter factor (0–1) |
| `circuitBreakerConfig.failureThreshold` | `5` | Consecutive failures before circuit opens |
| `circuitBreakerConfig.resetTimeout` | `30.0` | Seconds before half-open probe |
| `secondaryApiKey` | `nil` | Backup key used during key rotation |
| `enableRequestSigning` | `false` | Enable HMAC-SHA256 request signing |
| `onRateLimitUpdate` | `nil` | Closure fired on rate-limit header changes |

## Bulk Email

```swift
let bulk = try await client.sendBulkEmails(HuefyBulkEmailRequest(
    emails: [
        HuefySendEmailRequest(templateKey: "promo", recipient: HuefyRecipient(email: "bob@example.com")),
        HuefySendEmailRequest(templateKey: "promo", recipient: HuefyRecipient(email: "carol@example.com")),
    ]
))

print("Sent: \(bulk.totalSent), Failed: \(bulk.totalFailed)")
```

## Error Handling

```swift
import Huefy

do {
    let response = try await client.sendEmail(request)
    print("Delivered:", response.messageId)
} catch let error as HuefyAuthError {
    print("Invalid API key")
} catch let error as HuefyRateLimitError {
    print("Rate limited. Retry after \(error.retryAfter)s")
} catch let error as HuefyCircuitOpenError {
    print("Circuit open — service unavailable, backing off")
} catch let error as HuefyError {
    print("Huefy error [\(error.code)]: \(error.localizedDescription)")
}
```

### Error Code Reference

| Type | Code | Meaning |
|------|------|---------|
| `HuefyInitError` | 1001 | Client failed to initialise |
| `HuefyAuthError` | 1102 | API key rejected |
| `HuefyNetworkError` | 1201 | Upstream request failed |
| `HuefyCircuitOpenError` | 1301 | Circuit breaker tripped |
| `HuefyRateLimitError` | 2003 | Rate limit exceeded |
| `HuefyTemplateMissingError` | 2005 | Template key not found |

## Health Check

```swift
let health = try await client.healthCheck()
if health.status != "healthy" {
    print("Huefy degraded:", health.status)
}
```

## Local Development

Set `HUEFY_MODE=local` in your environment, or override `baseURL` in config:

```swift
let client = try HuefyEmailClient(config: HuefyConfig(
    apiKey: "sdk_local_key",
    baseURL: URL(string: "http://localhost:3000/api/v1/sdk")!
))
```

## Developer Guide

Full documentation, advanced patterns, and provider configuration are in the [Swift Developer Guide](../../docs/spec/guides/swift.guide.md).

## License

MIT
