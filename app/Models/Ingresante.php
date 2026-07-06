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

    protected $casts = [
        'puntaje' => 'decimal:3',
        'porcentaje_similitud' => 'decimal:2',
        'fecha' => 'date:Y-m-d',
    ];

    public static bool $allowAutomaticConfirm = false;

    protected static function booted()
    {
        static::saving(function (Ingresante $ingresante) {
            // Check for INV-01
            if ($ingresante->isDirty('estado_match') && $ingresante->estado_match === 'confirmado_automatico') {
                if (!static::$allowAutomaticConfirm) {
                    return false;
                }
            }

            // Check for INV-04 (De-duplication of identical rows)
            $fecha = $ingresante->fecha;
            if ($fecha instanceof \DateTimeInterface) {
                $fecha = $fecha->format('Y-m-d');
            } elseif (is_string($fecha)) {
                $fecha = substr($fecha, 0, 10);
            }

            $query = static::where([
                'lote_cruce_id' => $ingresante->lote_cruce_id,
                'codigo' => $ingresante->codigo,
                'apellidos' => $ingresante->apellidos,
                'nombres' => $ingresante->nombres,
                'fecha' => $fecha,
            ]);

            if ($ingresante->exists) {
                $query->where('id', '!=', $ingresante->id);
            }

            if ($query->exists()) {
                return false;
            }
        });
    }

    public function loteCruce(): BelongsTo
    {
        return $this->belongsTo(LoteCruce::class, 'lote_cruce_id');
    }

    public function candidatos(): HasMany
    {
        return $this->hasMany(IngresanteCandidato::class, 'ingresante_id');
    }
}
