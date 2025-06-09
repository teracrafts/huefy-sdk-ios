<?php

declare(strict_types=1);

namespace Huefy\SDK\Models;

use InvalidArgumentException;

/**
 * Response model for bulk email operations.
 *
 * This class represents the response received after sending multiple emails
 * in a single bulk operation. It contains statistics about the operation
 * and details about individual email results.
 *
 * @example
 * ```php
 * use Huefy\SDK\Models\BulkEmailResponse;
 *
 * $response = new BulkEmailResponse(
 *     totalEmails: 100,
 *     successfulEmails: 95,
 *     failedEmails: 5,
 *     results: [
 *         ['messageId' => 'msg_1', 'status' => 'sent', 'provider' => 'sendgrid'],
 *         ['messageId' => 'msg_2', 'status' => 'sent', 'provider' => 'sendgrid'],
 *         // ... more results
 *     ]
 * );
 *
 * echo "Successfully sent {$response->getSuccessfulEmails()} out of {$response->getTotalEmails()} emails";
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class BulkEmailResponse
{
    private int $totalEmails;
    private int $successfulEmails;
    private int $failedEmails;
    private array $results;

    /**
     * Create a new bulk email response.
     *
     * @param int $totalEmails Total number of emails processed
     * @param int $successfulEmails Number of successfully sent emails
     * @param int $failedEmails Number of failed emails
     * @param array<array<string, mixed>> $results Detailed results for each email
     */
    public function __construct(
        int $totalEmails,
        int $successfulEmails,
        int $failedEmails,
        array $results
    ) {
        $this->totalEmails = $totalEmails;
        $this->successfulEmails = $successfulEmails;
        $this->failedEmails = $failedEmails;
        $this->results = $results;
    }

    /**
     * Get the total number of emails processed.
     *
     * @return int
     */
    public function getTotalEmails(): int
    {
        return $this->totalEmails;
    }

    /**
     * Get the number of successfully sent emails.
     *
     * @return int
     */
    public function getSuccessfulEmails(): int
    {
        return $this->successfulEmails;
    }

    /**
     * Get the number of failed emails.
     *
     * @return int
     */
    public function getFailedEmails(): int
    {
        return $this->failedEmails;
    }

    /**
     * Get the detailed results for each email.
     *
     * @return array<array<string, mixed>>
     */
    public function getResults(): array
    {
        return $this->results;
    }

    /**
     * Get the success rate as a percentage.
     *
     * @return float
     */
    public function getSuccessRate(): float
    {
        if ($this->totalEmails === 0) {
            return 0.0;
        }

        return ($this->successfulEmails / $this->totalEmails) * 100;
    }

    /**
     * Check if all emails were sent successfully.
     *
     * @return bool
     */
    public function isFullySuccessful(): bool
    {
        return $this->failedEmails === 0 && $this->totalEmails > 0;
    }

    /**
     * Get only the successful email results.
     *
     * @return array<array<string, mixed>>
     */
    public function getSuccessfulResults(): array
    {
        return array_filter(
            $this->results,
            fn(array $result) => ($result['status'] ?? '') === 'sent'
        );
    }

    /**
     * Get only the failed email results.
     *
     * @return array<array<string, mixed>>
     */
    public function getFailedResults(): array
    {
        return array_filter(
            $this->results,
            fn(array $result) => ($result['status'] ?? '') !== 'sent'
        );
    }

    /**
     * Convert the response to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'totalEmails' => $this->totalEmails,
            'successfulEmails' => $this->successfulEmails,
            'failedEmails' => $this->failedEmails,
            'results' => $this->results,
            'successRate' => $this->getSuccessRate(),
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
        if (!isset($data['totalEmails']) || !is_int($data['totalEmails'])) {
            throw new InvalidArgumentException('totalEmails is required and must be an integer');
        }

        if (!isset($data['successfulEmails']) || !is_int($data['successfulEmails'])) {
            throw new InvalidArgumentException('successfulEmails is required and must be an integer');
        }

        if (!isset($data['failedEmails']) || !is_int($data['failedEmails'])) {
            throw new InvalidArgumentException('failedEmails is required and must be an integer');
        }

        if (!isset($data['results']) || !is_array($data['results'])) {
            throw new InvalidArgumentException('results is required and must be an array');
        }

        return new self(
            totalEmails: $data['totalEmails'],
            successfulEmails: $data['successfulEmails'],
            failedEmails: $data['failedEmails'],
            results: $data['results']
        );
    }
}