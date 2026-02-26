import Foundation

/// Log levels for the Huefy SDK logger.
public enum HuefyLogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

/// Protocol for logging within the Huefy SDK.
public protocol HuefyLogger: Sendable {
    func log(_ level: HuefyLogLevel, _ message: String)
}

/// Logger that outputs to the console via `print`.
public struct ConsoleLogger: HuefyLogger {
    public init() {}

    public func log(_ level: HuefyLogLevel, _ message: String) {
        print("[\(level.rawValue)] [Huefy] \(message)")
    }
}

/// Logger that discards all messages.
public struct NoopLogger: HuefyLogger {
    public init() {}

    public func log(_ level: HuefyLogLevel, _ message: String) {
        // intentionally empty
    }
}
