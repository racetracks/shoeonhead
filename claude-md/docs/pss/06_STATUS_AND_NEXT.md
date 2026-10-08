# Status and next step (2026-10-08)

Kept short and current: every PR updates it (baseline 02 E10). History up to 3.4.1.30 is in `reference/06_status-history-to-3.4.1.30.md`. The addon as it works is in `01_HANDOVER.md`; the current plan is `10_CORE_UPLIFT.md`.

## Now
- **Live release: 3.4.0.29** (full, the new PSS window; mirrored to `racetracks/Pour-Social-Score`). **Main: 3.4.1.30** (PR #118, the mirror carries the release's files).
- **Current project: core uplift** (`10_CORE_UPLIFT.md`, locked by Dan on 2026-10-08, all 12 decisions as recommended, with his forward-compatibility addition to decision 10). It runs on three lines: 3.4.1 fixes and data, 3.4.2 core performance, 3.4.3 window tidy.
- **On its PR: 3.4.1.31 "Plan"** (PR #119; docs and working rules only).
  - The core uplift plan.
  - One stage per session, with context updated in every PR (baseline v9, 02 E9 to E11).
  - Dan's preferences in one file (`11_PREFERENCES.md`).
  - `CLAUDE.md` loads less.
  - This file trimmed.
- **Next:**
  1. Dan runs the six `/dump` lines (10 section 2.1) on Camelot and pastes the output.
  2. A fresh session builds **N1 (3.4.1.32)**, `M.PSS_NormName`.
- The closed projects: the PSS window (3.4.0, `09_PSS_UI_PROJECT.md`; its code map and lessons stay the reference for the window) and parity (3.3.1, `08`).

## Waiting on Dan
1. The `/dump` output from Camelot (core uplift decision 12), before N1.
2. Archive `racetracks/PourSocialScore-EllesmereUI` and close its PR #18.
3. Delete merged `claude/*` branches (Claude gets 403).
4. Close issue #78 (parity, closed at 3.3.1).

## Known breaches
In 02 section 12, each with its fix line. The idle GC cycle is fixed by core uplift P2 (3.4.2).

## Open issues (addon repo)
- #37: the guild exclusion list is not saved (its intent needs defining).
- #38: seeing a shipped-guild member loads the lists.
- #39: unload the GUI on close.
- #40: research whether a LoadOnDemand addon can unload.
- #44: clean up console output.
- #45: Questie-style upgrade output (core uplift U2).
- #78: parity (the project closed at 3.3.1).

## Parked
- Pack the in-play chat filter log (offered, not started).
- Dashboard / overview page (paused, branch `claude/project-thread-pa7y7o`).
