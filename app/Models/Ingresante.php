<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ingresante extends Model
{
    use HasFactory;

    protected $table = 'ingresantes';

    protected $fillable = [
        'lote_cruce_id',
        'alumno_id',
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
        'estado_match',
        'porcentaje_similitud',
    ];

    protected function casts(): array
    {
        return [
            'puntaje' => 'decimal:3',
            'fecha' => 'date:Y-m-d',
            'porcentaje_similitud' => 'decimal:2',
        ];
    }

    public const string PENDIENTE = 'pendiente';
    public const string CONFIRMADO_AUTOMATICO = 'confirmado_automatico';
    public const string CONFIRMADO_MANUAL = 'confirmado_manual';
    public const string NO_INGRESADO = 'no_ingresado';

    protected static function booted(): void
    {
        static::saving(function (Ingresante $ingresante) {
            if ($ingresante->exists && $ingresante->isDirty('estado_match')) {
                $original = $ingresante->getOriginal('estado_match');
                $newValue = $ingresante->estado_match;
                if ($original !== 'confirmado_automatico' && $newValue === 'confirmado_automatico') {
                    return false;
                }
            }

            if (!$ingresante->exists && $ingresante->estado_match === 'confirmado_automatico') {
                return false;
            }
        });

        static::creating(function (Ingresante $ingresante) {
            if (empty($ingresante->apellido_paterno) && !empty($ingresante->apellidos)) {
                $normalizer = new \App\Actions\Cruce\NormalizarTextoAction();
                $split = $normalizer->separar($ingresante->apellidos . ', ' . ($ingresante->nombres ?? ''));
                $ingresante->apellido_paterno = $split['apellido_paterno'];
                $ingresante->apellido_materno = $split['apellido_materno'];
            }
        });
    }

    public function loteCruce(): BelongsTo
    {
        return $this->belongsTo(LoteCruce::class, 'lote_cruce_id');
    }

    public function ingresanteCandidatos(): HasMany
    {
        return $this->hasMany(IngresanteCandidato::class, 'ingresante_id');
    }

    public function getAlumnoAttribute()
    {
        return $this->alumno_id;
    }
}
