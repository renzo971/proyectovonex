---
applyTo: "mock/**/*.mjs"
---
# Mock API coding standards

## Response Methods (Low Priority)
- Use `sendStatus()` method instead of chaining `status().send()` for status-only responses
- This is more concise and idiomatic for Express.js mock APIs
- Examples:
  - ✅ `res.sendStatus(200)`
  - ✅ `res.sendStatus(204)`
  - ✅ `res.sendStatus(404)`
  - ❌ `res.status(200).send()`
  - ❌ `res.status(204).send()`
