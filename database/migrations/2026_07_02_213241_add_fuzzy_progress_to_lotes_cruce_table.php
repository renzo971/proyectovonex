<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('lotes_cruce', function (Blueprint $table) {
            $table->integer('fuzzy_procesados')->default(0)->after('total_pendientes');
        });
    }

    public function down(): void
    {
        Schema::table('lotes_cruce', function (Blueprint $table) {
            $table->dropColumn('fuzzy_procesados');
        });
    }
};
