# Huefy SDK Examples

This directory contains comprehensive examples for all Huefy SDKs across different programming languages. Each example demonstrates the core functionality of the SDK including sending emails, error handling, and advanced features.

## Available Examples

### JavaScript/TypeScript
- **Location**: [`../sdks/javascript/examples/`](../sdks/javascript/examples/)
- **Files**:
  - `basic-usage.js` - Core JavaScript functionality
  - `typescript-example.ts` - TypeScript-specific features with type safety
- **Features**: Promise-based API, retry logic, multiple providers, error handling

### React
- **Location**: [`../sdks/react/examples/`](../sdks/react/examples/)
- **Files**:
  - `basic-usage.tsx` - Complete React application with hooks
- **Features**: Context provider, hooks, loading states, form handling, bulk operations

### Go
- **Location**: [`../sdks/go/examples/`](../sdks/go/examples/)
- **Files**:
  - `main.go` - Complete Go example with context support
- **Features**: Context-aware operations, structured error handling, concurrent operations

### Java
- **Location**: [`../sdks/java/examples/`](../sdks/java/examples/)
- **Files**:
  - `BasicUsage.java` - Comprehensive Java example
- **Features**: Builder pattern, async operations, exception hierarchy, custom configurations

### Python
- **Location**: [`../sdks/python/examples/`](../sdks/python/examples/)
- **Files**:
  - `basic_usage.py` - Complete Python example with sync and async
- **Features**: Context managers, async/await, type hints, Pydantic models

### PHP
- **Location**: [`../sdks/php/examples/`](../sdks/php/examples/)
- **Files**:
  - `basic_usage.php` - Complete PHP example
- **Features**: PSR standards, strict types, enums (PHP 8.0+), comprehensive error handling

## Common Features Demonstrated

All examples demonstrate these core features:

### 🚀 **Basic Email Sending**
- Single email sending with templates
- Template data substitution
- Provider selection

### 📧 **Bulk Email Operations**
- Sending multiple emails in one request
- Batch processing with success/failure tracking
- Performance optimization

### 🛡️ **Error Handling**
- Authentication errors
- Validation errors
- Network timeouts
- Rate limiting
- Provider-specific errors

### ⚙️ **Configuration**
- Custom timeouts
- Retry logic with exponential backoff
- Base URL configuration
- User agent customization

### 🔄 **Provider Support**
- Amazon SES
- SendGrid
- Mailgun
- Mailchimp Transactional

### 🏥 **Health Monitoring**
- API health checks
- Version information
- Uptime tracking

## Quick Start

### 1. Set Your API Key
Set your Huefy API key as an environment variable:

```bash
export HUEFY_API_KEY="your-actual-api-key"
```

### 2. Run Examples

#### JavaScript/Node.js
```bash
cd sdks/javascript/examples
npm install
node basic-usage.js
```

#### TypeScript
```bash
cd sdks/javascript/examples
npm install
npx tsx typescript-example.ts
```

#### React
```bash
cd sdks/react/examples
npm install
npm start
```

#### Go
```bash
cd sdks/go/examples
go mod tidy
go run main.go
```

#### Java
```bash
cd sdks/java/examples
mvn compile exec:java -Dexec.mainClass="com.huefy.sdk.examples.BasicUsage"
```

#### Python
```bash
cd sdks/python/examples
pip install -r ../requirements.txt
python basic_usage.py
```

#### PHP
```bash
cd sdks/php/examples
composer install
php basic_usage.php
```

## Example Templates

All examples use these common email templates:

### Welcome Email (`welcome-email`)
```json
{
  "name": "John Doe",
  "company": "Acme Corp",
  "activation_link": "https://app.example.com/activate/abc123",
  "support_email": "support@example.com"
}
```

### Newsletter (`newsletter`)
```json
{
  "subscriber_name": "Alice",
  "newsletter_title": "Weekly Updates",
  "unsubscribe_link": "https://app.example.com/unsubscribe",
  "articles": [
    {
      "title": "Feature Release",
      "summary": "New features available",
      "url": "https://blog.example.com/features"
    }
  ]
}
```

