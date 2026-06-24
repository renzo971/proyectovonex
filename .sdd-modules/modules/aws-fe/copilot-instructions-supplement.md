## Acme FE Module

This project uses the `aws-fe` SDD module, which packages Acme FE-specific frontend guidance and prompt bundles.

### Installed Instruction Namespace

All Acme FE instruction files are installed under `.github/instructions/aws-fe/`.

Key references:

<instruction>
<file>.github/instructions/aws-fe/architecture.instructions.md</file>
<description>Architecture, foldering, data flow, and project structure rules.</description>
</instruction>

<instruction>
<file>.github/instructions/aws-fe/general-coding.instructions.md</file>
<description>General coding and maintainability conventions.</description>
</instruction>

<instruction>
<file>.github/instructions/aws-fe/react.instructions.md</file>
<description>React component and hook patterns.</description>
</instruction>

<instruction>
<file>.github/instructions/aws-fe/typescript.instructions.md</file>
<description>TypeScript rules and typing guidance.</description>
</instruction>

<instruction>
<file>.github/instructions/aws-fe/stratos.instructions.md</file>
<description>Stratos component selection and layout guidance.</description>
</instruction>

### Installed Prompt Namespace

All Acme FE prompts are installed under `.github/prompts/aws-fe/` and remain split by domain:

- `aws-fe/party-account/`
- `aws-fe/securities/`
- `aws-fe/settlement/`
- root prompts for scaffolding and nullable migration

### Setup References

- `.specify/templates/setup/project-guidelines.setup.md`
- `.specify/templates/setup/unit-tests.setup.md`
- `.specify/templates/setup/vscode-settings.setup.json`
- `.specify/templates/setup/vscode-mcp.setup.json`

### Notes

- `Neo` and `Smith` are provided as manual agent patches under `agent-patches/` as `agent-neo-generator.patch.md` and `agent-smith-reviewer.patch.md`.
- The Acme FE prompt bundle assumes the target project follows the guidelines shipped in the setup templates.