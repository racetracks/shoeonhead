> Appendix of the core uplift plan (`00_CORE_UPLIFT.md`, locked 2026-10-08). Findings as reviewed at 3.4.1.30; the plan's decisions win where they differ.

# Review B: PourSocialScore_GUI and its calls into Libraries (main 3.4.1.30)

Scope: every file in `PourSocialScore_GUI` (Skin, Kit, Tooltip, Menu, Popups,
Rows, Pie, Detail, History, Players, Guilds, Filters, Events, Options, Window)
and the Libraries functions they call. Read against `CLAUDE.md` Interface,
PSS 02 and 09. Items fixed in R1 to R3 (01_REVIEW_AND_PLAN.md L1 to L19, M5,
M8, M9, M12) are not repeated. Every finding below was checked in the code;
line numbers are on main `d2ab159`.

Effort: S = under an hour, M = half a day, L = more. Risk: what could break.

## Summary

| Id | Area | File:line | One line | Effort | Risk |
| --- | --- | --- | --- | --- | --- |
| G1 | Logic | PSS_History.lua:18, 67-89 | Row and tip formatting copied from `M.PSS_EventCells` / `TimeText` / `M.PSS_EventTip` | S | Low |
| G2 | Logic | PSS_Players.lua:352, 357; PSS_Guilds.lua:653, 655 | Picker tick / "listed" strings built twice in the GUI | S | Low |
| G3 | Logic | PSS_Guilds.lua:135-138, 233-236, 291, 344, 522-539, 587-600, 892 | Raw `M.PSS_FindGuildRule` lookups and saved-record field reads in the GUI | M | Low |
| G4 | Logic | PSS_Guilds.lua:243 | Which guild Remove acts on is decided in the GUI | S | Low |
| G5 | Logic | PSS_Guilds.lua:269, 273, 406, 457, 468, 483; PSS_Filters.lua:119 | GUI writes the view's `dirty` / `mdirty` after actions | S | Low |
| G6 | Logic | PSS_Guilds.lua:54, 153; PSS_History.lua:61 | Empty-list and hint texts chosen in the GUI | S | None |
| G7 | Logic | PSS_Players.lua:254, 268, 282-284; PSS_Guilds.lua:538-540, 564-567, 606-608; PSS_Filters.lua:357-359 | Each pane fills its Summary spec and a few labels itself | S | Low |
| G8 | Logic | PSS_Detail.lua:267-271, 348-352 | Type-pie tip string and spec copy in the GUI | S | None |
| G9 | Logic | PSS_Events.lua:38, 41, 125, 151-152 | Raw reads of `view.q` / `view.name` and string building | S | None |
| G10 | Logic | PSS_Options.lua:162, 165-180, 184, 212, 226 | Raw `M.PSS_IO` reads, export subtitle, import decision chain | S | Low |
| G11 | Logic | PSS_Guilds.lua:602 | Core data upgrade `M.PSS_EnsureMemberBlockData` called from a redraw (redundant) | S | None |
| G12 | Dead | Menu:110, Detail:34, Window:249, Guilds:918, Players:405, Guilds:700, GuildView:334, DetailQuery:53, 55, 157 | Unreferenced ns / M names | S | None |
| G13 | Dead | PSS_Window.lua:340-344, 127 | "comes in a later 3.4.0 build" placeholder still built | S | None |
| G14 | Dead | Skin:4-12, 55; Kit:4-7; Window:24-26; Rows:23-25 | Header comments still describe two looks / Blizzard default | S | None |
| G15 | Kit | PSS_Players.lua:336-406; PSS_Guilds.lua:637-701 | Results picker built twice | M | Low |
| G16 | Kit | Players:68-82, 149-183; Guilds:179-200; Filters:68-74; Events:98-105 | `Line` / `Label` / `Strip` helpers copied per tab | S | None |
| G17 | Kit | PSS_Players.lua:181-198; PSS_Guilds.lua:213-230 | W I G P C tick row built twice | S | Low |
| G18 | Kit | PSS_Players.lua:448-452, 470; PSS_Guilds.lua:740-746 | Edit box placeholder hint hand-built twice (the search box has one) | S | None |
| G19 | Kit | PSS_Filters.lua:184-214; PSS_Popups.lua:189-214 | Multi-line text area is raw `CreateFrame("EditBox")`, twice | M | Low |
| G20 | Kit | Players:393-394; Guilds:688-689; Popups:30-31 | `b.pssPrimary = true; b.pssPaint()` pattern | S | None |
| G21 | Perf | core PSS_ChatFilters.lua:969 with PSS_Filters.lua:468-478 | Every filter block fires FILTERS_CHANGED: an unthrottled full Filters Resort per frame | S | Low |
| G22 | Perf | PSS_Guilds.lua:533 with GuildView:88-93 | The selected guild's members are walked twice per block redraw | S | Low |
| G23 | Perf | Players:543-548; Guilds:954-966; Detail:381-390 | Whole pane redrawn per block (4/s), exception tips built eagerly | S-M | Low |
| G24 | Perf | PSS_Menu.lua:137 | Leaving one menu slot re-lays every slot | S | None |
| G25 | Perf | Kit:358; Window:209; Guilds:938; Filters:474; History:126; Players:54 | Small per-call allocations | S | None |
| G26 | Bug | PSS_Guilds.lua:943-944 (no FILTERS_CHANGED) | Guild rows keep a stale "rule off" dim after a rule is switched on the Chat Filters tab | S | Low |
| G27 | Bug | PSS_Menu.lua:25, 149-158, 336-340 | Dark right-click menus cap at 200 px: "Remove Player" needs the wheel; width measured on visible slots only | S | Low |
| G28 | Bug | PSS_Skin.lua:67 | Modern art check covers only some of the atlases Modern draws | S | Low |
| G29 | Rule | PSS_Menu.lua:132 | Menu divider is 1 unit, not one physical pixel | S | None |
| G30 | Bug | PSS_Guilds.lua:428-430 vs 279-283 | Two Exclusion "Remove" paths behave differently | S | None |

