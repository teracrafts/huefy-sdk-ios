import XCTest
@testable import HuefySDK

final class HuefySDKTests: XCTestCase {
    
    var client: HuefyClient!
    
    override func setUp() {
        super.setUp()
        client = HuefyClient(apiKey: "test-api-key")
    }
    
    override func tearDown() {
        client = nil
        super.tearDown()
    }
    
    func testClientInitialization() {
        XCTAssertNotNil(client)
    }
    
    func testConfigurationInitialization() {
        let config = HuefyConfiguration(
            apiKey: "test-key",
            baseURL: URL(string: "https://test.api.com")!,
            timeout: 60.0,
            retryAttempts: 5,
            retryDelay: 2.0
        )
        
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.baseURL.absoluteString, "https://test.api.com")
        XCTAssertEqual(config.timeout, 60.0)
        XCTAssertEqual(config.retryAttempts, 5)
        XCTAssertEqual(config.retryDelay, 2.0)
    }
    
    func testEmailProviderRawValues() {
        XCTAssertEqual(EmailProvider.ses.rawValue, "ses")
        XCTAssertEqual(EmailProvider.sendgrid.rawValue, "sendgrid")
        XCTAssertEqual(EmailProvider.mailgun.rawValue, "mailgun")
        XCTAssertEqual(EmailProvider.mailchimp.rawValue, "mailchimp")
    }
    
    func testSendEmailRequestInitialization() {
        let request = SendEmailRequest(
            templateKey: "test-template",
            data: ["name": "John", "age": 30],
            recipient: "john@example.com",
            provider: .ses
        )
        
        XCTAssertEqual(request.templateKey, "test-template")
        XCTAssertEqual(request.recipient, "john@example.com")
        XCTAssertEqual(request.provider, .ses)
        XCTAssertEqual(request.data["name"] as? String, "John")
        XCTAssertEqual(request.data["age"] as? Int, 30)
    }
    
    func testHuefyErrorDescription() {
        let invalidApiKeyError = HuefyError.invalidApiKey
        XCTAssertEqual(invalidApiKeyError.errorDescription, "Invalid API key provided")
        
        let templateNotFoundError = HuefyError.templateNotFound("test-template")
        XCTAssertEqual(templateNotFoundError.errorDescription, "Template 'test-template' not found")
        
        let validationError = HuefyError.validationError("Invalid email", nil)
        XCTAssertEqual(validationError.errorDescription, "Validation error: Invalid email")
        
        let rateLimitError = HuefyError.rateLimitExceeded(retryAfter: 30.0)
        XCTAssertEqual(rateLimitError.errorDescription, "Rate limit exceeded. Retry after 30.0 seconds")
        
        let serverError = HuefyError.serverError(500, "Internal server error")
        XCTAssertEqual(serverError.errorDescription, "Server error 500: Internal server error")
    }
    
    func testHuefyErrorEquality() {
        XCTAssertEqual(HuefyError.invalidApiKey, HuefyError.invalidApiKey)
        XCTAssertEqual(HuefyError.templateNotFound("test"), HuefyError.templateNotFound("test"))
        XCTAssertNotEqual(HuefyError.templateNotFound("test1"), HuefyError.templateNotFound("test2"))
        XCTAssertEqual(HuefyError.validationError("msg", nil), HuefyError.validationError("msg", nil))
        XCTAssertEqual(HuefyError.serverError(500, "error"), HuefyError.serverError(500, "error"))
    }
    
    func testBulkEmailRequestInitialization() {
        let emails = [
            SendEmailRequest(
                templateKey: "template1",
                data: ["name": "John"],
                recipient: "john@example.com"
            ),
            SendEmailRequest(
                templateKey: "template2",
                data: ["name": "Jane"],
                recipient: "jane@example.com"
            )
        ]
        
        let bulkRequest = BulkEmailRequest(emails: emails)
        XCTAssertEqual(bulkRequest.emails.count, 2)
        XCTAssertEqual(bulkRequest.emails[0].templateKey, "template1")
        XCTAssertEqual(bulkRequest.emails[1].templateKey, "template2")
    }
    
    func testValidateTemplateRequestInitialization() {
        let testData = ["name": "Test User", "company": "Test Corp"]
        let request = ValidateTemplateRequest(
            templateKey: "test-template",
            testData: testData
        )
        
        XCTAssertEqual(request.templateKey, "test-template")
        XCTAssertEqual(request.testData["name"] as? String, "Test User")
        XCTAssertEqual(request.testData["company"] as? String, "Test Corp")
    }
    
    // Integration tests would go here if we had a test environment
    // For now, these are unit tests for the public API
    
    func testDefaultConfiguration() {
        let config = HuefyConfiguration(apiKey: "test-key")
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.huefy.com/api/v1/sdk")
        XCTAssertEqual(config.timeout, 30.0)
        XCTAssertEqual(config.retryAttempts, 3)
        XCTAssertEqual(config.retryDelay, 1.0)
    }
    
    func testConvenienceInitializer() {
        let client = HuefyClient(apiKey: "test-key")
        XCTAssertNotNil(client)
    }
}