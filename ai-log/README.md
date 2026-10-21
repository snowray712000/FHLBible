# ai-log — Rules (read this before writing or reading logs)

`ai-log/` is a development journal **written by AI, for future AI**. It is not for humans (a human who wants Chinese will ask an AI to translate). Each project (FHLBible, FHLBibleTW, FHLCommon) has its **own, separate** `ai-log/` inside its own git repo.

## Purpose

1. A future AI can recover the **situation and reasoning** of past development: why something exists, what was tried, what was decided.
2. Strong goal: **even if the source code were lost, the logs should be enough to roughly reproduce the program**, possibly in another language or on another platform. So logs must capture behavior, data formats, API contracts, algorithms, and constraints, not just "files changed".

## Language

English. Keep identifiers, file names, API names, and UI strings in their original form (UI strings in Traditional Chinese stay Chinese, quoted).

## Location and naming

```
<project>/ai-log/
  README.md          this file
  index.md           lookup table (see below), always kept up to date
  <YYYY>/s<Q>/<MMDD><seq>_<title>.md
```

- `<Q>` is the calendar quarter of the date: `s1` = Jan–Mar, `s2` = Apr–Jun, `s3` = Jul–Sep, `s4` = Oct–Dec.
- `<MMDD>` is the local date the work was done. Take it from the system's current date, never guess.
- `<seq>` is a lowercase letter sequence per day, in creation order: `a, b, c, … z, aa, ab, … az, ba, …` (the 27th log of a day is `aa`). To pick the next one, list the quarter folder for that day and continue from the last one. Order is by length, then alphabetically (so `z` < `aa`).
- `<title>`: lowercase English `snake_case`, about 2–6 words, describing the topic. No spaces, no Chinese.
- Example: today 2026-10-21 → `ai-log/2026/s4/1021a_add_tw_reading_swipe.md`; second one the same day → `1021b_<title>.md`.
- Create the year / quarter folders if missing.

## When to write a log

Write **one log per meaningful unit of work** at the end of the task (not one per tool call):
- a feature, a behavior change, a bug fix with a non-obvious cause, a refactor or file move, a data/API format discovery, a build/config/release change, an important decision or a rejected approach, an investigation that ended without code changes (so nobody repeats it).
- Skip: pure typo / formatting changes, and trivial edits whose diff explains itself.

Also update `index.md` in the same task. Include both in the same commit as the code change when the user asks for a commit. Never put secrets (tokens, keys, passwords) in a log.

## When to read logs

At the start of any non-trivial task in a project: read `ai-log/index.md` first, then open only the logs relevant to the area you are about to touch. Logs record the context at that time; if code now disagrees, trust the code but find out why (a later log may explain).

## Append-only

Do not rewrite history. Old logs are not edited except to fix typos, add a `Superseded by:` line at the top, or append a dated `## Addendum` section at the end with later facts (for example verification results). If a past decision is reversed, write a new log with `Supersedes: <path>` and explain why.

## Log template

```markdown
# <Human-readable title>

- Date: YYYY-MM-DD
- Project: FHLBible | FHLBibleTW | FHLCommon
- Type: feature | fix | refactor | investigation | config | baseline
- Related logs: <paths in this project, or "none">
- Cross-project: <other project's log path, if the work spanned projects, else "none">
- Commit: <short hash if known, or "uncommitted">
- Supersedes / Superseded by: <path or omit>

## Goal / why
What was asked and the motivation, in 2–5 sentences.

## Starting state
Relevant behavior/code before the change. Enough to understand the diff.

## What changed (behavior level)
What the program now does, described so that it could be re-implemented. Not a diff.

## Design and decisions
Chosen approach and why; alternatives rejected and why; constraints (e.g. iOS 14 minimum).

## Key files / types / functions
Paths relative to the project root, with one line each on responsibility.

## Contracts and algorithms
Whatever is needed to reproduce: API endpoints + parameters + sample response shape, DB schema / SQL, data formats, parsing rules / regexes, state machines, step-by-step algorithm, threading model, UserDefaults keys, default values.

## Gotchas
Non-obvious pitfalls, platform quirks, things that looked right but were wrong.

## Verification
What was actually built / run / tested, and what was NOT verified.

## Open issues / next steps
Anything left undone or worth doing later.
```

Sections with nothing to say may be shortened to one line or `n/a`, but keep the headings so logs stay scannable.

## index.md format

- Short header: what the project is (2–3 lines) and a pointer to this README.
- Then one section per quarter, **newest quarter first, newest entry first**, as a table:

  `| Log | Type | Summary | Areas / keywords | Files touched |`

  - `Log`: relative link, e.g. `[1021a_add_tw_reading_swipe](2026/s4/1021a_add_tw_reading_swipe.md)`
  - `Summary`: one sentence, enough to decide whether to open the log.
  - `Areas / keywords`: terms an AI would grep for (feature names, type names, API names).
- A final "Legacy docs (pre ai-log)" section may point to older hand-written notes outside `ai-log/`.
- Keep rows to one line each. The index is a map, not a duplicate of the logs.

## Cross-project work

FHLBible and FHLBibleTW depend on FHLCommon. If a task changes more than one project, write **one log in each project** describing that project's part, and fill `Cross-project:` in each so they point at each other.
