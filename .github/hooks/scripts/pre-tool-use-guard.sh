#!/usr/bin/env bash
set -u

deny() {
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg reason "$1" \
      '{permissionDecision:"deny",permissionDecisionReason:$reason}'
  else
    printf '%s\n' '{"permissionDecision":"deny","permissionDecisionReason":"The Bash guard requires jq and denied because it is unavailable."}'
  fi
  exit 0
}

allow() {
  printf '%s\n' '{"permissionDecision":"allow"}'
  exit 0
}

command -v jq >/dev/null 2>&1 || deny 'The Bash guard requires jq.'
payload="$(cat)" || deny 'The guard could not read the hook payload.'

tool_name="$(
  printf '%s' "$payload" |
    jq -er '.toolName // .tool_name // empty' 2>/dev/null
)" || deny 'The guard could not parse the hook payload.'

case "$tool_name" in
  bash|powershell|Bash) ;;
  *) allow ;;
esac

command_text="$(
  printf '%s' "$payload" |
    jq -er '
      (.toolArgs // .tool_input) as $args |
      if ($args | type) == "string" then
        (try ($args | fromjson) catch {"command": $args})
      else
        $args
      end |
      .command // .script // empty
    ' 2>/dev/null
)" || deny 'Shell command could not be identified from the hook payload.'

normalized="$(printf '%s' "$command_text" | tr '\r\n\t' '   ' | tr -s ' ')"

patterns=(
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+reset[[:space:]]+--hard([[:space:]]|$)'
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+clean([^;&|])*(--force|[[:space:]]+-[a-z]*f)'
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+branch[[:space:]]+-D([[:space:]]|$)'
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([^;&|])*(--force-with-lease|--force|[[:space:]]+-[a-z]*f)'
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+checkout[[:space:]]+--[[:space:]]+(\.|\.\.|/|\*|\\)([[:space:]]|$)'
  '(^|[;&|][[:space:]]*)git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+restore([[:space:]]|$)'
  '(^|[;&|][[:space:]]*)rm[[:space:]]+([^;&|])*((-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*)|(--recursive([^;&|])*--force|--force([^;&|])*--recursive))([^;&|])*[[:space:]](\.|\.\.|/|\*|~|\$HOME|\$\{HOME\})(/|\*)?([[:space:]]|$|[;&|])'
  '(^|[;&|][[:space:]]*)(Remove-Item|rm|ri)[[:space:]]+([^;&|])*-Recurse([^;&|])*[[:space:]](\.|\.\.|[A-Z]:\\|\\\\[^\\]+\\[^\\]+\\?|\$HOME|\$env:USERPROFILE)(\\|\*)?([[:space:]]|$|[;&|])'
)

for pattern in "${patterns[@]}"; do
  if printf '%s\n' "$normalized" | grep -Eiq -- "$pattern"; then
    deny 'Blocked a recognized destructive Git operation or broad recursive deletion.'
  fi
done

if [[ -n "${COPILOT_GUARD_EXTRA_BLOCK_REGEX:-}" ]]; then
  set +e
  printf '%s\n' "$normalized" |
    grep -Eiq -- "$COPILOT_GUARD_EXTRA_BLOCK_REGEX" 2>/dev/null
  regex_status=$?
  set -e
  if [[ $regex_status -eq 2 ]]; then
    deny 'COPILOT_GUARD_EXTRA_BLOCK_REGEX is invalid.'
  fi
  if [[ $regex_status -eq 0 ]]; then
    deny 'Blocked by COPILOT_GUARD_EXTRA_BLOCK_REGEX.'
  fi
fi

allow
