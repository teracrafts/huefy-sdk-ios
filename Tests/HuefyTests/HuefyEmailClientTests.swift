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
                recipients: [BulkRecipient(email: "not-an-email", data: nil as [String: JSONValue]?)]
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
                recipients: [BulkRecipient(email: "john@example.com", data: nil as [String: JSONValue]?)]
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
        XCTAssertNil(request.recipientObject)
        XCTAssertNil(request.providerType)
    }

    func testSendEmailRequestEncodesCamelCaseKeysAndJSONValues() throws {
        let request = SendEmailRequest(
            templateKey: "welcome",
            data: [
                "name": "John",
                "count": 2,
                "beta": true
            ],
            recipient: "john@example.com",
            providerType: .sendgrid
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        XCTAssertEqual(json["templateKey"] as? String, "welcome")
        XCTAssertEqual(json["providerType"] as? String, "sendgrid")
        XCTAssertNil(json["template_key"])
        XCTAssertNil(json["provider_type"])

        let data = try XCTUnwrap(json["data"] as? [String: Any])
        XCTAssertEqual(data["name"] as? String, "John")
        XCTAssertEqual(data["count"] as? Int, 2)
        XCTAssertEqual(data["beta"] as? Bool, true)
    }

    func testSendEmailRequestEncodesRecipientObject() throws {
        let request = SendEmailRequest(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: SendEmailRecipient(
                email: "john@example.com",
                type: "cc",
                data: ["segment": "vip"]
            ),
            providerType: .ses
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        let recipient = try XCTUnwrap(json["recipient"] as? [String: Any])
        XCTAssertEqual(recipient["email"] as? String, "john@example.com")
        XCTAssertEqual(recipient["type"] as? String, "cc")
        XCTAssertEqual((recipient["data"] as? [String: Any])?["segment"] as? String, "vip")
    }

    func testSendBulkEmailsRequestInit() {
        let recipients = [BulkRecipient(email: "alice@example.com", data: ["name": "Alice"])]
        let request = SendBulkEmailsRequest(templateKey: "welcome", recipients: recipients)
        XCTAssertEqual(request.templateKey, "welcome")
        XCTAssertEqual(request.recipients.count, 1)
        XCTAssertNil(request.providerType)
    }
}
