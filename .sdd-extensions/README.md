# SDD Extensions

This directory holds Enterprise SDD extensions.

- Extension packs live under `.sdd-extensions/extensions/`.
- Schemas live under `.sdd-extensions/schema/`.
- Authoring conventions are documented in `.sdd-extensions/AUTHORING-GUIDE.md`.

## Extension Structure

```
.sdd-extensions/
├── schema/
│   ├── sdd-extension.schema.json
│   └── sdd-tailored-extension.schema.json
└── extensions/
    └── sdd-extension-my-tool/
        ├── sdd-extension.json    ← required manifest
        ├── hooks/
        │   ├── after-gate-pass.sh
        │   └── after-new-feature.sh
        ├── instructions/
        ├── prompts/
        └── templates/
```

## Manifest Format

```json
{
  "name": "sdd-extension-my-tool",
  "version": "1.0.0",
  "description": "My custom SDD extension",
  "author": "Your Name",
  "hooks": {
    "after-gate-pass":    "hooks/after-gate-pass.sh",
    "after-new-feature":  "hooks/after-new-feature.sh"
  },
  "commands": {},
  "templates": {},
  "agentPatches": {}
}
```

## Available Hooks

| Hook | Trigger | Arguments |
|------|---------|-----------|
| `after-gate-pass` | After a gate passes validation | `<feature-id> <gate-num>` |
| `after-new-feature` | After `sdd new` / `new-feature.sh` completes | `<feature-id>` |

> Current implementation actively fires `after-gate-pass` and `after-new-feature`.
> Additional hook names may be introduced later via script updates and schema evolution.

## Schema Validation

The manifest is validated against `.sdd-extensions/schema/sdd-extension.schema.json`.
Tailored frontend packs are validated against `.sdd-extensions/schema/sdd-tailored-extension.schema.json`.
Extension names must follow the pattern `sdd-extension-<something>`.

## Example: Slack Notification Extension

```bash
mkdir -p .sdd-extensions/extensions/sdd-extension-slack/hooks
cat > .sdd-extensions/extensions/sdd-extension-slack/sdd-extension.json <<'EOF'
{
  "name": "sdd-extension-slack",
  "version": "1.0.0",
  "description": "Post Slack notifications on gate pass",
  "hooks": {
    "after-gate-pass": "hooks/notify.sh"
  }
}
EOF

cat > .sdd-extensions/extensions/sdd-extension-slack/hooks/notify.sh <<'EOF'
#!/usr/bin/env bash
FEATURE_ID="$1"
GATE_NUM="$2"
curl -s -X POST "$SLACK_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"✅ Gate $GATE_NUM passed for feature $FEATURE_ID\"}"
EOF
chmod +x .sdd-extensions/extensions/sdd-extension-slack/hooks/notify.sh
```
