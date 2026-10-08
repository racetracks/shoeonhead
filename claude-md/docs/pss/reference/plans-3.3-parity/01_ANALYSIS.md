# Analysis: porting the EllesmereUI front end into the native GUI

Written 2026-10-05 against main `0d47591` (v3.2.0). Read with 02_PLAN.md.
Every file and line reference was read in that commit. Sizes are compiled
Lua measured with `loadfile` plus `collectgarbage("count")`, the smallest of
five runs (loading a file into the game costs more than this; the figures
compare parts, they are not a memory budget).

## 1. What each window is today

| | Native GUI (`PourSocialScore_GUI`) | EllesmereUI front end (`PourSocialScore_EllesmereUI`) |
| --- | --- | --- |
| Compiled size | 437 KB over 9 files | 406 KB over 12 files |
| When loaded | On demand, when the window opens | On demand, and only when EllesmereUI is installed and `euiIntegration` is on |
| Shape | One tabbed window plus separate pop-up windows (player detail, guild members, block history) | One tabbed window; everything happens inside it in a detail pane |
| Tabs | Player Ignore List, Chat Filters, Options, Import/Export, plus a Guild Ignore List window | Player Ignore List, Guild Ignore List, Chat Filters, Events, Import/Export, Options |
| Look | Blizzard templates through `PSS_UIKit.lua` | EllesmereUI skin, with a plain dark fallback |

Both read the same core and the same `M.PSS_OPTIONS`, so options and lists
already agree. The differences are in what each window shows about blocks.

## 2. Gaps: in the EllesmereUI window, missing from native

| Feature | Where it is drawn | Native resource it would use | Port shape |
| --- | --- | --- | --- |
| Period pie (this session / last 24 hours / all time), tick box and count per period, slices nested so the overlap is drawn once | `EUI_Pie.lua` (10 KB), `ns.NewSummary` in `EUI_Detail.lua` | `frame:CreateLine` with `SetThickness` and `SetColorTexture`, which is plain Blizzard API and needs no texture file; `UI.Check` for the ticks | G9 copy of the pie widget, redrawn with UIKit text and checkboxes |
| All-time pie by block type, with a tick box per type that also filters every period pie | `ns.NewTypePie`, `ns.typeOff` in `EUI_Detail.lua` | Same as above; colours come from `History.CAT_COLOR` in core | Same copy |
| A whole list's totals shown when nothing is selected | `ns.NewTotals` in `EUI_Detail.lua`; counts from `M.PSS_ListTotals` (already in Libraries) | UIKit summary block | New native pane, existing Libraries call |
| Events tab: every list's blocked lines in one view, with Time, Types and Source drop-downs, a custom date range, a search over player, channel and message, and sortable columns | `EUI_HistoryView.lua` (61 KB) | `FauxScrollFrameTemplate` and `UI.CreateHeaderRow` (what the native history list already uses); `MenuUtil` or `WowStyle1DropdownTemplate` for the drop-downs | The biggest piece of work. Native has per-tab Block History panels and a pop-up, each scoped to one list |
| "Data expired from logs" and "Counted, not stored" rows: blocks counted but no longer in the log, one row per type per 10 minutes | `AddExpired`, `EUI_HistoryView.lua:90` | None needed, it is data only | Move to Libraries, both windows call it |
| The "Stored: 8 in the log, 3 kept, 1 waiting, 2 expired" line | `ns.WhereText`, `EUI_Detail.lua:215` | None needed | Move to Libraries |
| Breadcrumb trail, back and forward (also mouse buttons 4 and 5), Escape goes up one level, clicking a selected row or empty space deselects, a tab click resets that tab | `EUI_Window.lua` `nav*`, `win.crumbs`; `emptyClick` in `EUI_Rows.lua` | UIKit buttons | Behaviour, not assets. Native has no navigation model at all (see issue C) |
| A "Managed Communities" parent row that nests the default guild lists under it and adds them up | `EUI_Guilds.lua` with `rows = { nest = true }` | None needed | One flag: `M.PSS_GuildRows` in Libraries already builds it, native just never asks for it (`PSS_GuildUI.lua:283` passes a plain table) |
| A detail pane with three pages: Summary, Event History, View/Edit Rule | `ns.NewDetailPages` in `EUI_Detail.lua` | UIKit tabs and panels | Native uses separate pop-up windows instead. A judgement call, not a gap to close blindly (issue C) |
| Tick box per block type over a pane's history, shared by every history list | `ns.TypeBoxes`, `ns.histHidden` in `EUI_History.lua` | `UI.Check` | Small |
| A search box over the Options tab | `ns.BuildOptionsTab` in `EUI_Options.lua` | `UI.SearchBox` | Small |

