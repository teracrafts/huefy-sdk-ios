# Huefy Android SDK

Official Android SDK for sending emails via the Huefy API.

## Installation

### Gradle (Kotlin DSL)

Add the dependency to your `build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.teracrafts:huefy-sdk:1.0.0")
}
```

### Gradle (Groovy)

Add the dependency to your `build.gradle`:

```groovy
dependencies {
    implementation 'com.teracrafts:huefy-sdk:1.0.0'
}
```

### Maven

Add the dependency to your `pom.xml`:

```xml
<dependency>
    <groupId>com.teracrafts</groupId>
    <artifactId>huefy-sdk</artifactId>
    <version>1.0.0</version>
</dependency>
```

## Usage

### Basic Usage

```kotlin
import com.teracrafts.huefy.HuefyClient
import com.teracrafts.huefy.EmailProvider

// Initialize the client
val client = HuefyClient(apiKey = "your-api-key")

// Send an email
try {
    val response = client.sendEmail(
        templateKey = "welcome-email",
        data = mapOf("name" to "John Doe", "company" to "Acme Inc"),
        recipient = "john@example.com"
    )
    println("Email sent with ID: ${response.messageId}")
} catch (e: Exception) {
    println("Failed to send email: ${e.message}")
}
```

### Advanced Configuration

```kotlin
import com.teracrafts.huefy.HuefyClient
import com.teracrafts.huefy.HuefyConfiguration

val config = HuefyConfiguration(
    apiKey = "your-api-key",
    baseUrl = "https://api.huefy.com/api/v1/sdk",
    timeout = 30_000,
    retryAttempts = 3,
    retryDelay = 1_000,
    enableLogging = true
)

val client = HuefyClient(config)
```

### Using Specific Providers

```kotlin
// Send with a specific provider
val response = client.sendEmail(
    templateKey = "newsletter",
    data = mapOf("content" to "Monthly updates"),
    recipient = "subscriber@example.com",
    provider = EmailProvider.SENDGRID
)
```

### Bulk Email Sending

```kotlin
import com.teracrafts.huefy.SendEmailRequest

val emails = listOf(
    SendEmailRequest(
        templateKey = "welcome-email",
        data = mapOf("name" to "John"),
        recipient = "john@example.com"
    ),
    SendEmailRequest(
        templateKey = "welcome-email",
        data = mapOf("name" to "Jane"),
        recipient = "jane@example.com"
    )
)

val response = client.sendBulkEmails(emails)
println("Sent ${response.successCount} emails successfully")
```

### Using with Coroutines

```kotlin
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

// In a coroutine scope
launch {
    try {
        val response = client.sendEmail(
            templateKey = "welcome-email",
            data = mapOf("name" to "John"),
            recipient = "john@example.com"
        )
        println("Email sent: ${response.messageId}")
    } catch (e: Exception) {
        println("Error: ${e.message}")
    }
}

// Or using runBlocking for synchronous usage
runBlocking {
    val response = client.sendEmail(
        templateKey = "welcome-email",
        data = mapOf("name" to "John"),
        recipient = "john@example.com"
    )
    println("Email sent: ${response.messageId}")
}
```

### Error Handling

```kotlin
import com.teracrafts.huefy.HuefyException

try {
    val response = client.sendEmail(
        templateKey = "welcome-email",
        data = mapOf("name" to "John"),
        recipient = "john@example.com"
    )
} catch (e: HuefyException.InvalidApiKey) {
    println("Invalid API key")
} catch (e: HuefyException.TemplateNotFound) {
    println("Template not found: ${e.message}")
} catch (e: HuefyException.ValidationError) {
    println("Validation error: ${e.message}")
} catch (e: HuefyException.RateLimitExceeded) {
    println("Rate limited, retry after: ${e.retryAfter ?: 0} seconds")
} catch (e: HuefyException.ServerError) {
    println("Server error ${e.statusCode}: ${e.responseMessage}")
} catch (e: Exception) {
    println("Unexpected error: ${e.message}")
}
```

### Template Validation

```kotlin
val response = client.validateTemplate(
    templateKey = "welcome-email",
    testData = mapOf("name" to "Test User", "company" to "Test Corp")
)

if (response.valid) {
    println("Template is valid")
} else {
    println("Template errors: ${response.errors}")
}
```

### Health Check

```kotlin
val health = client.healthCheck()
println("API Status: ${health.status}")
println("Version: ${health.version ?: "unknown"}")
```

### Android-specific Usage

When using in Android applications, ensure network calls are made on a background thread:

```kotlin
// In an Activity or Fragment
lifecycleScope.launch {
    try {
        val response = client.sendEmail(
            templateKey = "welcome-email",
            data = mapOf("name" to "John"),
            recipient = "john@example.com"
        )
        // Update UI on main thread
        withContext(Dispatchers.Main) {
            // Update your UI here
        }
    } catch (e: Exception) {
        // Handle error
    }
}
```

## API Reference

### HuefyClient

The main client for interacting with the Huefy API.

#### Methods

- `sendEmail(templateKey, data, recipient, provider?)` - Send a single email
- `sendBulkEmails(emails)` - Send multiple emails
- `validateTemplate(templateKey, testData)` - Validate a template
- `healthCheck()` - Check API health
- `getProviders()` - Get available providers

### Email Providers

Available email providers:
- `EmailProvider.SES` (default)
- `EmailProvider.SENDGRID`
- `EmailProvider.MAILGUN`
- `EmailProvider.MAILCHIMP`

### Exception Types

- `HuefyException.InvalidApiKey` - Invalid API key
- `HuefyException.TemplateNotFound` - Template not found
- `HuefyException.ValidationError` - Validation error
- `HuefyException.RateLimitExceeded` - Rate limit exceeded
- `HuefyException.NetworkError` - Network error
- `HuefyException.ServerError` - Server error

## Requirements

- Android API level 21 (Android 5.0) or higher
- Kotlin 1.9.0 or higher
- Java 11 or higher

## Permissions

Add the following permission to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## ProGuard/R8

If you're using ProGuard or R8, add the following rules to your `proguard-rules.pro`:

```pro
# Huefy SDK
-keep class com.teracrafts.huefy.** { *; }

# Moshi
-keepclasseswithmembers class * {
    @com.squareup.moshi.* <methods>;
}
-keep @com.squareup.moshi.JsonQualifier interface *
-keepclassmembers @com.squareup.moshi.JsonClass class * extends java.lang.Enum {
    <fields>;
}

# OkHttp
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
```

## Support

For issues and questions, please visit our [GitHub repository](https://github.com/teracrafts/huefy-sdk-android).