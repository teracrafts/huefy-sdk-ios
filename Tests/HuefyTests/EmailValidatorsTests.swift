import XCTest
@testable import Huefy

final class EmailValidatorsTests: XCTestCase {

    // MARK: - validateEmail

    func testValidEmailReturnsNil() {
        XCTAssertNil(EmailValidators.validateEmail("user@example.com"))
    }

    func testEmptyEmailReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmail(""))
    }

    func testEmailWithoutAtSignReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmail("userexample.com"))
    }

    func testEmailWithoutDomainReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmail("user@"))
    }

    func testEmailExceedingMaxLengthReturnsError() {
        let longEmail = String(repeating: "a", count: 250) + "@b.co"
        let result = EmailValidators.validateEmail(longEmail)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("maximum length"))
    }

    func testEmailWithSpacesReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmail("user @example.com"))
    }

    func testValidEmailWithSubdomainReturnsNil() {
        XCTAssertNil(EmailValidators.validateEmail("user@mail.example.com"))
    }

    // MARK: - validateTemplateKey

    func testValidTemplateKeyReturnsNil() {
        XCTAssertNil(EmailValidators.validateTemplateKey("welcome-email"))
    }

    func testEmptyTemplateKeyReturnsError() {
        XCTAssertNotNil(EmailValidators.validateTemplateKey(""))
    }

    func testWhitespaceOnlyTemplateKeyReturnsError() {
        XCTAssertNotNil(EmailValidators.validateTemplateKey("   "))
    }

    func testTemplateKeyExceedingMaxLengthReturnsError() {
        let longKey = String(repeating: "a", count: 101)
        let result = EmailValidators.validateTemplateKey(longKey)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("maximum length"))
    }

    func testTemplateKeyAtMaxLengthReturnsNil() {
        let key = String(repeating: "a", count: 100)
        XCTAssertNil(EmailValidators.validateTemplateKey(key))
    }

    // MARK: - validateEmailData

    func testValidDataReturnsNil() {
        XCTAssertNil(EmailValidators.validateEmailData(["name": "John"]))
    }

    func testValidStructuredDataReturnsNil() {
        XCTAssertNil(
            EmailValidators.validateEmailData([
                "count": 2,
                "beta": true,
                "profile": ["plan": "pro"]
            ])
        )
    }

    func testNilDataReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmailData(nil as [String: JSONValue]?))
    }

    func testEmptyDataReturnsNil() {
        XCTAssertNil(EmailValidators.validateEmailData([:] as [String: JSONValue]))
    }

    // MARK: - validateBulkCount

    func testValidBulkCountReturnsNil() {
        XCTAssertNil(EmailValidators.validateBulkCount(10))
    }

    func testZeroBulkCountReturnsError() {
        XCTAssertNotNil(EmailValidators.validateBulkCount(0))
    }

    func testNegativeBulkCountReturnsError() {
        XCTAssertNotNil(EmailValidators.validateBulkCount(-1))
    }

    func testBulkCountOverLimitReturnsError() {
        let result = EmailValidators.validateBulkCount(1001)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("maximum"))
    }

    func testBulkCountAtLimitReturnsNil() {
        XCTAssertNil(EmailValidators.validateBulkCount(1000))
    }

    // MARK: - validateSendEmailInput

    func testValidInputReturnsEmptyArray() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: "user@example.com"
        )
        XCTAssertTrue(errors.isEmpty)
    }

    func testInvalidInputReturnsErrors() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "",
            data: nil as [String: JSONValue]?,
            recipient: "bad"
        )
        XCTAssertGreaterThanOrEqual(errors.count, 3)
    }

    func testPartiallyInvalidInputReturnsPartialErrors() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: "bad"
        )
        XCTAssertEqual(errors.count, 1)
    }

    func testRecipientObjectInputReturnsNoErrors() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: SendEmailRecipient(
                email: "user@example.com",
                type: "cc",
                data: ["segment": "vip"]
            )
        )
        XCTAssertTrue(errors.isEmpty)
    }

    func testInvalidRecipientObjectReturnsError() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: SendEmailRecipient(email: "bad", type: "cc")
        )
        XCTAssertEqual(errors.count, 1)
    }

    func testInvalidRecipientObjectTypeReturnsError() {
        let errors = EmailValidators.validateSendEmailInput(
            templateKey: "welcome",
            data: ["name": "John"],
            recipient: SendEmailRecipient(email: "user@example.com", type: "weird")
        )
        XCTAssertEqual(errors, ["recipient type must be one of: to, cc, bcc"])
    }
}
