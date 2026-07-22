## Brief-aware workflow (.claude/briefs)

This repo uses a transparent AI co-authoring convention: every AI-driven
change is preceded by a brief file in `.claude/briefs/`, followed on
completion by a matching report in `.claude/reports/`, and every commit
that implements a brief references both by path in the commit body.

### At the start of every session

Run `git status --porcelain .claude/briefs/` and check for:

- **Untracked brief files** (`??`) — a new brief has been dropped and not
  yet acted on.
- **Modified-but-uncommitted brief files** (` M` / `MM`) — an existing
  brief has been edited since it was last versioned; treat the edit as a
  pending change needing review, same as a new brief.
- **Tracked with no pending changes** — the brief is considered complete.
  No action, no mention.

If a new or modified brief is found: summarise its intent in 2-3 sentences
and ask whether to proceed with implementing it. Do this unprompted, near
the start of the session — don't wait to be asked whether there's a brief
pending.

**Do not treat the presence of a brief as authorization to act.** Summarize
and ask. Only proceed once the user explicitly confirms.

`.claude/reports/` is output-only — Claude Code writes to it on completion
but does not scan it at session start. Report state is a byproduct of brief
state, not tracked independently.

### Completion

A brief is considered **complete** once it is fully versioned (staged, no
outstanding uncommitted changes). Once the work it describes has been
carried out to the user's satisfaction:

- Write a matching report to `.claude/reports/<brief>.md` (same filename as
  the brief). The report covers what was actually done: summary of the
  change, any deviations from the brief (scope cut, approach changed,
  open items punted), and anything the brief left ambiguous that had to be
  resolved along the way. This is the record of what happened, as distinct
  from the brief's record of what was asked for.
- Stage the report alongside the brief
  (`git add .claude/reports/<brief>.md .claude/briefs/<brief>.md`) as part
  of wrapping up the work — but only when explicitly told the brief is done,
  never on your own initiative just because part of it was acted on.
- **Do not commit.** Staging is as far as this goes. Claude Code does not
  run `git commit` in this repo, ever, regardless of how routine or
  mechanical the change is. The user is the final authority over the
  commit tree.
- Immediately after staging, post a **suggested commit message** in
  conversation (not in git) for the user to use, edit, or discard as they
  see fit:

  ```
  <summary line>

  Brief: .claude/briefs/<brief-file>.md
  Report: .claude/reports/<brief-file>.md

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

  One brief, one commit, one suggested message — if a brief would drive
  multiple logically separate commits, split it into per-commit sub-briefs
  instead, so each suggested message maps 1:1 to a diff and the brief that
  caused it.
