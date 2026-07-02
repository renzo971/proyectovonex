<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lotes_cruce', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->date('fecha_examen')->unique();
            $table->integer('total_registros')->default(0);
            $table->integer('total_ingresantes')->default(0);
            $table->integer('total_no_ingresantes')->default(0);
            $table->integer('total_match_exacto')->default(0);
            $table->integer('total_pendientes')->default(0);
            $table->integer('total_no_ingresado')->default(0);
            $table->string('estado', 50)->default('processing');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lotes_cruce');
    }
};
