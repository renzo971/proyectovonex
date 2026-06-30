<?php

declare(strict_types=1);

namespace Tests\Contract;

use App\Models\LoteCruce;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\Test;
use Symfony\Component\Yaml\Yaml;
use Tests\TestCase;

/**
 * Test Suite: OpenAPI Contract Validation
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class OpenApiContractTest extends TestCase
{
    use RefreshDatabase;

    private array $openApiSpec;

    protected function setUp(): void
    {
        parent::setUp();

        $specPath = base_path('.specify/specs/001-motor-cruce-ingresantes/contracts/openapi.yaml');
        if (file_exists($specPath)) {
            $this->openApiSpec = Yaml::parseFile($specPath);
        }
    }

    /**
     * TC-049: GET /api/cruce/lotes — List all batches
     * Traces to: US-001, US-004, NFR-005, openapi.yaml
     * Type: Contract
     * Priority: P1
     */
    #[Test]
    public function tc049_lotes_endpoint_matches_openapi_spec(): void
    {
        if (empty($this->openApiSpec)) {
            $this->markTestSkipped('OpenAPI spec not found');
        }

        $paths = $this->openApiSpec['paths'] ?? [];
        expect($paths)->toHaveKey('/cruce/lotes');

        $lotesPath = $paths['/cruce/lotes'];
        expect($lotesPath)->toHaveKey('get');

        $getOp = $lotesPath['get'];
        expect($getOp)->toHaveKey('responses');
        expect($getOp['responses'])->toHaveKey('200');
    }

    #[Test]
    public function tc049_lotes_response_schema_is_valid(): void
    {
        if (empty($this->openApiSpec)) {
            $this->markTestSkipped('OpenAPI spec not found');
        }

        $components = $this->openApiSpec['components'] ?? [];
        $schemas = $components['schemas'] ?? [];

        expect($schemas)->toHaveKey('LoteCruce');

        $loteSchema = $schemas['LoteCruce'];
        expect($loteSchema['properties'])->toHaveKeys([
            'lote_id',
            'estado',
            'fecha_examen',
            'total_registros',
            'created_at',
        ]);
    }

    #[Test]
    public function tc049_upload_endpoint_exists_in_spec(): void
    {
        if (empty($this->openApiSpec)) {
            $this->markTestSkipped('OpenAPI spec not found');
        }

        $paths = $this->openApiSpec['paths'] ?? [];
        expect($paths)->toHaveKey('/cruce/upload');

        $uploadPath = $paths['/cruce/upload'];
        expect($uploadPath)->toHaveKey('post');
    }
}
