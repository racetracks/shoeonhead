# EllesmereUI read-only rule vs moving logic out of the EllesmereUI folder

Date: 2026-10-05. Status: **decided 2026-10-05 16:09Z: option b.** Nothing has been built yet; the work is step 3 of `pss-projects/pss-native-gui-port/02_PLAN.md`.

## The conflict
- **Rule G10 (Dan, 2026-10-05):** the port must preserve the EllesmereUI integration. Treat `PourSocialScore_EllesmereUI` as read only. Functions that serve calls from both UIs must be optimized for performance.
- **Handover plan, step 2 (00_PRIMARY_OBJECTIVE.md):** "Move any logic you find in a UI folder into Libraries (or core) first, as its own step." Doing that means editing EllesmereUI files.
- **Rule G1:** no application or service logic in a UI folder.

So G10 and step 2 cannot both hold. Logic already in the EllesmereUI folder breaks G1, but G10 forbids removing it.

## What the EllesmereUI folder holds today (3.2.0, main 0d47591)
Most of what the EllesmereUI folder does is draw, and call core or Libraries readers (`History.RecentCounts`, `History.RecentSlots`, `History.RecentByCat`, `History.Where`, `M.PSS_GetGuildBlockCounts` and others). A few pieces are real logic that the native window will need too:

| Logic | Where | What it does |
| --- | --- | --- |
| Expired / not-stored rows | `EUI_HistoryView.lua:90` `AddExpired` (exported as `ns.HistoryAddExpired`) | Compares counted blocks per type and 10-minute slot with stored lines, and adds "Data expired from logs" and "Not stored" rows |
| Event query filter | `EUI_HistoryView.lua:166` `Range`, `:172` `Matches` | Applies the time period, custom range, types and search text to event lines |
| Managed list totals | `EUI_Guilds.lua:894` `GroupRecent` | Adds up session and 24 h counts over every guild in a managed list |
| Type-tick sums | `EUI_Detail.lua:164` `SumOn` | Sums counts over the ticked types for the pies |

Each one is small (about 10 to 45 lines). This list comes from reading the code. The full feature comparison is still to come and may find more.

## Options
**a. Leave the EllesmereUI files untouched (recommended).** For each piece above, write a performance-tuned version in `PourSocialScore_Libraries`, and have the native window call it. The EllesmereUI folder keeps its own copy as it is. A harness check runs both versions on Dan's real saves (2.0.44 and 3.2.0) and fails if any number differs.

**b. Allow one kind of edit.** Swap each piece in the EllesmereUI folder for a call to the same Libraries function. Each swap ships as its own step and must pass `ui_compare.sh` and `check_eui_all.sh` with the window left identical.

**c. Do a now and b later.** Finish parity under option a. Then, as a separate step that Dan approves on its own, remove the copies from the EllesmereUI folder.

## Recommendation: option a, keeping c open
- **It follows G10 as written.** The EllesmereUI integration is the most recently tested front end (3.2.0), and none of its code is touched.
- **The copy costs little memory in practice.** `M.PSS_OpenUI` opens the EllesmereUI window when the integration is on, and the native window otherwise (`/pss gui force` is the only way to open both). So normally only one copy is loaded. Both copies are load on demand, so neither adds to always-loaded core. I'll measure resident cost for each Libraries function when it is built, as F and G2 require.
- **The numbers can't drift unnoticed.** The harness check compares the two versions on real saves, which turns Dan's rule that "every number must match" into a test.
- **The cost is the same logic in two places.** A fix to one copy has to be made in the other too. The harness check catches any fix that is made in only one place. Option c removes the copies once parity is done, if Dan wants that.
- **It is the faster path for the parity work itself.** No EllesmereUI regression testing is needed for each step.

## What Dan needs to decide
1. Which option: a, b or c? (Recommended: a, with c as an optional step after parity.)
2. Should the harness check that compares the two versions be part of the first 3.3.0 step? (Recommended: yes)

## Decision (Dan, 2026-10-05 16:09Z): option b

Each piece of logic above moves to `PourSocialScore_Libraries` once, and the
EllesmereUI file calls it instead of keeping its own copy. This is the one
kind of edit allowed in the EllesmereUI folder under rule G10: a function body
swapped for a Libraries call, with nothing visible changing. Each such step
must pass `ui_compare.sh` ("UI identical") and `check_eui_all.sh` before the
PR goes up.

Why, over option a: one copy means the two windows cannot drift and a fix
lands in both at once, and rule G1 (no logic in a UI folder) holds. Memory is
about the same either way, since normally only one window is loaded.
