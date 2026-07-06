<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;

class AcademiaDbHelper
{
    public static function ensureTablesAndSeed(): void
    {
        if (app()->environment('testing') || config('database.default') === 'sqlite') {
            if (Schema::connection('academia')->hasTable('personas')) {
                return;
            }

            // Create tables
            Schema::connection('academia')->create('personas', function (Blueprint $table) {
                $table->string('dni')->primary();
                $table->string('nombres');
                $table->string('apellido_paterno');
                $table->string('apellido_materno');
                $table->string('telefono')->nullable();
            });

            Schema::connection('academia')->create('alumnos', function (Blueprint $table) {
                $table->string('codigo')->primary();
                $table->string('persona_dni');
                $table->string('email')->nullable();
            });

            Schema::connection('academia')->create('alumno_matricula', function (Blueprint $table) {
                $table->id();
                $table->string('alumno_codigo');
                $table->unsignedBigInteger('aula_id');
                $table->smallInteger('estado');
                $table->smallInteger('estado_aula')->default(1);
                $table->timestamp('fecha')->useCurrent();
                $table->unsignedBigInteger('matricularegular_id')->nullable();
            });

            Schema::connection('academia')->create('aulas', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('matricula_id');
            });

            Schema::connection('academia')->create('matriculas', function (Blueprint $table) {
                $table->id();
            });

            Schema::connection('academia')->create('ciclos', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('matricula_id');
                $table->date('fecha_fin');
            });

            // Seed cycles, matriculas, aulas
            for ($i = 1; $i <= 50; $i++) {
                DB::connection('academia')->table('matriculas')->insert(['id' => $i]);
                DB::connection('academia')->table('aulas')->insert(['id' => $i, 'matricula_id' => $i]);
                DB::connection('academia')->table('ciclos')->insert([
                    'id' => $i,
                    'matricula_id' => $i,
                    'fecha_fin' => '2026-12-31',
                ]);
            }

            // 1. Exact match JUAN LOPEZ GARCIA
            self::insertStudent('11111111', 'JUAN', 'LOPEZ', 'GARCIA', 'ALU001', 1, 2);

            // 2. Exact match DIEGO CASTILLO TORIBIO
            self::insertStudent('22222222', 'DIEGO', 'CASTILLO', 'TORIBIO', 'ALU002', 2, 2);

            // 3. Fuzzy candidates for RAMOS LOPEZ JHON
            self::insertStudent('30000001', 'JHON', 'RAMOS', 'LOPEZ', 'ALUF01', 3, 2);
            self::insertStudent('30000002', 'JON', 'RAMOS', 'LOPEZ', 'ALUF02', 4, 2);
            self::insertStudent('30000003', 'JHOAN', 'RAMOS', 'LOPEZ', 'ALUF03', 5, 2);
            self::insertStudent('30000004', 'JOHAN', 'RAMOS', 'LOPEZ', 'ALUF04', 6, 2);
            self::insertStudent('30000005', 'JOHNNY', 'RAMOS', 'LOPEZ', 'ALUF05', 7, 2);

            // 4. Fuzzy candidates for GARCIA LOPEZ MARIA (testing alphabetical tie-break by apellido_paterno)
            self::insertStudent('40000001', 'MARIA', 'ZAMORA', 'LOPEZ', 'ALUM01', 8, 2);
            self::insertStudent('40000002', 'MARIA', 'BAKER', 'LOPEZ', 'ALUM02', 9, 2);
            self::insertStudent('40000003', 'MARIA', 'CARTER', 'LOPEZ', 'ALUM03', 10, 2);
            self::insertStudent('40000004', 'MARIA', 'AARONS', 'LOPEZ', 'ALUM04', 11, 2);
            self::insertStudent('40000005', 'MARIA', 'GARCIA', 'LOPEZ', 'ALUM05', 12, 2);
            self::insertStudent('40000006', 'MARIA', 'DAVIS', 'LOPEZ', 'ALUM06', 13, 2);

            // 5. Fuzzy candidates for GONZALES DE LA FLOR PEDRO
            self::insertStudent('50000001', 'PEDRO', 'GONZALES', 'DE LA FLOR', 'ALUP01', 14, 2);
            self::insertStudent('50000002', 'PEDRO', 'GONZALES', 'DE LA VEGA', 'ALUP02', 15, 2);
            self::insertStudent('50000003', 'PEDRO', 'GONZALEZ', 'FLORES', 'ALUP03', 16, 2);
            self::insertStudent('50000004', 'PEDRO', 'GONZALES', 'SILVA', 'ALUP04', 17, 2);
            self::insertStudent('50000005', 'PETE', 'GONZALES', 'FLOR', 'ALUP05', 18, 2);
        }
    }

    private static function insertStudent(
        string $dni,
        string $nombres,
        string $paterno,
        string $materno,
        string $codigo,
        int $matriculaId,
        int $estado
    ): void {
        DB::connection('academia')->table('personas')->insert([
            'dni' => $dni,
            'nombres' => $nombres,
            'apellido_paterno' => $paterno,
            'apellido_materno' => $materno,
        ]);

        DB::connection('academia')->table('alumnos')->insert([
            'codigo' => $codigo,
            'persona_dni' => $dni,
        ]);

        DB::connection('academia')->table('alumno_matricula')->insert([
            'id' => $matriculaId,
            'alumno_codigo' => $codigo,
            'aula_id' => $matriculaId,
            'estado' => $estado,
            'estado_aula' => 1,
        ]);
    }
}
