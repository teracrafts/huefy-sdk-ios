# Huefy SDK

Multi-language SDKs for the Huefy email sending platform.

## Overview

Huefy SDK provides production-ready libraries for sending emails through the Huefy API across multiple programming languages. Each SDK provides idiomatic interfaces while maintaining consistent functionality across all supported platforms.

**🚀 All SDKs are complete and ready for production use!**

### Key Capabilities
- **Template-based emails** with dynamic data substitution
- **Multiple email providers** (SES, SendGrid, Mailgun, Mailchimp)
- **Bulk email operations** for efficient mass sending
- **Comprehensive error handling** with retry logic
- **Health monitoring** and API status checks
- **Type safety** with full TypeScript, Go, Java, Python, and PHP support

## Supported Languages

| Language | Package | Installation | Status |
|----------|---------|--------------|--------|
| JavaScript/Node.js | [@huefy/sdk](./sdks/javascript/) | `npm install @huefy/sdk` | ✅ **Complete** |
| React | [@huefy/react-sdk](./sdks/react/) | `npm install @huefy/react-sdk` | ✅ **Complete** |
| Go | [github.com/huefy/huefy-sdk/go](./sdks/go/) | `go get github.com/huefy/huefy-sdk/go` | ✅ **Complete** |
| Java | [com.huefy:huefy-java-sdk](./sdks/java/) | Maven/Gradle | ✅ **Complete** |
| Python | [huefy](./sdks/python/) | `pip install huefy` | ✅ **Complete** |
| PHP | [huefy/php-sdk](./sdks/php/) | `composer require huefy/php-sdk` | ✅ **Complete** |

## Quick Start

### JavaScript/Node.js
```javascript
import { HuefyClient } from '@huefy/sdk';

const huefy = new HuefyClient({
  apiKey: 'your-api-key'
});

await huefy.sendEmail('welcome-email', {
  name: 'John Doe',
  company: 'Acme Corp'
}, 'john@example.com');
```

### React
```jsx
import { HuefyProvider, useHuefy, EmailProvider } from '@huefy/react-sdk';

function App() {
  return (
    <HuefyProvider apiKey="your-api-key">
      <EmailForm />
    </HuefyProvider>
  );
}

function EmailForm() {
  const { sendEmail, loading, error } = useHuefy({
    onSuccess: (messageId) => console.log('Email sent:', messageId)
  });
  
  const handleSend = async () => {
    await sendEmail(
      'welcome-email', 
      { name: 'John', company: 'Acme Corp' }, 
      'john@example.com',
      { provider: EmailProvider.SENDGRID }
    );
  };
  
  return (
    <div>
      <button onClick={handleSend} disabled={loading}>
        {loading ? 'Sending...' : 'Send Email'}
      </button>
      {error && <div>Error: {error.message}</div>}
    </div>
  );
}
```

### Go
```go
package main

import (
    "context"
    "fmt"
    "log"
    
    "github.com/huefy/huefy-sdk/sdks/go"
)

func main() {
    client := huefy.NewClient("your-api-key", nil)
    
    request := &huefy.SendEmailRequest{
        TemplateKey: "welcome-email",
        Recipient:   "john@example.com",
        Data: map[string]interface{}{
            "name":    "John Doe",
            "company": "Acme Corp",
        },
        Provider: huefy.ProviderSendGrid,
    }
    
    resp, err := client.SendEmail(context.Background(), request)
    if err != nil {
        log.Fatal(err)
    }
    
    fmt.Printf("Email sent: %s\n", resp.MessageID)
}
```

### Java
```java
import com.huefy.sdk.HuefyClient;
import com.huefy.sdk.models.SendEmailRequest;
import com.huefy.sdk.models.SendEmailResponse;
import com.huefy.sdk.models.EmailProvider;
import java.util.Map;

public class Example {
    public static void main(String[] args) throws Exception {
        HuefyClient client = new HuefyClient("your-api-key");
        
        Map<String, Object> data = Map.of(
            "name", "John Doe",
            "company", "Acme Corp"
        );
        
        SendEmailRequest request = SendEmailRequest.builder()
            .templateKey("welcome-email")
            .recipient("john@example.com")
            .data(data)
            .provider(EmailProvider.SENDGRID)
            .build();
        
        SendEmailResponse response = client.sendEmail(request);
        System.out.println("Email sent: " + response.getMessageId());
    }
}
```