## 1. Logic still in the GUI

### G1 Block history rows and tips duplicate the Events formatting
- **Where:** `PourSocialScore_GUI/PSS_History.lua:18` (`TIME_FMT`), `:67-80` (`Draw`), `:82-89` (`Tip`).
- **What:** `Draw` formats the time with `date(TIME_FMT, ts) or History.UNKNOWN`, builds the coloured type `"|c" .. History.CAT_COLOR[...] .. M.PSS_EventType(h) .. "|r"`, strips the realm with `M.removeServer`, and substitutes `"|cff888888(no message text)|r"`. That is line for line `TimeText` and `M.PSS_EventCells` in `PourSocialScore_Libraries/PSS_EventsView.lua:41, 128-131, 410-419` (same `TIME_FMT`). `Tip` concatenates time, channel, member, message and the double-click hint, the shape of `M.PSS_EventTip` (`:421-425`).
- **Why:** data formatting belongs in Libraries (Interface: no query or shaping in a drawing file); two copies drift (one already says "Double-click: these events", the other "copy the message", which is right for each, but the time and colour code are pure copies).
- **Fix:** in `PSS_EventsView.lua` add `M.PSS_HistCells(h, into)` (time, kind, name, message; reuse `TimeText` and the kind builder `M.PSS_EventCells` uses) and `M.PSS_HistTip(h, canOpen)`. `PSS_History.lua` keeps only `SetText` calls. Drop the GUI `TIME_FMT`.
- **Effort / risk:** S / low (`check_players`, `check_guilds`, `check_filters` read the history rows).

### G2 Picker cells: tick and "listed" texts built in two tabs
- **Where:** `PSS_Players.lua:352, 357`; `PSS_Guilds.lua:653, 655`.
- **What:** both `DrawPick` functions build `it.listed and "|cff808080[x]|r" or (it.ticked and "|cff00ff00[x]|r" or "[  ]")` and `"|cff808080listed|r"`. Players already calls `M.PSS_PlayerPickerCells` for the other columns.
- **Fix:** `M.PSS_PickerCells(it, into)` in `PSS_ViewNav.lua` beside `M.PSS_PickerToggle` (fills `tick`, `state`); `M.PSS_PlayerPickerCells` calls it. Pairs with G15.
- **Effort / risk:** S / low.

