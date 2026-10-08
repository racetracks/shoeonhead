> Appendix of the core uplift plan (`00_CORE_UPLIFT.md`, locked 2026-10-08). Findings as reviewed at 3.4.1.30; the plan's decisions win where they differ.

# D. Upgrade output: Questie's model, PSS today, a proposed helper (issue #45)

Research only, no commits. Questie read from a sparse clone of `Questie/Questie`
(HEAD `42ee926`, 2026-10-08): `Modules/Migration.lua`, `Modules/Migration.test.lua`,
`Modules/QuestieInit.lua`, `Questie.lua`. The checkout has no LICENSE file at
the root: treat it as all rights reserved. Ideas only, no code copied.

## 1. How Questie does it

### 1.1 The migration table
- One module, `Migration`, holds a local array `migrationFunctions[1..41]`.
  The comment rule: append at the end only; they run first to last.
- **Keyed by a migration index, not by the addon version.** Nothing in the
  table names a Questie version; the index is the schema version.
- Run-once tracking: one integer, `Questie.db.profile.migrationVersion`
  (AceDB profile, so per profile). Missing means 0.
- `Migration:Migrate()`: if `migrationVersion == #migrationFunctions` it
  returns (a debug line only). Otherwise it calls every function from
  `migrationVersion + 1` to the end in a plain loop, then writes the new
  number once at the end. No per-step record, no timestamp, no version
  string, no "blocked" step: a step cannot refuse.
- Steps are tiny and blind: most set one profile key to a new default
  (`[5] enableTooltipsNextInChain = true`), some reshape a key
  (`[9]` folds `autoaccept` / `acceptTrivial` into an `autoAccept` table and
  nils the old keys), some prune dead data (`[39]` nils a list of compiled
  database keys in three scopes; `[40]` nils five townsfolk tables that are
  now rebuilt each login; `[41]` nils a retired option). Step 19 checks
  `migrationVersion == 0` to skip work on a brand new profile.
- It runs synchronously from `QuestieInit.OnAddonLoaded()` (ADDON_LOADED,
  right after AceDB is created), before any module reads the settings.
- Tested with busted (`Migration.test.lua`): set `migrationVersion = 37`,
  plant old keys, run `Migrate()`, assert they are gone.

### 1.2 What the player actually sees
Less than the issue assumed:
- **Migrations print almost nothing.** Of 41 steps only step 1 prints, once:
  `Questie: [Migration] Migrated Questie for v9.0. This will reset all Questie
  settings to default. Journey history has been preserved.` (only when old
  `db.char` settings existed). The others are silent.
- **The startup stage lines are debug output.** `QuestieInit.Stages[1..3]`
  run as one coroutine (`ThreadLib.Thread`, resumed per frame; each
  `coroutine.yield()` hands back a frame) and log `[QuestieInit:Stage1]
  QuestieDB initializing.`, `... Townsfolk building.`, `[QuestieInit:Stage3]
  Questie init done.` through `Questie.Debug(level, ...)`. That prints only
  when the user turned on debug and debug printing and the level bit matches;
  the line gets coloured tags (`|cff00f2e6[CRITICAL]|r`, `|cff00bc32[INFO]|r`,
  `|cff7c83ff[DEVELOP]|r`). A normal user sees none of it.
- All chat goes through `Questie:Print` (AceConsole): the green addon name
  prefix, then the text. Errors add `|cffff0000[ERROR]|r`, warnings
  `|cffffff00[WARNING]|r` (debug only).
