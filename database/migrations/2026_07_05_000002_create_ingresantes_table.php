<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ingresantes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lote_cruce_id')->constrained('lotes_cruce')->cascadeOnDelete();
            $table->unsignedBigInteger('alumno_id')->nullable();
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
            $table->string('estado_match', 50)->default('pendiente');
            $table->decimal('porcentaje_similitud', 5, 2)->nullable();
            $table->timestamps();

            $table->index(['apellidos', 'nombres']);
            $table->index(['apellido_paterno', 'apellido_materno', 'nombres']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ingresantes');
    }
};
