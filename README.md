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

let response = try await client.sendEmail(
    templateKey: "welcome-email",
    data: ["firstName": "Alice", "trialDays": 14],
    recipient: "alice@example.com"
)

print("Message ID:", response.data.emailId)
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
| `baseUrl` | `https://api.huefy.dev/api/v1/sdk` | Override the API base URL |
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
let bulk = try await client.sendBulkEmails(
    templateKey: "promo",
    recipients: [
        BulkRecipient(email: "bob@example.com"),
        BulkRecipient(email: "carol@example.com"),
    ]
)

print("Sent: \(bulk.data.successCount), Failed: \(bulk.data.failureCount)")
```

## Error Handling

```swift
import Huefy

do {
    let response = try await client.sendEmail(request)
    print("Delivered:", response.data.emailId)
} catch let error as HuefyError {
    switch error.code {
    case .authInvalidKey, .authMissingKey, .authUnauthorized:
        print("Invalid API key")
    case .networkRetryLimit:
        print("Rate limited. Retry after \(Int(error.retryAfter ?? 0))s")
    case .circuitOpen:
        print("Circuit open — service unavailable, backing off")
    default:
        print("Huefy error [\(error.code.rawValue)]: \(error.message)")
    }
}
```

### Error Code Reference

| Type | Code | Meaning |
|------|------|---------|
| `HuefyError` | `ErrorCode.authInvalidKey` / `authMissingKey` / `authUnauthorized` | API key rejected |
| `HuefyError` | `ErrorCode.networkRetryLimit` | Rate limit exceeded |
| `HuefyError` | `ErrorCode.circuitOpen` | Circuit breaker tripped |
| `HuefyError` | `ErrorCode.*` | Transport, validation, or configuration failure |

## Health Check

```swift
let health = try await client.healthCheck()
if health.data.status != "healthy" {
    print("Huefy degraded:", health.data.status)
}
```

## Local Development

Set `HUEFY_MODE=local` to target `https://api.huefy.on/api/v1/sdk`, or override `baseUrl` in config. To bypass Caddy and hit the raw app port directly, set `http://localhost:8080/api/v1/sdk` explicitly:

```swift
let client = try HuefyEmailClient(config: HuefyConfig(
    apiKey: "sdk_local_key",
    baseUrl: "https://api.huefy.on/api/v1/sdk"
))
```

## Developer Guide

Full documentation, advanced patterns, and provider configuration are in the [Swift Developer Guide](../../docs/spec/guides/swift.guide.md).

## License

MIT
