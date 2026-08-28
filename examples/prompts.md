# Prompt patterns

Good workflow prompts state the intent, variable inputs, mutation boundary, and
acceptance criteria. Let the skill carry the reusable policy.

## Guarded PR landing

**Before**

> Merge the PR if it looks good.

**After**

> Use `/guarded-pr-landing` for PR 123 in `OWNER/REPO` against `main`.
> Read-only triage first, then merge is authorized only if confidence is at
> least 95, the head is unchanged, all required reviews/checks pass, and
> `npm test` succeeds. Use squash merge. Otherwise return `BLOCKED`.

## Safe disk cleanup

**Before**

> Delete old build junk and free space.

**After**

> Use `/safe-disk-cleanup` under `D:\worktrees` and `D:\package-cache`.
> Allow only untracked `bin`, `obj`, and package-cache entries older than 14
> days. Preserve source, uncommitted work, branches, repository roots, and valid
> worktrees. Preview exact paths and sizes, measure free space before/after, and
> do not rebuild.

## Visual artifact

**Before**

> Make an architecture diagram.

**After**

> Use `/artifact-delivery-contract` to create an editable architecture diagram
> at `docs/system.excalidraw` and open it in the available canvas. Preview the
> visual direction after the first representative flow. Accept when labels are
> readable, light/dark contrast works, edges do not overlap labels, and the
> final persisted file reopens correctly.

## Session history map-reduce

**Before**

> Look through my old sessions and find recurring problems.

**After**

> Use `/session-history-map-reduce` for `2026-01-01T00:00:00-08:00` through
> `2026-04-01T00:00:00-07:00`. Partition initially by seven days with a fixed
> 30-second query timeout. Analyze turns and tool calls only through explicit
> session IDs. Redact credentials and local usernames. Report deduplicated
> recurring failure categories, session/time coverage, and every failed or
> split partition.
