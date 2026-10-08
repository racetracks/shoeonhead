# Project plan: the native GUI reaches parity with the EllesmereUI front end

Written 2026-10-05 against main `0d47591` (v3.2.0). Read 01_ANALYSIS.md
first. Nothing here is started.

## How a step works

Every step is one PR based on the latest `origin/main`, never stacked, and
carries:

- the next dev number, starting at **3.3.0-dev001**, never reused;
- all 21 TOCs bumped and a `history.txt` section;
- `sh tools/check_rules.sh` and `sh tools/harness/check_eui_all.sh` green;
- `validate_all.sh` against both real saves (2.0.44 and 3.2.0-dev011);
- `ui_compare.sh` saying "UI identical" on any step that should not change a
  window;
- a measured size for anything added or moved, as rules F and G2 require;
- an install zip on scratch in `PourSocialScore/test-builds/`, with the link;
- a short list of exactly what to check in game.

Dan tests in game and merges. The EllesmereUI folder is edited in one step
only (step 3), and only to swap its logic for Libraries calls with nothing
visible changing (issue #77, option b). Every other step leaves it alone.

## The order, and why

> **Decisions answered 2026-10-05 16:32Z** (see 01_ANALYSIS.md section 6). Changes to the table below: step 2 is approved; step 7 becomes the three-page detail pane ported into the native window (not pies on the pop-ups); the breadcrumb and back / forward navigation is a new step, after the Events tab; the native window never loads or reads PourSocialScore_EllesmereUI, and code both windows need goes in PourSocialScore_Libraries.

> **Update 2026-10-05:** step 3 (the logic move, issue #77 option b) went first, as **3.3.0-dev001** ([PR #79](https://github.com/racetracks/PourSocialScore/pull/79)). It also carries step 1's split-check fix and a new `tools/harness/eui_compare.sh` that proves the EllesmereUI window looks the same, step by step. The dev numbers in the table below shift: the next step takes 3.3.0-dev002, and step 1 is now only the number-matching check.

Steps 1 and 2 make the numbers trustworthy before anything new is drawn:
there is no point porting pies on top of two counting systems that disagree.
Step 3 builds the shared query code. Steps 4 to 8 each add one visible
feature, smallest first, so each one can be checked in game on its own.
Steps 9 and 10 close up.

| Step | Dev | What it does | How you validate it |
| --- | --- | --- | --- |
| 1 | 3.3.0-dev001 | **Harness first.** Fix the "split" check so it only runs on 2.0-layout saves (issue F), and add a number-matching check: for every owner in your real saves, the native and EllesmereUI readings of this session, the last 24 hours, all time and the per-type counts must be equal. No addon code changes. | The harness goes green on both saves, including the 3.2.0-dev011 set. `ui_compare.sh` says "UI identical". Nothing to check in game. |
| 2 | 3.3.0-dev002 | **One counting system** (decision 1). The native window reads `History.RecentCounts` / `RecentTotals` instead of `M.PSS_Stats`; `PSS_BlockStats.lua` leaves the always-loaded core; an upgrade step prunes the old `blockStats` table. | The session and 24 hour lines above the Player, Guild and Chat Filters tabs show the same numbers as the EllesmereUI window. Your save's Player tab stops reading 0. The step reports the core size it gave back (about 12 KB) and the harness check from step 1 enforces the match. **Needs your OK first: it changes saved data.** |
| 3 | 3.3.0-dev003 | **Move the logic into Libraries** (issue #77, option b). A new `PourSocialScore_Libraries/PSS_EventsQuery.lua` takes the expired and not-stored rows, the event query filter (period, custom range, types, search), the managed-list totals, the type sums, the "Stored:" text and the block-type naming out of the EllesmereUI folder, and the EllesmereUI files call it. The list-wide collect and reset that both windows already duplicate move too. No window changes. | `ui_compare.sh` says "UI identical" and `check_eui_all.sh` passes. The step reports the measured size moved (about 19 KB, load on demand) and what each folder lost and gained. The EllesmereUI window shows exactly what it showed before. |
| 4 | 3.3.0-dev004 | **Managed Communities row.** The native guild list asks `M.PSS_GuildRows` for the nested shape, so the default guild lists sit under one parent row that adds them up, with expand, collapse and the rule toggle in its right-click menu. | The Guild Ignore List shows the parent row with the list count, expands and collapses, and its numbers equal the EllesmereUI window's. |
| 5 | 3.3.0-dev005 | **The pie widget**, copied into `PourSocialScore_GUI` (rule G9) and drawn with `CreateLine` and UIKit text and ticks: the period pie with a tick box and count per period, on the Player, Guild and Chat Filters tabs when nothing is selected, together with the whole-list totals pane. | The pie appears, hover dims the other slices and shows the count, the tick boxes add and remove periods, and the totals equal the EllesmereUI window's. Works in the default Blizzard look with no other addon loaded. |
| 6 | 3.3.0-dev006 | **Type pie and type ticks**: the all-time pie by block type with a tick per type, and the ticks filter the period pies as they do in the EllesmereUI window. | Unticking a type lowers both pies and leaves its count in the legend, matching the EllesmereUI window. |
| 7 | 3.3.0-dev007 | **The pies on the detail windows** (decision 4): the player detail window, the guild member window and the guild pane get the same period and type pies and the "Stored:" line. | Each window shows the pies and the "Stored:" line, with numbers equal to the EllesmereUI detail pane for the same player, member and guild. |
| 8 | 3.3.0-dev008 to dev010 | **The Events tab** (decision 3), the largest piece, split across three PRs: (a) the tab, the list and the Source drop-down over the existing per-list histories; (b) the Time drop-down with the custom date range, and the Types drop-down; (c) the expired and not-stored rows, the search box, column sorting, and opening the tab from a pie slice or a View Events button. | After each PR the tab shows the same lines, counts and row order as the EllesmereUI Events tab for the same filters. The existing per-list Block History panels keep working. |
| 9 | 3.3.0-dev011 | **Small matches**: the type tick boxes over each pane's history, the Options tab search box, click-again and empty-space deselect, and a tab click resetting its tab (decision 2 keeps the breadcrumb out). | Each behaves as in the EllesmereUI window. |
| 10 | 3.3.0 | **Release.** A rules check that fails if a UI folder gains query or counting logic, the readme and history updated, the parity table in the handover marked done, and the version set to plain `3.3.0`. | The release zip installs, both windows show the same numbers everywhere, and the Rules CI including the new check is green. |

Ten numbered steps, twelve PRs, each shippable and checkable on its own.
If a step turns out bigger than it looks when I start it, I will split it and
tell you before building, rather than growing one PR.

## What is deliberately not in this plan

- No EllesmereUI change beyond step 3's logic move (rule G10, with the one
  exception Dan allowed in issue #77).
- The breadcrumb and back / forward navigation (decision 2).
- Rebuilding the native pop-ups as an in-window detail pane (decision 4).
- The four native-only features (analysis section 3): Player Search, Prune,
  the right-click menus and the resizable columns stay native-only for now
  (decision 5). They are the other half of parity and want their own small
  project after this one.

## Risks

- **Step 2 touches saved data.** It is the only step that does. The migration
  is validated against both real saves and the login tidy-up before the PR
  exists; the old table is pruned, not left behind to grow.
- **Step 8 is big.** Hence three PRs. If the Events tab needs a fourth, it
  gets one.
- **The native window grows by roughly 100 to 130 KB compiled** (analysis
  issue E), all load on demand, all outside the always-loaded core, and step
  2 gives about 12 KB of core back. Each step reports its own measured cost,
  so you can stop if a feature is not worth its size.
- **Step 3 edits the EllesmereUI folder**, the one exception to rule G10.
  It is limited to swapping function bodies for Libraries calls, and it does
  not go up until `ui_compare.sh` says "UI identical".

## Before step 1

Decision 6 (issue #77) is settled: option b. Decisions 1 to 5 in
01_ANALYSIS.md section 6 are still open. Decisions 1 to 4 change what gets
built; 5 changes the order. Step 1 is pure harness work and can start now.
