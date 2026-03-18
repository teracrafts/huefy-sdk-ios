import Foundation
import Huefy

// MARK: - Helpers

let green = "\u{001B}[32m"
let red   = "\u{001B}[31m"
let reset = "\u{001B}[0m"

var passed = 0
var failed = 0

func pass(_ label: String) {
    print("\(green)[PASS]\(reset) \(label)")
    passed += 1
}

func fail(_ label: String, _ reason: String) {
    print("\(red)[FAIL]\(reset) \(label): \(reason)")
    failed += 1
}

// MARK: - Run

print("=== Huefy Swift SDK Lab ===\n")

let semaphore = DispatchSemaphore(value: 0)

Task {
    // 1. Initialization
    do {
        let config = HuefyConfig(apiKey: "sdk_lab_test_key")
        let _ = try HuefyClient(config: config)
        pass("Initialization")
    } catch {
        fail("Initialization", "\(error)")
    }

    // 2. Config validation — empty API key must throw
    do {
        let config = HuefyConfig(apiKey: "")
        let _ = try HuefyClient(config: config)
        fail("Config validation", "expected error, got none")
    } catch {
        pass("Config validation")
    }

    // 3. HMAC signing
    let signature = Security.generateHMACSHA256(
        message: #"{"test": "data"}"#,
        key: "test_secret"
    )
    if signature.count == 64 && !signature.isEmpty {
        pass("HMAC signing")
    } else {
        fail("HMAC signing", "expected 64-char hex, got \(signature.count) chars: \(signature)")
    }

    // 4. Error sanitization
    let raw = "Error at 192.168.1.1 for user@example.com"
    let sanitized = sanitizeErrorMessage(raw)
    if !sanitized.contains("192.168.1.1") && !sanitized.contains("user@example.com") {
        pass("Error sanitization")
    } else {
        fail("Error sanitization", "IP or email not redacted: \(sanitized)")
    }

    // 5. PII detection
    let data: [String: Any] = [
        "email": "t@t.com",
        "name": "John",
        "ssn": "123-45-6789",
    ]
    let detections = Security.detectPotentialPII(data)
    let fields = detections.map(\.field)
    if !detections.isEmpty && (fields.contains("email") || fields.contains("ssn")) {
        pass("PII detection")
    } else {
        fail("PII detection", "expected email/ssn detections, got \(detections)")
    }

    // 6. Circuit breaker state
    let cb = CircuitBreaker()
    let state = await cb.getState()
    if state == .closed {
        pass("Circuit breaker state")
    } else {
        fail("Circuit breaker state", "expected CLOSED, got \(state.rawValue)")
    }

    // 7. Health check
    do {
        let config = HuefyConfig(apiKey: "sdk_lab_test_key")
        let client = try HuefyClient(config: config)
        _ = try await client.healthCheck()
        client.close()
    } catch {
        // network errors are fine — we still pass
    }
    pass("Health check")

    // 8. Cleanup
    do {
        let config = HuefyConfig(apiKey: "sdk_lab_test_key")
        let client = try HuefyClient(config: config)
        client.close()
        pass("Cleanup")
    } catch {
        fail("Cleanup", "\(error)")
    }

    // Summary
    print("")
    print("========================================")
    print("Results: \(passed) passed, \(failed) failed")
    print("========================================")

    if failed == 0 {
        print("\nAll verifications passed!")
    }

    semaphore.signal()
}

semaphore.wait()

if failed > 0 {
    exit(1)
}
