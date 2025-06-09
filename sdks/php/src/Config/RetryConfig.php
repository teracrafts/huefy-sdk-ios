<?php

declare(strict_types=1);

namespace Huefy\SDK\Config;

use InvalidArgumentException;

/**
 * Configuration for retry behavior in the Huefy client.
 *
 * This class defines how the client should handle retries for failed requests,
 * including the maximum number of retries, delays between attempts, and exponential backoff.
 *
 * @example
 * ```php
 * use Huefy\SDK\Config\RetryConfig;
 *
 * $retryConfig = new RetryConfig(
 *     enabled: true,
 *     maxRetries: 3,
 *     baseDelay: 1.0,
 *     maxDelay: 30.0
 * );
 *
 * // Or create a disabled configuration
 * $noRetries = RetryConfig::disabled();
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class RetryConfig
{
    private const DEFAULT_MAX_RETRIES = 3;
    private const DEFAULT_BASE_DELAY = 1.0;
    private const DEFAULT_MAX_DELAY = 30.0;

    private bool $enabled;
    private int $maxRetries;
    private float $baseDelay;
    private float $maxDelay;

    /**
     * Create a new retry configuration.
     *
     * @param bool $enabled Whether retries are enabled
     * @param int $maxRetries Maximum number of retry attempts
     * @param float $baseDelay Base delay between retries in seconds
     * @param float $maxDelay Maximum delay between retries in seconds
     *
     * @throws InvalidArgumentException If any parameter is invalid
     */
    public function __construct(
        bool $enabled = true,
        int $maxRetries = self::DEFAULT_MAX_RETRIES,
        float $baseDelay = self::DEFAULT_BASE_DELAY,
        float $maxDelay = self::DEFAULT_MAX_DELAY
    ) {
        $this->enabled = $enabled;
        $this->setMaxRetries($maxRetries);
        $this->setBaseDelay($baseDelay);
        $this->setMaxDelay($maxDelay);

        if ($this->baseDelay > $this->maxDelay) {
            throw new InvalidArgumentException('Base delay cannot be greater than max delay');
        }
    }

    /**
     * Check if retries are enabled.
     *
     * @return bool
     */
    public function isEnabled(): bool
    {
        return $this->enabled;
    }

    /**
     * Enable or disable retries.
     *
     * @param bool $enabled
     */
    public function setEnabled(bool $enabled): void
    {
        $this->enabled = $enabled;
    }

    /**
     * Get the maximum number of retry attempts.
     *
     * @return int
     */
    public function getMaxRetries(): int
    {
        return $this->maxRetries;
    }

    /**
     * Set the maximum number of retry attempts.
     *
     * @param int $maxRetries
     *
     * @throws InvalidArgumentException If maxRetries is negative
     */
    public function setMaxRetries(int $maxRetries): void
    {
        if ($maxRetries < 0) {
            throw new InvalidArgumentException('Max retries must be >= 0');
        }

        $this->maxRetries = $maxRetries;
    }

    /**
     * Get the base delay between retries in seconds.
     *
     * @return float
     */
    public function getBaseDelay(): float
    {
        return $this->baseDelay;
    }

    /**
     * Set the base delay between retries in seconds.
     *
     * @param float $baseDelay
     *
     * @throws InvalidArgumentException If baseDelay is not positive
     */
    public function setBaseDelay(float $baseDelay): void
    {
        if ($baseDelay <= 0) {
            throw new InvalidArgumentException('Base delay must be positive');
        }

        $this->baseDelay = $baseDelay;
    }

    /**
     * Get the maximum delay between retries in seconds.
     *
     * @return float
     */
    public function getMaxDelay(): float
    {
        return $this->maxDelay;
    }

    /**
     * Set the maximum delay between retries in seconds.
     *
     * @param float $maxDelay
     *
     * @throws InvalidArgumentException If maxDelay is not positive
     */
    public function setMaxDelay(float $maxDelay): void
    {
        if ($maxDelay <= 0) {
            throw new InvalidArgumentException('Max delay must be positive');
        }

        $this->maxDelay = $maxDelay;
    }

    /**
     * Create a disabled retry configuration.
     *
     * @return self
     */
    public static function disabled(): self
    {
        return new self(enabled: false);
    }

    /**
     * Create a configuration with aggressive retries.
     *
     * @return self
     */
    public static function aggressive(): self
    {
        return new self(
            enabled: true,
            maxRetries: 5,
            baseDelay: 0.5,
            maxDelay: 10.0
        );
    }

    /**
     * Create a configuration with conservative retries.
     *
     * @return self
     */
    public static function conservative(): self
    {
        return new self(
            enabled: true,
            maxRetries: 2,
            baseDelay: 2.0,
            maxDelay: 60.0
        );
    }
}