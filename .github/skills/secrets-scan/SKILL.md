# secrets-scan

Purpose: detect hardcoded credentials, API keys, tokens, certificates, and passwords in source code and configuration files.

## Input

- Source directory path (e.g., `src/`, or feature-specific file list from `git diff`)
- Configuration files (`.env`, `*.config.*`, `*.yml`, `*.yaml`, `*.json`)

## Detection Patterns

### 1. API Keys and Tokens

| Pattern | Regex Hint | Risk |
|---------|-----------|------|
| AWS Access Key | `AKIA[0-9A-Z]{16}` | Critical |
| AWS Secret Key | `[0-9a-zA-Z/+=]{40}` near `aws_secret` | Critical |
| GitHub Token | `gh[ps]_[A-Za-z0-9_]{36,}` | Critical |
| GitLab Token | `glpat-[A-Za-z0-9\-]{20,}` | Critical |
| Slack Token | `xox[baprs]-[0-9a-zA-Z-]{10,}` | High |
| Google API Key | `AIza[0-9A-Za-z\-_]{35}` | High |
| Azure Key | `[0-9a-f]{8}-...-[0-9a-f]{12}` near `azure` | High |
| JWT | `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.` | Medium |
| Bearer Token | `Bearer [A-Za-z0-9_\-\.]{20,}` | Medium |
| npm Token | `npm_[A-Za-z0-9]{36}` | High |

### 2. Passwords and Secrets

| Pattern | Risk |
|---------|------|
| `password = "..."` or `secret = "..."` variable assignments | Critical |
| `DB_PASSWORD=...` in source code | Critical |
| `connection_string` with embedded credentials | Critical |
| `private_key` with PEM content | Critical |

### 3. Certificates and Keys

| Pattern | Risk |
|---------|------|
| `-----BEGIN RSA PRIVATE KEY-----` or `-----BEGIN EC PRIVATE KEY-----` | Critical |
| `.p12` / `.pfx` / `.pem` files in source tree | High |
| `-----BEGIN CERTIFICATE-----` (may be intentional) | Medium |

### 4. Configuration Files

| Check | Risk |
|-------|------|
| `.env` not in `.gitignore` or committed to Git history | Critical |
| Secrets in `docker-compose.yml`, CI config, Kubernetes manifests | High |

## Exclusion Rules

Do NOT flag: placeholder values (`<YOUR_API_KEY>`, `xxx`, `changeme`, `TODO`), test fixtures with obviously fake data, documentation examples with dummy credentials, environment variable references (`process.env.SECRET`, `os.getenv("SECRET")`), or encrypted values (ciphertext, vault references).

## Execution Flow

1. Identify all files in scope (source + config).
2. Check `.gitignore` for `.env` exclusion.
3. Scan each file line-by-line against all detection patterns.
4. Apply exclusion rules to reduce false positives.
5. For each match, verify it's a real credential (not placeholder/test).
6. Assign severity based on pattern risk level.
7. Produce the output report.

## Output Contract

Produce a report with: scope (files scanned), findings by severity, verdict (CLEAN / REVIEW NEEDED / BLOCK), configuration checks (`.env` in `.gitignore`, no `.env` in history, no secrets in CI config), and per-finding details (severity, category, file:line, remediation). Redact actual secret values.
