import Foundation

/// Supported email providers for the Huefy API.
public enum EmailProvider: String, Codable, Sendable, CaseIterable {
    case ses = "ses"
    case sendgrid = "sendgrid"
    case mailgun = "mailgun"
    case mailchimp = "mailchimp"
}
