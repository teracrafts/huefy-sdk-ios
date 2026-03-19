# Huefy Swift SDK Lab

A smoke-test harness that exercises the core subsystems of the Huefy Swift SDK without requiring a live API key.

## What it checks

1. **Initialization** — `HuefyClient(config: HuefyConfig(apiKey: "sdk_lab_test_key"))`
2. **Config validation** — `HuefyConfig(apiKey: "")` must throw
3. **HMAC signing** — sign a payload and verify the signature is a 64-char hex string
4. **Error sanitization** — sanitize `"Error at 192.168.1.1 for user@example.com"` and verify the IP and email are redacted
5. **PII detection** — detect PII fields (`email`, `ssn`) in a dictionary
6. **Circuit breaker state** — a new `CircuitBreaker()` must start in the `CLOSED` state
7. **Health check** — call `healthCheck()`; network/auth errors are accepted
8. **Cleanup** — call `client.close()`

## Running

The lab is an executable target (`SdkLab`) defined in `Package.swift`. The source lives at `Sources/SdkLab/main.swift`.

```bash
# From the swift SDK directory
cd sdks/swift
swift run SdkLab
```

Or from the repo root using the Taskfile:

```bash
task lab-swift
```

## Expected output

```
=== Huefy Swift SDK Lab ===

[PASS] Initialization
[PASS] Config validation
[PASS] HMAC signing
[PASS] Error sanitization
[PASS] PII detection
[PASS] Circuit breaker state
[PASS] Health check
[PASS] Cleanup

========================================
Results: 8 passed, 0 failed
========================================

All verifications passed!
```
