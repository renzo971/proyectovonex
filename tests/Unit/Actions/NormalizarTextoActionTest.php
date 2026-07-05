<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\Cruce\NormalizarTextoAction;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Test Suite: NormalizarTextoAction
 * Feature ID: 001-motor-cruce-ingresantes
 * Generated from: .specify/specs/001-motor-cruce-ingresantes/test-cases.md
 */
class NormalizarTextoActionTest extends TestCase
{
    private NormalizarTextoAction $action;

    protected function setUp(): void
    {
        parent::setUp();
        $this->action = new NormalizarTextoAction();
    }

    /**
     * TC-002: Normalización de acentos y Ñ en la lógica del backend
     * Traces to: US-001, AC-002, plan.md: NormalizarTextoAction
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc002_normalizes_accents_and_n_to_uppercase(): void
    {
        $input = 'María Ñañez de la Cruz';
        $expected = 'MARIA NANEZ DE LA CRUZ';

        $result = $this->action->execute($input);

        expect($result)->toBe($expected);
    }

    /**
     * TC-002b: Normalización de todos los caracteres acentuados
     * Traces to: US-001, AC-002
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc002b_normalizes_all_accented_characters(): void
    {
        $testCases = [
            'Á' => 'A',
            'É' => 'E',
            'Í' => 'I',
            'Ó' => 'O',
            'Ú' => 'U',
            'á' => 'A',
            'é' => 'E',
            'í' => 'I',
            'ó' => 'O',
            'ú' => 'U',
            'Ñ' => 'N',
            'ñ' => 'N',
        ];

        foreach ($testCases as $input => $expected) {
            $result = $this->action->execute($input);
            expect($result)->toBe($expected);
        }
    }

    /**
     * TC-002: Separación de apellidos compuestos y nombres con normalización
     * Traces to: US-001, AC-002, AC-003, test-cases.md TC-2
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc002_separates_compound_surname_and_normalizes(): void
    {
        $input = 'De la Cruz Muñoz, María-José';
        $result = $this->action->separar($input);

        expect($result)->toHaveKeys(['apellido_paterno', 'apellido_materno', 'nombres']);
        expect($result['apellido_paterno'])->toBe('DE LA CRUZ');
        expect($result['apellido_materno'])->toBe('MUNOZ');
        expect($result['nombres'])->toBe('MARIA-JOSE');
    }

    /**
     * TC-044: Valor crudo de OBSERVACION nunca es evaluado — solo el normalizado (INV-05)
     * Traces to: INV-05, CQ-001, US-001 AC-004
     * Type: Unit
     * Priority: P1
     */
    #[Test]
    public function tc0044_normalizes_observacion_before_filter_evaluation(): void
    {
        $rawInput = 'alcanzó vacante';
        $normalized = $this->action->execute($rawInput);

        expect($normalized)->toBe('ALCANZO VACANTE');
        expect($normalized)->not->toContain('ó');
        expect(mb_strtoupper($normalized))->toBe($normalized);
    }
}
