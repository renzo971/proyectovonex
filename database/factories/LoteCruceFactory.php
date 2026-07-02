<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\LoteCruce;
use Illuminate\Database\Eloquent\Factories\Factory;

class LoteCruceFactory extends Factory
{
    protected $model = LoteCruce::class;

    public function definition(): array
    {
        return [
            'fecha_examen' => $this->faker->unique()->date(),
            'total_registros' => 0,
            'total_ingresantes' => 0,
            'total_no_ingresantes' => 0,
            'total_match_exacto' => 0,
            'total_pendientes' => 0,
            'total_no_ingresado' => 0,
            'estado' => 'processing',
            'started_at' => null,
            'completed_at' => null,
        ];
    }
}
