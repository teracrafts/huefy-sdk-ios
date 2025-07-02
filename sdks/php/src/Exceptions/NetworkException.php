<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

/**
 * Exception thrown when network-related errors occur.
 *
 * This exception is thrown when there are connectivity issues, DNS resolution
 * problems, or other network-related failures that prevent the request from
 * reaching the Huefy API.
 *
 * @example
 * ```php
 * try {
 *     $client->sendEmail($request);
 * } catch (NetworkException $e) {
 *     echo "Network error: " . $e->getMessage();
 *     // Handle network connectivity issues
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class NetworkException extends HuefyException
{
    /**
     * Create a new network exception.
     *
     * @param string $message The network error message
     * @param int $code The exception code
     * @param \Exception|null $previous The previous exception
     * @param array<string, mixed>|null $context Additional context information
     */
    public function __construct(
        string $message = 'Network error occurred',
        int $code = 0,
        ?\Exception $previous = null,
        ?array $context = null
    ) {
        parent::__construct($message, $code, $previous, 'NETWORK_ERROR', $context);
    }

    /**
     * Create an exception for connection failures.
     *
     * @param string $host The host that could not be reached
     *
     * @return self
     */
    public static function connectionFailed(string $host = ''): self
    {
        $message = 'Failed to establish connection';
        if (!empty($host)) {
            $message .= " to {$host}";
        }

        return new self(
            message: $message,
            context: [
                'host' => $host,
                'suggestion' => 'Please check your internet connection and try again',
            ]
        );
    }

    /**
     * Create an exception for DNS resolution failures.
     *
     * @param string $host The host that could not be resolved
     *
     * @return self
     */
    public static function dnsResolutionFailed(string $host = ''): self
    {
        $message = 'DNS resolution failed';
        if (!empty($host)) {
            $message .= " for {$host}";
        }

        return new self(
            message: $message,
            context: [
                'host' => $host,
                'suggestion' => 'Please check your DNS settings and internet connection',
            ]
        );
    }

    /**
     * Create an exception for SSL/TLS errors.
     *
     * @param string $details Additional error details
     *
     * @return self
     */
    public static function sslError(string $details = ''): self
    {
        $message = 'SSL/TLS error occurred';
        if (!empty($details)) {
            $message .= ": {$details}";
        }

        return new self(
            message: $message,
            context: [
                'details' => $details,
                'suggestion' => 'Please check your SSL configuration and certificates',
            ]
        );
    }

    /**
     * Create an exception for general connectivity issues.
     *
     * @param string $details Additional error details
     *
     * @return self
     */
    public static function connectivityIssue(string $details = ''): self
    {
        $message = 'Connectivity issue';
        if (!empty($details)) {
            $message .= ": {$details}";
        }

        return new self(
            message: $message,
            context: [
                'details' => $details,
                'suggestion' => 'Please check your network connection and firewall settings',
            ]
        );
    }
}
