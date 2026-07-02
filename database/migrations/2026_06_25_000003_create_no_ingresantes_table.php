<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('no_ingresantes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->foreignId('lote_cruce_id')->constrained('lotes_cruce')->cascadeOnDelete();
            $table->string('codigo', 50);
            $table->string('apellidos', 255);
            $table->string('nombres', 255);
            $table->string('eap', 255);
            $table->decimal('puntaje', 8, 3);
            $table->integer('merito');
            $table->string('observacion', 255);
            $table->string('tipo', 100);
            $table->string('modalidad', 100);
            $table->string('universidad', 100);
            $table->string('periodo', 50);
            $table->date('fecha');
            $table->timestamp('created_at')->nullable();

            $table->index('lote_cruce_id');
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("
                CREATE OR REPLACE FUNCTION prevent_no_ingresantes_mutation()
                RETURNS TRIGGER AS \$\$
                BEGIN
                    RAISE EXCEPTION 'no_ingresantes is append-only (INV-02). DELETE and UPDATE are not permitted.';
                END;
                \$\$ LANGUAGE plpgsql;
            ");

            DB::statement("
                CREATE TRIGGER trg_no_ingresantes_readonly
                BEFORE UPDATE OR DELETE ON no_ingresantes
                FOR EACH ROW
                EXECUTE PROCEDURE prevent_no_ingresantes_mutation();
            ");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('DROP TRIGGER IF EXISTS trg_no_ingresantes_readonly ON no_ingresantes');
            DB::statement('DROP FUNCTION IF EXISTS prevent_no_ingresantes_mutation');
        }
        Schema::dropIfExists('no_ingresantes');
    }
};
