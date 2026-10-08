---
name: pss-working-preferences
description: How Dan wants PSS work run - one step per PR, zip link, numbered questions, measure perf, ask before SV changes
metadata:
  type: feedback
---
- One step at a time: one PR per repo per step, bump all TOCs + history.txt, installable zip on racetracks/scratch (link https://github.com/racetracks/scratch/raw/main/<path>), exact in-game checks. Dan tests in game and merges; Claude can't delete branches.
- Dev builds are X.Y.Z-devNNN (3 digits) and publish as GitHub pre-releases.
- Numbered questions with a recommendation; Dan answers "1: yes 2: ...". Answer first, plain short replies.
- Performance/memory first: zero cost when off, lazy UI, GC only on request. Measure (loadfile + collectgarbage count), never estimate. "The performance option" = benchmark and pick fastest/smallest with numbers.
- SavedVariables must not grow; layout changes need a validated migration and Dan's OK first.
- The EllesmereUI window is an alternative front end: every number it shows must match the PSS window (same definitions, e.g. "this session" = since login or /reload). Never let them diverge.
- Copy logic, never code/IDs, from DBM/ElvUI/EllesmereUI. Never change TOC Title/Notes unless asked.
- Before push: sh tools/check_rules.sh; validate_all.sh with PSS_REAL_SAVES=/mnt/project-files/baselines; ui_compare.sh for UI-neutral changes.

**Why:** stated across 2.0-3.2 threads (handover 01 section 8, 02_RULES). **How to apply:** every PSS step. See [[pss-project-overview]].
