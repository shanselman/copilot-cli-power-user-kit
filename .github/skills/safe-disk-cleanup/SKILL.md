---
name: safe-disk-cleanup
description: Reclaim disk space by inventorying and deleting only explicitly allowlisted regenerable outputs while preserving source, uncommitted work, branches, and valid worktrees. Use for repository or development-machine cleanup where broad recursive deletion is unacceptable.
license: MIT
---

# Safe disk cleanup

Inventory first. Delete only paths proven to be regenerable and explicitly
allowlisted for this run. A cleanup that cannot establish safety returns
`BLOCKED` and deletes nothing ambiguous.

## Required prompt parameters

- cleanup roots as explicit absolute or repository-relative paths;
- allowed output categories or exact path patterns;
- paths, repositories, or worktrees that must be excluded;
- minimum age or "not currently in use" rules, if any;
- whether a settled rebuild is requested after cleanup;
- optional target amount of space to reclaim.

Reject filesystem roots, home directories, repository roots, unresolved
variables, and broad wildcards as deletion targets.

## Procedure

1. **Establish the boundary.** Resolve every cleanup root to a canonical path.
   Confirm each target is below an intended workspace or cache directory. Do not
   follow symlinks, junctions, mount points, or reparse points outside that
   boundary.
2. **Measure before.** Record free space on the relevant volume and inventory
   candidate sizes. On Windows use volume-aware commands such as
   `Get-Volume`/`Get-PSDrive`; on Linux/macOS use `df` plus `du`.
3. **Protect Git state.** For every repository in scope, record `git status
   --short`, branches, current HEAD, and `git worktree list --porcelain`.
   Preserve tracked source, untracked or ignored files that may be source or
   user work, stashes, branches, `.git` data, and every valid linked worktree.
   Never use `git clean`, `git reset --hard`, or deletion as a substitute for
   understanding state.
4. **Build the candidate inventory.** Match only known regenerable outputs such
   as dependency caches or build directories allowed by the prompt. For each
   candidate record canonical path, type, size, owner repository, evidence of
   regenerability, Git classification, last modification time, and whether a
   process or valid worktree uses it.
5. **Apply the allowlist and exclusions.** A candidate is eligible only when:
   - its canonical path is a strict descendant of an approved root;
   - its category or exact path matches the run's allowlist;
   - it is not tracked source, uncommitted work, a repository root, a `.git`
     path, a branch, or a valid worktree;
   - it is not a symlink/junction/reparse-point escape;
   - no active process is known to use it;
   - a documented command can regenerate it.
6. **Preview.** Present the exact deletion list, total estimated bytes, and
   exclusions before mutation. Never convert a partial glob preview into a
   broader recursive command.
7. **Delete exact paths.** Delete candidates one at a time using canonical,
   quoted paths. Do not recursively delete `.`, `..`, `/`, a drive root, a home
   directory, a repository root, or any path containing unresolved variables or
   wildcards. Stop on unexpected path changes or errors; do not broaden scope.
8. **Verify preservation.** Re-run Git status and worktree inventory. Compare
   against the recorded baseline and report any difference as a failure. Confirm
   all preserved repositories and worktrees still resolve.
9. **Measure after.** Record free space on the same volumes and compute observed
   change. Explain that filesystem accounting may differ from summed file sizes.
10. **Optional settled rebuild.** Only after cleanup and preservation checks
    complete, run a prompt-authorized rebuild in a single chosen repository.
    Wait for it to settle, report recreated space, and do not start broad
    parallel restores that immediately refill the disk.

## Platform notes

- **Windows:** Treat drive roots, UNC share roots, junctions, reparse points,
  locked files, long paths, and case-insensitive path comparisons explicitly.
  Prefer `Remove-Item -LiteralPath` for exact approved paths; never combine
  `-Recurse` with a broad variable or wildcard.
- **Linux/macOS:** Resolve mount boundaries and symlinks. Use `--` before exact
  paths where supported. Never compose `rm -rf` from unchecked text or use a
  root/home/current-directory target.
- On every platform, path validation and deletion must use the same canonical
  value to avoid time-of-check/time-of-use substitution.

## Outcome

Return `CLEANED` with before/after measurements, exact removed paths, preserved
Git state, and rebuild result; or `BLOCKED` with the ambiguous or unsafe
candidates. Partial cleanup must be labeled explicitly.
