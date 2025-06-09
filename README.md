# Huefy SDK

Multi-language SDKs for the Huefy email sending platform.

## Overview

Huefy SDK provides easy-to-use libraries for sending emails through the Huefy API across multiple programming languages. Each SDK provides idiomatic interfaces while maintaining consistent functionality across all supported platforms.

## Supported Languages

| Language | Package | Installation | Status |
|----------|---------|--------------|--------|
| JavaScript/Node.js | [@huefy/sdk](https://npmjs.com/package/@huefy/sdk) | `npm install @huefy/sdk` | 🔄 In Development |
| React | [@huefy/react](https://npmjs.com/package/@huefy/react) | `npm install @huefy/react` | 🔄 In Development |
| Go | [github.com/huefy/huefy-sdk-go](https://github.com/huefy/huefy-sdk-go) | `go get github.com/huefy/huefy-sdk-go` | 🔄 In Development |
| Java | [com.huefy:huefy-sdk](https://search.maven.org/artifact/com.huefy/huefy-sdk) | Maven/Gradle | 🔄 In Development |
| Python | [huefy](https://pypi.org/project/huefy/) | `pip install huefy` | 🔄 In Development |
| PHP | [huefy/huefy-sdk](https://packagist.org/packages/huefy/huefy-sdk) | `composer require huefy/huefy-sdk` | 🔄 In Development |

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
import { HuefyProvider, useHuefy } from '@huefy/react';

function App() {
  return (
    <HuefyProvider apiKey="your-api-key">
      <EmailForm />
    </HuefyProvider>
  );
}

function EmailForm() {
  const { sendEmail, loading } = useHuefy();
  
  const handleSend = async () => {
    await sendEmail('welcome-email', { name: 'John' }, 'john@example.com');
  };
  
  return (
    <button onClick={handleSend} disabled={loading}>
      Send Email
    </button>
  );
}
```

### Go
```go
package main

import (
    "github.com/huefy/huefy-sdk-go"
)

func main() {
    client := huefy.NewClient("your-api-key")
    
    data := map[string]string{
        "name": "John Doe",
        "company": "Acme Corp",
    }
    
    resp, err := client.SendEmail("welcome-email", data, "john@example.com")
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Email sent: %s\n", resp.MessageID)
}
```

### Java
```java
import com.huefy.HuefyClient;
import java.util.Map;

public class Example {
    public static void main(String[] args) {
        HuefyClient huefy = new HuefyClient("your-api-key");
        
        Map<String, String> data = Map.of(
            "name", "John Doe",
            "company", "Acme Corp"
        );
        
        String messageId = huefy.sendEmail("welcome-email", data, "john@example.com");
        System.out.println("Email sent: " + messageId);
    }
}
```

### Python
```python
from huefy import HuefyClient

huefy = HuefyClient(api_key="your-api-key")

result = huefy.send_email(
    template_key="welcome-email",
    data={
        "name": "John Doe",
        "company": "Acme Corp"
    },
    recipient="john@example.com"
)

print(f"Email sent: {result['message_id']}")
```

### PHP
```php
<?php
require_once 'vendor/autoload.php';

use Huefy\SDK\HuefyClient;

$huefy = new HuefyClient('your-api-key');

$result = $huefy->sendEmail('welcome-email', [
    'name' => 'John Doe',
    'company' => 'Acme Corp'
], 'john@example.com');

echo "Email sent: " . $result['message_id'];
```

## Features

- ✅ **Simple API** - Consistent interface across all languages
- ✅ **Type Safety** - Full TypeScript, Go, and Java type definitions
- ✅ **Error Handling** - Comprehensive error handling and retry logic
- ✅ **Multiple Providers** - Support for SES (default), SendGrid, Mailgun, Mailchimp
- ✅ **Async Support** - Native async/await support where applicable
- ✅ **Framework Integration** - React hooks, Laravel service providers, and more
- 🔄 **Template Management** - Coming soon
- 🔄 **Bulk Sending** - Coming soon
- 🔄 **Analytics** - Coming soon

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

- [Implementation Guide](./IMPLEMENTATION.md) - Development progress and technical details
- [API Reference](./docs/api-reference.md) - Complete API documentation
- [Examples](./examples/) - Usage examples for each language
- [Troubleshooting](./docs/troubleshooting.md) - Common issues and solutions

## Development

This is a monorepo containing all Huefy SDKs. See [CLAUDE.md](./CLAUDE.md) for development commands and architecture details.

```bash
# Install dependencies
npm install @openapitools/openapi-generator-cli -g

# Generate all SDKs
./scripts/generate-sdks.sh

# Build all SDKs
./scripts/build-all.sh

# Test all SDKs
./scripts/test-all.sh
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