import XCTest
@testable import Huefy

final class HuefyEmailClientTests: XCTestCase {

    // MARK: - sendEmail validation

    func testSendEmailThrowsOnEmptyTemplateKey() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))

        do {
            _ = try await client.sendEmail(
                templateKey: "",
                data: ["name": "John"],
                recipient: "john@example.com"
            )
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .validationError)
        }
    }

    func testSendEmailThrowsOnInvalidRecipient() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))

        do {
            _ = try await client.sendEmail(
                templateKey: "welcome",
                data: ["name": "John"],
                recipient: "not-an-email"
            )
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .validationError)
        }
    }

    func testSendEmailThrowsWhenClosed() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))
        client.close()

        do {
            _ = try await client.sendEmail(
                templateKey: "welcome",
                data: ["name": "John"],
                recipient: "john@example.com"
            )
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .initFailed)
        }
    }

    // MARK: - sendBulkEmails validation

    func testSendBulkEmailsThrowsOnEmptyRecipients() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))

        do {
            _ = try await client.sendBulkEmails(templateKey: "welcome", recipients: [])
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .validationError)
        }
    }

    func testSendBulkEmailsThrowsOnInvalidRecipientEmail() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))

        do {
            _ = try await client.sendBulkEmails(
                templateKey: "welcome",
                recipients: [BulkRecipient(email: "not-an-email")]
            )
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .validationError)
            XCTAssertTrue(error.message.contains("recipients[0]"))
        }
    }

    func testSendBulkEmailsThrowsWhenClosed() async throws {
        let client = try HuefyEmailClient(config: HuefyConfig(apiKey: "sdk_test_key"))
        client.close()

        do {
            _ = try await client.sendBulkEmails(
                templateKey: "welcome",
                recipients: [BulkRecipient(email: "john@example.com")]
            )
            XCTFail("Expected HuefyError to be thrown")
        } catch let error as HuefyError {
            XCTAssertEqual(error.code, .initFailed)
        }
    }

    // MARK: - Model construction

    func testSendEmailRequestFieldOrder() {
        let request = SendEmailRequest(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: "john@example.com"
        )
        XCTAssertEqual(request.templateKey, "welcome")
        XCTAssertEqual(request.data, ["name": "John"])
        XCTAssertEqual(request.recipient, "john@example.com")
        XCTAssertNil(request.providerType)
    }

    func testSendBulkEmailsRequestInit() {
        let recipients = [BulkRecipient(email: "alice@example.com", data: ["name": "Alice"])]
        let request = SendBulkEmailsRequest(templateKey: "welcome", recipients: recipients)
        XCTAssertEqual(request.templateKey, "welcome")
        XCTAssertEqual(request.recipients.count, 1)
        XCTAssertNil(request.providerType)
    }
}
