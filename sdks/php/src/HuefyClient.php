<?php

declare(strict_types=1);

namespace Huefy\SDK;

use GuzzleHttp\Client as GuzzleClient;
use GuzzleHttp\Exception\GuzzleException;
use GuzzleHttp\Exception\RequestException;
use GuzzleHttp\RequestOptions;
use Huefy\SDK\Config\HuefyConfig;
use Huefy\SDK\Exceptions\HuefyException;
use Huefy\SDK\Exceptions\NetworkException;
use Huefy\SDK\Exceptions\TimeoutException;
use Huefy\SDK\Exceptions\ValidationException;
use Huefy\SDK\Models\BulkEmailResponse;
use Huefy\SDK\Models\HealthResponse;
use Huefy\SDK\Models\SendEmailRequest;
use Huefy\SDK\Models\SendEmailResponse;
use InvalidArgumentException;
use JsonException;
use Psr\Log\LoggerInterface;
use Psr\Log\NullLogger;

/**
 * Main client for the Huefy email sending platform.
 *
 * The HuefyClient provides a simple interface for sending template-based emails
 * through the Huefy API with support for multiple email providers, retry logic,
 * and comprehensive error handling.
 *
 * @example
 * ```php
 * use Huefy\SDK\HuefyClient;
 * use Huefy\SDK\Models\SendEmailRequest;
 * use Huefy\SDK\Models\EmailProvider;
 *
 * $client = new HuefyClient('your-api-key');
 *
 * $request = new SendEmailRequest(
 *     templateKey: 'welcome-email',
 *     recipient: 'john@example.com',
 *     data: ['name' => 'John Doe', 'company' => 'Acme Corp'],
 *     provider: EmailProvider::SENDGRID
 * );
 *
 * $response = $client->sendEmail($request);
 * echo "Email sent: {$response->messageId}";
 * ```
 *
 * @author Huefy Team
 * @since 1.0.0
 */
class HuefyClient
{
    private const USER_AGENT = 'Huefy-PHP-SDK/1.0.0';
    private const DEFAULT_BASE_URL = 'https://api.huefy.com';

    private GuzzleClient $httpClient;
    private HuefyConfig $config;
    private LoggerInterface $logger;

    /**
     * Create a new Huefy client.
     *
     * @param string $apiKey The Huefy API key
     * @param HuefyConfig|null $config Optional client configuration
     * @param LoggerInterface|null $logger Optional logger instance
     *
     * @throws InvalidArgumentException If API key is empty
     */
    public function __construct(
        private readonly string $apiKey,
        ?HuefyConfig $config = null,
        ?LoggerInterface $logger = null
    ) {
        if (empty(trim($this->apiKey))) {
            throw new InvalidArgumentException('API key cannot be empty');
        }

        $this->config = $config ?? new HuefyConfig();
        $this->logger = $logger ?? new NullLogger();
        $this->httpClient = $this->createHttpClient();

        $this->logger->debug('HuefyClient initialized', [
            'base_url' => $this->config->getBaseUrl(),
            'timeout' => $this->config->getTimeout(),
        ]);
    }

    /**
     * Send a single email using a template.
     *
     * @param SendEmailRequest $request The email request
     *
     * @return SendEmailResponse The email response
     *
     * @throws HuefyException If the request fails
     * @throws ValidationException If the request is invalid
     */
    public function sendEmail(SendEmailRequest $request): SendEmailResponse
    {
        $request->validate();

        $responseData = $this->makeRequest(
            'POST',
            '/api/v1/sdk/emails/send',
            $request->toArray()
        );

        return SendEmailResponse::fromArray($responseData);
    }

    /**
     * Send multiple emails in a single request.
     *
     * @param SendEmailRequest[] $requests Array of email requests
     *
     * @return BulkEmailResponse The bulk email response
     *
     * @throws HuefyException If the request fails
     * @throws InvalidArgumentException If requests array is empty
     * @throws ValidationException If any request is invalid
     */
    public function sendBulkEmails(array $requests): BulkEmailResponse
    {
        if (empty($requests)) {
            throw new InvalidArgumentException('Requests array cannot be empty');
        }

        // Validate all requests
        foreach ($requests as $index => $request) {
            if (!$request instanceof SendEmailRequest) {
                throw new InvalidArgumentException(
                    sprintf('Request at index %d must be an instance of SendEmailRequest', $index)
                );
            }

            try {
                $request->validate();
            } catch (ValidationException $e) {
                throw new ValidationException(
                    sprintf('Validation failed for request %d: %s', $index, $e->getMessage()),
                    $e->getCode(),
                    $e
                );
            }
        }

        $payload = [
            'emails' => array_map(fn (SendEmailRequest $req) => $req->toArray(), $requests),
        ];

        $responseData = $this->makeRequest(
            'POST',
            '/api/v1/sdk/emails/bulk',
            $payload
        );

        return BulkEmailResponse::fromArray($responseData);
    }