### G3 Guild tab reads rules and saved records directly
- **Where (all `PSS_Guilds.lua`):**
  - `:233-236` `GuildOpts(key)`: `select(2, M.PSS_FindGuildRule(key)).opts`, used at `:311` (member exception from the row menu);
  - `:291` row menu exception: `M.PSS_ToggleException(select(2, M.PSS_FindGuildRule(item.key)), ...)`;
  - `:343-346` Scan button tip: looks the rule up, then `M.PSS_GuildScanTip(g)`;
  - `:892` `navApply`: `select(2, M.PSS_FindGuildRule(key))` as an "exists" test;
  - `:522-539` `ShowGuild`: `tostring(g.name)` twice, `g.customScan`, passes the raw record `g` to exceptions;
  - `:587-600` `ShowMember`: rule lookup, `m.note`, `gg.opts`;
  - `:135-138` `DrawMember`: `m.name`, `m.guild`, `m.note` straight from the stored member.
- **What / why:** the Players and Filters tabs read through Libraries rows (`M.PSS_PlayerRow`, `M.PSS_FilterRow`); the Guild tab still knows the saved layout (`customScan`, `opts`, member fields). R3 (L9) moved part of this; these remain. A save layout change (the planned 3.4.1 member cap and `memberCount` removal) then has to touch a drawing file.
- **Fix:** in `PSS_GuildView.lua`: `M.PSS_GuildPaneView(key, into)` (name, info, sweep label, scan fields text, removable, the record for exceptions), as `M.PSS_GuildGroupView` does for groups; `M.PSS_GuildOpts(key)`; let `M.PSS_GuildScanTip` take a key; `v:CanOpenMembers(key)` (or `M.PSS_GuildExists(key)`) for `navApply`; `M.PSS_MemberCells(m, into)` for `DrawMember` and the note box.
- **Effort / risk:** M / low (`check_guilds.lua`, `check_menus.lua`, `tui_compare.sh` identical).

### G4 Remove Guild decides its target in the GUI
- **Where:** `PSS_Guilds.lua:243` `local key = V.selKind == "guild" and V.sel or (V.view == "members" and V.mguild)`.
- **Fix:** `v:RemoveTarget()` in `PSS_GuildView.lua`; the GUI asks it, then `M.PSS_GuildRemoveText`.
- **Effort / risk:** S / low.

### G5 The GUI writes the view's dirty flags after actions
- **Where:** `PSS_Guilds.lua:269, 273, 406` (`V.dirty = true` after `M.PSS_GuildSetAllRules` / `M.PSS_GroupToggleRule`), `:457` (`V.mdirty` after a member note), `:468` (after a member W I G P C), `:483` (after Add Guild on a member); `PSS_Filters.lua:119` (`V.dirty` after Reset Block History, which already fires FILTER_HISTORY_CHANGED).
- **What / why:** these compensate for events the tab does not hear (G26) or that do not exist; the view's state is set from a drawing file (Interface: no state in a drawing file). Dirty marks in event handlers and `stale()` are the pattern and are fine.
- **Fix:** listen to the event that the setter fires (G26 for the rules); for member edits add a view method (`v:MemberEdited()`) that marks both lists, or have `M.PSS_MemberCommitNote` / `M.PSS_MemberToggleAllowed` / `M.PSS_AddMembersGuild` fire GUILDS_CHANGED. Drop the Filters one (redundant).
- **Effort / risk:** S / low.

### G6 Texts chosen in the GUI
- **Where:** `PSS_Guilds.lua:54` (empty text by `V.find`), `:153` (search hint by view), `PSS_History.lua:61` ("Every line here is of a type ticked off above.").
- **Why:** Players and Filters get the empty text from `V:Resort()`; the Guild tab is the odd one.
- **Fix:** `V:Resort()` returns the empty text in `PSS_GuildView.lua` as in the other views; `v:SearchHint()`; the history text from `M.PSS_HistFilter` (or a constant in `PSS_DetailQuery.lua`).
- **Effort / risk:** S / none.

