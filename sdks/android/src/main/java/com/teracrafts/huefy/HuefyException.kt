package com.teracrafts.huefy

/**
 * Base exception class for all Huefy SDK errors
 */
sealed class HuefyException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    
    /**
     * Invalid API key provided
     */
    object InvalidApiKey : HuefyException("Invalid API key provided")
    
    /**
     * Invalid URL configuration
     */
    object InvalidUrl : HuefyException("Invalid URL configuration")
    
    /**
     * Network error occurred
     */
    class NetworkError(cause: Throwable) : HuefyException("Network error: ${cause.message}", cause)
    
    /**
     * Failed to decode response
     */
    class DecodingError(message: String) : HuefyException("Failed to decode response: $message")
    
    /**
     * Failed to encode request
     */
    class EncodingError(message: String) : HuefyException("Failed to encode request: $message")
    
    /**
     * Template not found
     */
    class TemplateNotFound(templateKey: String) : HuefyException("Template '$templateKey' not found")
    
    /**
     * Validation error
     */
    class ValidationError(message: String, val details: Map<String, Any>? = null) : HuefyException("Validation error: $message")
    
    /**
     * Rate limit exceeded
     */
    class RateLimitExceeded(val retryAfter: Long? = null) : HuefyException(
        if (retryAfter != null) "Rate limit exceeded. Retry after $retryAfter seconds" else "Rate limit exceeded"
    )
    
    /**
     * Provider error
     */
    class ProviderError(val provider: String, val code: String? = null) : HuefyException(
        "Provider '$provider' error${code?.let { " ($it)" } ?: ""}"
    )
    
    /**
     * Server error
     */
    class ServerError(val statusCode: Int, val responseMessage: String? = null) : HuefyException(
        "Server error $statusCode${responseMessage?.let { ": $it" } ?: ""}"
    )
    
    /**
     * Unknown error
     */
    class Unknown(message: String) : HuefyException("Unknown error: $message")
}