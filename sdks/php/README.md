# Huefy PHP SDK

The official PHP SDK for the Huefy email sending platform. Send template-based emails with multiple provider support, comprehensive error handling, and retry logic.

## Installation

Install the SDK using Composer:

```bash
composer require teracrafts/huefy
```

## Quick Start

```php
<?php

require_once 'vendor/autoload.php';

use Huefy\SDK\HuefyClient;
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\EmailProvider;

// Create a client with your API key
$client = new HuefyClient('your-huefy-api-key');

// Create an email request
$request = new SendEmailRequest(
    templateKey: 'welcome-email',
    recipient: 'john@example.com',
    data: [
        'name' => 'John Doe',
        'company' => 'Acme Corp'
    ],
    provider: EmailProvider::SENDGRID
);

// Send the email
try {
    $response = $client->sendEmail($request);
    echo "Email sent! Message ID: " . $response->getMessageId();
} catch (\Huefy\SDK\Exceptions\HuefyException $e) {
    echo "Error: " . $e->getMessage();
}
```

## Features

- ✅ **Template-based emails** - Send emails using predefined templates
- ✅ **Multiple providers** - Support for SendGrid, Mailgun, Amazon SES, and Mailchimp
- ✅ **Bulk sending** - Send multiple emails in a single request
- ✅ **Retry logic** - Automatic retries with exponential backoff
- ✅ **Type safety** - Full PHP 8.0+ type declarations and enums
- ✅ **Comprehensive error handling** - Specific exceptions for different error types
- ✅ **PSR standards** - Follows PSR-4, PSR-7, and PSR-12
- ✅ **Logging support** - PSR-3 logger interface support
- ✅ **Health checks** - Monitor API status

## Requirements

- PHP 8.0 or higher
- Guzzle HTTP client
- Valid Huefy API key

## Configuration

### Basic Configuration

```php
use Huefy\SDK\HuefyClient;
use Huefy\SDK\Config\HuefyConfig;

$config = new HuefyConfig(
    baseUrl: 'https://api.huefy.com',
    timeout: 30.0,
    connectTimeout: 10.0
);

$client = new HuefyClient('your-api-key', $config);
```

### Retry Configuration

```php
use Huefy\SDK\Config\RetryConfig;

$retryConfig = new RetryConfig(
    enabled: true,
    maxRetries: 3,
    baseDelay: 1.0,
    maxDelay: 30.0
);

$config = new HuefyConfig(retryConfig: $retryConfig);
$client = new HuefyClient('your-api-key', $config);
```

### Predefined Configurations

```php
// Disable retries
$config = HuefyConfig::withoutRetries();

// Aggressive retries
$retryConfig = RetryConfig::aggressive();

// Conservative retries  
$retryConfig = RetryConfig::conservative();
```

## Usage Examples

### Single Email

```php
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\EmailProvider;

$request = new SendEmailRequest(
    templateKey: 'password-reset',
    recipient: 'user@example.com',
    data: [
        'username' => 'johndoe',
        'reset_link' => 'https://app.example.com/reset/xyz789'
    ],
    provider: EmailProvider::MAILGUN
);

$response = $client->sendEmail($request);
```

### Bulk Emails

```php
$requests = [
    new SendEmailRequest('newsletter', 'user1@example.com', ['name' => 'Alice']),
    new SendEmailRequest('newsletter', 'user2@example.com', ['name' => 'Bob']),
    new SendEmailRequest('newsletter', 'user3@example.com', ['name' => 'Carol']),
];

$response = $client->sendBulkEmails($requests);

echo "Success rate: " . $response->getSuccessRate() . "%";
```

### Health Check

```php
$health = $client->healthCheck();

if ($health->isHealthy()) {
    echo "API is operational";
    echo "Version: " . $health->getVersion();
    echo "Uptime: " . $health->getFormattedUptime();
}
```

## Email Providers

The SDK supports multiple email providers:

```php
use Huefy\SDK\Models\EmailProvider;

EmailProvider::SES        // Amazon SES
EmailProvider::SENDGRID   // SendGrid
EmailProvider::MAILGUN    // Mailgun
EmailProvider::MAILCHIMP  // Mailchimp Transactional
```

## Error Handling

The SDK provides specific exception types for different error scenarios:

```php
use Huefy\SDK\Exceptions\{
    HuefyException,
    AuthenticationException,
    ValidationException,
    NetworkException,
    TimeoutException
};

try {
    $response = $client->sendEmail($request);
} catch (AuthenticationException $e) {
    // Invalid API key or insufficient permissions
    echo "Auth error: " . $e->getMessage();
} catch (ValidationException $e) {
    // Invalid request data
    echo "Validation error: " . $e->getMessage();
    echo "Field: " . $e->getField();
} catch (TimeoutException $e) {
    // Request timed out
    echo "Timeout: " . $e->getTimeout() . "s";
} catch (NetworkException $e) {
    // Network connectivity issues
    echo "Network error: " . $e->getMessage();
} catch (HuefyException $e) {
    // Any other Huefy-specific error
    echo "Huefy error: " . $e->getMessage();
    echo "Error code: " . $e->getErrorCode();
}
```

## Logging

The SDK supports PSR-3 compatible loggers:

```php
use Monolog\Logger;
use Monolog\Handler\StreamHandler;

$logger = new Logger('huefy');
$logger->pushHandler(new StreamHandler('huefy.log', Logger::DEBUG));

$client = new HuefyClient('your-api-key', null, $logger);
```

## Testing

Run the test suite:

```bash
# Install dependencies
composer install

# Run tests
composer test

# Run tests with coverage
composer test:coverage

# Run static analysis
composer analyze
```

## API Reference

### HuefyClient

#### Methods

- `sendEmail(SendEmailRequest $request): SendEmailResponse`
- `sendBulkEmails(array $requests): BulkEmailResponse`
- `healthCheck(): HealthResponse`

### Models

#### SendEmailRequest
- `getTemplateKey(): string`
- `getRecipient(): string`
- `getData(): array`
- `getProvider(): ?EmailProvider`
- `validate(): void`
- `toArray(): array`
- `fromArray(array $data): self`

#### SendEmailResponse
- `getMessageId(): string`
- `getProvider(): EmailProvider`
- `getStatus(): string`

#### BulkEmailResponse
- `getTotalEmails(): int`
- `getSuccessfulEmails(): int`
- `getFailedEmails(): int`
- `getSuccessRate(): float`
- `isFullySuccessful(): bool`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

This SDK is released under the MIT License. See [LICENSE](LICENSE) for details.

## Support

- Documentation: [https://docs.huefy.com](https://docs.huefy.com)
- Issues: [GitHub Issues](https://github.com/teracrafts/huefy-sdk/issues)
- Email: support@huefy.com