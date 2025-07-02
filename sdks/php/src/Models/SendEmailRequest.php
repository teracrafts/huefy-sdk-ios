<?php

declare(strict_types=1);

namespace Huefy\SDK\Models;

use Huefy\SDK\Exceptions\ValidationException;
use InvalidArgumentException;

/**
 * Request model for sending a single email.
 *
 * This class represents a request to send an email using a template.
 * It includes the template key, recipient email address, template data,
 * and optional provider specification.
 *
 * @example
 * ```php
 * use Huefy\SDK\Models\SendEmailRequest;
 * use Huefy\SDK\Models\EmailProvider;
 *
 * $request = new SendEmailRequest(
 *     templateKey: 'welcome-email',
 *     recipient: 'john@example.com',
 *     data: [
 *         'name' => 'John Doe',
 *         'company' => 'Acme Corp'
 *     ],
 *     provider: EmailProvider::SENDGRID
 * );
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class SendEmailRequest
{
    private string $templateKey;
    private string $recipient;
    private array $data;
    private ?EmailProvider $provider;

    /**
     * Create a new email request.
     *
     * @param string $templateKey The template key to use
     * @param string $recipient The recipient email address
     * @param array<string, mixed> $data Template data for variable substitution
     * @param EmailProvider|null $provider Optional email provider to use
     */
    public function __construct(
        string $templateKey,
        string $recipient,
        array $data,
        ?EmailProvider $provider = null
    ) {
        $this->templateKey = $templateKey;
        $this->recipient = $recipient;
        $this->data = $data;
        $this->provider = $provider;
    }

    /**
     * Get the template key.
     *
     * @return string
     */
    public function getTemplateKey(): string
    {
        return $this->templateKey;
    }

    /**
     * Set the template key.
     *
     * @param string $templateKey
     */
    public function setTemplateKey(string $templateKey): void
    {
        $this->templateKey = $templateKey;
    }

    /**
     * Get the recipient email address.
     *
     * @return string
     */
    public function getRecipient(): string
    {
        return $this->recipient;
    }

    /**
     * Set the recipient email address.
     *
     * @param string $recipient
     */
    public function setRecipient(string $recipient): void
    {
        $this->recipient = $recipient;
    }

    /**
     * Get the template data.
     *
     * @return array<string, mixed>
     */
    public function getData(): array
    {
        return $this->data;
    }

    /**
     * Set the template data.
     *
     * @param array<string, mixed> $data
     */
    public function setData(array $data): void
    {
        $this->data = $data;
    }

    /**
     * Get the email provider.
     *
     * @return EmailProvider|null
     */
    public function getProvider(): ?EmailProvider
    {
        return $this->provider;
    }

    /**
     * Set the email provider.
     *
     * @param EmailProvider|null $provider
     */
    public function setProvider(?EmailProvider $provider): void
    {
        $this->provider = $provider;
    }

    /**
     * Validate the request data.
     *
     * @throws ValidationException If the request is invalid
     */
    public function validate(): void
    {
        if (empty(trim($this->templateKey))) {
            throw new ValidationException('Template key is required');
        }

        if (empty(trim($this->recipient))) {
            throw new ValidationException('Recipient email is required');
        }

        if (!$this->isValidEmail($this->recipient)) {
            throw new ValidationException(sprintf('Invalid recipient email address: %s', $this->recipient));
        }

        if (empty($this->data)) {
            throw new ValidationException('Template data is required');
        }
    }

    /**
     * Convert the request to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'templateKey' => $this->templateKey,
            'recipient' => $this->recipient,
            'data' => $this->data,
            'providerType' => $this->provider?->value,
        ];
    }

    /**
     * Create a request from an array.
     *
     * @param array<string, mixed> $data
     *
     * @return self
     *
     * @throws InvalidArgumentException If required fields are missing
     */
    public static function fromArray(array $data): self
    {
        if (!isset($data['templateKey'])) {
            throw new InvalidArgumentException('templateKey is required');
        }

        if (!isset($data['recipient'])) {
            throw new InvalidArgumentException('recipient is required');
        }

        if (!isset($data['data']) || !is_array($data['data'])) {
            throw new InvalidArgumentException('data must be an array');
        }

        $provider = null;
        if (isset($data['providerType']) && is_string($data['providerType'])) {
            $provider = EmailProvider::tryFrom($data['providerType']);
        }

        return new self(
            templateKey: (string) $data['templateKey'],
            recipient: (string) $data['recipient'],
            data: $data['data'],
            provider: $provider
        );
    }

    /**
     * Validate an email address.
     *
     * @param string $email
     *
     * @return bool
     */
    private function isValidEmail(string $email): bool
    {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
}
