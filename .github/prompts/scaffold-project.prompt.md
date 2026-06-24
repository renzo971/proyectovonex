---
mode: agent
description: Scaffold a new project from constitution
tools:
  - editFiles
  - search
  - runCommands
---

## Scaffold Project

You are setting up a new project. Follow these steps:

1. Read the constitution at `.specify/memory/constitution.md`
2. Read the setup templates at `.specify/templates/setup/`
3. Ask the user for:
   - Project name
   - Repository URL (if applicable)
   - Any constitution articles not yet defined
4. Generate the project structure following the templates:
   - **Project setup** → `.specify/templates/setup/project-setup-template.md`
   - **Integration tests** → `.specify/templates/setup/integration-tests-setup-template.md`
   - **Quality tools** → `.specify/templates/setup/quality-tools-setup-template.md`
5. Run `sdd init` if not already done
6. Create a smoke test to verify the setup
7. Report what was created and suggest next steps
