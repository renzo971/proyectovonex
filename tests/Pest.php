<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Test Case
|--------------------------------------------------------------------------
|
| The closure you provide to your test functions is always bound to a specific PHPUnit
| test case class. By default, that class is "PHPUnit\Framework\TestCase".
|
*/

uses(Tests\TestCase::class)->in('Unit', 'Features');

/*
|--------------------------------------------------------------------------
| Expectations
|--------------------------------------------------------------------------
|
| Once you have determined how to test your application, you may define expectations
| that will be applied to your test cases. These methods will be available to every
| test case in the test suite, making it easy to write concise and expressive tests.
|
*/

expect()->extend('toBeOne', function () {
    return $this->toBe(1);
});

/*
|--------------------------------------------------------------------------
| Functions
|--------------------------------------------------------------------------
|
| While Pest is out of the box very PHP-ish, it still gives you access to a variety of
| helper functions that you can use anywhere in your tests.
|
*/

/**
 * Normalize text the same way the application does:
 * uppercase + remove accents + Ñ → N.
 */
function normalizeText(string $text): string
{
    $text = mb_strtoupper($text, 'UTF-8');
    $text = preg_replace('/[ÁÉÍÓÚ]/u', 'AEIOU', $text);
    $text = str_replace('Ñ', 'N', $text);
    $text = str_replace('ñ', 'N', $text);

    return $text;
}

/**
 * Calculate Dice coefficient on bigrams.
 */
function diceCoefficient(string $a, string $b): float
{
    if (strlen($a) < 2 || strlen($b) < 2) {
        return 0.0;
    }

    $bigramsA = [];
    for ($i = 0; $i < strlen($a) - 1; $i++) {
        $bigramsA[] = substr($a, $i, 2);
    }

    $bigramsB = [];
    for ($i = 0; $i < strlen($b) - 1; $i++) {
        $bigramsB[] = substr($b, $i, 2);
    }

    $intersection = array_intersect_key($bigramsA, $bigramsB);

    return (2.0 * count($intersection)) / (count($bigramsA) + count($bigramsB));
}

/**
 * Calculate Levenshtein distance between two strings.
 */
function levenshteinSimilarity(string $a, string $b): float
{
    $distance = levenshtein($a, $b);
    $maxLen = max(strlen($a), strlen($b));

    if ($maxLen === 0) {
        return 1.0;
    }

    return 1.0 - ($distance / $maxLen);
}

/**
 * Combined similarity score: Levenshtein × 0.6 + Dice × 0.4.
 */
function combinedSimilarity(string $a, string $b): float
{
    $normA = normalizeText($a);
    $normB = normalizeText($b);

    return levenshteinSimilarity($normA, $normB) * 0.6
        + diceCoefficient($normA, $normB) * 0.4;
}

/**
 * Resolve the highest-priority status from multiple academic records.
 * Hierarchy: MATRICULADO > PAGADO > FINALIZADO > SUSPENDIDO > RETIRADO > TRASLADADO > STAND BY > ANULADO
 */
function resolveStatusHierarchy(array $statuses): string
{
    $hierarchy = [
        'MATRICULADO',
        'PAGADO',
        'FINALIZADO',
        'SUSPENDIDO',
        'RETIRADO',
        'TRASLADADO',
        'STAND BY',
        'ANULADO',
    ];

    foreach ($hierarchy as $priority) {
        if (in_array($priority, $statuses, true)) {
            return $priority;
        }
    }

    return 'ANULADO';
}

/**
 * Get the path to a test fixture CSV file.
 */
function fixturePath(string $filename): string
{
    return __DIR__ . '/Fixtures/csv/' . $filename;
}

/**
 * Read a fixture CSV file contents.
 */
function readFixture(string $filename): string
{
    return file_get_contents(fixturePath($filename));
}
