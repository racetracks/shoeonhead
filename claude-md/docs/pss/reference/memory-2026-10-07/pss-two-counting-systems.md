---
name: pss-two-counting-systems
description: Native GUI and the EllesmereUI window count session/24h blocks with two different systems that cannot agree; retiring PSS_BlockStats is proposed
metadata:
  type: project
---
Found 2026-10-05 while comparing the two front ends on 3.2.0 (main 0d47591):
- Native reads M.PSS_Stats (PourSocialScore/PSS_BlockStats.lua, ~12 KB compiled, ALWAYS-LOADED core): whole-hour buckets saved as blockStats, one bucket per hour per source (player/guild/filter), not per owner.
- The EllesmereUI window reads History.RecentCounts / RecentTotals / RecentByCat: 144 ten-minute slots saved as recent, per owner.
They disagree by design (native "last 24 hours" spans up to 25 hours; blockStats is per source, recent is per owner). In Dan's 3.2.0-dev011 save blockStats.player is empty (0) while guild=71 and filter=492, so the native Player tab shows 0 over a list with counted blocks.

Proposal (decision 1 of the parity analysis): native reads History.Recent* too, PSS_BlockStats leaves core (~12 KB back, helps rule G2), upgrade step prunes blockStats. It is a SavedVariables change, so it needs Dan's OK and a validated migration. Plan steps 1 and 2 (harness number-matching check first, then the switch).

**Why:** Dan's standing rule is that every number both windows show must be equal. **How to apply:** do not port pies or the Events tab before this is settled. See [[pss-current-status]], [[pss-porting-rules]].

DONE in 3.3.0-dev002 (branch claude/one-counting-system, 2026-10-05): PSS_BlockStats.lua removed from core (-12.1 KB), native reads M.PSS_RecentListStats (Libraries/PSS_TotalsQuery.lua), login upgrade sets db.blockStats = nil, tools/harness/check_match.lua gates equal numbers on every real save. Also found: EUI filter list all-time summed counts.total (290 short of filterCount on Dan's saves); PSS_ListTotals now uses filterCount with the gap as unknown.
