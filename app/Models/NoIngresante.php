<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NoIngresante extends Model
{
    use HasFactory;

    protected $table = 'no_ingresantes';

    const UPDATED_AT = null;

    protected $fillable = [
        'lote_cruce_id',
        'codigo',
        'apellidos',
        'apellido_paterno',
        'apellido_materno',
        'nombres',
        'eap',
        'puntaje',
        'merito',
        'observacion',
        'tipo',
        'modalidad',
        'universidad',
        'periodo',
        'fecha',
    ];

    protected $casts = [
        'puntaje' => 'decimal:3',
        'fecha' => 'date:Y-m-d',
    ];

    protected static function booted()
    {
        static::updating(function ($model) {
            return false;
        });

        static::deleting(function ($model) {
            throw new \Exception('no_ingresantes table is append-only');
        });
    }

    public function loteCruce(): BelongsTo
    {
        return $this->belongsTo(LoteCruce::class, 'lote_cruce_id');
    }
}
