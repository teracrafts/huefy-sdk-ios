<?php

declare(strict_types=1);

namespace Huefy\SDK\Models;

use InvalidArgumentException;

/**
 * Response model for health check operations.
 *
 * This class represents the response received from the Huefy API health check
 * endpoint. It provides information about the API's operational status,
 * version, and uptime.
 *
 * @example
 * ```php
 * use Huefy\SDK\Models\HealthResponse;
 *
 * $response = new HealthResponse(
 *     status: 'healthy',
 *     version: '1.2.3',
 *     uptime: 86400,
 *     timestamp: '2024-01-01T12:00:00Z'
 * );
 *
 * if ($response->isHealthy()) {
 *     echo "API is running version {$response->getVersion()}";
 * }
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class HealthResponse
{
    private string $status;
    private string $version;
    private int $uptime;
    private string $timestamp;

    /**
     * Create a new health response.
     *
     * @param string $status The health status (e.g., 'healthy', 'degraded', 'unhealthy')
     * @param string $version The API version
     * @param int $uptime The uptime in seconds
     * @param string $timestamp The response timestamp
     */
    public function __construct(
        string $status,
        string $version,
        int $uptime,
        string $timestamp
    ) {
        $this->status = $status;
        $this->version = $version;
        $this->uptime = $uptime;
        $this->timestamp = $timestamp;
    }

    /**
     * Get the health status.
     *
     * @return string
     */
    public function getStatus(): string
    {
        return $this->status;
    }

    /**
     * Get the API version.
     *
     * @return string
     */
    public function getVersion(): string
    {
        return $this->version;
    }

    /**
     * Get the uptime in seconds.
     *
     * @return int
     */
    public function getUptime(): int
    {
        return $this->uptime;
    }

    /**
     * Get the response timestamp.
     *
     * @return string
     */
    public function getTimestamp(): string
    {
        return $this->timestamp;
    }

    /**
     * Check if the API is healthy.
     *
     * @return bool
     */
    public function isHealthy(): bool
    {
        return strtolower($this->status) === 'healthy';
    }

    /**
     * Check if the API is degraded.
     *
     * @return bool
     */
    public function isDegraded(): bool
    {
        return strtolower($this->status) === 'degraded';
    }

    /**
     * Check if the API is unhealthy.
     *
     * @return bool
     */
    public function isUnhealthy(): bool
    {
        return strtolower($this->status) === 'unhealthy';
    }

    /**
     * Get the uptime in a human-readable format.
     *
     * @return string
     */
    public function getFormattedUptime(): string
    {
        $days = intval($this->uptime / 86400);
        $hours = intval(($this->uptime % 86400) / 3600);
        $minutes = intval(($this->uptime % 3600) / 60);
        $seconds = $this->uptime % 60;

        if ($days > 0) {
            return sprintf('%dd %dh %dm %ds', $days, $hours, $minutes, $seconds);
        }

        if ($hours > 0) {
            return sprintf('%dh %dm %ds', $hours, $minutes, $seconds);
        }

        if ($minutes > 0) {
            return sprintf('%dm %ds', $minutes, $seconds);
        }

        return sprintf('%ds', $seconds);
    }

    /**
     * Convert the response to an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        return [
            'status' => $this->status,
            'version' => $this->version,
            'uptime' => $this->uptime,
            'timestamp' => $this->timestamp,
            'isHealthy' => $this->isHealthy(),
            'formattedUptime' => $this->getFormattedUptime(),
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
        if (!isset($data['status']) || !is_string($data['status'])) {
            throw new InvalidArgumentException('status is required and must be a string');
        }

        if (!isset($data['version']) || !is_string($data['version'])) {
            throw new InvalidArgumentException('version is required and must be a string');
        }

        if (!isset($data['uptime']) || !is_int($data['uptime'])) {
            throw new InvalidArgumentException('uptime is required and must be an integer');
        }

        if (!isset($data['timestamp']) || !is_string($data['timestamp'])) {
            throw new InvalidArgumentException('timestamp is required and must be a string');
        }

        return new self(
            status: $data['status'],
            version: $data['version'],
            uptime: $data['uptime'],
            timestamp: $data['timestamp']
        );
    }
}
