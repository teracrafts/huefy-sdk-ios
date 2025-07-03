package com.teracrafts.huefy

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

/**
 * Email provider options
 */
enum class EmailProvider(val value: String) {
    SES("ses"),
    SENDGRID("sendgrid"),
    MAILGUN("mailgun"),
    MAILCHIMP("mailchimp")
}

/**
 * Request to send a single email
 */
@JsonClass(generateAdapter = true)
data class SendEmailRequest(
    @Json(name = "template_key") val templateKey: String,
    val data: Map<String, Any>,
    val recipient: String,
    val provider: EmailProvider? = null
)

/**
 * Response from sending a single email
 */
@JsonClass(generateAdapter = true)
data class SendEmailResponse(
    @Json(name = "message_id") val messageId: String,
    val provider: String,
    val status: String,
    val timestamp: String
)

/**
 * Request to send multiple emails in bulk
 */
@JsonClass(generateAdapter = true)
data class BulkEmailRequest(
    val emails: List<SendEmailRequest>
)

/**
 * Response from sending bulk emails
 */
@JsonClass(generateAdapter = true)
data class BulkEmailResponse(
    val results: List<BulkEmailResult>,
    @Json(name = "success_count") val successCount: Int,
    @Json(name = "failure_count") val failureCount: Int,
    @Json(name = "total_count") val totalCount: Int
)

/**
 * Result for individual email in bulk operation
 */
@JsonClass(generateAdapter = true)
data class BulkEmailResult(
    val email: String,
    val success: Boolean,
    @Json(name = "message_id") val messageId: String?,
    val error: String?
)

/**
 * Health check response
 */
@JsonClass(generateAdapter = true)
data class HealthResponse(
    val status: String,
    val version: String?,
    val uptime: Long?,
    val timestamp: String,
    val providers: Map<String, String>?
)

/**
 * Request to validate a template
 */
@JsonClass(generateAdapter = true)
data class ValidateTemplateRequest(
    @Json(name = "template_key") val templateKey: String,
    @Json(name = "test_data") val testData: Map<String, Any>
)

/**
 * Response from template validation
 */
@JsonClass(generateAdapter = true)
data class ValidateTemplateResponse(
    val valid: Boolean,
    val errors: List<String>?
)

/**
 * Response containing available providers
 */
@JsonClass(generateAdapter = true)
data class ProvidersResponse(
    val providers: List<Provider>
)

/**
 * Provider information
 */
@JsonClass(generateAdapter = true)
data class Provider(
    val name: String,
    val status: String,
    val description: String?,
    val features: List<String>?
)