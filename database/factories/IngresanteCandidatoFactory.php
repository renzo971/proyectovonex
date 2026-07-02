<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Ingresante;
use App\Models\IngresanteCandidato;
use Illuminate\Database\Eloquent\Factories\Factory;

class IngresanteCandidatoFactory extends Factory
{
    protected $model = IngresanteCandidato::class;

    public function definition(): array
    {
        return [
            'ingresante_id' => Ingresante::factory(),
            'alumno_id' => $this->faker->unique()->numberBetween(1, 999999),
            'porcentaje_similitud' => $this->faker->randomFloat(2, 70, 100),
            'ranking' => $this->faker->numberBetween(1, 5),
        ];
    }
}
