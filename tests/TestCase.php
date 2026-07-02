<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

abstract class TestCase extends BaseTestCase
{
    use RefreshDatabase;

    protected function expectedCsvHeaders(): array
    {
        return [
            'CODIGO',
            'APELLIDOS',
            'NOMBRES',
            'EAP',
            'PUNTAJE',
            'MERITO',
            'OBSERVACION',
            'TIPO',
            'MODALIDAD',
            'UNIVERSIDAD',
            'PERIODO',
            'FECHA',
        ];
    }

    protected function buildCsvRow(array $values): string
    {
        return implode(',', $values) . "\n";
    }

    protected function buildCsv(array $rows, bool $includeHeaders = true): string
    {
        $csv = '';

        if ($includeHeaders) {
            $csv .= implode(',', $this->expectedCsvHeaders()) . "\n";
        }

        foreach ($rows as $row) {
            $csv .= $this->buildCsvRow($row);
        }

        return $csv;
    }

    protected function createTempCsv(string $content, string $name = 'test.csv'): string
    {
        $path = storage_path('app/' . $name);
        file_put_contents($path, $content);

        return $path;
    }

    protected function validCsvRow(array $overrides = []): array
    {
        return array_merge([
            'CODIGO' => '001',
            'APELLIDOS' => 'LOPEZ GARCIA',
            'NOMBRES' => 'JUAN',
            'EAP' => 'MEDICINA HUMANA',
            'PUNTAJE' => '15.500',
            'MERITO' => '10',
            'OBSERVACION' => 'ALCANZO VACANTE',
            'TIPO' => 'ORDINARIO',
            'MODALIDAD' => 'GENERAL',
            'UNIVERSIDAD' => 'UNMSM',
            'PERIODO' => '2026-I',
            'FECHA' => '2026-05-17',
        ], $overrides);
    }
}
