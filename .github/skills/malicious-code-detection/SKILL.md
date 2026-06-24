# malicious-code-detection

Purpose: scan source code for malicious patterns including eval injection, dynamic imports, base64 payloads, crypto-mining indicators, and data exfiltration vectors.

## Input

- Source directory path (e.g., `src/`, or feature-specific file list from `git diff`)
- Language context (TypeScript, Python, Go, etc.)

## Pattern Categories

### 1. Code Injection

Detect dangerous dynamic execution patterns:

| Pattern | Language | Risk | Example |
|---------|----------|------|---------|
| `eval()` / `Function()` / `exec()` | JS/TS/Python | Critical | Dynamic code execution |
| `os.system()` / `subprocess.call(shell=True)` | Python | High | Shell command injection |
| `child_process.exec()` / `vm.runInNewContext()` | Node.js | High | Unsafe dynamic execution |
| Dynamic `require()` / `import()` | JS/TS | Medium | Unsafe dynamic loading |
| Template literal injection | JS/TS | Medium | Unsafe string interpolation |

### 2. Base64 Payloads

- Base64-encoded strings >100 chars, unsafe `atob()` / `btoa()` / `Buffer.from()` with dynamic input

### 3. Crypto-Mining & Exfiltration

- Mining pool references (`stratum+tcp://`), WebSocket to mining endpoints, CPU-intensive hash loops
- Unexpected HTTP/HTTPS to non-allowlisted domains, file reads followed by network sends

## Execution Flow

1. Identify all source files in scope (from diff or directory scan).
2. For each file, scan line-by-line against all pattern categories.
3. For each match, evaluate context:
   - Is it in test code? → lower severity
   - Is it in a security-sensitive path (auth, payment)? → higher severity
   - Is there input sanitization before the pattern? → mitigated
4. Assign severity: Critical, High, Medium, Low, Info.
5. Produce the output report.

## Output Contract

Produce a report with: scope (files scanned), findings count by severity, verdict (CLEAN / REVIEW NEEDED / BLOCK). Each finding lists severity, category, file:line, matched pattern, context snippet, risk, and remediation.
