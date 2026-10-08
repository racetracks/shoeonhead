---
name: pss-parity-decisions
description: Dan's answers (2026-10-05 16:32Z) to native GUI parity decisions 1-5: retire BlockStats, breadcrumb, Events tab, port the 3-page pane, front ends independent
metadata:
  type: project
---
Native GUI port (issue #78, plan at scratch pss-projects/pss-native-gui-port/), Dan 2026-10-05 16:32Z:
1. Yes: retire PSS_BlockStats; native reads History.Recent*; the blockStats prune (SavedVariables change) is APPROVED. Validate on all three real saves.
2. Yes: native copies the breadcrumb and back / forward navigation (Claude had recommended no; Dan chose yes).
3. Yes: native gets an Events tab.
4. Port it: the three-page detail pane (Summary / Event History / View-Edit Rule) goes into the native window, not pies on the pop-ups.
5. The native GUI must never read files from or depend on PourSocialScore_EllesmereUI. The front ends are independent so a user never loads both; shared needs go in PourSocialScore_Libraries as shared functions. Native-only features stay native-only for now.

**Why:** Dan wants full parity with each front end standing alone. **How to apply:** steps start at 3.3.0-dev002 once PR #79 merges (no stacked PRs). G9 copies of our EUI code into PourSocialScore_GUI stay allowed (a copy is not a dependency). See [[pss-porting-rules]], [[pss-two-counting-systems]], [[pss-current-status]].
