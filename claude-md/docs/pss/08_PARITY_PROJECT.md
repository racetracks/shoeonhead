# Closed project: native GUI parity with the EllesmereUI window (3.3.0, issue #78)

**Closed 2026-10-07 by Dan at 3.3.1:** "we're just going to merge whatever its at now and call that done, ive got other plans, scrap those features and just stamp this at 3.3.1". Stages 1 to 5 shipped in 3.3.1; the rest are dropped, not parked.

This is the feature that owns the 3.3.0 line. It follows baseline 10 (design, stages, one PR per stage, validation between PRs). The original analysis and plan are in `reference/plans-3.3-parity/` (on the old `racetracks/scratch` `pss-projects/pss-native-gui-port/`); the plan's step table predates the decisions, so use the table below.

## Objective
The native window (`PourSocialScore_GUI`) and the EllesmereUI window (`PourSocialScore_EllesmereUI`) offer the same features and show the same numbers, each in its own look, with the folders independent (02 sections 6 and 7). Parity is not shared UI code.

## Decisions (Dan, 2026-10-05 16:32Z)
1. **Yes:** retire `PSS_BlockStats`; native reads `History.Recent*`; the `blockStats` prune is approved. Done in dev002.
2. **Yes:** native gets the breadcrumb and back / forward navigation (Claude had recommended no).
3. **Yes:** native gets an Events tab.
4. **Port it:** the three-page detail pane (Summary / Event History / View-Edit Rule) goes into the native window, not pies on the pop-ups.
5. The front ends are independent; shared needs become shared functions in Libraries. Native-only features stay native-only for now.
Also: issue #77 decided option b (logic leaves the EUI folder for Libraries), done in dev001. dev004's layout card (side pane, 1290 wide) was never answered; built on the recommendation.

## Stage table
| Stage | Dev | What | Validation | State |
| --- | --- | --- | --- | --- |
| 1 | dev001 | Events logic to `PSS_EventsQuery.lua`; eui_compare; split check fix | eui_compare identical; harness green | Merged #79 |
| 2 | dev002 | One counting system; BlockStats retired; check_match | Migration on 3 real saves; numbers match | Merged #80 |
| 3 | dev003 | Managed Communities row | check_managed_row; numbers match | Merged #81 |
| 4 | dev004 | Totals pane + period pie (`PSS_Pie.lua`) | check_match on the pane; in game | Merged #82 (release not published) |
| 5 | dev005 | Bugfix: window opens next to Retail 12.1's Social window (`SocialUIFrame`) as well as FriendsFrame | Harness opens Social and the Who switch; ui_compare / eui_compare identical; real saves | Merged #85 |
| 6 | dev006 | Type pie and type ticks; ticks filter the period pie | Numbers match per type; in game | Dropped |
| 7 | dev007 | Three-page detail pane in the native side pane (decision 4) | Same numbers as the EUI detail pane; in game | Dropped |
| 8 to 10 | dev008 to dev010 | Events tab in three PRs: (a) tab, list, Source; (b) Time with custom range, Types; (c) expired / not-stored rows, search, sorting, opening from a slice or View Events | Same lines, counts and order as the EUI Events tab after each PR | Dropped |
| 11 | dev011 | Breadcrumb and back / forward (decision 2) | Behaves as in EUI | Dropped |
| 12 | dev012 | Small matches: type ticks over history, Options search, click-again deselect, a tab click resetting its tab | Behaves as in EUI | Dropped |
| 13 | dev013 | A rules check that fails if a UI folder gains query or counting logic; readme | Rules CI green | Dropped |
| Release | **3.3.1** | Version only; history section for dev001 to dev005 | Dan stamped it done, 2026-10-07 | Released on merge |

Every stage: one PR from main, all TOCs bumped, history section, test zip on scratch, check_rules, check_eui_all, validate_all on the three real saves, ui_compare or eui_compare as relevant, measured size of anything added.

## Not in this project
- Native-only features (Player Search, Prune, right-click menus, resizable columns) in the EUI window: a later project.
- Any EUI folder change beyond dev001's logic move (G10).
- The rule deviations in 01 section 5, unless Dan says to fold them in.

## Native resources to use (G7, G8)
Pies drawn with `CreateLine` and UIKit text and tick boxes (as dev004); Blizzard templates (UICheckButtonTemplate, InputBoxTemplate, WowStyle1DropdownTemplate, UIPanelButtonTemplate, ScrollFrameTemplate); nothing from EllesmereUI's media or API. Say per stage whether it is a G9 copy (with its measured size) or a rewrite.
