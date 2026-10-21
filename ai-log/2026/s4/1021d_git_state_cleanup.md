# Git state cleanup before starting new FHLBible work

- Date: 2026-10-21
- Project: FHLBible
- Type: config
- Related logs: 2026/s4/1021c_deployment_target_raised_to_15.md
- Cross-project: FHLCommon `ai-log/2026/s4/1021c_git_state_cleanup.md`, FHLBibleTW `ai-log/2026/s4/1021d_git_state_cleanup.md`
- Commit: see `git log` (this log is part of the last commit of the cleanup)

## Goal / why
Before starting real FHLBible development, bring all three repos to a clean stopping point: nothing important only on one machine, no large pile of unrelated uncommitted changes.

## Starting state
- Branch `複製存成圖片` was 20 commits ahead of `origin/main` and was never pushed (the remote branch `origin/閱讀_長按_複製` equals `main`). These commits include the 2024-02/03 refactors that moved shared code into FHLCommon and the 2026-03/04 work (4.7.1 to 4.9.1, parsing fixes, Bible table-of-contents).
- Uncommitted: version bump 4.9 → 4.11 (`VCIndex.swift` label 4.11.1 / 2026.04.13a), deployment target 15.0, untracked shared scheme and Xcode Cloud manifest, an untracked doc, CLAUDE.md edits.
- No `.gitignore`; six `xcuserdata` files tracked; 8 old stashes from 2023.

## What changed (git level)
1. Pushed the local branch to GitHub as `origin/複製存成圖片` (backup; `main` untouched).
2. Created 6 local commits on top (NOT pushed): project settings (15.0, MARKETING_VERSION 4.11), version label 4.11.1, shared scheme + Xcode Cloud manifest, doc `260927a_離線parsing資料庫_bible_parsing.md`, `.gitignore` (+ untrack `xcuserdata`), CLAUDE.md + ai-log.
3. `.gitignore` ignores `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, `build/`, `DerivedData/`, `.claude/`.

## Design and decisions
- Pushing the backup branch was done first and with the maintainer's approval; no force push, `main` not changed.
- Merging the branch into `main` and releasing is the maintainer's decision (the branch is 26 commits ahead of `main`).
- The old `FHLBible` copies of shared files still exist next to FHLCommon's (see baseline log).

## Key files / types / functions
`.gitignore`, `FHLBible.xcodeproj/project.pbxproj`, `FHLBible/VCIndex.swift`, `FHLBible.xcodeproj/xcshareddata/`.

## Contracts and algorithms
n/a

## Gotchas
- The 8 stashes (2023) were left untouched.
- FHLBible depends on FHLCommon code that is now committed locally in FHLCommon but not yet pushed. Push FHLCommon before relying on a fresh clone of FHLBible.
- Commit messages follow the existing style: Traditional Chinese, short, with prefixes.

## Verification
Checked `git status`, `git log`, `git rev-list --count` for each repo. No build by AI.

## Open issues / next steps
- Push the 6 new commits (and FHLCommon / FHLBibleTW commits) when the maintainer approves.
- Decide whether to merge `複製存成圖片` into `main`.
- Decide what to do with the 8 old stashes.
