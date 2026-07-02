<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class IngresanteCandidato extends Model
{
    use HasFactory;

    protected $table = 'ingresante_candidatos';

    const UPDATED_AT = null;

    protected $fillable = [
        'ingresante_id',
        'alumno_id',
        'porcentaje_similitud',
        'ranking',
    ];

    protected function casts(): array
    {
        return [
            'porcentaje_similitud' => 'decimal:2',
        ];
    }

    public function ingresante(): BelongsTo
    {
        return $this->belongsTo(Ingresante::class, 'ingresante_id');
    }
}
