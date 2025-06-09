<?php

require_once __DIR__ . '/../vendor/autoload.php';

use Huefy\SDK\HuefyClient;
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\EmailProvider;
use Huefy\SDK\Config\HuefyConfig;
use Huefy\SDK\Config\RetryConfig;
use Huefy\SDK\Exceptions\HuefyException;

/**
 * Basic usage example for the Huefy PHP SDK.
 *
 * This example demonstrates how to:
 * 1. Create a Huefy client
 * 2. Send a single email
 * 3. Send bulk emails
 * 4. Handle exceptions
 * 5. Use custom configuration
 *
 * @author Huefy Team
 * @since 1.0.0
 */

// Replace with your actual API key
$apiKey = 'your-huefy-api-key';

try {
    // Example 1: Basic client creation and single email
    echo "=== Basic Email Sending ===\n";
    
    $client = new HuefyClient($apiKey);
    
    $emailRequest = new SendEmailRequest(
        templateKey: 'welcome-email',
        recipient: 'john@example.com',
        data: [
            'name' => 'John Doe',
            'company' => 'Acme Corporation',
            'activation_link' => 'https://app.example.com/activate/abc123'
        ],
        provider: EmailProvider::SENDGRID
    );
    
    $response = $client->sendEmail($emailRequest);
    
    echo "✅ Email sent successfully!\n";
    echo "Message ID: {$response->getMessageId()}\n";
    echo "Provider: {$response->getProvider()->getName()}\n";
    echo "Status: {$response->getStatus()}\n\n";

    // Example 2: Custom configuration with retries
    echo "=== Client with Custom Configuration ===\n";
    
    $config = new HuefyConfig(
        baseUrl: 'https://api.huefy.com',
        timeout: 45.0,
        connectTimeout: 15.0,
        retryConfig: new RetryConfig(
            enabled: true,
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 60.0
        )
    );
    
    $clientWithConfig = new HuefyClient($apiKey, $config);
    
    $passwordResetRequest = new SendEmailRequest(
        templateKey: 'password-reset',
        recipient: 'user@example.com',
        data: [
            'username' => 'johndoe',
            'reset_link' => 'https://app.example.com/reset/xyz789',
            'expires_at' => '2024-01-02 15:30:00'
        ]
    );
    
    $response = $clientWithConfig->sendEmail($passwordResetRequest);
    echo "✅ Password reset email sent: {$response->getMessageId()}\n\n";

    // Example 3: Bulk email sending
    echo "=== Bulk Email Sending ===\n";
    
    $bulkRequests = [
        new SendEmailRequest(
            'newsletter',
            'subscriber1@example.com',
            ['name' => 'Alice', 'content' => 'Monthly Newsletter']
        ),
        new SendEmailRequest(
            'newsletter',
            'subscriber2@example.com',
            ['name' => 'Bob', 'content' => 'Monthly Newsletter']
        ),
        new SendEmailRequest(
            'newsletter',
            'subscriber3@example.com',
            ['name' => 'Carol', 'content' => 'Monthly Newsletter']
        ),
    ];
    
    $bulkResponse = $client->sendBulkEmails($bulkRequests);
    
    echo "✅ Bulk email operation completed!\n";
    echo "Total emails: {$bulkResponse->getTotalEmails()}\n";
    echo "Successful: {$bulkResponse->getSuccessfulEmails()}\n";
    echo "Failed: {$bulkResponse->getFailedEmails()}\n";
    echo "Success rate: {$bulkResponse->getSuccessRate():.1f}%\n";
    
    if (!$bulkResponse->isFullySuccessful()) {
        echo "❌ Some emails failed:\n";
        foreach ($bulkResponse->getFailedResults() as $failed) {
            echo "  - {$failed['recipient'] ?? 'Unknown'}: {$failed['error'] ?? 'Unknown error'}\n";
        }
    }
    echo "\n";

    // Example 4: Health check
    echo "=== API Health Check ===\n";
    
    $healthResponse = $client->healthCheck();
    
    if ($healthResponse->isHealthy()) {
        echo "✅ API is healthy\n";
    } elseif ($healthResponse->isDegraded()) {
        echo "⚠️  API is degraded\n";
    } else {
        echo "❌ API is unhealthy\n";
    }
    
    echo "Version: {$healthResponse->getVersion()}\n";
    echo "Uptime: {$healthResponse->getFormattedUptime()}\n";
    echo "Timestamp: {$healthResponse->getTimestamp()}\n\n";

    // Example 5: Using different email providers
    echo "=== Multiple Email Providers ===\n";
    
    $providers = [
        EmailProvider::SENDGRID,
        EmailProvider::MAILGUN,
        EmailProvider::SES,
        EmailProvider::MAILCHIMP
    ];
    
    foreach ($providers as $provider) {
        try {
            $providerRequest = new SendEmailRequest(
                templateKey: 'test-template',
                recipient: 'test@example.com',
                data: ['message' => "Testing with {$provider->getName()}"],
                provider: $provider
            );
            
            $providerResponse = $client->sendEmail($providerRequest);
            echo "✅ {$provider->getName()}: {$providerResponse->getMessageId()}\n";
            
        } catch (HuefyException $e) {
            echo "❌ {$provider->getName()}: {$e->getMessage()}\n";
        }
    }

} catch (HuefyException $e) {
    // Handle Huefy-specific exceptions
    echo "❌ Huefy Error: {$e->getMessage()}\n";
    echo "Error Code: {$e->getErrorCode()}\n";
    
    if ($context = $e->getContext()) {
        echo "Context: " . json_encode($context, JSON_PRETTY_PRINT) . "\n";
    }
    
    // Handle specific exception types
    if ($e instanceof \Huefy\SDK\Exceptions\AuthenticationException) {
        echo "💡 Please check your API key configuration.\n";
    } elseif ($e instanceof \Huefy\SDK\Exceptions\ValidationException) {
        echo "💡 Please check your request data.\n";
    } elseif ($e instanceof \Huefy\SDK\Exceptions\NetworkException) {
        echo "💡 Please check your network connection.\n";
    } elseif ($e instanceof \Huefy\SDK\Exceptions\TimeoutException) {
        echo "💡 Request timed out. Consider increasing timeout settings.\n";
    }
    
} catch (Exception $e) {
    // Handle general exceptions
    echo "❌ Unexpected Error: {$e->getMessage()}\n";
    echo "File: {$e->getFile()}:{$e->getLine()}\n";
}

echo "\n=== Example completed ===\n";