## 3. Gaps the other way: native features the EllesmereUI window does not have

Parity cuts both ways, so these are listed for a decision rather than
assumed. Under rule G10 the EllesmereUI folder is read only, so closing
these would be later work, not part of this port.

| Feature | Where it is drawn |
| --- | --- |
| Player Search: a `/who` for a name and a tick-list of the players found. The EllesmereUI window only has an Add Player box | `PSS_UI.lua:988` with `W.Picker` |
| Add your target when the box is empty | `PSS_UI.lua` `targetName` |
| Prune: remove entries older than n days | `StaticPopupDialogs["PSS_PRUNE"]`, `PSS_UI.lua:62` |
| Right-click menus: add or remove from the ignore list from a history line, guild row actions, per-guild and per-player option overrides in a menu | `History.RowMenu` in `PSS_ChatHistoryUI.lua:32`, `guildRowMenu` in `PSS_GuildUI.lua:485`, `M.PSS_AddOverrideMenu` |
| A resizable window, resizable columns whose widths are remembered, and W I G P C tick boxes and block-count columns in the list rows themselves | `PSS_UIKit.lua` `UI.CreateHeaderRow`, `UI.CreateExclusionBoxes`, `UI.MetricColumns` |

## 4. Issues

**A. Two different counting systems feed "this session" and "last 24 hours".**
This is the most serious finding, because it breaks the standing rule that
every number in one window must equal the other.

- The native window reads `M.PSS_Stats` (`PSS_BlockStats.lua`, 12 KB in the
  always-loaded core), which counts into whole-hour buckets saved as
  `blockStats`, one bucket per hour per source.
- The EllesmereUI window reads `History.RecentCounts` and
  `History.RecentTotals`, which count into 144 ten-minute slots saved as
  `recent`, per owner.

They disagree by design. Hour buckets mean the native "last 24 hours" covers
up to 25 hours, and the two systems count different things: `blockStats` has
one bucket for all players together, while `recent` is per player, guild and
filter. In your 3.2.0-dev011 save the native player total is already wrong:
`blockStats.player` is empty (0 blocks) while `blockStats.guild` holds 71 and
`blockStats.filter` 492, so the Player Ignore List tab would show 0 for both
windows above a list that has counted blocks.

Retiring `PSS_BlockStats.lua` and having the native window read the same
`History.Recent*` functions would make the numbers equal by construction,
take about 12 KB out of the always-loaded core (which rule G2 wants kept to
chat filtering and the launchpad), and stop writing `blockStats` to saved
data. It needs an upgrade step to prune the old `blockStats` table, so it is
a SavedVariables change and needs your approval first. See decision 1.

