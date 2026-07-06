<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('no_ingresantes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lote_cruce_id')->constrained('lotes_cruce')->cascadeOnDelete();
            $table->string('codigo');
            $table->string('apellidos');
            $table->string('apellido_paterno')->nullable();
            $table->string('apellido_materno')->nullable();
            $table->string('nombres');
            $table->string('eap');
            $table->decimal('puntaje', 8, 3);
            $table->integer('merito');
            $table->string('observacion');
            $table->string('tipo');
            $table->string('modalidad');
            $table->string('universidad');
            $table->string('periodo');
            $table->date('fecha');
            $table->timestamp('created_at')->useCurrent();
        });

        // Add trigger to prevent UPDATE or DELETE
        $driver = DB::getDriverName();
        if ($driver === 'sqlite') {
            DB::unprepared("
                CREATE TRIGGER trg_no_ingresantes_readonly_update BEFORE UPDATE ON no_ingresantes
                BEGIN
                    SELECT RAISE(FAIL, 'no_ingresantes table is append-only');
                END;
            ");
            DB::unprepared("
                CREATE TRIGGER trg_no_ingresantes_readonly_delete BEFORE DELETE ON no_ingresantes
                BEGIN
                    SELECT RAISE(FAIL, 'no_ingresantes table is append-only');
                END;
            ");
        } elseif ($driver === 'pgsql') {
            DB::unprepared("
                CREATE OR REPLACE FUNCTION trg_no_ingresantes_readonly() RETURNS TRIGGER AS $$
                BEGIN
                    RAISE EXCEPTION 'no_ingresantes table is append-only';
                END;
                $$ LANGUAGE plpgsql;
            ");
            DB::unprepared("
                CREATE TRIGGER trg_no_ingresantes_readonly_update BEFORE UPDATE ON no_ingresantes
                FOR EACH ROW EXECUTE FUNCTION trg_no_ingresantes_readonly();
            ");
            DB::unprepared("
                CREATE TRIGGER trg_no_ingresantes_readonly_delete BEFORE DELETE ON no_ingresantes
                FOR EACH ROW EXECUTE FUNCTION trg_no_ingresantes_readonly();
            ");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('no_ingresantes');
    }
};
