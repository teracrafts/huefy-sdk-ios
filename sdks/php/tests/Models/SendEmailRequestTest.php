<?php

declare(strict_types=1);

namespace Huefy\SDK\Tests\Models;

use Huefy\SDK\Exceptions\ValidationException;
use Huefy\SDK\Models\EmailProvider;
use Huefy\SDK\Models\SendEmailRequest;
use PHPUnit\Framework\TestCase;

/**
 * Test suite for the SendEmailRequest model.
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class SendEmailRequestTest extends TestCase
{
    public function testConstructorAndGetters(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe', 'company' => 'Acme Corp'],
            provider: EmailProvider::SENDGRID
        );

        $this->assertEquals('welcome-email', $request->getTemplateKey());
        $this->assertEquals('test@example.com', $request->getRecipient());
        $this->assertEquals(['name' => 'John Doe', 'company' => 'Acme Corp'], $request->getData());
        $this->assertEquals(EmailProvider::SENDGRID, $request->getProvider());
    }

    public function testSetters(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'initial-template',
            recipient: 'initial@example.com',
            data: ['initial' => 'data']
        );

        $request->setTemplateKey('updated-template');
        $request->setRecipient('updated@example.com');
        $request->setData(['updated' => 'data']);
        $request->setProvider(EmailProvider::MAILGUN);

        $this->assertEquals('updated-template', $request->getTemplateKey());
        $this->assertEquals('updated@example.com', $request->getRecipient());
        $this->assertEquals(['updated' => 'data'], $request->getData());
        $this->assertEquals(EmailProvider::MAILGUN, $request->getProvider());
    }

    public function testValidationSuccess(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe']
        );

        // Should not throw any exception
        $request->validate();
        $this->assertTrue(true); // Assertion to indicate test passed
    }

    public function testValidationEmptyTemplateKey(): void
    {
        $request = new SendEmailRequest(
            templateKey: '',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe']
        );

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Template key is required');

        $request->validate();
    }

    public function testValidationEmptyRecipient(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: '',
            data: ['name' => 'John Doe']
        );

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Recipient email is required');

        $request->validate();
    }

    public function testValidationInvalidEmail(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'invalid-email',
            data: ['name' => 'John Doe']
        );

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Invalid recipient email address: invalid-email');

        $request->validate();
    }

    public function testValidationEmptyData(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: []
        );

        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Template data is required');

        $request->validate();
    }

    public function testToArray(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe'],
            provider: EmailProvider::SENDGRID
        );

        $array = $request->toArray();

        $this->assertEquals([
            'templateKey' => 'welcome-email',
            'recipient' => 'test@example.com',
            'data' => ['name' => 'John Doe'],
            'provider' => 'sendgrid'
        ], $array);
    }

    public function testToArrayWithoutProvider(): void
    {
        $request = new SendEmailRequest(
            templateKey: 'welcome-email',
            recipient: 'test@example.com',
            data: ['name' => 'John Doe']
        );

        $array = $request->toArray();

        $this->assertEquals([
            'templateKey' => 'welcome-email',
            'recipient' => 'test@example.com',
            'data' => ['name' => 'John Doe'],
            'provider' => null
        ], $array);
    }

    public function testFromArray(): void
    {
        $data = [
            'templateKey' => 'welcome-email',
            'recipient' => 'test@example.com',
            'data' => ['name' => 'John Doe'],
            'provider' => 'sendgrid'
        ];

        $request = SendEmailRequest::fromArray($data);

        $this->assertEquals('welcome-email', $request->getTemplateKey());
        $this->assertEquals('test@example.com', $request->getRecipient());
        $this->assertEquals(['name' => 'John Doe'], $request->getData());
        $this->assertEquals(EmailProvider::SENDGRID, $request->getProvider());
    }

    public function testFromArrayMissingTemplateKey(): void
    {
        $data = [
            'recipient' => 'test@example.com',
            'data' => ['name' => 'John Doe']
        ];

        $this->expectException(\InvalidArgumentException::class);
        $this->expectExceptionMessage('templateKey is required');

        SendEmailRequest::fromArray($data);
    }

    public function testFromArrayInvalidProvider(): void
    {
        $data = [
            'templateKey' => 'welcome-email',
            'recipient' => 'test@example.com',
            'data' => ['name' => 'John Doe'],
            'provider' => 'invalid-provider'
        ];

        $request = SendEmailRequest::fromArray($data);

        // Invalid provider should result in null
        $this->assertNull($request->getProvider());
    }
}