**B. The read-only rule and the logic in the EllesmereUI folder (issue
#77): decided, option b.** Rule G10 makes `PourSocialScore_EllesmereUI` read
only, while some logic in it breaks rule G1. Dan chose option b (2026-10-05
16:09Z): each piece moves to Libraries once and the EllesmereUI file calls
it, the only kind of edit allowed in that folder, with `ui_compare.sh` saying
"UI identical" and `check_eui_all.sh` passing.

**C. The native window has no navigation model.** The EllesmereUI window is
built around one window with a breadcrumb and back and forward. Native opens
separate pop-up windows and swaps a panel in place. Copying the breadcrumb
would mean rebuilding how the native window moves between views, which is far
more work than any single feature, and it would make native stop looking like
a Blizzard window. Decision 2.

**D. No EllesmereUI asset is actually needed.** Every drawn thing in the
EllesmereUI window comes from either plain Blizzard API or EllesmereUI's skin
applied to a Blizzard template. The pie is `CreateLine` plus
`SetColorTexture`; the ticks are `UICheckButtonTemplate`; the drop-downs are
`WowStyle1DropdownTemplate`; the rows are a `ScrollFrame`. So rules G7 and G8
can be met by copying our own code (G9) and swapping `ns.S`, `ns.Font` and
`ns.NewText` for the UIKit equivalents. Nothing has to be redrawn from
scratch and no media file is involved.

**E. Expect the native window to grow by roughly 100 to 130 KB compiled.**
The pieces to copy measure 10 KB (pie), 44 KB (detail pane and summary) and
61 KB (Events tab), minus what the UIKit already provides. It is all load on
demand, so the cost is zero until the window opens, and it does not touch the
always-loaded core. Each step measures its own cost, and issue A gives 12 KB
back in core.

**F. One harness gap.** `validate_all.sh`'s "split" check replays the 2.0 to
3.0 data move through an old build that cannot read a 3.x save, so it fails
on your 3.2.0-dev011 set while the "real save" check passes. The split loop
should only take 2.0-layout saves. Fixed in step 1.

## 5. Where shared code goes

Your question was whether shared UI kit helpers and assets belong in
Libraries or in core. The answer differs for logic and for drawing.

**Logic and queries go in `PourSocialScore_Libraries`.** Both windows already
depend on it (`NEEDS = {GUI="Libraries", EllesmereUI="Libraries"}`), it is
load on demand so nothing is resident until a window opens, and rule G2 keeps
core to chat filtering and the launchpad. Nothing in this port is regularly
active, so nothing here belongs in core. The pieces: the expired and
not-stored rows, the event query filter (period, custom range, types,
search), the managed-list totals, the type sums, the "Stored:" text and the
block-type naming. Extracted together they measure about 19 KB compiled,
which goes in a new `PSS_EventsQuery.lua` next to the existing
`PSS_TotalsQuery.lua` (8 KB). Under option b the EllesmereUI copies are
removed and both windows call this one file.

**Drawing widgets are copied into each UI folder, not shared.** A pie or a
row list shared from Libraries would force one look on both windows, which
rule G3 forbids: the EllesmereUI window must take EllesmereUI's fonts, accent
colour and skin, and the native window must look like Blizzard. So the pie
and the row list are a G9 copy into `PourSocialScore_GUI`, written against
the UIKit. The maths inside the pie (slice angles, the nested overlap, which
segment the cursor is over) is logic, not drawing, and that part can sit in
Libraries if a second caller ever wants it; with one caller each it is
simpler to keep it in the copied widget, and the number-matching harness
check covers the arithmetic either way.

**Nothing new goes in core.** Core already has every counter and reader the
windows need (`History.RecentCounts`, `RecentTotals`, `RecentByCatData`,
`Where`, `SessionStart`). Issue A would take 12 KB out of core, not add any.

## 6. Decisions needed

> **Dan's answers, 2026-10-05 16:32Z:** 1 yes (retire `PSS_BlockStats`, native reads `History.Recent*`; the SavedVariables change is approved). 2 yes (the native window gets the breadcrumb and back / forward navigation, against the recommendation). 3 yes (an Events tab). 4 port it (the three-page Summary / Event History / View-Edit Rule pane, not pies on the pop-ups). 5 the native GUI must never read files from or depend on PourSocialScore_EllesmereUI: the two front ends are independent, so a user never has to load both; anything both need is a shared function in PourSocialScore_Libraries. The native-only features stay native-only for now.

1. **Retire `PSS_BlockStats.lua` and have the native window read
   `History.Recent*`, the same as the EllesmereUI window?** (Recommended:
   yes.) It is the only way the two windows can show the same session and 24
   hour numbers, it removes about 12 KB from the always-loaded core, and it
   fixes the native player counts that already read 0 in your save. It is a
   SavedVariables change: `blockStats` stops being written and an upgrade
   step prunes it, validated against both your saves.
2. **Should the native window copy the breadcrumb and back / forward
   navigation?** (Recommended: no.) Keep the native idiom: pop-up windows and
   a panel swapped in place, with the tab-click reset and the click-again
   deselect, which are cheap, and no breadcrumb. Copying the whole navigation
   model is the single largest piece of work here and would make the native
   window stop reading as a Blizzard window (rule G8).
3. **Does the native window get an Events tab, or do its existing per-list
   Block History panels grow the Time, Types and Source filters?**
   (Recommended: an Events tab.) A sixth tab matches the EllesmereUI window
   and is where "the same features" plainly lands; growing three panels
   instead means the same filters written three times.
4. **The three-page detail pane (Summary / Event History / View-Edit Rule):
   port it, or put the pies on the existing native pop-ups?**
   (Recommended: the existing pop-ups, plus a totals pane on each tab.) The
   native player detail and guild member windows already show counts and
   history, so the pies go there; rebuilding them as an in-window pane is a
   redesign of the native window, not parity.
5. **Do the four native-only features in section 3 stay native-only for
   now?** (Recommended: yes.) Rule G10 makes the EllesmereUI folder read
   only, so closing those gaps is separate work to schedule after this port.
6. **Issue #77.** Decided 2026-10-05: option b (see issue B).
