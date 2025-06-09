<?php

declare(strict_types=1);

namespace Huefy\SDK\Tests;

use GuzzleHttp\Client;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Psr7\Response;
use Huefy\SDK\Config\HuefyConfig;
use Huefy\SDK\Exceptions\AuthenticationException;
use Huefy\SDK\Exceptions\ValidationException;
use Huefy\SDK\HuefyClient;
use Huefy\SDK\Models\EmailProvider;
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\SendEmailResponse;
use PHPUnit\Framework\TestCase;

/**
 * Test suite for the HuefyClient class.
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class HuefyClientTest extends TestCase
{
    private HuefyClient $client;
    private MockHandler $mockHandler;

    protected function setUp(): void
    {
        $this->mockHandler = new MockHandler();
        $handlerStack = HandlerStack::create($this->mockHandler);
        
        $config = new HuefyConfig();
        $this->client = new HuefyClient('test-api-key', $config);
        
        // Use reflection to replace the HTTP client with our mock
        $reflection = new \ReflectionClass($this->client);
        $property = $reflection->getProperty('httpClient');
        $property->setAccessible(true);
        $property->setValue($this->client, new Client(['handler' => $handlerStack]));
    }

    public function testSendEmailSuccess(): void
    {
        $responseData = [
            'messageId' => 'msg_test123',
            'provider' => 'sendgrid',
            'status' => 'sent'
        ];

        $this->mockHandler->append(
            new Response(200, ['Content-Type' => 'application/json'], json_encode($responseData))
        );

        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe'],
            provider: EmailProvider::SENDGRID
        );

        $response = $this->client->sendEmail($request);

        $this->assertInstanceOf(SendEmailResponse::class, $response);
        $this->assertEquals('msg_test123', $response->getMessageId());
        $this->assertEquals(EmailProvider::SENDGRID, $response->getProvider());
        $this->assertEquals('sent', $response->getStatus());
    }

    public function testSendEmailValidationError(): void
    {
        $request = new SendEmailRequest(
            templateKey: '', // Invalid empty template key
            recipient: 'test@example.com',
            data: ['name' => 'John Doe']
        );

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Template key is required');

        $this->client->sendEmail($request);
    }

    public function testSendEmailAuthenticationError(): void
    {
        $errorResponse = [
            'error' => [
                'code' => 'INVALID_API_KEY',
                'message' => 'Invalid API key provided'
            ]
        ];

        $this->mockHandler->append(
            new Response(401, ['Content-Type' => 'application/json'], json_encode($errorResponse))
        );

        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe']
        );

        $this->expectException(AuthenticationException::class);
        $this->expectExceptionMessage('Invalid API key provided');

        $this->client->sendEmail($request);
    }

    public function testSendBulkEmailsSuccess(): void
    {
        $responseData = [
            'totalEmails' => 2,
            'successfulEmails' => 2,
            'failedEmails' => 0,
            'results' => [
                ['messageId' => 'msg_1', 'provider' => 'sendgrid', 'status' => 'sent'],
                ['messageId' => 'msg_2', 'provider' => 'sendgrid', 'status' => 'sent']
            ]
        ];

        $this->mockHandler->append(
            new Response(200, ['Content-Type' => 'application/json'], json_encode($responseData))
        );

        $requests = [
            new SendEmailRequest('welcome-email', 'user1@example.com', ['name' => 'User 1']),
            new SendEmailRequest('welcome-email', 'user2@example.com', ['name' => 'User 2'])
        ];

        $response = $this->client->sendBulkEmails($requests);

        $this->assertEquals(2, $response->getTotalEmails());
        $this->assertEquals(2, $response->getSuccessfulEmails());
        $this->assertEquals(0, $response->getFailedEmails());
        $this->assertTrue($response->isFullySuccessful());
    }

    public function testHealthCheckSuccess(): void
    {
        $responseData = [
            'status' => 'healthy',
            'version' => '1.0.0',
            'uptime' => 86400,
            'timestamp' => '2024-01-01T12:00:00Z'
        ];

        $this->mockHandler->append(
            new Response(200, ['Content-Type' => 'application/json'], json_encode($responseData))
        );

        $response = $this->client->healthCheck();

        $this->assertTrue($response->isHealthy());
        $this->assertEquals('1.0.0', $response->getVersion());
        $this->assertEquals(86400, $response->getUptime());
    }

    public function testConstructorWithEmptyApiKey(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('API key cannot be empty');

        new HuefyClient('');
    }
}