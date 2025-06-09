<?php

declare(strict_types=1);

namespace Huefy\SDK\Models;

/**
 * Enum representing supported email providers.
 *
 * This enum defines the email providers that can be used to send emails
 * through the Huefy API. Each provider has its own capabilities and configuration.
 *
 * @author Huefy Team
 * @since 1.0.0
 */
enum EmailProvider: string
{
    case SES = 'ses';
    case SENDGRID = 'sendgrid';
    case MAILGUN = 'mailgun';
    case MAILCHIMP = 'mailchimp';

    /**
     * Get all available email providers.
     *
     * @return array<string>
     */
    public static function getAll(): array
    {
        return array_map(fn(self $provider) => $provider->value, self::cases());
    }

    /**
     * Check if a provider value is valid.
     *
     * @param string $value
     *
     * @return bool
     */
    public static function isValid(string $value): bool
    {
        return in_array($value, self::getAll(), true);
    }

    /**
     * Create EmailProvider from string value.
     *
     * @param string $value
     *
     * @return self|null
     */
    public static function tryFrom(string $value): ?self
    {
        return match ($value) {
            'ses' => self::SES,
            'sendgrid' => self::SENDGRID,
            'mailgun' => self::MAILGUN,
            'mailchimp' => self::MAILCHIMP,
            default => null,
        };
    }

    /**
     * Get a human-readable name for the provider.
     *
     * @return string
     */
    public function getName(): string
    {
        return match ($this) {
            self::SES => 'Amazon SES',
            self::SENDGRID => 'SendGrid',
            self::MAILGUN => 'Mailgun',
            self::MAILCHIMP => 'Mailchimp Transactional',
        };
    }
}