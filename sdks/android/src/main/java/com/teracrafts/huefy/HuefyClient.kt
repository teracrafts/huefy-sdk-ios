package com.teracrafts.huefy

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.math.pow

/**
 * Configuration for the Huefy client
 */
data class HuefyConfiguration(
    val apiKey: String,
    val baseUrl: String = "https://api.huefy.com/api/v1/sdk",
    val timeout: Long = 30_000,
    val retryAttempts: Int = 3,
    val retryDelay: Long = 1_000,
    val enableLogging: Boolean = false
)

/**
 * Main Huefy SDK client for sending template-based emails
 */
class HuefyClient(private val configuration: HuefyConfiguration) {
    
    private val httpClient: OkHttpClient
    private val moshi: Moshi
    
    init {
        val clientBuilder = OkHttpClient.Builder()
            .connectTimeout(configuration.timeout, TimeUnit.MILLISECONDS)
            .readTimeout(configuration.timeout, TimeUnit.MILLISECONDS)
            .writeTimeout(configuration.timeout, TimeUnit.MILLISECONDS)
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .addHeader("Content-Type", "application/json")
                    .addHeader("Accept", "application/json")
                    .addHeader("X-API-Key", configuration.apiKey)
                    .addHeader("User-Agent", "Huefy-Android-SDK/1.0.0")
                    .build()
                chain.proceed(request)
            }
        
        // Logging can be added if needed
        // if (configuration.enableLogging) {
        //     val logging = HttpLoggingInterceptor()
        //     logging.level = HttpLoggingInterceptor.Level.BODY
        //     clientBuilder.addInterceptor(logging)
        // }
        
