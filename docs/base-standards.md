---
description: This document contains all development rules and guidelines for this project, applicable to all AI agents (Claude, Cursor, Codex, Gemini, etc.).
alwaysApply: true
---

## 1. Core Principles

- **Small tasks, one at a time**: Always work in baby steps, one at a time. Never go forward more than one step.
- **Pattern Preservation**: Follow the existing architecture patterns of the codebase (e.g. Action class pattern in backend, Custom Hooks in frontend).
- **Incremental Changes**: Prefer incremental, focused changes over large, complex modifications.
- **Question Assumptions**: Always question assumptions and inferences.
- **Pattern Detection**: Detect and highlight repeated code patterns.

## 2. Language Standards
- **English for Code**: All technical code artifacts (variables, function names, classes, internal comments, error logs) must be in English.
- **Spanish for Domain & UI**: Domain-specific terms (database tables/columns, business rules) and UI elements (buttons, pages, tabs, labels, messages visible to the user) are in Spanish to match the legacy codebase and user requirements.
- **Git Commit Messages**: Commits should be in English following conventional commits format.

## 3. Specific Standards

For detailed standards and guidelines specific to different areas of the project, refer to:

- [Backend Standards](./backend-standards.md) - Laravel 5.8, Eloquent ORM, Action classes, and PHP 7.1+ best practices.
- [Frontend Standards](./frontend-standards.md) - Vue.js 2.x inside Blade views, Bootstrap 4, SweetAlert2, and modular custom styling.
- [Documentation Standards](./documentation-standards.md) - Technical documentation structure, formatting, and maintenance guidelines.
- [OpenSpec Tasks Mandatory Steps](./openspec-tasks-mandatory-steps.md) - Required checklist and execution rules when creating or updating OpenSpec `tasks.md` files.

## 4. Symlink Integrity and Multi-Agent Portability

- **Canonical Source**: Keep reusable artifacts in `ai-specs` as the canonical source. Agent-specific paths (such as `.claude` and `.cursor`) should reference them through symlinks when possible.
- **Update Safety**: Whenever a file is renamed, moved, or its suffix changes, verify and update all symlinks that target it before considering the change complete.
- **New Artifact Linking**: Whenever creating a new artifact that requires multi-agent exposure, create the corresponding symlinks from the expected agent-specific reference paths.

## 5. Mandatory OpenSpec Artifact Updates for Post-Apply Changes

When a new fix/change request appears after `opsx:apply` (or `/apply`) and before `opsx:archive` (or `/archive`), agents must treat it as a spec update first, not as an informal "fix this quickly".

Required order:
1. Update the affected OpenSpec change artifacts (e.g. scenarios, requirements, and `tasks.md`).
2. If artifact regeneration is needed, run the corresponding OpenSpec step before coding.
3. Implement code only after artifacts reflect the new request.
4. Re-run verification against the updated artifacts before archiving.
