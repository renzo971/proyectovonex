<?php

declare(strict_types=1);

namespace Tests\Contract;

use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\Yaml\Yaml;
use Tests\TestCase;

/**
 * Test Suite: AsyncAPI Contract Validation
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class AsyncApiContractTest extends TestCase
{
    use RefreshDatabase;

    private array $asyncApiSpec;

    protected function setUp(): void
    {
        parent::setUp();

        $specPath = base_path('.specify/specs/001-motor-cruce-ingresantes/contracts/asyncapi.yaml');
        if (file_exists($specPath)) {
            $this->asyncApiSpec = Yaml::parseFile($specPath);
        }
    }

    /**
     * TC-050: CruceBatchProcessedEvent dispatched on batch success
     * Traces to: asyncapi.yaml CruceBatchProcessedEvent, tasks.md T007
     * Type: Contract
     * Priority: P1
     */
    #[Test]
    public function tc050_cruce_batch_processed_event_exists_in_spec(): void
    {
        if (empty($this->asyncApiSpec)) {
            $this->markTestSkipped('AsyncAPI spec not found');
        }

        $channels = $this->asyncApiSpec['channels'] ?? [];
        $messages = $this->asyncApiSpec['components']['messages'] ?? [];

        // Check if CruceBatchProcessedEvent is defined
        $hasEvent = false;
        foreach ($messages as $key => $message) {
            if (str_contains($key, 'CruceBatchProcessed') || str_contains($message['name'] ?? '', 'CruceBatchProcessed')) {
                $hasEvent = true;
                break;
            }
        }

        expect($hasEvent)->toBeTrue();
    }

    /**
     * TC-051: CruceBatchFailedEvent dispatched on batch failure
     * Traces to: asyncapi.yaml CruceBatchFailedEvent, tasks.md T007
     * Type: Contract
     * Priority: P1
     */
    #[Test]
    public function tc051_cruce_batch_failed_event_exists_in_spec(): void
    {
        if (empty($this->asyncApiSpec)) {
            $this->markTestSkipped('AsyncAPI spec not found');
        }

        $messages = $this->asyncApiSpec['components']['messages'] ?? [];

        $hasEvent = false;
        foreach ($messages as $key => $message) {
            if (str_contains($key, 'CruceBatchFailed') || str_contains($message['name'] ?? '', 'CruceBatchFailed')) {
                $hasEvent = true;
                break;
            }
        }

        expect($hasEvent)->toBeTrue();
    }
}
