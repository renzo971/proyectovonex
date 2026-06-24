## Std-FE Module

This project uses the `std-fe` module, which packages the tailored FE framework guidance for React microfrontends.

### Installed Instruction Files

<instruction>
<file>.github/instructions/fe/architecture.instructions.md</file>
<description>Frontend microfrontend architecture, foldering, state management, routing, and integration patterns.</description>
</instruction>

<instruction>
<file>.github/instructions/fe/general-coding.instructions.md</file>
<description>General FE coding standards and conventions.</description>
</instruction>

<instruction>
<file>.github/instructions/fe/stratos.instructions.md</file>
<description>Stratos design-system rules and component-selection guidance.</description>
</instruction>

<instruction>
<file>.github/instructions/fe/stratos-ui-agent.instructions.md</file>
<description>UI generation guidance for design-driven workflows.</description>
</instruction>

<instruction>
<file>.github/instructions/fe/e2e-testing.instructions.md</file>
<applyTo>e2e-tests/**/*.{ts,feature}</applyTo>
<description>Playwright and Cucumber end-to-end testing standards.</description>
</instruction>

### Notes

- Additional FE test-generation notes are available in `.specify/templates/setup/std-fe-copilot-test-instructions.setup.md` after installation.
- The `Severus` profile under `agent-patches/` is provided for manual agent adaptation, not for automatic installation.
