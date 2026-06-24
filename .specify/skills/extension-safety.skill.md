# extension-safety

Purpose: validate extension safety constraints before activation.

## Steps

1. Run `sdd extension validate <path> --format tailored`.
2. Run `sdd extension doctor <path>`.
3. Ensure no namespace crossing.
4. Ensure no immutable-core override.

## Output Contract

- Extension validation report (PASS/FAIL)
- Namespace crossing check result
- Core immutability verification result
