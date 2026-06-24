# pattern-analyze

Purpose: scan the project codebase, infer structural and coding patterns in use, and produce
a `CODEBASE-PATTERNS.md` artefact that agents can consult to ensure new code is consistent
with existing conventions.

## Execution Plan

1. Locate `src/` (or the project's primary source root) and `tests/` directories.
2. Analyse directory structure to identify:
   - Layering model (feature-based, layer-based, hexagonal, etc.)
   - Naming conventions (files, classes, functions, variables)
   - Module boundaries and import patterns
3. Sample 10–20 representative source files to detect:
   - Dominant coding style (class-based vs functional, async patterns, error handling idiom)
   - Dependency injection patterns
   - State management patterns (frontend) or repository pattern (backend)
   - Test file colocation vs separate `tests/` directory
4. Cross-reference with `.specify/memory/constitution.md` (Articles II–IV) to identify
   adherence and deviations.
5. Write findings to `CODEBASE-PATTERNS.md` in the project root (or `.specify/memory/codebase-patterns.md`).

## Output Contract

- **Directory Map** — annotated tree (max 3 levels) of `src/`
- **Naming Patterns** — table of: scope | convention | example
- **Dominant Idioms** — bullet list of recurring coding conventions
- **Test Layout** — where tests live, naming convention, framework detected
- **Constitution Compliance** — matched | deviates | not specified (per Article IV principle)
- **Recommended Actions** — up to 5 actionable consistency improvements
