---
name: pss-current-status
description: PSS release state, next dev number and open issues as of the parity project start (updated 2026-10-05 16:40Z)
metadata:
  type: project
---
#79 merged 16:33Z and #80 (3.3.0-dev002, one counting system, branch claude/one-counting-system) merged 16:45Z on 2026-10-05; 3.2.0 was the last FULL release. PR #81 MERGED 16:52Z = 3.3.0-dev003 (native Managed Communities row, branch claude/native-managed-row, zip pss-builds/PourSocialScore-3.3.0-dev003.zip). Merged PR #79 (branch claude/eui-logic-to-libraries, 3.3.0-dev001): #77 option b, shared Events logic in PourSocialScore_Libraries/PSS_EventsQuery.lua, plus eui_compare.sh and the split-check fix; zip scratch pss-builds/PourSocialScore-3.3.0-dev001.zip. Test builds 3.2.0-dev008..dev012 on scratch PourSocialScore/test-builds/.

PR #82 MERGED 20:45Z = 3.3.0-dev004 (branch claude/native-period-pie): native totals pane + period pie (PourSocialScore_GUI/PSS_Pie.lua), window 1290 wide on the recommended side-pane layout (layout card asked 19:30Z, unanswered at PR time); zip scratch PourSocialScore/test-builds/. Test builds now go in PourSocialScore/test-builds/ (dev001-003 copied there). Next dev number: 3.3.0-dev005 (plan step 6: type pie + type ticks) (dev001 = PR #79; dev002 = PR #80 merged, zip pss-builds/PourSocialScore-3.3.0-dev002.zip) (Dan chose the 3.3.0 line for parity work, 2026-10-05). Numbers are three digits, never reused; non-suffixed = production only when Dan says.

Open issues: #78 the parity project itself (analysis + 10-step plan at scratch pss-projects/pss-native-gui-port/, 3.3.0-dev001 first, decisions 1-6 all answered (see [[pss-parity-decisions]])); #77 G10 vs moving logic out of the EUI folder: DECIDED option b 16:09Z (move to Libraries, EUI calls it), notes at scratch pss-issues/eui-read-only-vs-logic-move.md; #37 guild exclusion list intent, #38 shipped-member sighting loads lists, #39 unload GUI on close, #40 research LoD unload, #44 console output, #45 Questie-style upgrade output.

Open items for Dan (from handover): archive the retired EUI repo + close its PR #18; delete merged claude/* branches. 3.x save received 15:36Z (see [[pss-baseline-saves]]). (G2 cut-off rule confirmed 15:30Z, see [[pss-binding-rules]].)

GraphQL is blocked: use gh api REST for PRs. Avoid stacked PRs (they merged into stale branches in 3.2.0).

Handover packs v3 (2026-10-05 evening): scratch handover-packs/ (latest/ + versions/2026-10-05-v3/, README for Dan); bump to v4 there next time.

**Why:** a new thread needs the live state. **How to apply:** re-check live PR state before acting. See [[pss-project-overview]].
