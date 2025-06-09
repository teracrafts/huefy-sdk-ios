<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

/**
 * Exception thrown when request timeouts occur.
 *
 * This exception is thrown when a request to the Huefy API takes longer
 * than the configured timeout period, either for connection establishment
 * or request completion.
 *
 * @example
 * ```php
 * try {
 *     $client->sendEmail($request);
 * } catch (TimeoutException $e) {
 *     echo "Request timed out: " . $e->getMessage();
 *     // Handle timeout and potentially retry
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class TimeoutException extends NetworkException
{
    private ?float $timeout = null;
    private ?string $timeoutType = null;

    /**
     * Create a new timeout exception.
     *
     * @param string $message The timeout error message
     * @param float|null $timeout The timeout value in seconds
     * @param string|null $timeoutType The type of timeout (connection, request, etc.)
     * @param int $code The exception code
     * @param \Exception|null $previous The previous exception
     */
    public function __construct(
        string $message = 'Request timed out',
        ?float $timeout = null,
        ?string $timeoutType = null,
        int $code = 0,
        ?\Exception $previous = null
    ) {
        $this->timeout = $timeout;
        $this->timeoutType = $timeoutType;

        $context = [];
        if ($timeout !== null) {
            $context['timeout'] = $timeout;
        }
        if ($timeoutType !== null) {
            $context['timeoutType'] = $timeoutType;
        }
        $context['suggestion'] = 'Please try again or increase the timeout value';

        parent::__construct($message, $code, $previous, $context);
        $this->errorCode = 'TIMEOUT_ERROR';
    }

    /**
     * Get the timeout value in seconds.
     *
     * @return float|null
     */
    public function getTimeout(): ?float
    {
        return $this->timeout;
    }

    /**
     * Get the timeout type.
     *
     * @return string|null
     */
    public function getTimeoutType(): ?string
    {
        return $this->timeoutType;
    }

    /**
     * Create an exception for connection timeouts.
     *
     * @param float $timeout The connection timeout in seconds
     *
     * @return self
     */
    public static function connectionTimeout(float $timeout): self
    {
        return new self(
            message: sprintf('Connection timed out after %.2f seconds', $timeout),
            timeout: $timeout,
            timeoutType: 'connection'
        );
    }

    /**
     * Create an exception for request timeouts.
     *
     * @param float $timeout The request timeout in seconds
     *
     * @return self
     */
    public static function requestTimeout(float $timeout): self
    {
        return new self(
            message: sprintf('Request timed out after %.2f seconds', $timeout),
            timeout: $timeout,
            timeoutType: 'request'
        );
    }

    /**
     * Create an exception for read timeouts.
     *
     * @param float $timeout The read timeout in seconds
     *
     * @return self
     */
    public static function readTimeout(float $timeout): self
    {
        return new self(
            message: sprintf('Read operation timed out after %.2f seconds', $timeout),
            timeout: $timeout,
            timeoutType: 'read'
        );
    }

    /**
     * Convert the exception to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return array_merge(parent::toArray(), [
            'timeout' => $this->timeout,
            'timeoutType' => $this->timeoutType,
        ]);
    }
}