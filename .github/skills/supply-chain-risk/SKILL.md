# supply-chain-risk

Purpose: assess dependency supply-chain risks including known CVEs, typosquatting, unmaintained packages, and lockfile integrity.

## Input

- Dependency manifest file (`package.json`, `requirements.txt`, `go.mod`, `pom.xml`, etc.)
- Lockfile if present (`package-lock.json`, `poetry.lock`, `go.sum`, etc.)

## Risk Categories

### 1. CVEs & Maintenance

- Run ecosystem audit (`npm audit --json`, `pip-audit --format=json`) and map CVE IDs to affected versions
- Flag unmaintained packages: no release >2 yr (High), no commits >1 yr (Medium), archived (High), single maintainer (Low)
- Check typosquatting: Levenshtein distance ≤ 2 from top-1000 packages, missing hyphens, transposed chars, added suffixes, scope confusion

### 2. Lockfile & Dependency Hygiene

- Lockfile exists, committed, matches manifest, integrity hashes present
- Flag: prod deps that should be dev, broad version ranges (`*`), duplicates at different versions, transitive depth >10

## Execution Flow

1. Identify package manager and manifest file.
2. Parse manifest for direct dependencies and version constraints.
3. Run ecosystem-specific audit tool (npm audit, pip-audit, etc.).
4. Analyze each dependency against typosquatting patterns.
5. Check maintenance status indicators.
6. Verify lockfile integrity.
7. Compile risk assessment report.

## Output Contract

Produce a report with: ecosystem, direct/transitive dependency counts, verdict (LOW / MODERATE / HIGH / CRITICAL RISK), risk summary table (CVEs × Typosquatting × Unmaintained × Lockfile by severity), per-finding details (severity, category, package@version, remediation), and dependency health matrix.
