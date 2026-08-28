#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
guard="$repo_root/.github/hooks/scripts/pre-tool-use-guard.sh"
passed=0

assert_decision() {
  local name="$1"
  local command_text="$2"
  local expected="$3"
  local payload actual

  payload="$(
    jq -cn --arg command "$command_text" \
      '{sessionId:"test-session",timestamp:0,cwd:".",toolName:"bash",toolArgs:{command:$command}}'
  )"
  actual="$(printf '%s' "$payload" | bash "$guard" | jq -er '.permissionDecision')"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s: expected %s, got %s\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
  passed=$((passed + 1))
}

assert_decision 'status allowed' 'git status --short' 'allow'
assert_decision 'tests allowed' 'npm test' 'allow'
assert_decision 'named output cleanup allowed' 'rm -rf ./build' 'allow'
assert_decision 'hard reset blocked' 'git reset --hard HEAD~1' 'deny'
assert_decision 'forced clean blocked' 'git clean -fdx' 'deny'
assert_decision 'forced branch deletion blocked' 'git branch -D old-work' 'deny'
assert_decision 'root deletion blocked' 'rm -rf /' 'deny'
assert_decision 'home deletion blocked' 'rm --recursive --force $HOME' 'deny'

malformed="$(printf '{}' | bash "$guard" | jq -er '.permissionDecision')"
if [[ "$malformed" != 'deny' ]]; then
  printf 'Malformed payload must be denied.\n' >&2
  exit 1
fi
passed=$((passed + 1))

payload="$(
  jq -cn '{toolName:"bash",toolArgs:{command:"git status"}}'
)"
invalid_regex="$(
  printf '%s' "$payload" |
    COPILOT_GUARD_EXTRA_BLOCK_REGEX='[' bash "$guard" |
    jq -er '.permissionDecision'
)"
if [[ "$invalid_regex" != 'deny' ]]; then
  printf 'Invalid custom regex must be denied.\n' >&2
  exit 1
fi
passed=$((passed + 1))

printf 'Bash guard: %d cases passed.\n' "$passed"