### G7 Each pane fills its Summary spec and labels itself
- **Where:** `PSS_Players.lua:254` (`tostring(tonumber(r.expire) or 0)`), `:268` (`listed and "Guild listed" or "Add Guild"`), `:282-284`; `PSS_Guilds.lua:538-540, 564-567, 606-608`; `PSS_Filters.lua:357-359`. Each sets `s.owner, s.allTime, s.title, s.id` (and groups `s.counts`, `s.recent`) from history keys and counts.
- **Fix:** one Libraries helper per kind that fills the spec from what the pane already read, for example `M.PSS_PlayerSummarySpec(r, c, into)`, `M.PSS_GuildSummarySpec(key, g, c, into)`, `M.PSS_MemberSummarySpec(m, c, into)`, `M.PSS_FilterSummarySpec(r, into)` in the matching view files; `M.PSS_PlayerGuildState` returns the button label too.
- **Effort / risk:** S / low (`check_viewquery.lua` gates the numbers).

### G8 Type pie tip and spec copy in the GUI
- **Where:** `PSS_Detail.lua:267-271` (`("%s\n%s: %d blocked (all time)")` plus the click hint), `:348-352` (`NewTotals` copies `allSpec()` into a new table on each click).
- **Fix:** `M.PSS_TypeTip(title, sl, canOpen)` in `PSS_DetailQuery.lua` next to `M.PSS_PeriodTip`; the copy can stay (it is per click) or become `M.PSS_SpecCopy(spec)`.
- **Effort / risk:** S / none.

### G9 Events tab reads the view's query table
- **Where:** `PSS_Events.lua:38, 41` (`view.q.period == "custom"`, `view.q.scope ~= nil`), `:125` (`(view.q.period or "all") == t.key`), `:151-152` (`"Only " .. (view.name or "?")`).
- **Fix:** `v:IsCustom()`, `v:Scoped()`, `v:PeriodIs(key)`, `v:ScopeText()` in `PSS_EventsView.lua`.
- **Effort / risk:** S / none (`check_events.lua`).

### G10 Import/Export: raw state and the import decision chain
- **Where:** `PSS_Options.lua:184, 212, 226` (`local io = M.PSS_IO`, `io.mode`, `io[key]`), `:162` (subtitle with `#text`), `:165-180` (check, then ask or apply, then report).
- **Fix:** `M.PSS_IOOn(key)` / `M.PSS_IOMode()` getters in `PSS_OptionsView.lua`; `M.PSS_ExportText()` returns its subtitle; `M.PSS_ImportStart(str)` returns `err` or `(askText, apply)`, so the GUI only shows the confirm.
- **Effort / risk:** S / low (`check_options.lua`).

### G11 A core data upgrade called from a redraw
- **Where:** `PSS_Guilds.lua:602` `M.PSS_EnsureMemberBlockData(m)` in `ShowMember`.
- **What:** this is the core's legacy-count migration for a stored member (`PSS_GuildIgnoreList.lua:425-456`). The next line's `M.PSS_GetMemberBlockCounts` already runs it (`PSS_GuildIgnoreList.lua:1246`), and `M.PSS_MemberBlockTotal` (Libraries) does too.
- **Fix:** delete the line.
- **Effort / risk:** S / none.

## 2. Dead code and leftovers