### Python
```python
from huefy import HuefyClient
from huefy.models import EmailProvider

client = HuefyClient("your-api-key")

response = client.send_email(
    template_key="welcome-email",
    recipient="john@example.com",
    data={
        "name": "John Doe",
        "company": "Acme Corp"
    },
    provider=EmailProvider.SENDGRID
)

print(f"Email sent: {response.message_id}")
```

### PHP
```php
<?php
require_once 'vendor/autoload.php';

use Huefy\SDK\HuefyClient;
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\EmailProvider;

$client = new HuefyClient('your-api-key');

$request = new SendEmailRequest(
    templateKey: 'welcome-email',
    recipient: 'john@example.com',
    data: [
        'name' => 'John Doe',
        'company' => 'Acme Corp'
    ],
    provider: EmailProvider::SENDGRID
);

$response = $client->sendEmail($request);

echo "Email sent: " . $response->getMessageId();
```

## Features

- ✅ **Simple API** - Consistent interface across all languages
- ✅ **Type Safety** - Full TypeScript, Go, Java, Python, and PHP type definitions
- ✅ **Error Handling** - Comprehensive error handling and retry logic
- ✅ **Multiple Providers** - Support for SES, SendGrid, Mailgun, Mailchimp
- ✅ **Async Support** - Native async/await support (JavaScript, Python)
- ✅ **Framework Integration** - React hooks, context providers, and more
- ✅ **Bulk Sending** - Send multiple emails efficiently
- ✅ **Health Monitoring** - API health checks and status monitoring
- ✅ **Retry Logic** - Automatic retries with exponential backoff
- ✅ **Template Management** - Template-based email sending with data substitution
- ✅ **Context Support** - Go contexts, Python context managers
- ✅ **Validation** - Input validation and comprehensive error messages

## Authentication

All SDKs use API key authentication. Get your API key from the [Huefy Dashboard](https://app.huefy.com/api-keys).

```javascript
const huefy = new HuefyClient({
  apiKey: 'your-api-key',
  baseUrl: 'https://api.huefy.com/api/v1/sdk' // Optional, defaults to production
});
```

## Email Providers

Huefy supports multiple email providers. SES is used by default, but you can specify a different provider:

```javascript
// Use default provider (SES)
await huefy.sendEmail('template-key', data, 'user@example.com');

// Use specific provider
await huefy.sendEmail('template-key', data, 'user@example.com', {
  provider: 'sendgrid'
});
```

Supported providers:
- `ses` (Amazon SES) - Default
- `sendgrid` (SendGrid)
- `mailgun` (Mailgun)
- `mailchimp` (Mailchimp)

## Documentation

### Language-Specific Documentation
- [JavaScript/TypeScript SDK](./sdks/javascript/README.md) - Complete guide with examples
- [React SDK](./sdks/react/README.md) - Hooks, context providers, and components
- [Go SDK](./sdks/go/README.md) - Context-aware operations and error handling
- [Java SDK](./sdks/java/README.md) - Builder patterns and async operations
- [Python SDK](./sdks/python/README.md) - Sync/async support and context managers
- [PHP SDK](./sdks/php/README.md) - Modern PHP 8.0+ with strict types

### Examples
- [JavaScript Examples](./sdks/javascript/examples/) - Basic usage and TypeScript
- [React Examples](./sdks/react/examples/) - Complete React applications
- [Go Examples](./sdks/go/examples/) - Context patterns and error handling
- [Java Examples](./sdks/java/examples/) - Maven projects and async operations
- [Python Examples](./sdks/python/examples/) - Sync and async implementations
- [PHP Examples](./sdks/php/examples/) - Modern PHP patterns

### Project Documentation
- [Implementation Guide](./IMPLEMENTATION.md) - Development progress and technical details
- [Development Guide](./CLAUDE.md) - Architecture and build commands

## Development

This is a monorepo containing all Huefy SDKs. See [CLAUDE.md](./CLAUDE.md) for development commands and architecture details.

```bash
# Install dependencies
npm install @openapitools/openapi-generator-cli -g

# Generate all SDKs from OpenAPI specification
./scripts/generate-sdks.sh

# Build all SDKs
./scripts/build-all.sh

# Run tests for all SDKs
cd sdks/javascript && npm test
cd sdks/react && npm test
cd sdks/go && go test ./...
cd sdks/java && mvn test
cd sdks/python && pytest
cd sdks/php && composer test
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](./CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Support

- 📧 Email: support@huefy.com
- 💬 Discord: [Join our community](https://discord.gg/huefy)
- 📚 Documentation: [docs.huefy.com](https://docs.huefy.com)
- 🐛 Issues: [GitHub Issues](https://github.com/huefy/huefy-sdk/issues)