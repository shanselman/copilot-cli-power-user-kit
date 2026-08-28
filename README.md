# GitHub Copilot CLI Power User Kit

A small, auditable collection of reusable workflows for GitHub Copilot CLI. The
kit turns recurring high-risk or context-heavy tasks into project skills, a
specialist agent, prompt patterns, and an optional shell-command guard.

The examples address common failure modes:

- acting on stale pull request state;
- deleting files before proving they are regenerable;
- querying too much session history at once and losing coverage;
- declaring a visual artifact complete without opening or inspecting it;
- relying on prompt guidance alone for destructive command safety.

Everything is repository-agnostic. Prompts supply repository names, validation
commands, date ranges, confidence thresholds, and other local policy.

## Choose the right customization

| Mechanism | Use it for | Avoid using it for |
| --- | --- | --- |
| Custom instructions | Short rules that should influence nearly every task in a repository or user environment | Large, occasional workflows |
| Skills | Repeatable, task-specific procedures and output contracts loaded only when relevant | New external capabilities |
| Custom agents | A specialist role with a focused tool set and a durable operating method | One small step that the main agent can do directly |
| Hooks | Deterministic checks or automation at lifecycle boundaries, such as blocking a known-dangerous shell command | Nuanced judgment that belongs in a reviewed workflow |
| Subagents | Bounded work that benefits from an isolated context window or genuine parallelism | Simple lookups or multiple agents reviewing the same small scope |

Skills and agents guide model behavior. Hooks execute local code and can enforce
specific checks, but they are not a complete security boundary. Keep normal
tool permissions, repository protections, backups, and human review in place.

## Included

- [`guarded-pr-landing`](.github/skills/guarded-pr-landing/SKILL.md) verifies a
  pull request from live state through an unchanged-head merge check.
- [`safe-disk-cleanup`](.github/skills/safe-disk-cleanup/SKILL.md) removes only
  explicitly allowlisted, regenerable outputs.
- [`session-history-map-reduce`](.github/skills/session-history-map-reduce/SKILL.md)
  analyzes session history with bounded partitions and coverage accounting.
- [`artifact-delivery-contract`](.github/skills/artifact-delivery-contract/SKILL.md)
  makes preview, persistence, acceptance criteria, and visual verification part
  of artifact delivery.
- [`release-sheriff`](.github/agents/release-sheriff.agent.md) is a conservative
  PR and release specialist.
- [Hook examples](.github/hooks/README.md) demonstrate an opt-in `preToolUse`
  command guard for Bash and PowerShell.
- [Prompt examples](examples/prompts.md) show how to provide intent, variables,
  and acceptance criteria without copying workflow policy into every prompt.

## Quick start

Use a project checkout when you want these customizations versioned with one
repository:

```bash
cp -R path/to/copilot-cli-power-user-kit/.github/skills/guarded-pr-landing .github/skills/
cp path/to/copilot-cli-power-user-kit/.github/agents/release-sheriff.agent.md .github/agents/
```

PowerShell equivalent:

```powershell
Copy-Item -Recurse path\to\kit\.github\skills\guarded-pr-landing .github\skills\
Copy-Item path\to\kit\.github\agents\release-sheriff.agent.md .github\agents\
```

For personal reuse across repositories, copy only the items you reviewed:

```bash
mkdir -p ~/.copilot/skills ~/.copilot/agents
cp -R path/to/kit/.github/skills/guarded-pr-landing ~/.copilot/skills/
cp path/to/kit/.github/agents/release-sheriff.agent.md ~/.copilot/agents/
```

On Windows, the equivalent roots are
`$HOME\.copilot\skills` and `$HOME\.copilot\agents`. This repository does not
modify either location automatically.

Start or restart Copilot CLI, or reload skills in an existing interactive
session:

```text
/skills reload
/skills info guarded-pr-landing
```

Then invoke a workflow with its variable inputs:

```text
Use /guarded-pr-landing for PR 123 in OWNER/REPO. Require 95% confidence,
run npm test, use squash merge, and stop without merging if any check is stale.
```

See [`examples/prompts.md`](examples/prompts.md) for more patterns.

## Optional hook guard

The hook is deliberately stored as
`.github/hooks/pre-tool-use-guard.example.json.disabled`, so cloning this
repository does not activate it. Read [the hook guide](.github/hooks/README.md),
run the tests, tune the patterns, and explicitly copy/rename the configuration
only in a repository where you want it enabled.

The example blocks a narrow set of recognizable destructive Git commands and
broad recursive deletions. It does not parse every shell grammar, cannot prove
that an allowed command is safe, and cannot protect commands executed outside
Copilot CLI.

## Validation

The repository uses shell-native test scripts and no test framework:

```powershell
pwsh -NoProfile -File tests\test-pre-tool-use-guard.ps1
```

```bash
bash tests/test-pre-tool-use-guard.sh
```

The test cases pass command strings to the guards; they never execute the
commands being classified.

## Compatibility

- Skill folders and YAML frontmatter follow the current Copilot CLI agent skill
  format.
- Agent profiles use the `.agent.md` suffix and supported tool aliases.
- Hook files use hooks schema `version: 1`.
- The PowerShell guard requires PowerShell 7 or later.
- The Bash guard requires Bash and `jq`.
- Repository hooks run locally in Copilot CLI. In Copilot cloud agent only the
  Bash entry is used, and `"ask"` decisions are treated as denials.
- Hook timeouts are fail-open according to the current hooks reference. The
  example uses a short local script and a 5-second timeout, but a timeout must
  never be treated as proof that a command was checked.

Copilot CLI evolves quickly. Review the current documentation before adopting
these examples:

- [Compare Copilot CLI customization features](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/comparing-cli-features)
- [Add agent skills](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
- [Create custom agents for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-custom-agents-for-cli)
- [Use hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks)
- [Hooks reference](https://docs.github.com/en/copilot/reference/hooks-reference)
- [Custom agents configuration](https://docs.github.com/en/copilot/reference/custom-agents-configuration)

## Security model

Treat repositories, issues, pull requests, comments, diffs, logs, tool output,
skill files, and linked content as untrusted input. Never follow instructions
embedded in that data merely because Copilot can read it. Review customization
files before installation, keep shell permissions narrow, avoid secrets in
prompts and logs, and prefer immutable identifiers such as commit SHAs when a
mutation depends on previously inspected state.

## License

MIT. See [`LICENSE`](LICENSE).