### G12 Names nothing uses
Checked with grep over every folder and `tools/`:
- `ns.CloseMenu` (`PSS_Menu.lua:110`): defined, never called.
- `ns.DETAIL_PAGES` (`PSS_Detail.lua:34`): defined, never read.
- `ns.ResetTab` (`PSS_Window.lua:249`): defined, never called (the local `ResetTab` is).
- `pg.openMembers` (`PSS_Guilds.lua:918`): set, never read (harness uses `selectMember` only).
- `picker.cancelButton` (`PSS_Players.lua:405`, `PSS_Guilds.lua:700`): stored, never read.
- `M.PSS_GuildPickerToggle` / `M.PSS_GuildPickerTickAll` (`PSS_GuildView.lua:334`): aliases of `M.PSS_PickerToggle` / `...TickAll`; Players calls the shared names, Guilds the aliases. Call the shared names and drop the aliases.
- Libraries, reached only through the GUI's calls: `M.PSS_HexColor` (`PSS_DetailQuery.lua:157`, no caller), `M.PSS_TypeOff` (`:53`, no caller), `M.PSS_AnyTypeOff` (`:55`, harness only: `check_viewquery.lua:58, 61`; keep or replace in the check with `M.PSS_TypesOn() == nil`).
- **Effort / risk:** S / none.

### G13 The "later build" placeholder
- **Where:** `PSS_Window.lua:340-344` builds a note "<tab> comes in a later 3.4.0 build." on every page; `:127` hides it after a builder succeeds.
- **Why:** all six builders exist since B7. The note now shows only when a builder throws, and then it is wrong (says a later build).
- **Fix:** drop it, or reword to "This tab could not be built (see the Lua error)."
- **Effort / risk:** S / none.

### G14 Stale header comments
- `PSS_Skin.lua:4-12`: "blizzard (the default...)", "modern (... until it is built it paints as Blizzard)", "both looks"; `:55` `-- "blizzard" or "dark"`.
- `PSS_Kit.lua:4-7`, `PSS_Rows.lua:23-25`: "both looks".
- `PSS_Window.lua:24-26`: "Blizzard look ... Dark look" (no Modern).
- **Fix:** say Modern (default), Classic, Dark, in that order (Interface rule). Text only.
- **Effort / risk:** S / none.

## 3. Repeated drawing code (kit candidates)

### G15 The results picker is built twice
- **Where:** `PSS_Players.lua:336-406` (`ClosePicker`, `DrawPick`, `BuildPicker`) and `PSS_Guilds.lua:637-701`: same overlay over the list, title line, rows frame `-24 / 34`, a tick column, Save (primary), Tick All, Cancel; only the columns and the save/close calls differ.
- **Fix:** `ns.NewPicker(parent, anchor, { cols, draw, save, close })` in `PSS_Rows.lua` (or a new kit section), returning the frame with `:ShowItems(items, title)`; tick and toggle through G2. Add it to `tools/harness/kit_page.lua` (Interface rule 4).
- **Effort / risk:** M / low (`check_players.lua`, `check_guilds.lua` use `picker.list`, `saveButton`, `allButton`).

### G16 Line, Label and Strip copied per tab
- **Where:** `PSS_Players.lua:68-82` and `PSS_Guilds.lua:179-193` (identical `Line`, `Label`), `PSS_Guilds.lua:195-200` (`Strip`), `PSS_Players.lua:149-151, 166-168, 181-183` (the same strip made inline with `CreateFrame`), `PSS_Filters.lua:68-74` (`Label` with x, y), `PSS_Events.lua:98-105` (label + edit box).
- **Fix:** `ns.NewLine(parent, y)`, `ns.NewLabel(parent, text [, x, y])`, `ns.NewStrip(parent, y, h, w)` in `PSS_Detail.lua` (shared pane parts).
- **Effort / risk:** S / none (`tui_compare.sh` identical).

### G17 W I G P C tick row twice
- **Where:** `PSS_Players.lua:181-198` and `PSS_Guilds.lua:213-230` (`ExclBoxes`): label "Allowed", a tick and letter per `M.EXCL`, the same offsets (90, 22).
- **Fix:** `ns.NewAllowedBoxes(parent, x, y, w, tip, onClick)` in `PSS_Detail.lua`; Players passes left clicks only.
- **Effort / risk:** S / low.

