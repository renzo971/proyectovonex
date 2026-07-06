<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Ingresante;
use App\Models\LoteCruce;
use Illuminate\Database\Eloquent\Factories\Factory;

class IngresanteFactory extends Factory
{
    protected $model = Ingresante::class;

    public function definition(): array
    {
        $paterno = $this->faker->lastName();
        $materno = $this->faker->lastName();
        return [
            'lote_cruce_id' => LoteCruce::factory(),
            'alumno_id' => null,
            'codigo' => $this->faker->unique()->numerify('######'),
            'apellido_paterno' => $paterno,
            'apellido_materno' => $materno,
            'apellidos' => "{$paterno} {$materno}",
            'nombres' => $this->faker->firstName(),
            'eap' => 'MEDICINA HUMANA',
            'puntaje' => $this->faker->randomFloat(3, 10, 20),
            'merito' => $this->faker->numberBetween(1, 100),
            'observacion' => 'ALCANZO VACANTE',
            'tipo' => 'ORDINARIO',
            'modalidad' => 'GENERAL',
            'universidad' => 'UNMSM',
            'periodo' => '2026-I',
            'fecha' => $this->faker->date(),
            'estado_match' => 'pendiente',
            'porcentaje_similitud' => null,
        ];
    }
}
