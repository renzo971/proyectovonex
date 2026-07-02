<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\LoteCruce;
use App\Models\NoIngresante;
use Illuminate\Database\Eloquent\Factories\Factory;

class NoIngresanteFactory extends Factory
{
    protected $model = NoIngresante::class;

    public function definition(): array
    {
        return [
            'lote_cruce_id' => LoteCruce::factory(),
            'codigo' => $this->faker->unique()->numerify('######'),
            'apellidos' => $this->faker->lastName() . ' ' . $this->faker->lastName(),
            'nombres' => $this->faker->firstName(),
            'eap' => $this->faker->randomElement(['MEDICINA HUMANA', 'DERECHO', 'INGENIERIA DE SOFTWARE', 'ADMINISTRACION', 'CIENCIAS BIOLOGICAS']),
            'puntaje' => $this->faker->randomFloat(3, 5, 20),
            'merito' => $this->faker->numberBetween(1, 100),
            'observacion' => 'NO ALCANZO VACANTE',
            'tipo' => 'ORDINARIO',
            'modalidad' => 'GENERAL',
            'universidad' => 'UNMSM',
            'periodo' => '2026-I',
            'fecha' => now()->subDays(rand(1, 30))->format('Y-m-d'),
        ];
    }
}