### G18 Placeholder hint on an edit box, hand-built
- **Where:** `PSS_Players.lua:448-452, 470` and `PSS_Guilds.lua:740-746`: a font string at alpha 0.4, shown while the box is empty, through an `OnTextChanged` script. `ns.NewSearchBox` (`PSS_Kit.lua:267-288`) has the same thing built in.
- **Fix:** an optional `hint` argument to `ns.NewEditBox` (kit), used by `NewSearchBox` too.
- **Effort / risk:** S / none.

### G19 The multi-line text area is raw and copied
- **Where:** `PSS_Filters.lua:184-214` (filter text) and `PSS_Popups.lua:189-214` (copy / import): a `NewPanel` box, `NewScrollFrame`, a raw `CreateFrame("EditBox")` with `SetMultiLine`, `ns.Font(11, "ChatFontNormal")`, and an `OnCursorChanged` that keeps the cursor in view. The Popups copy has no guard for a nil `y` / `h` or a zero-height view (`:209-214`); the Filters copy has them (`:202-210`).
- **Why:** baseline A8 names a text area among the kit builders; Interface rule 4 asks for the kit, not raw frames.
- **Fix:** `ns.NewTextArea(parent, fontSize, maxLetters)` in `PSS_Kit.lua` (box, scroll, edit box, cursor follow, width follow), used by both; add it to the kit preview.
- **Effort / risk:** M / low (`check_filters.lua`, `check_options.lua` reach `filterBox` / `edit`).

### G20 The primary (red in Modern) button
- **Where:** `PSS_Players.lua:393-394`, `PSS_Guilds.lua:688-689`, `PSS_Popups.lua:30-31`: `b.pssPrimary = true; b.pssPaint()` after `ns.NewButton`.
- **Fix:** `ns.NewButton(parent, text, w, onClick, primary)` or `ns.SetPrimary(b)` in the kit.
- **Effort / risk:** S / none.

## 4. Optimisation

### G21 Every filter block makes the Filters tab resort, unthrottled
- **Where:** core `PourSocialScore/PSS_ChatFilters.lua:968-969`: after `AddToBlockHistory` (which fires FILTER_HISTORY_CHANGED, `:161`) the filter path also fires FILTERS_CHANGED. `PSS_Filters.lua:468-478` turns FILTERS_CHANGED into `V.dirty = true` and a full `Refresh()` on the next frame (Resort, `ShowFilterDetail`, history re-read). The comment at `:471-472` already says "every blocked line fires it".
- **Why:** the 4-a-second throttle on FILTER_HISTORY_CHANGED (`:481-489`) is bypassed: with the tab open and spam coming in, the list is re-sorted and the pane redrawn once per frame that holds a block (C3, C9).
- **Fix:** drop the FILTERS_CHANGED fire after a block in `PSS_ChatFilters.lua:969` (FILTER_HISTORY_CHANGED says the counts changed; only `PSS_Filters.lua` listens to FILTERS_CHANGED, checked). If the Blocked sort must follow, mark `V:CountsChanged()` in the throttled handler as the Guild tab does. A core change, but small; it is also what G26 needs.
- **Effort / risk:** S / low (`check_filters.lua`; one in-game check: the Blocked column still counts up).

### G22 The selected guild is counted twice per block redraw
- **Where:** `PSS_Guilds.lua:954-962` (`V:CountsChanged(); list:Redraw(); ShowDetail()`), `PSS_GuildView.lua:88-93` (`FreshCounts` runs `M.PSS_GetGuildBlockCounts(item.key)` for each drawn row), `PSS_Guilds.lua:533` (`ShowGuild` runs it again for the selected guild).
- **Why:** `M.PSS_GetGuildBlockCounts` walks every member with a closure and a `guilds` table per call (core `PSS_GuildIgnoreList.lua:1219-1241`, the known hot spot). The selected guild is usually on screen, so its members are walked twice up to 4 times a second.
- **Fix:** `v:GuildCounts(key)` in `PSS_GuildView.lua` returning the drawn row's `item.bc` when `item.counted == self.gen`, else counting once and caching by `gen`; `ShowGuild` calls it.
- **Effort / risk:** S / low (`check_guilds.lua`, `check_viewquery.lua`).

