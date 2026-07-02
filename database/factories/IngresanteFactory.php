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
        $apellidoPaterno = $this->faker->randomElement(['LOPEZ', 'GARCIA', 'PEREZ', 'RAMOS', 'CASTILLO']);
        $apellidoMaterno = $this->faker->randomElement(['GARCIA', 'LOPEZ', 'TORIBIO', 'RUIZ', 'SANCHEZ']);

        return [
            'lote_cruce_id' => LoteCruce::factory(),
            'alumno_id' => null,
            'codigo' => $this->faker->unique()->numerify('######'),
            'apellidos' => $apellidoPaterno . ' ' . $apellidoMaterno,
            'apellido_paterno' => $apellidoPaterno,
            'apellido_materno' => $apellidoMaterno,
            'nombres' => $this->faker->firstName(),
            'eap' => $this->faker->randomElement(['MEDICINA HUMANA', 'DERECHO', 'INGENIERIA DE SOFTWARE', 'ADMINISTRACION', 'CIENCIAS BIOLOGICAS']),
            'puntaje' => $this->faker->randomFloat(3, 5, 20),
            'merito' => $this->faker->numberBetween(1, 100),
            'observacion' => 'ALCANZO VACANTE',
            'tipo' => 'ORDINARIO',
            'modalidad' => 'GENERAL',
            'universidad' => 'UNMSM',
            'periodo' => '2026-I',
            'fecha' => now()->subDays(rand(1, 30))->format('Y-m-d'),
            'estado_match' => Ingresante::PENDIENTE,
            'porcentaje_similitud' => null,
        ];
    }
}
