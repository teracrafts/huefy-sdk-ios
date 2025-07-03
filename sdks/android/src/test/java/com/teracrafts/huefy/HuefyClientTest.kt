package com.teracrafts.huefy

import kotlinx.coroutines.runBlocking
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.util.concurrent.TimeUnit

class HuefyClientTest {
    
    private lateinit var mockWebServer: MockWebServer
    private lateinit var client: HuefyClient
    
    @Before
    fun setup() {
        mockWebServer = MockWebServer()
        mockWebServer.start()
        
        val config = HuefyConfiguration(
            apiKey = "test-api-key",
            baseUrl = mockWebServer.url("/").toString().trimEnd('/'),
            timeout = 5_000,
            retryAttempts = 1
        )
        client = HuefyClient(config)
    }
    
    @After
    fun teardown() {
        mockWebServer.shutdown()
    }
    
    @Test
    fun testClientInitialization() {
        assertNotNull(client)
    }
    
    @Test
    fun testConvenienceConstructor() {
        val simpleClient = HuefyClient("test-key")
        assertNotNull(simpleClient)
    }
    
    @Test
    fun testConfigurationDefaults() {
        val config = HuefyConfiguration(apiKey = "test-key")
        assertEquals("test-key", config.apiKey)
        assertEquals("https://api.huefy.com/api/v1/sdk", config.baseUrl)
        assertEquals(30_000, config.timeout)
        assertEquals(3, config.retryAttempts)
        assertEquals(1_000, config.retryDelay)
        assertFalse(config.enableLogging)
    }
    
    @Test
    fun testEmailProviderValues() {
        assertEquals("ses", EmailProvider.SES.value)
        assertEquals("sendgrid", EmailProvider.SENDGRID.value)
        assertEquals("mailgun", EmailProvider.MAILGUN.value)
        assertEquals("mailchimp", EmailProvider.MAILCHIMP.value)
    }
    
    @Test
    fun testSendEmailSuccess() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(200)
            .setBody("""
                {
                    "message_id": "test-123",
                    "provider": "ses",
                    "status": "sent",
                    "timestamp": "2023-01-01T00:00:00Z"
                }
            """.trimIndent())
        
        mockWebServer.enqueue(mockResponse)
        
        val response = client.sendEmail(
            templateKey = "test-template",
            data = mapOf("name" to "John", "age" to 30),
            recipient = "john@example.com",
            provider = EmailProvider.SES
        )
        