### G23 The whole pane redraws on every block
- **Where:** `PSS_Players.lua:543-548` (`ShowPlayerDetail()` on PLAYER_BLOCKED), `PSS_Guilds.lua:954-966` (`ShowDetail()`), `PSS_Filters.lua:481-486`. `ShowPlayerDetail` sets heading, four text lines, both boxes, W I G P C, and `pane.exceptions:Set`, which for each of the 4 boxes calls `M.PSS_ExceptionState`, `M.PSS_ExceptionText` and builds `M.PSS_ExceptionTip` (`PSS_Detail.lua:381-390`), though only the counts, Summary and history change.
- **Fix:** a counts-only path per pane (counts line, `hist:Set`, `summary:Set`) for the block events; make the exception tip lazy (`b.tip` a function read in `OnEnter`, as `ns.Tip` already accepts).
- **Effort / risk:** S-M / low.

### G24 Menu slot leave redraws the whole menu
- **Where:** `PSS_Menu.lua:137` `sl:SetScript("OnLeave", function() ns.DrawMenu() end)`; `Draw` re-anchors every slot, re-reads every tick (`IsOn` may call functions) and the thumb.
- **Fix:** on leave, set that slot's text alpha back (`title and 0.41 or 0.53`).
- **Effort / risk:** S / none.

### G25 Small allocations on repeated paths
- `PSS_Kit.lua:358` `ipairs({ "Back", "Forward", ... })`: a table per paint per scroll frame (hoist to a file local).
- `PSS_Window.lua:209` a `parts` table and a closure per `UpdateNav` (every navigation).
- `PSS_Guilds.lua:938`, `PSS_Filters.lua:474` a new closure per queued redraw (hoist one function per file).
- `PSS_History.lua:126` a key string per `HV:Set` (every pane redraw, so up to 4/s); compare `id`, `total` and `ready` as three fields instead.
- `PSS_Players.lua:54` `r.listed .. "d"` per drawn row (let `M.PSS_PlayerRow` or a cells helper give the text).
- **Effort / risk:** S / none.

## 5. Bugs and rule breaks

### G26 Guild rows keep a stale "rule off" dim
- **Where:** `PSS_Guilds.lua:943-944` listens to GUILDS_CHANGED and GUILD_SCAN_DONE only. A default guild list's rule is a chat filter: `M.PSS_SetFilterActive` (`PSS_ChatFilters.lua:494-504`) and `M.PSS_SetManagedGroupActive` (`:323-329`) fire only FILTERS_CHANGED. The row's `groupOn` is cached at Resort (`PSS_GuildQuery.lua:168, 234`) and drives the dim (`PSS_GuildView.lua:203`).
- **Repro (by reading):** window open, Guild tab shown once; switch to Chat Filters, untick a "Managed Communities - ..." guild rule (or use its row menu); switch back. `SelectTab` calls `refresh`, `V.dirty` is false (no guild block in between), so `list:Redraw()` draws the cached `groupOn`: the list still shows the rule on (rows not dimmed), and a group row's order and totals are from before. The Guild tab's own toggles work only because they set `V.dirty` by hand (G5).
- **Fix:** `ns.Listen("FILTERS_CHANGED", Changed)` in `PSS_Guilds.lua`, after G21 (otherwise every filter block would resort the guild list); then drop the manual `V.dirty` writes at `:269, 273, 406`.
- **Effort / risk:** S / low; add a step to `check_guilds.lua` (toggle the rule through `M.PSS_SetFilterActive`, refresh, expect the dim).

