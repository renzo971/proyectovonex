<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LoteCruce extends Model
{
    use HasFactory;

    protected $table = 'lotes_cruce';

    protected $fillable = [
        'fecha_examen',
        'total_registros',
        'total_ingresantes',
        'total_no_ingresantes',
        'total_match_exacto',
        'total_pendientes',
        'fuzzy_procesados',
        'total_no_ingresado',
        'estado',
        'started_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'fecha_examen' => 'date:Y-m-d',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public const string PROCESSING = 'processing';
    public const string COMPLETED = 'completed';
    public const string PAUSED = 'paused';
    public const string ERROR = 'error';

    public function ingresantes(): HasMany
    {
        return $this->hasMany(Ingresante::class, 'lote_cruce_id');
    }

    public function noIngresantes(): HasMany
    {
        return $this->hasMany(NoIngresante::class, 'lote_cruce_id');
    }
}
