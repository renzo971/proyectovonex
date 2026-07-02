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

    protected function casts(): array
    {
        return [
            'puntaje' => 'decimal:3',
            'fecha' => 'date:Y-m-d',
        ];
    }

    public function update(array $attributes = [], array $options = []): bool
    {
        return false;
    }

    public function delete(): ?bool
    {
        throw new \Exception('no_ingresantes is append-only (INV-02). DELETE and UPDATE are not permitted.');
    }

    public function loteCruce(): BelongsTo
    {
        return $this->belongsTo(LoteCruce::class, 'lote_cruce_id');
    }
}
