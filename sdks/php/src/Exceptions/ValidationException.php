<?php

declare(strict_types=1);

namespace Huefy\SDK\Exceptions;

/**
 * Exception thrown when request validation fails.
 *
 * This exception is thrown when the provided request data does not pass
 * validation checks, such as missing required fields, invalid email addresses,
 * or malformed data.
 *
 * @example
 * ```php
 * try {
 *     $request = new SendEmailRequest('', 'invalid-email', []);
 *     $request->validate();
 * } catch (ValidationException $e) {
 *     echo "Validation failed: " . $e->getMessage();
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class ValidationException extends HuefyException
{
    private ?string $field = null;
    private mixed $value = null;

    /**
     * Create a new validation exception.
     *
     * @param string $message The validation error message
     * @param string|null $field The field that failed validation
     * @param mixed $value The invalid value
     * @param int $code The exception code
     * @param \Exception|null $previous The previous exception
     */
    public function __construct(
        string $message = '',
        ?string $field = null,
        mixed $value = null,
        int $code = 0,
        ?\Exception $previous = null
    ) {
        parent::__construct($message, $code, $previous, 'VALIDATION_ERROR');
        $this->field = $field;
        $this->value = $value;
    }

    /**
     * Get the field that failed validation.
     *
     * @return string|null
     */
    public function getField(): ?string
    {
        return $this->field;
    }

    /**
     * Get the invalid value.
     *
     * @return mixed
     */
    public function getValue(): mixed
    {
        return $this->value;
    }

    /**
     * Create a validation exception for a missing required field.
     *
     * @param string $field The missing field name
     *
     * @return self
     */
    public static function missingField(string $field): self
    {
        return new self(
            message: sprintf('Required field "%s" is missing', $field),
            field: $field
        );
    }

    /**
     * Create a validation exception for an invalid field value.
     *
     * @param string $field The field name
     * @param mixed $value The invalid value
     * @param string $reason The reason why the value is invalid
     *
     * @return self
     */
    public static function invalidField(string $field, mixed $value, string $reason): self
    {
        return new self(
            message: sprintf('Field "%s" is invalid: %s', $field, $reason),
            field: $field,
            value: $value
        );
    }

    /**
     * Create a validation exception for an invalid email address.
     *
     * @param string $email The invalid email address
     *
     * @return self
     */
    public static function invalidEmail(string $email): self
    {
        return new self(
            message: sprintf('Invalid email address: %s', $email),
            field: 'email',
            value: $email
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
            'field' => $this->field,
            'value' => $this->value,
        ]);
    }
}