import Foundation
import Network
import Huefy

let green = "\u{001B}[32m"
let red = "\u{001B}[31m"
let reset = "\u{001B}[0m"

var passed = 0
var failed = 0

func pass(_ label: String) {
    passed += 1
    print("\(green)[PASS]\(reset) \(label)")
}

func fail(_ label: String, _ reason: String) {
    failed += 1
    print("\(red)[FAIL]\(reset) \(label) - \(reason)")
}

final class LocalStubServer {
    struct CapturedRequest {
        let path: String
        let method: String
        let body: Data
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "huefy.sdklab.stub")
    private let lock = NSLock()
    private var requests: [CapturedRequest] = []

    init() throws {
        listener = try NWListener(using: .tcp, on: .any)
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
    }

    var baseURL: String {
        let port = listener.port?.rawValue ?? 0
        return "http://127.0.0.1:\(port)"
    }

    func start() async throws {
        try await withCheckedThrowingContinuation { continuation in
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }
    }

    func stop() {
        listener.cancel()
    }

    func hitCount(path: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return requests.filter { $0.path == path }.count
    }

    func lastRequest(path: String) -> CapturedRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.last(where: { $0.path == path })
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, error in
            guard let self else {
                connection.cancel()
                return
            }

            if let error {
                print("Stub server receive error: \(error)")
                connection.cancel()
                return
            }

            var accumulated = buffer
            if let data {
                accumulated.append(data)
            }