### Password Reset (`password-reset`)
```json
{
  "username": "johndoe",
  "reset_link": "https://app.example.com/reset/xyz789",
  "expires_at": "2024-01-02 15:30:00"
}
```

## Error Handling Patterns

### JavaScript/TypeScript
```javascript
try {
  const response = await client.sendEmail(request);
  console.log('Success:', response.messageId);
} catch (error) {
  if (error.name === 'ValidationError') {
    console.error('Validation failed:', error.field);
  } else if (error.name === 'AuthenticationError') {
    console.error('Invalid API key');
  }
}
```

### Go
```go
response, err := client.SendEmail(ctx, request)
if err != nil {
  switch e := err.(type) {
  case *huefy.ValidationError:
    log.Printf("Validation error: %s (Field: %s)", e.Message, e.Field)
  case *huefy.AuthenticationError:
    log.Printf("Authentication error: %s", e.Message)
  }
  return
}
```

### Java
```java
try {
  SendEmailResponse response = client.sendEmail(request);
  System.out.println("Success: " + response.getMessageId());
} catch (ValidationException e) {
  System.err.println("Validation failed: " + e.getField());
} catch (AuthenticationException e) {
  System.err.println("Invalid API key: " + e.getMessage());
}
```

### Python
```python
try:
  response = client.send_email(request)
  print(f"Success: {response.message_id}")
except ValidationException as e:
  print(f"Validation failed: {e.field}")
except AuthenticationException as e:
  print(f"Invalid API key: {e.message}")
```

### PHP
```php
try {
  $response = $client->sendEmail($request);
  echo "Success: " . $response->getMessageId();
} catch (ValidationException $e) {
  echo "Validation failed: " . $e->getField();
} catch (AuthenticationException $e) {
  echo "Invalid API key: " . $e->getMessage();
}
```

## Environment Variables

All examples support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `HUEFY_API_KEY` | Your Huefy API key | `your-huefy-api-key` |
| `HUEFY_BASE_URL` | API base URL | `https://api.huefy.com` |
| `HUEFY_TIMEOUT` | Request timeout (seconds) | `30` |
| `HUEFY_MAX_RETRIES` | Maximum retry attempts | `3` |

## Testing with Examples

### 1. Mock Mode
Some examples include mock/test modes that don't send real emails:

```bash
# JavaScript
HUEFY_MOCK_MODE=true node basic-usage.js

# Python
HUEFY_MOCK_MODE=true python basic_usage.py
```

### 2. Test Email Addresses
Use these special email addresses for testing:
- `test@example.com` - Always succeeds
- `fail@example.com` - Always fails (for error testing)
- `timeout@example.com` - Simulates timeout

## Troubleshooting

### Common Issues

1. **API Key Not Set**
   ```
   Error: Invalid API key
   Solution: Set HUEFY_API_KEY environment variable
   ```

2. **Network Timeouts**
   ```
   Error: Request timed out
   Solution: Increase timeout or check network connection
   ```

3. **Rate Limiting**
   ```
   Error: Rate limit exceeded
   Solution: Implement backoff or reduce request frequency
   ```

4. **Invalid Template**
   ```
   Error: Template not found
   Solution: Check template key spelling and availability
   ```

### Debug Mode

Enable debug logging in examples:

```bash
# JavaScript
DEBUG=huefy:* node basic-usage.js

# Python
HUEFY_DEBUG=true python basic_usage.py

# Go
HUEFY_DEBUG=true go run main.go

# Java
-Dhuefy.debug=true

# PHP
HUEFY_DEBUG=true php basic_usage.php
```

## Contributing

To add a new example:

1. Create the example file in the appropriate SDK directory
2. Follow the established patterns and structure
3. Include comprehensive error handling
4. Add documentation and comments
5. Test with various scenarios
6. Update this README

## Support

- **Documentation**: [https://docs.huefy.com](https://docs.huefy.com)
- **Issues**: [GitHub Issues](https://github.com/huefy/huefy-sdk/issues)
- **Community**: [Discord](https://discord.gg/huefy)
- **Email**: [support@huefy.com](mailto:support@huefy.com)