- Two normal-user notices are staged with `C_Timer.After(2, ...)` at the end
  of stage 3 (the AQ War Effort reminder in red; the Isle of Quel'Danas phase),
  so they land after the login spam. A stage 2 wait also uses a 3 s
  `C_Timer.After` timeout. **Both are wall-clock gates: PSS cannot copy that
  (baseline 02 C3).**
- Failures latch once (`_StopStartup`), stop both coroutines, and set one
  status record with a message and an action ("Update Questie and QuestieDB,
  then reload the UI.").

### 1.3 Ideas worth taking (not code)
1. A flat, append-only registry of small steps; one number says how far a
   save got. PSS already has this (`PSS_Upgrade.lua` says "the Questie model").
2. Steps that prune by name lists (`[39]`, `[40]`): one table of retired keys,
   one loop. Cheaper to review than scattered `db.x = nil` lines.
3. Stage labels written as "<Area> <verb>ing" give a readable trace; PSS can
   make the same idea user-facing, once, only after an update.
4. A step knows whether the save is new (`[19]`), so a fresh save says nothing.
5. Unit tests per migration on a planted old record.

Not to take: the coroutine and timers (PSS has no long startup work and C3
forbids timer gates), AceDB/AceConsole (02 A10), debug-only output (Dan
wants the player to see it).

## 2. PSS_Upgrade.lua today (3.4.1.30 line)

### 2.1 When it runs
`PourSocialScore.lua` `ApplicationStartup`, once, when both ADDON_LOADED
(PourSocialScore) and the first PLAYER_ENTERING_WORLD have been seen:
1. `M.ShowMsg(L["LOAD_1"])` ("Type /pss for help and options"), every login.
2. `M.PSS_PrepareSavedData({quiet = fresh, startup = true})`: routing, and
   the actual move of a 2.0 / 3.0.0-dev save into `PourSocialScore_Options`
   and `PourSocialScore_Logging` (prints "Saved data moved to ..." with counts,
   or "Saved data not moved ..." on a mismatch). Loads Logging when data
   must move.
3. `M.PSS_ApplyOptionDefaults()`: drops options equal to their default
   (every login, silent).
4. `M.PSS_RunUpgradeFields()`: every step's `fields` part.
5. `M.PSS_ExpandFilters()`, managed list data load.
6. `M.PSS_RunUpgradeData(fresh)`: every step's `data` part, then the record,
   then the one chat line.
7. If Logging got loaded, `M.PSS_LoadLogging()`: unpack, outbox in, `CapKeep`,
   `Trim`, `M.PSS_TidyBlockHistory()` (also runs whenever Logging loads
   later: the Logging-side cleanups, baseline 04).

### 2.2 The record
`PourSocialScoreDB.upgrade = { step = N, version = "<TOC Version>", at = <server time> }`.
A step runs when `i > step` or it is marked `always`. A part returning
`false` blocks it and every later step for this login (not recorded).
`version` and `at` are rewritten when a step was reached or the version
changed. `M.PSS_UpgradeText()` feeds `/pss mem` and `/pss check`.

### 2.3 Output today
- Only when steps were reached and the save is not new:
  `Pour Social Score: Saved data upgraded to 3.4.0.29 (step 7).`
  (`M.ShowMsg` prefixes `|cff33ff99Pour Social Score: |cffffffff`).
- A version change with no new step prints nothing.
- Step 7 prints `L["OLD_FOLDERS"]` once if an old folder is still on disk.
- `validate_all.sh` "upgrade record" greps exactly
  `Saved data upgraded to .* (step N)` on a 2.0.44 save and its absence on
  the next login and on a fresh save; `check_cutover.lua` asserts step 7.

### 2.4 Every step
| Step | Since | Runs | Part | What it touches | Prints |
| --- | --- | --- | --- | --- | --- |
| 1 | 3.0 (2.0 login pass) | **every login** (`always`) | fields | `showIgnoreDebug`, `filterTotal` defaults; drops `autoIgnore`, `autoUpdate`, `autoCount`, `autoTime`, `attachFriends`; `M.ResetSpamFilters()` if the filter arrays are missing; creates `delList`, `expList`, `syncInfo`, `typeList` parallel to `ignoreList`; `revision` (names to proper case once); `filterActive`; `filterID` (`M.PSS_AssignLegacyFilterIDs`); drops `syncList`, `filterHistory`; creates `filterBlocked`, `filterBlockedLast`; coerces `filterWhisperTotal`, `filterPrivateTotal` | nothing |
| 1 | | every login | data | `M.PSS_UpgradeLegacyData()` (guild module: player records from list fields; `cleanupLegacyGuildPlayers`; `ensureManagedRules`; `historyFormat` 2 / 3 / 4: one history format, one shared log, per-person keep; W I G P C conversion (2.0.4); scan field defaults (2.0.10); guild block data v2, guild copies dropped); `M.PSS_UnlinkGuildRuleCounts()` (2.0.39 double count undone); `blockStats = nil` (3.3.0-dev002); `M.PSS_TidyPlayerData()` (records of unlisted players removed, dropped and empty fields; returns the count); `M.PSS_TidyBlockHistory()` if Logging is loaded (GC requested when lines went) | nothing |
| 2 | 3.0.0 | once | fields | records the move to `PourSocialScore_Options` (done by `PSS_PrepareSavedData`); `false` blocks | (the move prints) |
| 3 | 3.0.0 | once | fields | records the move to `PourSocialScore_Logging` | (the move prints) |
| 4 | 3.0.0 | once | fields | records counts / format markers moved to `PSS_CountsDB` (Options) | (the move prints) |
| 5 | 3.0 | once | fields | 2.0.12 switch-off of `ignoreResponse` / `blizzardSync` on very old saves; drops `optionsV2012`, `charOptions`, `historySize` | nothing |
| 6 | 3.4.0.22 | once | fields | drops a saved `showDeclines = true` (now Off by default) | nothing |
| 7 | 3.4.0.25 | once | fields | drops `euiIntegration`, `windowSizes`, `columnWidths`, every `windowPoints` key but `PSS_Window` / `PSS_WindowTab` | |
| 7 | | once | data | names a leftover `PourSocialScore_EllesmereUI` / `PourSocialScore_UI` folder | `OLD_FOLDERS`, once |
| (8) | 3.4.1 planned | once | | stored guild members capped at 1500 per rule, `g.memberCount` dropped (04 section 9, review L12) | |

Outside the file but part of the same login upgrade: `M.PSS_ApplyOptionDefaults`
(every login), `M.PSS_PrepareSavedData` (moves), `M.PSS_LoadLogging`'s
`KeepToLog` / `UnpackSaved` / `CapKeep` / `Trim` / `TidyBlockHistory`.

Observations:
- Step 1 mixes one-time conversions (each guarded by a nil check or
  `historyFormat`) with per-login tidies; the file already says they should
  be separated. The tidies return counts (`TidyPlayerData`,
  `TidyBlockHistory`) that are thrown away.
- `PSS_ChatHistory.lua` `loadWhenQuiet` uses `C_Timer.After(30, ...)` to retry
  outside combat: a timer gate, already on the 3.4.1 core performance list.

## 3. Proposal: a feature-level upgrade report

### 3.1 What the player sees
Printed **once, all at once**, at the end of `M.PSS_RunUpgradeData`, on the
first login where `upgrade.version` differs from the TOC version (or a step
was reached) and the save is not new. Every line through `M.ShowMsg`, so each
starts with the green `Pour Social Score: ` prefix. A feature line appears only
when its group did something; the cleanup line always appears; the last line
keeps today's wording, so the existing harness grep and `/pss check` stay valid.

Example: a 3.4.0.29 save logging in on 3.4.1.31 (step 8, the member cap):
```
Pour Social Score: Type /pss for help and options
Pour Social Score: Updated from 3.4.0.29 to 3.4.1.31. Upgrading your saved data:
Pour Social Score:   Guild Ignore List: 3 guilds trimmed to 1500 stored members (2,214 removed).
Pour Social Score:   SavedVariables performance cleanup: 41 guild member counts and 2 retired keys removed.
Pour Social Score: Saved data upgraded to 3.4.1.31 (step 8).
```

Example: a 2.0.44 save on the current build (every group has work):
```
Pour Social Score: Updated from 2.0.44 to 3.4.1.31. Upgrading your saved data:
Pour Social Score:   Chat Filtering: built-in rules rebuilt, 2 guild rule counts moved to their guilds.
Pour Social Score:   Player Ignore List: 412 entries checked, 3 records of players no longer listed removed.
Pour Social Score:   Guild Ignore List: 37 guild rules converted to W I G P C.
Pour Social Score:   Managed Communities: shipped lists added (off until you turn their rules on).
Pour Social Score:   Block History: 12,480 lines moved to PourSocialScore_Logging, 96 lines of removed entries tidied.
Pour Social Score:   Options: 5 settings moved, 3 retired settings removed.
Pour Social Score:   SavedVariables performance cleanup: 14 retired keys removed, 3 old stores pruned, schema steps 1 to 8 applied.
Pour Social Score: Saved data upgraded to 3.4.1.31 (step 8).
```

Example: a version change with no new step (a pure build bump):
```
Pour Social Score: Updated from 3.4.1.30 to 3.4.1.31. Upgrading your saved data:
Pour Social Score:   SavedVariables performance cleanup: nothing to tidy.
Pour Social Score: Saved data upgraded to 3.4.1.31 (step 8).
```

Example: an older build than the save (build numbers never reset, so the
fourth part orders any two versions):
```
Pour Social Score: Running 3.4.1.30, older than your saved data (3.4.1.31). Nothing was upgraded.
```
(and the record keeps the newer version, so going forward again does not
re-report; today it silently overwrites `version`).

Lines that must stay as they are: the move messages from
`PSS_PrepareSavedData` print before the report (they carry the move's
counts; the report's Block History / Options lines then say "moved"
without repeating the numbers, or the move messages are folded into the
report: decision 2 below). `OLD_FOLDERS` becomes the cleanup line's tail
("... ; PourSocialScore_EllesmereUI is no longer used and safe to delete.").

Wording rules: ASCII only (`2,214` uses an ASCII comma; numbers through one
`fmtNum` helper), no em dashes, at most 8 report lines, no colour codes
except what `M.ShowMsg` adds (a red `|cffff3333` only for a blocked step:
"`Saved data upgrade paused at step 3: <reason>. It tries again at the next login.`").
Strings go in `PSS_Localization.lua` (`L["UPG_HEAD"]`, `L["UPG_FEATURE"]`, ...),
English filled, other locales fall back.

### 3.2 Feature groups and the mapping of every step
Six feature groups plus the always-on cleanup, in this print order:

| Group (`feature` value) | Printed label | Existing work mapped to it |
| --- | --- | --- |
| `filters` | Chat Filtering | step 1 fields: `filterList` / `filterDesc` / `filterCount` reset, `filterActive`, `filterID`, `filterBlocked`, `filterBlockedLast`, `filterTotal`, whisper / private totals; step 1 data: `M.PSS_UnlinkGuildRuleCounts`; (`M.PSS_ExpandFilters` stays every login, unreported) |
| `players` | Player Ignore List | step 1 fields: `delList`, `expList`, `syncInfo`, `typeList`, `revision` (proper-case names); step 1 data: the player part of `M.PSS_UpgradeLegacyData`, `M.PSS_TidyPlayerData` (count of records removed); step 6 (`showDeclines`, the listed-people default) |
| `guilds` | Guild Ignore List | step 1 data: `cleanupLegacyGuildPlayers`, W I G P C conversion (2.0.4), scan field defaults (2.0.10), guild block data v2; planned step 8: the 1500 member cap |
| `managed` | Managed Communities | step 1 data: `ensureManagedRules` (shipped lists added / refreshed) |
| `history` | Block History | step 1 data: `historyFormat` 2 to 4, `M.PSS_TidyBlockHistory`; step 3 (the move to Logging); `M.PSS_LoadLogging`'s `KeepToLog` / `UnpackSaved` / `CapKeep` / `Trim` when Logging loads at this login |
| `options` | Options | step 2 and step 4 (moves to `PourSocialScore_Options` / `PSS_CountsDB`); step 5 (2.0.12 switch-off); step 7 fields (old window sizes, widths, places; the window's own place kept) |
| `cleanup` | SavedVariables performance cleanup | **always runs**: `M.PSS_ApplyOptionDefaults` (default-valued options dropped); the retired-key list (`autoIgnore`, `autoUpdate`, `autoCount`, `autoTime`, `attachFriends`, `syncList`, `filterHistory`, `blockStats`, `optionsV2012`, `charOptions`, `historySize`, `euiIntegration`, `windowSizes`, `columnWidths`, later `memberCount`); type repair (`filterWhisperTotal` / `filterPrivateTotal` to numbers, missing parallel arrays); the schema record (`upgrade.step`); step 7 data (old folders note) |

Step 1's always-run parts keep running every login exactly as now; on a login
without a version change they report nothing and build no strings.

### 3.3 Code shape
Lua 5.1, tabs, everything local, `t[#t + 1]`, in `PSS_Upgrade.lua` (core,
since step 1 runs every login; the one-time steps and the report text are a
Libraries move candidate for the 3.4.1 core placement work, with the measured
cost).

```lua
-- One row per step; ids never change once released.
--   id       the schema number recorded in upgrade.step
--   feature  "filters" | "players" | "guilds" | "managed" | "history" | "options" | "cleanup"
--   always   also runs every login (only cleanup work and step 1's tidies)
--   fields / data  run(db, out): return false to pause (not recorded),
--                  otherwise add to out (counts only, no strings)
local STEPS = {
	{ id = 1, feature = "cleanup", always = true, fields = step1Fields, data = step1Data },
	{ id = 2, feature = "options", fields = function() return M.PSS_SavedDataSplit("PourSocialScore_Options") end },
	{ id = 3, feature = "history", fields = function() return M.PSS_SavedDataSplit("PourSocialScore_Logging") end },
	{ id = 4, feature = "options", fields = function() return M.PSS_SavedDataSplit("PourSocialScore_Options") end },
	{ id = 5, feature = "options", fields = step5 },
	{ id = 6, feature = "players", fields = step6 },
	{ id = 7, feature = "options", fields = step7Fields, data = step7Data },
	-- { id = 8, feature = "guilds", data = capMembers },	-- 3.4.1
}

local FEATURES = { "filters", "players", "guilds", "managed", "history", "options", "cleanup" }

-- Counts per feature for this login, filled only when reporting
-- (out == nil on an ordinary login: the parts skip all counting).
-- out.filters.counts = n, out.players.tidied = n, out.cleanup.keys = n, ...
local function tally(out, feature, key, n)
	if not out or not n or n == 0 then return end
	local f = out[feature]
	if not f then f = {}; out[feature] = f end
	f[key] = (f[key] or 0) + n
end

-- Retired keys, one list, one loop (the Questie [39] idea); counts what it drops.
local RETIRED = { "autoIgnore", "autoUpdate", "autoCount", "autoTime", "attachFriends",
	"syncList", "filterHistory", "blockStats", "optionsV2012", "charOptions", "historySize",
	"euiIntegration", "windowSizes", "columnWidths" }
local function dropRetired(db, out)
	for i = 1, #RETIRED do
		local k = RETIRED[i]
		if db[k] ~= nil then db[k] = nil; tally(out, "cleanup", "keys", 1) end
	end
end
```

Step 1 is split into feature-tagged sub-parts that still run under id 1
(no renumbering, same effect on the data), so each sub-part can tally into
its group: for example `M.PSS_TidyPlayerData()` already returns its count,
`tally(out, "players", "tidied", M.PSS_TidyPlayerData())`; a nil-guarded
conversion tallies 1 when it fired (`if db.revision == nil then ...;
tally(out, "players", "renamed", #db.ignoreList) end`). Helpers that do not
return counts today (`M.PSS_ApplyOptionDefaults`, `M.PSS_UnlinkGuildRuleCounts`,
`ensureManagedRules`) gain a count return; callers that ignore it are unchanged.

The report, built only when needed:

```lua
-- versionOrder("3.4.0.29", "3.4.1.31") -> -1; nil when either is not X.Y.Z.B
-- (older names such as 3.3.0-dev004 or 2.0.44 count as older than any X.Y.Z.B).

function M.PSS_RunUpgradeData(fresh)
	-- out is a table only when this login reports (version changed or a step is due, not fresh)
	...
	if out then
		M.ShowMsg(L["UPG_HEAD"]:format(prev or L["UPG_OLD"], version))
		for i = 1, #FEATURES - 1 do
			local f = out[FEATURES[i]]
			if f then M.ShowMsg("  " .. L["UPG_" .. FEATURES[i]] .. ": " .. resultText(FEATURES[i], f)) end
		end
		M.ShowMsg("  " .. L["UPG_cleanup"] .. ": " .. resultText("cleanup", out.cleanup))	-- always
		M.ShowMsg(("Saved data upgraded to %s (step %d)."):format(version, reached))
	end
end
```

`resultText(feature, counts)` picks the fixed phrases for the counts present
("%d guild rule counts moved to their guilds", "%d records of players no
longer listed removed", ...; "nothing to tidy" for an empty cleanup), joined
with ", " and ending in ".". One table of phrases per feature in
`PSS_Localization.lua`.

Deciding `out`: `local reporting = not fresh and (done < reached_due or rec.version ~= version)`,
known before the fields pass (the record is read first), so the fields pass
gets `out` too. The record keeps `prev = rec.version` before rewriting it.

Rules met:
- **No timers (C3):** all lines print at once from the startup handler
  (ADDON_LOADED + PLAYER_ENTERING_WORLD), after `LOAD_1`. No coroutine, no
  `C_Timer`. If Dan wants them after Blizzard's login lines, the only
  event-driven option is the next event already registered there; printing
  at once is the recommendation.
- **Zero cost when no upgrade (C1, C13):** `out` stays nil; `tally` returns
  at once; no strings are formatted; the report helpers are locals already
  resident (measure: `loadfile` + `collectgarbage("count")` of `PSS_Upgrade.lua`
  before and after; expect a few KB of resident code, numbers in the PR).
- **No UI at login (C5):** chat lines only, through `M.ShowMsg`.
- **ASCII (A2), tabs (A4), locals (A5), no `table.insert` (C12).**
- **No SavedVariables layout change:** the record keeps `{step, version, at}`;
  nothing new is saved (D1 to D3).
- Logging stays on demand: the Block History line only reports what ran at
  this login; when Logging is not loaded it says
  "tidied when the block history next loads" and nothing loads for the report.

### 3.4 Harness check to add
New `tools/harness/check_upgrade_report.lua` plus a section in
`validate_all.sh` ("== upgrade report"), replacing the "upgrade record" grep
with a stricter one (keeping the last line's wording):
1. **Registry shape** (script on a fresh load): ids are 1..N with no gap;
   every step's `feature` is one of the seven; `M.PSS_UPGRADE_STEPS == N`.
2. **2.0.44 save** (`sv-gr-2.0.44.lua`): output has the head line, then only
   lines starting `Pour Social Score:   <one of the seven labels>: `, the
   cleanup line present exactly once and last before
   `Saved data upgraded to <version> (step N).`; at most 8 report lines;
   every line ASCII (`not line:find("[\128-\255]")`); the Player Ignore List
   line's count equals the records `TidyPlayerData` removed (planted).
3. **Next login, same version:** no head line, no feature line, nothing but
   `LOAD_1` (proves zero output and the always parts silent).
4. **Fresh save:** no report; record stamped (as today).
5. **Version-only change:** a save stamped `upgrade.version = "3.4.1.30"`
   at the current step: head line, `SavedVariables performance cleanup:
   nothing to tidy.`, the last line; no feature lines.
6. **Planted retired keys** (`autoIgnore`, `historySize`, `windowSizes`,
   `blockStats` in the right tables): the cleanup line counts 4 and the keys
   are gone (`rawget` on `PourSocialScoreDB` and `PSS_OptionsDB`).
7. **Older build than the save:** `upgrade.version = "9.9.9.999"`: the
   "older than your saved data" line, nothing upgraded, record version kept.
8. **Paused step:** stub `M.PSS_SavedDataSplit` to return false: the red
   pause line, step not recorded, the next login reports again.
9. **Real saves:** run each `PSS_REAL_SAVES/<version>/PourSocialScore.lua`
   (2.0.44, 3.0.0, 3.2.0-dev011): no Lua error, report shape as in 2, and
   `M.PSS_Validate()` reports no problems afterwards.
10. **No-upgrade cost:** on the second login, `collectgarbage("count")`
    around `M.PSS_RunUpgradeData` grows by less than a set bound (no report
    tables built).
`check_cutover.lua` keeps working (step 7 recorded); its old-folder grep
moves to the cleanup line's tail.

### 3.5 Stages and decisions
Stages (one PR each, 3.4.1 line, next build numbers):
1. Invisible refactor: step 1 split into feature-tagged sub-parts, the
   retired-key list, count returns on the helpers; no output change;
   `validate_all.sh` saves byte-identical before and after.
2. The report: strings, `out`, version order, the new check; the old
   one-line message becomes the report's last line.
3. (With the member cap) step 8 tagged `guilds`, reporting its counts.

Decisions for Dan (recommended first):
1. Feature lines only for groups that did something, cleanup always
   (recommended) / every group always (with "up to date").
2. Keep the move messages as they are and print the report after them
   (recommended, no change to tested text) / fold the moves into the
   Block History and Options lines.
3. Print all at once at login (recommended) / after the next quiet event
   (out of combat, not in an instance; more code for a one-time message).
4. Report a downgrade with one line and keep the newer version in the record
   (recommended) / stay silent as today.
