<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

use Exception;

/**
 * Factory class for creating appropriate exceptions from API responses.
 *
 * This class analyzes error responses from the Huefy API and creates
 * the most appropriate exception type based on the error code and HTTP status.
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class ExceptionFactory
{
    /**
     * Create an exception from an API error response.
     *
     * @param array<string, mixed> $errorData The error data from the API response
     * @param int $statusCode The HTTP status code
     * @param Exception|null $previous The previous exception
     *
     * @return HuefyException
     */
    public static function createFromResponse(
        array $errorData,
        int $statusCode,
        ?Exception $previous = null
    ): HuefyException {
        $error = $errorData['error'] ?? [];
        $message = $error['message'] ?? 'Unknown error occurred';
        $errorCode = $error['code'] ?? null;
        $details = $error['details'] ?? null;

        // Create context from error details
        $context = [];
        if ($details !== null) {
            $context['details'] = $details;
        }
        if (isset($errorData['requestId'])) {
            $context['requestId'] = $errorData['requestId'];
        }

        // Determine exception type based on status code and error code
        return match ($statusCode) {
            400 => self::createValidationException($message, $errorCode, $context, $previous),
            401 => self::createAuthenticationException($message, $context, $previous),
            403 => AuthenticationException::insufficientPermissions($errorCode ?? ''),
            404 => new HuefyException(
                message: $message,
                code: $statusCode,
                previous: $previous,
                errorCode: $errorCode,
                context: $context
            ),
            408 => TimeoutException::requestTimeout(30.0), // Default timeout
            429 => new HuefyException(
                message: $message ?: 'Rate limit exceeded',
                code: $statusCode,
                previous: $previous,
                errorCode: $errorCode ?: 'RATE_LIMIT_EXCEEDED',
                context: array_merge($context, [
                    'suggestion' => 'Please wait before making more requests'
                ])
            ),
            500, 502, 503, 504 => new HuefyException(
                message: $message ?: 'Server error occurred',
                code: $statusCode,
                previous: $previous,
                errorCode: $errorCode ?: 'SERVER_ERROR',
                context: array_merge($context, [
                    'suggestion' => 'Please try again later'
                ])
            ),
            default => new HuefyException(
                message: $message,
                code: $statusCode,
                previous: $previous,
                errorCode: $errorCode,
                context: $context
            )
        };
    }

    /**
     * Create a validation exception from error data.
     *
     * @param string $message The error message
     * @param string|null $errorCode The error code
     * @param array<string, mixed> $context Additional context
     * @param Exception|null $previous The previous exception
     *
     * @return ValidationException
     */
    private static function createValidationException(
        string $message,
        ?string $errorCode,
        array $context,
        ?Exception $previous
    ): ValidationException {
        // Try to extract field and value from context
        $field = $context['details']['field'] ?? null;
        $value = $context['details']['value'] ?? null;

        return new ValidationException(
            message: $message,
            field: $field,
            value: $value,
            previous: $previous
        );
    }

    /**
     * Create an authentication exception from error data.
     *
     * @param string $message The error message
     * @param array<string, mixed> $context Additional context
     * @param Exception|null $previous The previous exception
     *
     * @return AuthenticationException
     */
    private static function createAuthenticationException(
        string $message,
        array $context,
        ?Exception $previous
    ): AuthenticationException {
        // Check for specific authentication error types
        if (str_contains(strtolower($message), 'invalid api key')) {
            return AuthenticationException::invalidApiKey();
        }

        if (str_contains(strtolower($message), 'expired')) {
            return AuthenticationException::expiredApiKey();
        }

        if (str_contains(strtolower($message), 'missing')) {
            return AuthenticationException::missingApiKey();
        }

        return new AuthenticationException(
            message: $message,
            previous: $previous,
            context: $context
        );
    }

    /**
     * Create a timeout exception from an error message.
     *
     * @param string $message The error message
     * @param Exception|null $previous The previous exception
     *
     * @return TimeoutException
     */
    public static function createTimeoutException(string $message, ?Exception $previous = null): TimeoutException
    {
        if (str_contains(strtolower($message), 'connection')) {
            return TimeoutException::connectionTimeout(30.0); // Default timeout
        }

        if (str_contains(strtolower($message), 'read')) {
            return TimeoutException::readTimeout(30.0); // Default timeout
        }

        return TimeoutException::requestTimeout(30.0); // Default timeout
    }

    /**
     * Create a network exception from an error message.
     *
     * @param string $message The error message
     * @param Exception|null $previous The previous exception
     *
     * @return NetworkException
     */
    public static function createNetworkException(string $message, ?Exception $previous = null): NetworkException
    {
        $lowerMessage = strtolower($message);

        if (str_contains($lowerMessage, 'dns') || str_contains($lowerMessage, 'resolve')) {
            return NetworkException::dnsResolutionFailed();
        }

        if (str_contains($lowerMessage, 'ssl') || str_contains($lowerMessage, 'tls')) {
            return NetworkException::sslError($message);
        }

        if (str_contains($lowerMessage, 'connection')) {
            return NetworkException::connectionFailed();
        }

        return NetworkException::connectivityIssue($message);
    }
}