            if let request = self.parseRequest(from: accumulated) {
                self.record(request)
                self.respond(to: connection, path: request.path)
            } else {
                self.receive(on: connection, buffer: accumulated)
            }
        }
    }

    private func parseRequest(from data: Data) -> CapturedRequest? {
        let delimiter = Data("\r\n\r\n".utf8)
        guard let headerRange = data.range(of: delimiter) else {
            return nil
        }

        let headerData = data[..<headerRange.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return nil
        }

        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2 else {
            return nil
        }

        let method = String(parts[0])
        let path = String(parts[1])

        let contentLength = lines
            .dropFirst()
            .compactMap { line -> Int? in
                let segments = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                guard segments.count == 2 else { return nil }
                guard segments[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "content-length" else {
                    return nil
                }
                return Int(segments[1].trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .first ?? 0

        let bodyStart = headerRange.upperBound
        let availableBodyBytes = data.count - bodyStart
        guard availableBodyBytes >= contentLength else {
            return nil
        }

        let body = Data(data[bodyStart..<(bodyStart + contentLength)])
        return CapturedRequest(path: path, method: method, body: body)
    }

    private func record(_ request: CapturedRequest) {
        lock.lock()
        requests.append(request)
        lock.unlock()
    }

    private func respond(to connection: NWConnection, path: String) {
        let responseBody: String
        switch path {
        case "/emails/send":
            responseBody = #"{"success":true,"data":{"emailId":"email_123","status":"queued","recipients":[{"email":"john@example.com","status":"queued","messageId":"msg_123","sentAt":"2026-01-01T00:00:00Z"}],"scheduledAt":null,"sentAt":null},"correlationId":"corr_single"}"#
        case "/emails/send-bulk":
            responseBody = #"{"success":true,"data":{"batchId":"batch_123","status":"queued","templateKey":"account-update","templateVersion":1,"senderUsed":"noreply@example.com","senderVerified":true,"totalRecipients":2,"processedCount":2,"successCount":2,"failureCount":0,"suppressedCount":0,"startedAt":"2026-01-01T00:00:00Z","completedAt":"2026-01-01T00:00:01Z","recipients":[{"email":"alice@example.com","status":"queued","messageId":"msg_1","sentAt":"2026-01-01T00:00:00Z"},{"email":"bob@example.com","status":"queued","messageId":"msg_2","sentAt":"2026-01-01T00:00:00Z"}],"errors":[],"metadata":{"source":"sdk-lab"}},"correlationId":"corr_bulk"}"#
        case "/health":
            responseBody = #"{"success":true,"data":{"status":"healthy","timestamp":"2026-01-01T00:00:00Z","version":"sdk-lab"},"correlationId":"corr_health"}"#
        default:
            responseBody = #"{"success":false}"#
        }

        let bodyData = Data(responseBody.utf8)
        let header = "HTTP/1.1 200 OK\r\n"
            + "Content-Type: application/json\r\n"
            + "Content-Length: \(bodyData.count)\r\n"
            + "Connection: close\r\n"
            + "\r\n"

        var payload = Data(header.utf8)
        payload.append(bodyData)

        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}

func buildClient(baseURL: String) throws -> HuefyEmailClient {
    try HuefyEmailClient(config: HuefyConfig(
        apiKey: "sdk_lab_test_key_xxxxxxxxxxxx",
        baseUrl: baseURL,
        timeout: 2.0,
        retryConfig: RetryConfig(maxRetries: 0, baseDelay: 0.05, maxDelay: 0.05)
    ))
}

func decodeJSONBody(_ data: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: data)
    guard let json = object as? [String: Any] else {
        throw NSError(domain: "SdkLab", code: 1, userInfo: [NSLocalizedDescriptionKey: "request body was not a JSON object"])
    }
    return json
}

func verifySingleSend(_ client: HuefyEmailClient, server: LocalStubServer) async {
    do {
        let response = try await client.sendEmail(
            templateKey: " welcome-email ",
            data: [
                "name": "John",
                "count": 2,
                "beta": true,
                "roles": ["admin", "editor"]
            ],
            recipient: " john@example.com ",
            provider: .sendgrid
        )

        guard response.success else {
            fail("Single-send contract shaping", "stub response was not parsed as success")
            return
        }

        guard let captured = server.lastRequest(path: "/emails/send") else {
            fail("Single-send contract shaping", "missing single-send request")
            return
        }

        let body = try decodeJSONBody(captured.body)
        let data = body["data"] as? [String: Any]
        let roles = data?["roles"] as? [Any]

        guard
            captured.path == "/emails/send",
            captured.method == "POST",
            body["templateKey"] as? String == "welcome-email",
            body["recipient"] as? String == "john@example.com",
            body["providerType"] as? String == "sendgrid",
            body["template_key"] == nil,
            body["provider"] == nil,
            data?["name"] as? String == "John",
            data?["count"] as? Int == 2,
            data?["beta"] as? Bool == true,
            roles?.first as? String == "admin"
        else {
            fail("Single-send contract shaping", "captured request body did not match contract")
            return
        }

        pass("Single-send contract shaping")
    } catch {
        fail("Single-send contract shaping", "\(error)")
    }
}

func verifyBulkSend(_ client: HuefyEmailClient, server: LocalStubServer) async {
    do {
        _ = try await client.sendBulkEmails(
            templateKey: " account-update ",
            recipients: [
                BulkRecipient(email: " alice@example.com ", type: "TO", data: ["segment": "vip"]),
                BulkRecipient(email: "bob@example.com", type: "cc", data: ["segment": "standard"])
            ],
            provider: .ses
        )

        guard let captured = server.lastRequest(path: "/emails/send-bulk") else {
            fail("Bulk-send contract shaping", "missing bulk request")
            return
        }

        let body = try decodeJSONBody(captured.body)
        guard
            captured.path == "/emails/send-bulk",
            body["templateKey"] as? String == "account-update",
            body["providerType"] as? String == "ses",
            let recipients = body["recipients"] as? [[String: Any]],
            recipients.count == 2,
            recipients[0]["email"] as? String == "alice@example.com",
            recipients[0]["type"] as? String == "to",
            (recipients[0]["data"] as? [String: Any])?["segment"] as? String == "vip",
            recipients[1]["type"] as? String == "cc"
        else {
            fail("Bulk-send contract shaping", "captured request body did not match contract")
            return
        }

        pass("Bulk-send contract shaping")
    } catch {
        fail("Bulk-send contract shaping", "\(error)")
    }
}

func verifyInvalidSingle(_ client: HuefyEmailClient, server: LocalStubServer) async {
    let before = server.hitCount(path: "/emails/send")
    do {
        _ = try await client.sendEmail(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: "not-an-email"
        )
        fail("Invalid single rejection", "expected validation failure")
    } catch let error as HuefyError {
        if server.hitCount(path: "/emails/send") != before {
            fail("Invalid single rejection", "transport was called for invalid single input")
        } else if error.code != .validationError {
            fail("Invalid single rejection", error.message)
        } else {
            pass("Invalid single rejection")
        }
    } catch {
        fail("Invalid single rejection", "\(error)")
    }
}

func verifyInvalidBulk(_ client: HuefyEmailClient, server: LocalStubServer) async {
    let before = server.hitCount(path: "/emails/send-bulk")
    do {
        _ = try await client.sendBulkEmails(
            templateKey: "welcome",
            recipients: [BulkRecipient(email: "john@example.com", type: "reply-to", data: ["segment": "vip"])]
        )
        fail("Invalid bulk rejection", "expected validation failure")
    } catch let error as HuefyError {
        if server.hitCount(path: "/emails/send-bulk") != before {
            fail("Invalid bulk rejection", "transport was called for invalid bulk input")
        } else if error.code != .validationError || !error.message.contains("recipients[0]") {
            fail("Invalid bulk rejection", error.message)
        } else {
            pass("Invalid bulk rejection")
        }
    } catch {
        fail("Invalid bulk rejection", "\(error)")
    }
}

func verifyHealth(_ client: HuefyEmailClient, server: LocalStubServer) async {
    do {
        let response = try await client.healthCheck()
        guard
            server.lastRequest(path: "/health")?.path == "/health",
            response.data.status == "healthy"
        else {
            fail("Health request path behavior", "health request did not use expected path")
            return
        }

        pass("Health request path behavior")
    } catch {
        fail("Health request path behavior", "\(error)")
    }
}

func verifyCleanup(_ client: HuefyEmailClient) async {
    do {
        client.close()
        _ = try await client.sendEmail(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: "john@example.com"
        )
        fail("Cleanup", "expected closed client to reject requests")
    } catch let error as HuefyError {
        if error.code == .initFailed && error.message.contains("closed") {
            pass("Cleanup")
        } else {
            fail("Cleanup", error.message)
        }
    } catch {
        fail("Cleanup", "\(error)")
    }
}

print("=== Huefy Swift SDK Lab ===\n")

let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        let server = try LocalStubServer()
        try await server.start()
        defer { server.stop() }

        let client = try buildClient(baseURL: server.baseURL)
        pass("Initialization")
        await verifySingleSend(client, server: server)
        await verifyBulkSend(client, server: server)
        await verifyInvalidSingle(client, server: server)
        await verifyInvalidBulk(client, server: server)
        await verifyHealth(client, server: server)
        await verifyCleanup(client)
    } catch {
        fail("Initialization", "\(error)")
    }

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
