<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ingresantes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->foreignId('lote_cruce_id')->constrained('lotes_cruce')->cascadeOnDelete();
            $table->unsignedBigInteger('alumno_id')->nullable();
            $table->string('codigo', 50);
            $table->string('apellidos', 255);
            $table->string('apellido_paterno', 255);
            $table->string('apellido_materno', 255);
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
            $table->string('estado_match', 50)->default('pendiente');
            $table->decimal('porcentaje_similitud', 5, 2)->nullable();
            $table->timestamps();

            $table->index(['apellidos', 'nombres']);
            $table->index('lote_cruce_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ingresantes');
    }
};
