<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ingresante_candidatos', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->foreignId('ingresante_id')->constrained('ingresantes')->cascadeOnDelete();
            $table->unsignedBigInteger('alumno_id');
            $table->decimal('porcentaje_similitud', 5, 2);
            $table->smallInteger('ranking');
            $table->timestamp('created_at')->nullable();

            $table->unique(['ingresante_id', 'ranking']);
            $table->index('ingresante_id');
            $table->index(['ingresante_id', 'ranking']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ingresante_candidatos');
    }
};
