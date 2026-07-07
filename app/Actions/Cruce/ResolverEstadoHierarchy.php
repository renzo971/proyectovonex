<?php

declare(strict_types=1);

namespace App\Actions\Cruce;

/**
 * Shared INV-06 estado-hierarchy resolution.
 *
 * INV-06 (context-bridge.md, spec.md AC-007) is the immutable priority order
 * used to resolve which `alumno_matricula` record wins when the same person
 * has more than one historical record: MATRICULADO(2) > PAGADO(3) >
 * FINALIZADO(14) > SUSPENDIDO(9) > RETIRADO(0) > TRASLADADO(12) >
 * STAND BY(13) > ANULADO(11).
 *
 * Extracted so `RealizarCruceExactoAction` (exact matching) and
 * `CalcularSimilitudesCabosAction` (fuzzy matching) resolve duplicate-person
 * records identically and cannot drift apart again.
 *
 * **Correction (2026-07-07, PO verification against real production data):**
 * a person's MOST RECENT `alumno_matricula` record must win over any older
 * historical record, regardless of INV-06 hierarchy — the hierarchy is only
 * a TIE-BREAK when multiple records genuinely share the single most-recent
 * date (or when none of the contending records have a usable date). Without
 * this, a stale historical record with a higher-priority estado (e.g. a 2022
 * PAGADO row) incorrectly outranked the person's real CURRENT estado (e.g. a
 * 2026 RETIRADO row), because the hierarchy-only reading implemented in T036
 * had no concept of recency. This supersedes the hierarchy-only reading of
 * `dedupeByIdentity()` from T036; see tasks.md T038 for the full incident
 * writeup.
 */
final class ResolverEstadoHierarchy
{
    /**
     * INV-06 immutable order, highest priority first.
     */
    private const PRIORITY_ORDER = [2, 3, 14, 9, 0, 12, 13, 11];

    /**
     * Returns the estado (from a list of estado codes belonging to the same
     * person) with the highest INV-06 priority. Estados outside the known
     * hierarchy are treated as lowest priority.
     */
    public static function pickBestEstado(array $estados): int
    {
        $best = null;

        foreach ($estados as $estado) {
            $estado = (int) $estado;
            if ($best === null || self::isHigherPriority($estado, $best)) {
                $best = $estado;
            }
        }

        return $best ?? 0;
    }

    /**
     * True when $candidate has a strictly higher INV-06 priority than
     * $current (lower index in PRIORITY_ORDER wins). Unknown estados are
     * treated as lowest priority.
     */
    public static function isHigherPriority(int $candidate, int $current): bool
    {
        return self::priorityIndex($candidate) < self::priorityIndex($current);
    }

    private static function priorityIndex(int $estado): int
    {
        $position = array_search($estado, self::PRIORITY_ORDER, true);

        return $position === false ? PHP_INT_MAX : $position;
    }

    /**
     * Collapses $rows down to one row per identity key, keeping — for each
     * duplicate identity — a single "winning" row per the rule below. Rows
     * with a unique identity are returned unchanged. Original array keys of
     * the surviving rows are preserved; the relative order of distinct
     * identities follows each identity's first occurrence in $rows.
     *
     * Winning rule (2026-07-07 correction — see class docblock):
     * 1. If `$dateAccessor` is provided: the row with the MOST RECENT date
     *    wins. A row with a usable date always beats a row with none.
     * 2. INV-06 hierarchy (`$estadoAccessor` + `PRIORITY_ORDER`) is used ONLY
     *    as a tie-break — when `$dateAccessor` is omitted entirely, when both
     *    contending rows share the exact same date, or when neither has a
     *    usable date.
     *
     * @param array<int|string, mixed> $rows
     * @param callable(mixed): (int|string) $identityKey extracts the identity (e.g. dni) from a row
     * @param callable(mixed): int $estadoAccessor extracts the estado code from a row
     * @param (callable(mixed): (string|null))|null $dateAccessor extracts the recency signal (e.g. `alumno_matricula.fecha`) from a row; omit to keep pure hierarchy-only resolution
     * @return array<int|string, mixed>
     */
    public static function dedupeByIdentity(
        array $rows,
        callable $identityKey,
        callable $estadoAccessor,
        ?callable $dateAccessor = null
    ): array {
        $bestKeyByIdentity = [];

        foreach ($rows as $key => $row) {
            $identity = $identityKey($row);

            if (!array_key_exists($identity, $bestKeyByIdentity)) {
                $bestKeyByIdentity[$identity] = $key;
                continue;
            }

            $currentBestKey = $bestKeyByIdentity[$identity];

            if (self::isBetterCandidate($row, $rows[$currentBestKey], $estadoAccessor, $dateAccessor)) {
                $bestKeyByIdentity[$identity] = $key;
            }
        }

        $result = [];
        foreach ($bestKeyByIdentity as $key) {
            $result[$key] = $rows[$key];
        }

        return $result;
    }

    /**
     * True when $candidate should replace $current as the "best" row for a
     * shared identity, per the recency-first / hierarchy-tie-break rule
     * documented on `dedupeByIdentity()`.
     */
    private static function isBetterCandidate(
        mixed $candidate,
        mixed $current,
        callable $estadoAccessor,
        ?callable $dateAccessor
    ): bool {
        if ($dateAccessor !== null) {
            $candidateTimestamp = self::toTimestamp($dateAccessor($candidate));
            $currentTimestamp = self::toTimestamp($dateAccessor($current));

            if ($candidateTimestamp !== null && $currentTimestamp !== null) {
                if ($candidateTimestamp !== $currentTimestamp) {
                    return $candidateTimestamp > $currentTimestamp;
                }
                // Tied on the single most-recent date — fall through to the
                // INV-06 hierarchy tie-break below.
            } elseif ($candidateTimestamp !== $currentTimestamp) {
                // Exactly one of the two rows has a usable date — a dated
                // row always beats an undated one, regardless of hierarchy.
                return $candidateTimestamp !== null;
            }
            // Both undated — fall through to the INV-06 hierarchy tie-break.
        }

        return self::isHigherPriority((int) $estadoAccessor($candidate), (int) $estadoAccessor($current));
    }

    /**
     * Normalizes a raw date/timestamp value (string, DateTimeInterface, or
     * null/empty) to a comparable Unix timestamp, or null when the value is
     * missing or unparseable. Unparseable values are treated as "no date"
     * rather than throwing, since this resolves real production DB rows.
     */
    private static function toTimestamp(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        if ($value instanceof \DateTimeInterface) {
            return $value->getTimestamp();
        }

        $timestamp = strtotime((string) $value);

        return $timestamp === false ? null : $timestamp;
    }
}