    /**
     * Check the health status of the Huefy API.
     *
     * @return HealthResponse The health response
     *
     * @throws HuefyException If the request fails
     */
    public function healthCheck(): HealthResponse
    {
        $responseData = $this->makeRequest('GET', '/api/v1/sdk/health');
        return HealthResponse::fromArray($responseData);
    }

    /**
     * Make an HTTP request to the Huefy API.
     *
     * @param string $method HTTP method
     * @param string $path API path
     * @param array<string, mixed>|null $data Request data
     *
     * @return array<string, mixed> Response data
     *
     * @throws HuefyException If the request fails
     */
    private function makeRequest(string $method, string $path, ?array $data = null): array
    {
        $url = rtrim($this->config->getBaseUrl(), '/') . $path;
        $options = [];

        if ($data !== null) {
            $options[RequestOptions::JSON] = $data;
        }

        try {
            $this->logger->debug('Making API request', [
                'method' => $method,
                'url' => $url,
                'data' => $data,
            ]);

            $response = $this->httpClient->request($method, $url, $options);
            $body = $response->getBody()->getContents();

            if (empty($body)) {
                throw new HuefyException('Empty response body received');
            }

            try {
                $responseData = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
            } catch (JsonException $e) {
                throw new HuefyException('Failed to decode JSON response: ' . $e->getMessage(), 0, $e);
            }

            $this->logger->debug('API request successful', [
                'status_code' => $response->getStatusCode(),
                'response_size' => strlen($body),
            ]);

            return $responseData;
        } catch (RequestException $e) {
            $this->handleRequestException($e);
        } catch (GuzzleException $e) {
            throw new NetworkException('Network error: ' . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Handle Guzzle request exceptions and convert to appropriate Huefy exceptions.
     *
     * @param RequestException $e The request exception
     *
     * @throws HuefyException
     */
    private function handleRequestException(RequestException $e): void
    {
        $response = $e->getResponse();

        if ($response === null) {
            if (str_contains($e->getMessage(), 'timeout')) {
                throw new TimeoutException('Request timed out: ' . $e->getMessage(), 0, $e);
            }
            throw new NetworkException('Network error: ' . $e->getMessage(), 0, $e);
        }

        $statusCode = $response->getStatusCode();
        $body = $response->getBody()->getContents();

        try {
            $errorData = json_decode($body, true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            $errorData = [
                'error' => [
                    'code' => 'HTTP_' . $statusCode,
                    'message' => $body ?: 'HTTP ' . $statusCode,
                ],
            ];
        }

        $this->logger->error('API request failed', [
            'status_code' => $statusCode,
            'error_data' => $errorData,
        ]);

        throw Exceptions\ExceptionFactory::createFromResponse($errorData, $statusCode, $e);
    }

    /**
     * Create and configure the HTTP client.
     *
     * @return GuzzleClient
     */
    private function createHttpClient(): GuzzleClient
    {
        $config = [
            'base_uri' => $this->config->getBaseUrl(),
            'timeout' => $this->config->getTimeout(),
            'connect_timeout' => $this->config->getConnectTimeout(),
            'headers' => [
                'X-API-Key' => $this->apiKey,
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
                'User-Agent' => self::USER_AGENT,
            ],
        ];

        // Add retry middleware if enabled
        if ($this->config->getRetryConfig()->isEnabled()) {
            $config['handler'] = $this->createHandlerStack();
        }

        return new GuzzleClient($config);
    }

    /**
     * Create Guzzle handler stack with retry middleware.
     *
     * @return \GuzzleHttp\HandlerStack
     */
    private function createHandlerStack(): \GuzzleHttp\HandlerStack
    {
        $stack = \GuzzleHttp\HandlerStack::create();

        $retryConfig = $this->config->getRetryConfig();
        $retryMiddleware = \GuzzleHttp\Middleware::retry(
            function (int $retries, \Psr\Http\Message\RequestInterface $request, ?\Psr\Http\Message\ResponseInterface $response = null, ?RequestException $exception = null): bool {
                // Don't retry if max retries exceeded
                if ($retries >= $this->config->getRetryConfig()->getMaxRetries()) {
                    return false;
                }

                // Retry on network errors
                if ($exception && !$exception->hasResponse()) {
                    return true;
                }

                // Retry on 5xx errors and 429 (rate limit)
                if ($response) {
                    $statusCode = $response->getStatusCode();
                    return $statusCode >= 500 || $statusCode === 429;
                }

                return false;
            },
            function (int $retries): int {
                $delay = $this->config->getRetryConfig()->getBaseDelay() * (2 ** ($retries - 1));
                return (int) min($delay * 1000, $this->config->getRetryConfig()->getMaxDelay() * 1000);
            }
        );

        $stack->push($retryMiddleware);

        return $stack;
    }
}