### G27 Dark right-click menus are capped at 200 px
- **Where:** `PSS_Menu.lua:25` (`MAX_H = 200`), used for the compact right-click size too (`:149-158` stops laying slots at the cap); `:336-340` measures the width over the slots shown only.
- **What:** the player row menu (`PSS_RowMenus.lua:54-75`) is title 18 + divider 7 + Block History, Add Guild, Reset Expiration, Reset Block History (4 x 20) + divider 7 + the exceptions title 18 + 4 ticks (80) + divider 7 + Remove Player 20 = 237 px with a guild to add and an expiry set (197 without them, which just fits). In Dark (and in Classic on a client without the Menu API) "Remove Player" and the last ticks are below the cap and need the mouse wheel; Blizzard's menu (Modern, Classic) shows them all (`FillBlizzard` scrolls only above 20 entries). Interface rule 2: a look never hides a feature. Entries below the cap are also not measured for the width.
- **Fix:** a compact cap of about 400 (as `SetScrollMode(400)`), or no cap below 20 entries; measure the width over every entry with one hidden measuring font string.
- **Effort / risk:** S / low (`check_menus.lua` opens these menus in Dark).

### G28 The Modern art check is partial
- **Where:** `PSS_Skin.lua:67` `MODERN_ART` lists 8 atlases. Modern also draws `_128-RedButton-Center`, `128-RedButton-Right`, their `-Pressed` / `-Disabled` forms and `-Highlight` (`PSS_Kit.lua:52-54, 70`), `checkmark-minimal-disabled` (`:169`) and `common-searchbar-icon-a` (`:260`).
- **Why:** Interface rule 3: check the art, never assume it. A client that has the eight but not one of these shows an empty texture instead of falling back to Classic. Low likelihood (they ship together on Retail 12.x).
- **Fix:** add the right-hand, centre and state atlases (or check each where it is set and fall back per part).
- **Effort / risk:** S / low.

### G29 Menu divider is not one physical pixel
- **Where:** `PSS_Menu.lua:132` `sl.line:SetHeight(1)`, no `ns.NoSnap`.
- **Why:** Interface rule 5 (lines one physical pixel through `ns.OnePixel` / `ns.NoSnap`); at UI scales under 1 it blurs (09 lessons, thin lines).
- **Fix:** `ns.NoSnap(sl.line)` and `SetHeight(ns.OnePixel(sl))` when drawn.
- **Effort / risk:** S / none.

### G30 Two Exclusion "Remove" paths behave differently
- **Where:** `PSS_Guilds.lua:428-430` (the pane's "Remove from Exclusion List": `V:Select(nil, nil)` only, no `ClearEdits`, no redraw, relying on GUILDS_CHANGED next frame) and `:279-283` (the row menu: GUI `Select(nil, nil)` then `Resort()`).
- **Why:** both end the same today because `M.PSS_RemoveGuildExclusion` fires GUILDS_CHANGED, but one path redraws twice and the other not at all; one function avoids drift.
- **Fix:** one local `ExclRemoved()` used by both (or `v:ExclRemove(name)` in `PSS_GuildView.lua`).
- **Effort / risk:** S / none.

## Checked and fine
- No StaticPopup use in the GUI; every popup goes through `ns.Confirm` / `ns.CopyText` / `ns.ImportText` and `ns.EscapeCloses`.
- Text fades use `SetAlpha` everywhere in the GUI (the one 4-argument `SetTextColor`, `PSS_Skin.lua:123`, passes alpha 1).
- The pie's hover OnUpdate is the approved override; it is set only between OnEnter and OnLeave.
- Core events are heard only through `ns.Listen` (the window's OPTION_CHANGED is the documented exception).
- Every `M.*` the GUI calls is defined (checked by grep; `M.PSS_ScanCooldownActive` is core `PSS_Whois.lua:302`).
- Link hover uses the allow list and `IsForbidden`; `SetItemRef` is skipped in combat; the link insert hook checks `M.PSS_IsSecret`.

## Suggested order
1. G21 then G26 (one small PR: the stale dim bug and the per-block resort).
2. G11, G12, G13, G14, G29, G24, G25 (tidy, no visible change; `tui_compare.sh` identical).
3. G27, G28 (visible in Dark / fallback only).
4. G1 to G10 (logic to Libraries; `tui_compare.sh` identical, `check_*` green).
5. G15 to G20 (kit additions, each with the kit preview).
6. G22, G23 (measure garbage per block redraw before and after on Dan's 3.2.0-dev011 save).
