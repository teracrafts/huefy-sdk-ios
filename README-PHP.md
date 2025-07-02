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

## Documentation

Full documentation is available at [https://docs.huefy.dev/sdk/php](https://docs.huefy.dev/sdk/php)

## Support

- Documentation: [https://docs.huefy.com](https://docs.huefy.com)
- Issues: [GitHub Issues](https://github.com/teracrafts/huefy-sdk/issues)
- Email: support@huefy.com

## License

This SDK is released under the MIT License.