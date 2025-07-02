<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

use Exception;

/**
 * Base exception class for all Huefy SDK exceptions.
 *
 * This is the parent class for all exceptions thrown by the Huefy SDK.
 * It provides a common interface for catching any Huefy-related exception.
 *
 * @example
 * ```php
 * try {
 *     $client->sendEmail($request);
 * } catch (HuefyException $e) {
 *     // Handle any Huefy SDK exception
 *     echo "Huefy error: " . $e->getMessage();
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class HuefyException extends Exception
{
    protected ?string $errorCode = null;
    protected ?array $context = null;

    /**
     * Create a new Huefy exception.
     *
     * @param string $message The exception message
     * @param int $code The exception code
     * @param Exception|null $previous The previous exception
     * @param string|null $errorCode The Huefy-specific error code
     * @param array<string, mixed>|null $context Additional context information
     */
    public function __construct(
        string $message = '',
        int $code = 0,
        ?Exception $previous = null,
        ?string $errorCode = null,
        ?array $context = null
    ) {
        parent::__construct($message, $code, $previous);
        $this->errorCode = $errorCode;
        $this->context = $context;
    }

    /**
     * Get the Huefy-specific error code.
     *
     * @return string|null
     */
    public function getErrorCode(): ?string
    {
        return $this->errorCode;
    }

    /**
     * Get additional context information.
     *
     * @return array<string, mixed>|null
     */
    public function getContext(): ?array
    {
        return $this->context;
    }

    /**
     * Convert the exception to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'type' => static::class,
            'message' => $this->getMessage(),
            'code' => $this->getCode(),
            'errorCode' => $this->errorCode,
            'context' => $this->context,
            'file' => $this->getFile(),
            'line' => $this->getLine(),
        ];
    }

    /**
     * Get a string representation of the exception.
     *
     * @return string
     */
    public function __toString(): string
    {
        $string = static::class . ": {$this->message}";

        if ($this->errorCode !== null) {
            $string .= " (Error Code: {$this->errorCode})";
        }

        $string .= " in {$this->file}:{$this->line}";

        return $string;
    }
}
