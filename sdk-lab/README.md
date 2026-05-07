# Huefy Swift SDK Lab

Verifies the core email contract through the real Swift email client against a local loopback stub server.

## Run

```bash
swift run SdkLab
```

from `sdks/swift/`.

## Scenarios

1. Initialization
2. Single-send contract shaping
3. Bulk-send contract shaping
4. Invalid single rejection
5. Invalid bulk rejection
6. Health request path behavior
7. Cleanup

## Notes

- The lab uses a real loopback TCP stub because the SDK owns its own `URLSession`.
- It verifies the actual email-client methods, not generic helper utilities.
