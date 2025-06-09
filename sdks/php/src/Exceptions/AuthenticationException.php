<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

/**
 * Exception thrown when authentication fails.
 *
 * This exception is thrown when the API key is invalid, expired, or missing
 * the necessary permissions to perform the requested operation.
 *
 * @example
 * ```php
 * try {
 *     $client = new HuefyClient('invalid-api-key');
 *     $client->sendEmail($request);
 * } catch (AuthenticationException $e) {
 *     echo "Authentication failed: " . $e->getMessage();
 *     // Handle invalid API key
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class AuthenticationException extends HuefyException
{
    /**
     * Create a new authentication exception.
     *
     * @param string $message The authentication error message
     * @param int $code The HTTP status code
     * @param \Exception|null $previous The previous exception
     * @param array<string, mixed>|null $context Additional context information
     */
    public function __construct(
        string $message = 'Authentication failed',
        int $code = 401,
        ?\Exception $previous = null,
        ?array $context = null
    ) {
        parent::__construct($message, $code, $previous, 'AUTHENTICATION_ERROR', $context);
    }

    /**
     * Create an exception for an invalid API key.
     *
     * @return self
     */
    public static function invalidApiKey(): self
    {
        return new self(
            message: 'Invalid API key provided',
            context: ['suggestion' => 'Please check your API key and ensure it is valid']
        );
    }

    /**
     * Create an exception for an expired API key.
     *
     * @return self
     */
    public static function expiredApiKey(): self
    {
        return new self(
            message: 'API key has expired',
            context: ['suggestion' => 'Please generate a new API key']
        );
    }

    /**
     * Create an exception for insufficient permissions.
     *
     * @param string $operation The operation that was attempted
     *
     * @return self
     */
    public static function insufficientPermissions(string $operation = ''): self
    {
        $message = 'Insufficient permissions';
        if (!empty($operation)) {
            $message .= " for operation: {$operation}";
        }

        return new self(
            message: $message,
            code: 403,
            context: [
                'operation' => $operation,
                'suggestion' => 'Please check your API key permissions'
            ]
        );
    }

    /**
     * Create an exception for a missing API key.
     *
     * @return self
     */
    public static function missingApiKey(): self
    {
        return new self(
            message: 'API key is required but not provided',
            context: ['suggestion' => 'Please provide a valid API key']
        );
    }
}