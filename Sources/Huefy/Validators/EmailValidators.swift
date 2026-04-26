import Foundation

/// Validation utilities for email-related inputs.
public enum EmailValidators {

    /// Regex pattern for basic email validation.
    private static let emailRegex = try! NSRegularExpression(
        pattern: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"
    )

    /// Maximum allowed email address length.
    public static let maxEmailLength = 254

    /// Maximum allowed template key length.
    public static let maxTemplateKeyLength = 100

    /// Maximum number of emails in a single bulk request.
    public static let maxBulkEmails = 1000

    // MARK: - Individual Validators

    /// Validates a recipient email address.
    ///
    /// - Parameter email: The email address to validate.
    /// - Returns: An error message string, or `nil` if valid.
    public static func validateEmail(_ email: String) -> String? {
        if email.isEmpty {
            return "recipient email is required"
        }

        let trimmed = email.trimmingCharacters(in: .whitespaces)

        if trimmed.count > maxEmailLength {
            return "email exceeds maximum length of \(maxEmailLength) characters"
        }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if emailRegex.firstMatch(in: trimmed, range: range) == nil {
            return "invalid email address: \(trimmed)"
        }

        return nil
    }

    /// Validates a template key.
    ///
    /// - Parameter key: The template key to validate.
    /// - Returns: An error message string, or `nil` if valid.
    public static func validateTemplateKey(_ key: String) -> String? {
        if key.isEmpty {
            return "template key is required"
        }

        let trimmed = key.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            return "template key cannot be empty"
        }

        if trimmed.count > maxTemplateKeyLength {
            return "template key exceeds maximum length of \(maxTemplateKeyLength) characters"
        }

        return nil
    }

    /// Validates template data.
    ///
    /// - Parameter data: The template data dictionary.
    /// - Returns: An error message string, or `nil` if valid.
    public static func validateEmailData(_ data: [String: JSONValue]?) -> String? {
        if data == nil {
            return "template data is required"
        }
        return nil
    }

    public static func validateEmailData(_ data: [String: String]) -> String? {
        validateEmailData(data.mapValues(JSONValue.string))
    }

    /// Validates the count of emails in a bulk request.
    ///
    /// - Parameter count: The number of emails.
    /// - Returns: An error message string, or `nil` if valid.
    public static func validateBulkCount(_ count: Int) -> String? {
        if count <= 0 {
            return "at least one email is required"
        }
        if count > maxBulkEmails {
            return "maximum of \(maxBulkEmails) emails per bulk request"
        }
        return nil
    }

    // MARK: - Combined Validation

    /// Validates all inputs for sending a single email.
    ///
    /// - Parameters:
    ///   - templateKey: The template key.
    ///   - data: The template data.
    ///   - recipient: The recipient email.
    /// - Returns: An array of error message strings. Empty if all inputs are valid.
    public static func validateSendEmailInput(
        templateKey: String,
        data: [String: JSONValue]?,
        recipient: String
    ) -> [String] {
        var errors: [String] = []

        if let err = validateTemplateKey(templateKey) {
            errors.append(err)
        }
        if let err = validateEmailData(data) {
            errors.append(err)
        }
        if let err = validateEmail(recipient) {
            errors.append(err)
        }

        return errors
    }

    public static func validateSendEmailInput(
        templateKey: String,
        data: [String: String],
        recipient: String
    ) -> [String] {
        validateSendEmailInput(
            templateKey: templateKey,
            data: data.mapValues(JSONValue.string),
            recipient: recipient
        )
    }
}
