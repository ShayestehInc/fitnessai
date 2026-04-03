# Autonomous Development Pipeline

When told to **"run the pipeline"**, **"run autonomously"**, or **"run the full pipeline"**, execute this process.

## Pipeline Flow

```
Dev → [Review ↔ Fix ×1] → Ship
```

For thorough mode (say "run thorough pipeline"):

```
Dev → [Review ↔ Fix ×2] → [Security Audit] → [Polish Pass] → Ship
```

## Setup

1. If `tasks/focus.md` exists, read it — it sets the priority
2. If no focus exists and the user provided one, create `tasks/focus.md`
3. Read `PRODUCT_SPEC.md` to understand the product
4. Create a git feature branch: `feature/YYYY-MM-DD-HHMMSS`

## Git Checkpoints

After every stage that produces code changes:

```
git add -A && git diff --cached --quiet || git commit -m "<message>"
```

---

## Stage 1 — DEVELOP

1. Read `tasks/focus.md` if it exists. Read `PRODUCT_SPEC.md`.
2. Read the existing codebase to understand patterns and conventions.
3. Implement the feature completely — full production-ready code, not a skeleton.
4. Handle edge cases: empty states, error states, loading states, permission failures.
5. Write tests as part of implementation.
6. Run linting and existing test suite.
7. Write a summary to `tasks/dev-done.md`: files changed, key decisions, how to test.

**Checkpoint:** `wip: raw implementation`

---

## Stage 2 — REVIEW ↔ FIX

Spawn the **code-reviewer** subagent (`.claude/agents/code-reviewer.md`) to review the git diff.

- If APPROVE (score >= 7): proceed to ship (or next stage in thorough mode)
- If REQUEST CHANGES or BLOCK (score < 7): fix all critical and major issues, checkpoint, re-review
- Max rounds: 1 (standard) or 2 (thorough)

**Checkpoint:** `wip: review fixes round N`

---

## Stage 3 — SECURITY AUDIT (thorough mode only)

Spawn the **security-reviewer** subagent (`.claude/agents/security-reviewer.md`) on the git diff.

- If PASS: proceed
- If FAIL: fix all Critical/High issues, checkpoint

**Checkpoint:** `wip: security fixes`

---

## Stage 4 — POLISH PASS (thorough mode only)

Spawn the **polish-reviewer** subagent (`.claude/agents/polish-reviewer.md`) on UI changes.

- Finds and fixes dead UI, missing states, visual bugs
- Documents what it couldn't fix

**Checkpoint:** `wip: polish fixes`

---

## Ship

1. Run the complete test suite. All tests must pass.
2. Review the full git diff one final time.
3. If everything looks good:
   - `git commit -m "feat: YYYY-MM-DD — <what was built>"`
   - Update `PRODUCT_SPEC.md`: mark feature as done, move to "Completed Work"
   - Write `CHANGELOG.md` entry
   - `git commit -m "docs: update spec and changelog"`
   - Merge to main: `git checkout main && git merge <branch> --no-ff -m "feat: ship YYYY-MM-DD — <title>"`
4. If tests fail or critical issues remain:
   - `git commit -m "wip: blocked — needs attention"`
   - Note what needs resolution

---

## Execution Rules

1. **All stages run without stopping.** No user input between stages.
2. **Each stage reads prior stage artifacts.**
3. **If a stage fails** (e.g., no DB for tests), note it and continue.
4. **Quick mode** (say "quick" or "fast"): Dev → ship. No review loop.
5. **Thorough mode** (say "thorough"): Dev → Review×2 → Security → Polish → Ship.
6. **Resume:** If told "resume from <stage>", skip earlier stages.
7. **Focus override:** User-specified focus creates `tasks/focus.md`.

## Context Management

Use subagents to keep verbose operations out of the main conversation:

- **code-reviewer** agent for review (read-only, returns summary)
- **security-reviewer** agent for security audit (read-only, returns summary)
- **polish-reviewer** agent for UX/visual fixes (has edit access)
- Spawn exploration agents for reading 3+ files

Stay in main context for: direct edits, short reads, back-and-forth decisions.
