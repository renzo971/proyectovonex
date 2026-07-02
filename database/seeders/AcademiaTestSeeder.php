<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Support\Facades\DB;

class AcademiaTestSeeder
{
    public static function run(): void
    {
        $sql = file_get_contents(__DIR__ . '/AcademiaTestSeeder.sql');
        $statements = explode(";\n", $sql);

        DB::connection('academia')->statement('SET client_min_messages TO WARNING;');

        foreach ($statements as $statement) {
            $statement = trim($statement);
            if (!empty($statement)) {
                try {
                    DB::connection('academia')->statement($statement);
                } catch (\Exception $e) {
                    echo "Warning: " . $e->getMessage() . "\n";
                }
            }
        }

        DB::connection('academia')->statement("SELECT setval('alumno_matricula_id_seq', (SELECT MAX(id) FROM alumno_matricula))");
    }
}
