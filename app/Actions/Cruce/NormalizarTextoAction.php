<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

class NormalizarTextoAction
{
    /**
     * Normalize a given text: convert to uppercase, remove accents, map Ñ to N,
     * and protect against CSV injection.
     */
    public function execute(string $text): string
    {
        $text = mb_strtoupper($text, 'UTF-8');
        
        $map = [
            'Á' => 'A', 'É' => 'E', 'Í' => 'I', 'Ó' => 'O', 'Ú' => 'U',
            'Ñ' => 'N',
        ];
        $text = strtr($text, $map);
        
        $trimmed = trim(preg_replace('/\s+/', ' ', $text));
        
        if ($trimmed !== '') {
            $firstChar = mb_substr($trimmed, 0, 1, 'UTF-8');
            $csvInjections = ['=', '+', '-', '@', "\t", "\r"];
            if (in_array($firstChar, $csvInjections, true)) {
                $trimmed = "'" . $trimmed;
            }
        }
        
        return $trimmed;
    }

    /**
     * Separate a full name in the format "Apellidos, Nombres" into
     * maternal/paternal surnames and names.
     */
    public function separar(string $input): array
    {
        if (str_contains($input, ',')) {
            [$apellidosStr, $nombresStr] = explode(',', $input, 2);
        } else {
            $apellidosStr = $input;
            $nombresStr = '';
        }

        $apellidos = $this->execute($apellidosStr);
        $nombres = $this->execute($nombresStr);

        $words = preg_split('/\s+/', $apellidos, -1, PREG_SPLIT_NO_EMPTY);
        
        $paterno = '';
        $materno = '';

        if (count($words) === 1) {
            $paterno = $words[0];
            $materno = '';
        } elseif (count($words) > 1) {
            $prefixes = ['DE', 'DEL', 'LA', 'LAS', 'LOS', 'VON', 'SAN', 'SANTA', 'AL'];
            
            $maternalStartIndex = count($words) - 1;
            
            if ($maternalStartIndex > 0 && in_array($words[$maternalStartIndex - 1], $prefixes, true)) {
                $maternalStartIndex--;
                if ($maternalStartIndex > 0 && in_array($words[$maternalStartIndex - 1], $prefixes, true)) {
                    $maternalStartIndex--;
                }
            }
            
            $paternoWords = array_slice($words, 0, $maternalStartIndex);
            $maternoWords = array_slice($words, $maternalStartIndex);
            
            $paterno = implode(' ', $paternoWords);
            $materno = implode(' ', $maternoWords);
        }

        return [
            'apellido_paterno' => $paterno,
            'apellido_materno' => $materno,
            'nombres' => $nombres,
        ];
    }
}
