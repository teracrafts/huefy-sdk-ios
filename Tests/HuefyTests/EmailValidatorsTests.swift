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

    func testNilDataReturnsError() {
        XCTAssertNotNil(EmailValidators.validateEmailData(nil))
    }

    func testEmptyDataReturnsNil() {
        XCTAssertNil(EmailValidators.validateEmailData([:]))
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
        let result = EmailValidators.validateBulkCount(101)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("maximum"))
    }

    func testBulkCountAtLimitReturnsNil() {
        XCTAssertNil(EmailValidators.validateBulkCount(100))
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
            data: nil,
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
}
