<?php

declare(strict_types=1);

namespace Huefy\SDK\Models;

use InvalidArgumentException;

/**
 * Response model for a successful email send operation.
 *
 * This class represents the response received after successfully sending
 * an email through the Huefy API. It contains the message ID for tracking
 * and the email provider that was used.
 *
 * @example
 * ```php
 * use Huefy\SDK\Models\SendEmailResponse;
 * use Huefy\SDK\Models\EmailProvider;
 *
 * $response = new SendEmailResponse(
 *     messageId: 'msg_abc123def456',
 *     provider: EmailProvider::SENDGRID,
 *     status: 'sent'
 * );
 *
 * echo "Email sent with ID: " . $response->getMessageId();
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class SendEmailResponse
{
    private string $messageId;
    private EmailProvider $provider;
    private string $status;

    /**
     * Create a new email response.
     *
     * @param string $messageId Unique message identifier
     * @param EmailProvider $provider The provider that sent the email
     * @param string $status The status of the email
     */
    public function __construct(
        string $messageId,
        EmailProvider $provider,
        string $status
    ) {
        $this->messageId = $messageId;
        $this->provider = $provider;
        $this->status = $status;
    }

    /**
     * Get the message ID.
     *
     * @return string
     */
    public function getMessageId(): string
    {
        return $this->messageId;
    }

    /**
     * Get the email provider that was used.
     *
     * @return EmailProvider
     */
    public function getProvider(): EmailProvider
    {
        return $this->provider;
    }

    /**
     * Get the email status.
     *
     * @return string
     */
    public function getStatus(): string
    {
        return $this->status;
    }

    /**
     * Convert the response to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'messageId' => $this->messageId,
            'provider' => $this->provider->value,
            'status' => $this->status,
        ];
    }

    /**
     * Create a response from an array.
     *
     * @param array<string, mixed> $data
     *
     * @return self
     *
     * @throws InvalidArgumentException If required fields are missing or invalid
     */
    public static function fromArray(array $data): self
    {
        if (!isset($data['messageId']) || !is_string($data['messageId'])) {
            throw new InvalidArgumentException('messageId is required and must be a string');
        }

        if (!isset($data['provider']) || !is_string($data['provider'])) {
            throw new InvalidArgumentException('provider is required and must be a string');
        }

        if (!isset($data['status']) || !is_string($data['status'])) {
            throw new InvalidArgumentException('status is required and must be a string');
        }

        $provider = EmailProvider::tryFrom($data['provider']);
        if ($provider === null) {
            throw new InvalidArgumentException(sprintf('Invalid provider: %s', $data['provider']));
        }

        return new self(
            messageId: $data['messageId'],
            provider: $provider,
            status: $data['status']
        );
    }
}