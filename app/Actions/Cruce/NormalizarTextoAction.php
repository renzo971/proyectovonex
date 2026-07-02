<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

class NormalizarTextoAction
{
    public function execute(string $texto): string
    {
        $texto = mb_strtoupper($texto, 'UTF-8');
        $texto = str_replace(['Á', 'À', 'Â', 'Ã', 'Ä'], 'A', $texto);
        $texto = str_replace(['É', 'È', 'Ê', 'Ë'], 'E', $texto);
        $texto = str_replace(['Í', 'Ì', 'Î', 'Ï'], 'I', $texto);
        $texto = str_replace(['Ó', 'Ò', 'Ô', 'Õ', 'Ö'], 'O', $texto);
        $texto = str_replace(['Ú', 'Ù', 'Û', 'Ü'], 'U', $texto);
        $texto = str_replace(['Ñ'], 'N', $texto);

        return $texto;
    }

    public function separar(string $nombreCompleto): array
    {
        $normalized = $this->execute($nombreCompleto);

        $parts = preg_split('/\s*,\s*/', $normalized, 2);

        if (count($parts) === 2) {
            $surnamePart = trim($parts[0]);
            $namePart = trim($parts[1]);
        } else {
            $parts = preg_split('/\s{2,}/', $normalized, 2);
            if (count($parts) === 2) {
                $surnamePart = trim($parts[0]);
                $namePart = trim($parts[1]);
            } else {
                $surnamePart = '';
                $namePart = $normalized;
            }
        }

        $nameTokens = $namePart ? preg_split('/\s+/', $namePart) : [];
        $surnameTokens = $surnamePart ? preg_split('/\s+/', $surnamePart) : [];

        if (count($surnameTokens) < 2 && count($nameTokens) > 0) {
            $allTokens = $nameTokens;
            $nameTokens = [];

            $compoundPrefixes = [
                ['DE', 'LA'],
                ['DEL'],
                ['DE', 'LOS'],
                ['SAN'],
                ['SANTA'],
                ['VON'],
                ['VAN'],
            ];

            $i = 0;
            while ($i < count($allTokens)) {
                $isPrefix = false;
                foreach ($compoundPrefixes as $prefixWords) {
                    $match = true;
                    for ($j = 0; $j < count($prefixWords); $j++) {
                        if (!isset($allTokens[$i + $j]) || $allTokens[$i + $j] !== $prefixWords[$j]) {
                            $match = false;
                            break;
                        }
                    }
                    if ($match) {
                        foreach ($prefixWords as $pw) {
                            $surnameTokens[] = $pw;
                        }
                        $i += count($prefixWords);
                        $isPrefix = true;
                        break;
                    }
                }
                if (!$isPrefix) {
                    $surnameTokens[] = $allTokens[$i];
                    $i++;
                    if (count($surnameTokens) >= 2) {
                        break;
                    }
                }
            }

            $nameTokens = array_slice($allTokens, $i);
        }

        $compoundPrefixes = [
            ['DE', 'LA'],
            ['DEL'],
            ['DE', 'LOS'],
            ['SAN'],
            ['SANTA'],
            ['VON'],
            ['VAN'],
        ];

        $prefixIndex = -1;
        $prefixWordCount = 0;
        for ($i = 0; $i < count($surnameTokens); $i++) {
            foreach ($compoundPrefixes as $prefixWords) {
                $match = true;
                for ($j = 0; $j < count($prefixWords); $j++) {
                    if (!isset($surnameTokens[$i + $j]) || $surnameTokens[$i + $j] !== $prefixWords[$j]) {
                        $match = false;
                        break;
                    }
                }
                if ($match) {
                    $prefixIndex = $i;
                    $prefixWordCount = count($prefixWords);
                    break 2;
                }
            }
        }

        if ($prefixIndex >= 0 && $prefixIndex === 0) {
            $afterPrefix = array_slice($surnameTokens, $prefixWordCount);
            $paterno = implode(' ', array_slice($surnameTokens, 0, $prefixWordCount)) . ' ' . ($afterPrefix[0] ?? '');
            $materno = implode(' ', array_slice($afterPrefix, 1));
        } else {
            $total = count($surnameTokens);
            $mid = (int) ceil($total / 2);
            $paterno = implode(' ', array_slice($surnameTokens, 0, $mid));
            $materno = implode(' ', array_slice($surnameTokens, $mid));
        }

        return [
            'apellido_paterno' => trim($paterno),
            'apellido_materno' => trim($materno),
            'nombres' => implode(' ', $nameTokens),
        ];
    }
}
