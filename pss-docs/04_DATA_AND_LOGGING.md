# Data and logging (as of 3.3.0-dev004)

## 1. SavedVariables by folder
| Folder | SavedVariables | Holds |
| --- | --- | --- |
| core | `PourSocialScoreDB` | upgrade record, outbox, `recent` counts, sessionStart |
| _Options | `PSS_OptionsDB`, `PSS_PlayersDB`, `PSS_GuildsDB`, `PSS_RulesDB`, `PSS_CountsDB` | options (non-defaults), lists, rules, all-time counts |
| _Logging | `PSS_LoggingDB` | `blockLog`, `blockKeep` |
| _EllesmereUI | `PSS_EllesmereUIDB` | window position, last tab |

Upgrades: numbered steps in `PSS_Upgrade.lua`, run once, tracked in the upgrade record; Logging-side cleanups run when Logging loads.

## 2. Logging loads only when called
`PourSocialScore_Logging` holds PSS_LoggingDB (blockLog, blockKeep) and one code file, `PSS_SavedLog.lua`, which packs the log at logout and rebuilds it on load. Keeping the folder unloaded keeps its SavedVariables out of memory.

Logging loads only when:
- something reads history (the native Block History, the EUI Events tab, a detail pane's Event History), or
- the outbox reaches `OUTBOX_LOAD = 200` waiting lines **and** it is a quiet moment (not in combat, not in an instance), or
- code calls `M.PSS_LoadLogging()` directly.

That load is the moment waiting lines move into the log. **Lines move to the log framework only when logs are called.** Known exception: removing a guild member still loads Logging.

## 3. The outbox (core, always loaded)
- A block is **counted at once** (session, recent 24 h, all time), never later from log lines.
- Its line waits in `PourSocialScoreDB.outbox` while Logging is not loaded.
- The outbox is capped at `History.Cap()` lines, so it cannot grow without bound.
- `History.Log` / `History.Keep` and every reader call the loader first.
- `M.PSS_LoadLogging()` order: PrepareSavedData -> UnpackSaved (rebuild from the grouped save) -> KeepToLog (one-time move back, flag `logAllV1`) -> outbox into the log -> CapKeep -> Trim -> Tidy.

## 4. The log and the keep
- **blockLog:** every blocked line (`History.LOG_ALL = true`), the newest `History.Cap()` (2000 by default). Players, guild members, chat filters, world and guild chat.
- **blockKeep:** when a listed player's or guild member's line is trimmed off the log, their newest 10 text lines (whisper, party, raid, raid warning, BG), 5 party invites and 5 guild invites move here. World and guild chat is let go. `KEEP_TOTAL = 2000` lines across everyone, oldest first, trimmed in 5% batches. A line is in exactly one place.
- In play: the log is an array of entry tables; the keep is packed per person (`"<w|p|i|g><ts>\t<event>\t<channel>\t<message>"`; `KEPT_EVENTS` is append-only).

## 5. The saved format (grouped per owner, 3.2.0-dev007)
At logout and /reload `History.PackForSave` writes both the log and the keep as one table grouped by owner:
```
blockLog = { v = 2, [owner] = {
    m = name, n = { other names }, gk = guild rule key, r = rule tag,
    c = the group's usual channel, k = how many lines are kept lines (first),
    [1..] = "<type><time>\t<event>\t<channel>\t<who>\t<message>" } }
```
Times are the first line's time then `+<seconds>`; a repeated message is `"\2"`. `UnpackSaved` rebuilds the in-play tables when Logging loads. Nothing in PSS_SavedLog.lua runs unless Logging was loaded that session.

Measured on Dan's save: 2000 lines went from 633 KB to 203 KB. Earlier, packing the keep took 2000 kept lines from 806 KB to 165 KB.

## 6. Recent and session counts (core, always loaded)
- `PourSocialScoreDB.recent = { v=2, last, day={[owner]=n}, [1..144]={[cat]={[owner]=n}} }`: 144 slots of 10 minutes, time-major. Chosen by Dan after a benchmark.
- `day` is the running 24 h total per owner; expired slots subtract from it.
- Session counts are memory only and reset on login and /reload. `sessionCat[cat][owner]` (3.2.0-dev010) gives the session pie its type breakdown.
- Owner keys: `p:` players, `g:` guild members, `G:<gkey>` guild totals, `f:` filters.
- Readers: `History.CountRecent`, `RecentCounts`, `RecentSlots`, `Where`, `ForgetRecent`, `StartSession`, `SessionStart`; `History.RecentByCat` and `RecentByCatData` live in Libraries `PSS_TotalsQuery.lua`.
- History shows "Data expired from logs" rows per type per 10-minute slot where counts exceed stored lines, and "Not stored" rows where nothing is kept.

## 7. Own guild
`M.PSS_IsOwnGuild(actualGuild)`: a guild rule never blocks your own guild. Player list entries still block. Test: `check_ownguild.lua`.

## 8. Validation
`check_keep.lua`, `check_ondemand.lua`, `check_recent.lua`, `check_saveddata.lua`, `check_growth.lua`, `check_savedlog.lua` and `validate_all.sh` against all three real saves (2.0.44, 3.0.0, 3.2.0-dev011).

## 9. Possible next
- **Stored guild members: cap 1500 per guild rule** (code review decision 6, Dan, 2026-10-08). `guildData[g].members` grows with every /who and unit capture today. On the 3.4.1 line: the cap, a numbered migration that prunes over-cap rules, validated on the three real saves with the save sizes measured before and after. The same migration stops saving `g.memberCount` (derivable; kept on the row item instead) and drops it from old saves (review L12, Dan's OK 2026-10-08).
- Pack the in-play chat filter log like the keep (offered, not started).

## Retired in 3.3.0-dev002: PSS_BlockStats
The native window used to keep its own hourly counts (`PSS_BlockStats.lua`, saved as `blockStats`, one bucket per hour per source). They disagreed with the 10-minute per-owner `recent` counts the EllesmereUI window reads (a native "24 hours" spanned up to 25, and Dan's Player tab read 0). Dan approved retiring it (decision 1): the file left core (-12.1 KB resident), the login upgrade sets `PourSocialScoreDB.blockStats = nil`, and both windows read `History.RecentCounts`, `RecentTotals` and `RecentByCat` through `M.PSS_RecentListStats` and `M.PSS_ListTotals` in Libraries. `check_match.lua` keeps them equal.

## Real saves (savedvariables/ in this pack; scratch `SavedVariables/<version>/`)
| Version | Files | Notes |
| --- | --- | --- |
| 2.0.44 | PourSocialScore.lua (1.09 MB) | Before the split: one file holds everything |
| 3.0.0 | core (151 B), _Options (365 KB), _Logging (745 KB) | First split; no EUI file. Its upgrade record is dated after the dev011 one. |
| 3.2.0-dev011 | core (5.8 KB), _Options (372 KB), _Logging (224 KB), _EllesmereUI (137 B) | Grouped log (178 owners) |

Folders are named by the save's `upgrade.version` (the version last run). For the harness, `tools/harness/build_saves.sh` concatenates each 3.x set (core, Options, Logging, EllesmereUI) into `<out dir>/<version>/PourSocialScore.lua` straight from scratch `SavedVariables/<version>/` (`sh tools/harness/build_saves.sh <scratch checkout> <out dir>`); 2.0.44 is copied as is. The split check in validate_all.sh only takes 2.0-layout saves (no `PSS_OptionsDB`).