        assertEquals("test-123", response.messageId)
        assertEquals("ses", response.provider)
        assertEquals("sent", response.status)
        
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request)
        assertEquals("POST", request.method)
        assertEquals("/emails/send", request.path)
        assertEquals("application/json", request.getHeader("Content-Type"))
        assertEquals("test-api-key", request.getHeader("X-API-Key"))
        assertTrue(request.body.readUtf8().contains("test-template"))
    }
    
    @Test
    fun testSendEmailInvalidApiKey() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(401)
            .setBody("""{"message": "Invalid API key"}""")
        
        mockWebServer.enqueue(mockResponse)
        
        try {
            client.sendEmail(
                templateKey = "test-template",
                data = mapOf("name" to "John"),
                recipient = "john@example.com"
            )
            fail("Expected HuefyException.InvalidApiKey")
        } catch (e: HuefyException.InvalidApiKey) {
            // Expected
        }
    }
    
    @Test
    fun testSendEmailTemplateNotFound() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(404)
            .setBody("""{"message": "Template not found"}""")
        
        mockWebServer.enqueue(mockResponse)
        
        try {
            client.sendEmail(
                templateKey = "nonexistent-template",
                data = mapOf("name" to "John"),
                recipient = "john@example.com"
            )
            fail("Expected HuefyException.TemplateNotFound")
        } catch (e: HuefyException.TemplateNotFound) {
            assertTrue(e.message!!.contains("Template"))
        }
    }
    
    @Test
    fun testSendEmailValidationError() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(400)
            .setBody("""{"message": "Invalid email format"}""")
        
        mockWebServer.enqueue(mockResponse)
        
        try {
            client.sendEmail(
                templateKey = "test-template",
                data = mapOf("name" to "John"),
                recipient = "invalid-email"
            )
            fail("Expected HuefyException.ValidationError")
        } catch (e: HuefyException.ValidationError) {
            assertTrue(e.message!!.contains("Invalid email format"))
        }
    }
    
    @Test
    fun testSendEmailRateLimitExceeded() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(429)
            .setBody("""{"message": "Rate limit exceeded"}""")
        
        mockWebServer.enqueue(mockResponse)
        
        try {
            client.sendEmail(
                templateKey = "test-template",
                data = mapOf("name" to "John"),
                recipient = "john@example.com"
            )
            fail("Expected HuefyException.RateLimitExceeded")
        } catch (e: HuefyException.RateLimitExceeded) {
            assertTrue(e.message!!.contains("Rate limit exceeded"))
        }
    }
    
    @Test
    fun testSendEmailServerError() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(500)
            .setBody("""{"message": "Internal server error"}""")
        
        mockWebServer.enqueue(mockResponse)
        
        try {
            client.sendEmail(
                templateKey = "test-template",
                data = mapOf("name" to "John"),
                recipient = "john@example.com"
            )
            fail("Expected HuefyException.ServerError")
        } catch (e: HuefyException.ServerError) {
            assertEquals(500, e.statusCode)
            assertTrue(e.message!!.contains("Internal server error"))
        }
    }
    
    @Test
    fun testHealthCheckSuccess() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(200)
            .setBody("""
                {
                    "status": "healthy",
                    "version": "1.0.0",
                    "uptime": 12345,
                    "timestamp": "2023-01-01T00:00:00Z",
                    "providers": {
                        "ses": "healthy",
                        "sendgrid": "healthy"
                    }
                }
            """.trimIndent())
        
        mockWebServer.enqueue(mockResponse)
        
        val response = client.healthCheck()
        
        assertEquals("healthy", response.status)
        assertEquals("1.0.0", response.version)
        assertEquals(12345L, response.uptime)
        assertNotNull(response.providers)
        assertEquals("healthy", response.providers?.get("ses"))
        
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request)
        assertEquals("GET", request.method)
        assertEquals("/health", request.path)
    }
    
    @Test
    fun testBulkEmailSuccess() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(200)
            .setBody("""
                {
                    "results": [
                        {
                            "email": "john@example.com",
                            "success": true,
                            "message_id": "msg-123",
                            "error": null
                        },
                        {
                            "email": "jane@example.com",
                            "success": false,
                            "message_id": null,
                            "error": "Invalid email"
                        }
                    ],
                    "success_count": 1,
                    "failure_count": 1,
                    "total_count": 2
                }
            """.trimIndent())
        
        mockWebServer.enqueue(mockResponse)
        
        val emails = listOf(
            SendEmailRequest(
                templateKey = "test-template",
                data = mapOf("name" to "John"),
                recipient = "john@example.com"
            ),
            SendEmailRequest(
                templateKey = "test-template",
                data = mapOf("name" to "Jane"),
                recipient = "jane@example.com"
            )
        )
        
        val response = client.sendBulkEmails(emails)
        
        assertEquals(2, response.results.size)
        assertEquals(1, response.successCount)
        assertEquals(1, response.failureCount)
        assertEquals(2, response.totalCount)
        
        val successResult = response.results.find { it.success }
        assertNotNull(successResult)
        assertEquals("john@example.com", successResult?.email)
        assertEquals("msg-123", successResult?.messageId)
        
        val failureResult = response.results.find { !it.success }
        assertNotNull(failureResult)
        assertEquals("jane@example.com", failureResult?.email)
        assertEquals("Invalid email", failureResult?.error)
    }
    
    @Test
    fun testValidateTemplateSuccess() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(200)
            .setBody("""
                {
                    "valid": true,
                    "errors": null
                }
            """.trimIndent())
        
        mockWebServer.enqueue(mockResponse)
        
        val response = client.validateTemplate(
            templateKey = "test-template",
            testData = mapOf("name" to "Test User", "company" to "Test Corp")
        )
        
        assertTrue(response.valid)
        assertNull(response.errors)
        
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request)
        assertEquals("POST", request.method)
        assertEquals("/templates/validate", request.path)
        assertTrue(request.body.readUtf8().contains("test-template"))
    }
    
    @Test
    fun testValidateTemplateWithErrors() = runBlocking {
        val mockResponse = MockResponse()
            .setResponseCode(200)
            .setBody("""
                {
                    "valid": false,
                    "errors": ["Missing required field: name", "Invalid format: email"]
                }
            """.trimIndent())
        
        mockWebServer.enqueue(mockResponse)
        
        val response = client.validateTemplate(
            templateKey = "test-template",
            testData = mapOf("company" to "Test Corp")
        )
        
        assertFalse(response.valid)
        assertNotNull(response.errors)
        assertEquals(2, response.errors?.size)
        assertTrue(response.errors?.contains("Missing required field: name") == true)
        assertTrue(response.errors?.contains("Invalid format: email") == true)
    }
}