        httpClient = clientBuilder.build()
        moshi = Moshi.Builder()
            .add(KotlinJsonAdapterFactory())
            .build()
    }
    
    /**
     * Convenience constructor with API key
     */
    constructor(apiKey: String) : this(HuefyConfiguration(apiKey = apiKey))
    
    /**
     * Send a single email using a template
     */
    suspend fun sendEmail(
        templateKey: String,
        data: Map<String, Any>,
        recipient: String,
        provider: EmailProvider? = null
    ): SendEmailResponse {
        val request = SendEmailRequest(
            templateKey = templateKey,
            data = data,
            recipient = recipient,
            provider = provider
        )
        
        return performRequest(
            endpoint = "/emails/send",
            method = HttpMethod.POST,
            body = request,
            responseClass = SendEmailResponse::class.java
        )
    }
    
    /**
     * Send multiple emails in bulk
     */
    suspend fun sendBulkEmails(emails: List<SendEmailRequest>): BulkEmailResponse {
        val request = BulkEmailRequest(emails = emails)
        
        return performRequest(
            endpoint = "/emails/bulk",
            method = HttpMethod.POST,
            body = request,
            responseClass = BulkEmailResponse::class.java
        )
    }
    
    /**
     * Check API health status
     */
    suspend fun healthCheck(): HealthResponse {
        return performRequest(
            endpoint = "/health",
            method = HttpMethod.GET,
            responseClass = HealthResponse::class.java
        )
    }
    
    /**
     * Validate a template with test data
     */
    suspend fun validateTemplate(
        templateKey: String,
        testData: Map<String, Any>
    ): ValidateTemplateResponse {
        val request = ValidateTemplateRequest(
            templateKey = templateKey,
            testData = testData
        )
        
        return performRequest(
            endpoint = "/templates/validate",
            method = HttpMethod.POST,
            body = request,
            responseClass = ValidateTemplateResponse::class.java
        )
    }
    
    /**
     * Get available email providers
     */
    suspend fun getProviders(): ProvidersResponse {
        return performRequest(
            endpoint = "/providers",
            method = HttpMethod.GET,
            responseClass = ProvidersResponse::class.java
        )
    }
    
    // Private implementation
    
    private enum class HttpMethod {
        GET, POST, PUT, DELETE
    }
    
    private suspend fun <T> performRequest(
        endpoint: String,
        method: HttpMethod,
        body: Any? = null,
        responseClass: Class<T>
    ): T {
        var attempt = 0
        var lastException: Exception? = null
        
        while (attempt < configuration.retryAttempts) {
            try {
                return executeRequest(endpoint, method, body, responseClass)
            } catch (e: HuefyException) {
                // Don't retry client errors (4xx)
                when (e) {
                    is HuefyException.InvalidApiKey,
                    is HuefyException.TemplateNotFound,
                    is HuefyException.ValidationError -> throw e
                    else -> lastException = e
                }
            } catch (e: Exception) {
                lastException = e
            }
            
            attempt++
            if (attempt < configuration.retryAttempts) {
                val delay = configuration.retryDelay * (2.0.pow(attempt - 1)).toLong()
                withContext(Dispatchers.IO) {
                    Thread.sleep(delay)
                }
            }
        }
        
        throw lastException ?: HuefyException.Unknown("Request failed after ${configuration.retryAttempts} attempts")
    }
    
    private suspend fun <T> executeRequest(
        endpoint: String,
        method: HttpMethod,
        body: Any?,
        responseClass: Class<T>
    ): T = withContext(Dispatchers.IO) {
        val url = "${configuration.baseUrl}$endpoint"
        val requestBuilder = Request.Builder().url(url)
        
        when (method) {
            HttpMethod.GET -> requestBuilder.get()
            HttpMethod.POST -> {
                val requestBody = if (body != null) {
                    val json = moshi.adapter(body.javaClass).toJson(body)
                    json.toRequestBody("application/json".toMediaType())
                } else {
                    "".toRequestBody("application/json".toMediaType())
                }
                requestBuilder.post(requestBody)
            }
            HttpMethod.PUT -> {
                val requestBody = if (body != null) {
                    val json = moshi.adapter(body.javaClass).toJson(body)
                    json.toRequestBody("application/json".toMediaType())
                } else {
                    "".toRequestBody("application/json".toMediaType())
                }
                requestBuilder.put(requestBody)
            }
            HttpMethod.DELETE -> requestBuilder.delete()
        }
        
        val request = requestBuilder.build()
        val response = httpClient.newCall(request).execute()
        
        if (!response.isSuccessful) {
            handleHttpError(response.code, response.body?.string())
        }
        
        val responseBody = response.body?.string()
            ?: throw HuefyException.Unknown("Empty response body")
        
        try {
            moshi.adapter(responseClass).fromJson(responseBody)
                ?: throw HuefyException.Unknown("Failed to parse response")
        } catch (e: Exception) {
            throw HuefyException.DecodingError("Failed to decode response: ${e.message}")
        }
    }
    
    private fun handleHttpError(statusCode: Int, responseBody: String?): Nothing {
        val errorMessage = try {
            responseBody?.let { body ->
                moshi.adapter(Map::class.java).fromJson(body)?.get("message") as? String
            } ?: "HTTP $statusCode"
        } catch (e: Exception) {
            "HTTP $statusCode"
        }
        
        when (statusCode) {
            400 -> {
                if (errorMessage.contains("template", ignoreCase = true) && 
                    errorMessage.contains("not found", ignoreCase = true)) {
                    throw HuefyException.TemplateNotFound(errorMessage)
                }
                throw HuefyException.ValidationError(errorMessage)
            }
            401 -> throw HuefyException.InvalidApiKey
            404 -> {
                if (errorMessage.contains("template", ignoreCase = true)) {
                    throw HuefyException.TemplateNotFound(errorMessage)
                }
                throw HuefyException.ServerError(statusCode, errorMessage)
            }
            422 -> throw HuefyException.ValidationError(errorMessage)
            429 -> throw HuefyException.RateLimitExceeded(retryAfter = null)
            in 500..599 -> throw HuefyException.ServerError(statusCode, errorMessage)
            else -> throw HuefyException.ServerError(statusCode, errorMessage)
        }
    }
}