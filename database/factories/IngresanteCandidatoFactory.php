<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\IngresanteCandidato;
use App\Models\Ingresante;
use Illuminate\Database\Eloquent\Factories\Factory;

class IngresanteCandidatoFactory extends Factory
{
    protected $model = IngresanteCandidato::class;

    public function definition(): array
    {
        return [
            'ingresante_id' => Ingresante::factory(),
            'alumno_id' => $this->faker->numberBetween(1, 10000),
            'porcentaje_similitud' => $this->faker->randomFloat(2, 70, 99.9),
            'ranking' => $this->faker->numberBetween(1, 5),
        ];
    }
}
