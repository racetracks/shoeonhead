> Appendix of the core uplift plan (`00_CORE_UPLIFT.md`, locked 2026-10-08). Findings as reviewed at 3.4.1.30; the plan's decisions win where they differ.

# C. SavedVariables: would unique player and guild IDs help?

Analysis only (no commits). Measured on Dan's real saves, joined with `tools/harness/build_saves.sh`:
**3.4.0.28** (primary, newest layout after upgrade step 7), **3.2.0-dev011** (second data point), 3.0.0 and 2.0.44 (older layouts, for reference).
Prototype scripts: `scratchpad/review/proto/` (`sv.lua` serializer and loader, `measure.lua`, `names.lua`, `fields.lua`, `check_derive.lua`, `layouts.lua`, `purge.lua`, `synth_players.lua`, `idx.lua`, `misc.lua`); layout outputs in `proto/out/<version>/` (made from Dan's saves: scratchpad only, never to be committed to the addon repo).

## Short answer
- **Dan's data is not name-heavy where the question assumes.** In every real save the Player Ignore List is empty; the bulk is **guild members** (1208 records, 391.5 KB on disk, about 1026 KB in memory, always loaded) and the **block log** (211.6 KB, on demand).
- **The saved log is already grouped by owner key** (blockLog v2, 3.2.0-dev007): each person's name is stored once per group, not per line. Names are 13.4 KB of the 211.6 KB log (6%); message text is 134 KB (63%).
- **IDs alone save little and cost memory:** on 3.4.0.28, IDs on the current shapes save 70 KB on disk (11%) but only about 4% of memory, and the chat path then needs a name-to-ID index (81 KB for 1208 names) that does not exist today, so memory goes **up**.
- **The big win is removing derivable and default-valued fields** (baseline D1, D3, already breached): -197 KB on disk for guild members (-50%), -380 to -440 KB of always-loaded memory (-37 to -43%). IDs on top of that add 9 KB on disk and nothing in memory for Dan's save.
- **Purging a person's lines is slow today because of the code, not the keys:** `History.Clear(pred)` unpacks every kept line (2.4 to 5.6 ms, 750 KB garbage). A clear by owner key does the same job in about 70 us with no garbage, with names or IDs alike (the keep is already keyed by owner).
- **Recommendation:** keep the name-realm key as the identity (no ID generator); make member and player records sparse (one numbered migration); add `History.ClearOwner(o)` and a purge tombstone so forgetting someone never loads Logging. Revisit integer IDs only if the Player Ignore List grows into the thousands (projection below: IDs would then save about 18% on disk on top of sparse records).

## 1. Current layout of every store

Names below: `canon` = lowercase `name-realm` (the member key, `M.PSS_CanonPlayer`); `Display` = `Name-Realm` as seen; `gkey` = lowercase guild name.

| Store (SavedVariable, folder, loaded) | Shape | Where names repeat |
| --- | --- | --- |
| `PSS_PlayersDB` (Options, always) | Parallel arrays by list index: `ignoreList[i] = Display`, `typeList[i]` ("player"/"npc"/"server"), `factionList[i]`, `dateList[i]` ("08 Oct 2026"), `notes[i]` ("" stored), `expList[i]`, `syncInfo[i] = {}`; `playerData[canon] = { name = Display, whenBlocked = "dd Mon yyyy hh:mm:ss", whispersBlocked .. channelsBlocked = true, blockCounts = { total, 7 cats incl. zeros }, opts, note, ... }`; `delList = { Display, ... }` (recently removed) | Each listed player: `ignoreList[i]` (Display), `playerData` key (canon), `playerData.name` (Display); log owner `p:canon` + `m`; recent `p:canon` in `day` and every 10-minute slot |
| `PSS_GuildsDB.guildData` (Options, always) | `guildData[gkey] = { name, enabled, block = {...}, declineGroup, declineGuild, partyRaid, customScan, ruleOrigin, managed, managedGone = { [canon] = true }, members = { [canon] = member } }`; member = `{ name = Display, guild = "GUILD NAME", whenBlocked = "dd Mon yyyy hh:mm:ss" or "Managed list", class, level, faction, blockCounts = { total, 7 cats incl. zeros }, _playerKey = canon, _canon = canon, _gkey = gkey, _managed = true, excluded*, note, opts }` | Per member: the key (canon), `name` (Display), `_playerKey` (canon, 710 of 1208), `_canon` (254), `guild` (the rule's name again, all 1208), `_gkey` (254). 3263 person refs (83.5 KB) and 1818 guild refs (26.7 KB) in this store alone |
| `PSS_RulesDB` (Options, always) | `filterList[i]`, `filterDesc[i]`, `filterActive[i]`, `filterID[i]`, `builtinRules[id] = true`, format flags | none |
| `PSS_CountsDB` (Options, always) | `filterCount[i]`, `filterBlocked[i] = { counts = { total, 7 cats } }`, `builtinStats[id] = { count, blockedLast, blocked = { counts = {...} } }`, totals | none (zero-valued counters, 3.3 KB) |
| `PSS_OptionsDB` (Options, always) | Non-default options plus `windowPoints` | none |
| `PourSocialScoreDB.recent` (core, always) | `{ v = 2, last, day = { [owner] = n }, [1..144] = { [cat] = { [owner] = n } } }`; owner `p:canon`, `g:canon`, `G:gkey`, `f:<id>` | One owner string per slot and cat it appears in, plus `day`. 3.4.0.28: 44 slots, 440 slot entries, 132 day owners; 200 person refs (6.6 KB), 161 guild refs (2.6 KB) |
| `PourSocialScoreDB.outbox` (core, while Logging is unloaded) | Array of entry tables `{ ts, cat, event, channel, member = Display, message, o = owner, gk, r }`, capped at `History.Cap()` | `member`, `o` and `gk` on every waiting line (none waiting in the real saves) |
| `PSS_LoggingDB.blockLog` (Logging, on demand), saved | v2 grouped: `{ v = 2, [owner] = { m = Display, n = { other names }, gk, r, c, k, [1..] = "<type><time>\t<event>\t<channel>\t<who>\t<message>" } }` | Once per owner group: the key and `m` (3.4.0.28: 189 groups; keys 6.7 KB, `m` 7.2 KB) |
| `blockLog` in play | Array of entry tables, oldest first (as the outbox) | `o`, `member`, `gk` per line (interned in memory, so cheap) |
| `PSS_LoggingDB.blockKeep` | Saved inside blockLog v2 (`k` = how many leading lines are kept lines). In play: `{ [owner] = { m, gk, r, [1..] = "<type><ts>\t<event>\t<channel>\t<message>" } }` | Once per owner (empty in 3.4.0.28 and dev011; 112 KB in 3.0.0, old format) |

## 2. Measurements on the real saves

### 2.1 Disk and memory per store
Disk = bytes as WoW writes them (CRLF; the re-serializer matches the files to within 11 bytes). Memory = Lua 5.1 (64-bit) heap with only that table kept, harness overhead (6.5 KB) included in the "whole" rows.

| Store | 3.4.0.28 disk KB | 3.4.0.28 mem KB | dev011 disk KB | dev011 mem KB | Loaded |
| --- | ---: | ---: | ---: | ---: | --- |
| PSS_GuildsDB.guildData | 391.5 | 1032.3 | 356.0 | 950.4 | always |
| PSS_LoggingDB.blockLog | 211.6 | 398.7 | 219.0 | 401.7 | on demand |
| PourSocialScoreDB.recent | 18.8 | 56.2 | 5.5 | 21.6 | always |
| PSS_CountsDB | 4.3 | 20.3 | 4.7 | 22.2 | always |
| PSS_RulesDB | 0.8 | 9.2 | 0.8 | 9.2 | always |
| PSS_PlayersDB | 0.6 | 8.9 | 0.6 | 8.8 | always (list empty) |
| PSS_OptionsDB | 0.3 | 7.6 | 0.8 | 10.3 | always |
| Files: Options / Logging / core | 397.7 / 211.7 / 19.0 | | 363.0 / 219.1 / 5.7 | | |

Older layouts: 3.0.0 blockLog 615.3 KB + blockKeep 112.2 KB (entry tables, before the v2 grouped save); 2.0.44 one file 1066.8 KB, 2097 KB in memory.

### 2.2 Where the guild member bytes go (3.4.0.28, 1208 members, 254 managed, 120 rules)
| Member field | Records | Disk KB | Derivable? (checked on all 1208) |
| --- | ---: | ---: | --- |
| blockCounts | 403 | 69.7 | 2416 zero fields stored; `total` equals the sum |
| whenBlocked | 1208 | 48.8 | 253 are the constant "Managed list"; the rest a 20-char date string |
| name | 1208 | 45.4 | `TitleCase(key) == name` for 1076 of 1208 |
| guild | 1208 | 35.8 | equals the rule's `name` for 1205 (3 group members carry their real guild) |
| _playerKey | 710 | 35.2 | equals the key in 1208 of 1208 |
| class / faction / level | 971 / 498 / 473 | 21.8 / 13.1 / 7.7 | no (captured data) |
| _canon / _gkey / _managed | 254 each | 11.6 / 7.5 / 5.5 | `_canon` = key always; `_gkey` = parent 1207 of 1208; `_managed` follows from the shipped list |
| member keys and braces | 1208 | 40.8 | the identity itself |

About 210 KB of the 391.5 KB is derivable or default-valued (baseline D1 "nothing derivable", D3 "no default-valued fields": a known breach not listed in PSS 02 section 12).

### 2.3 How often names repeat (3.4.0.28; 1208 distinct people, 120 guild keys)
| Store | Person refs | Person bytes on disk | Guild refs | Guild bytes on disk |
| --- | ---: | ---: | ---: | ---: |
| guildData | 3263 | 83.5 KB | 1818 | 26.7 KB |
| blockLog | 346 | 10.8 KB | 174 | 2.6 KB |
| recent | 200 | 6.6 KB | 161 | 2.6 KB |
| **total** | 3809 | 100.9 KB | 2154 | 31.9 KB |

dev011: 3294 person refs (86.2 KB), 1880 guild refs (27.7 KB). 3.0.0 (log before v2): blockLog alone 1857 person refs (58.7 KB) and blockKeep 904 (28.2 KB); the v2 grouped save already took that from 87 KB to 11 KB.

**Memory vs disk:** Lua interns strings, so a name costs memory once per distinct spelling, and every reference is a 16-byte slot whether it holds a string or an integer. 3.4.0.28 holds 2744 distinct name strings (about 126 KB interned): each person exists as up to three spellings (`canon`, `Display`, `g:canon` / `p:canon`), each guild as `gkey`, `GUILD NAME` and `G:gkey`. An ID removes spellings, not slots; the slot count (and the tables, which are most of the 1 MB) stay.

### 2.4 Log composition (3.4.0.28)
2017 lines in 189 owner groups (617 lines from guild members, 1400 from chat filters), no kept lines. Owner keys 6.7 KB, `m` 7.2 KB, line text 172.5 KB of which messages 134.0 KB. IDs can only touch the 13.9 KB of keys and names.

## 3. Prototypes (proto/layouts.lua; the stores that hold names)

Layouts:
- **cur**: as saved.
- **A0, IDs only**: a high-water counter and id tables in the save (`ids = { nextP, nextG, p = { [id] = Display }, g = { [gid] = gkey } }`); members keyed by id, guildData by gid; `_playerKey`, `_canon`, `_gkey` dropped (the id replaces them); log groups and recent owners keyed by integer (`-gid` for guild totals), `m` dropped.
- **A1, IDs + sparse records**: A0 plus the sparse rules of C1.
- **(b) B, lines nested under each member record**: each `g:` group moved from blockLog into `guildData[...].members[canon].log`.
- **C1, sparse records, name keys**: drop `_playerKey`, `_canon`, `_gkey`, `_managed`, `_virtual`; `guild` when it equals the rule's name; `whenBlocked = "Managed list"`; `name` when `TitleCase(key)` gives it; zero counters, and `total` when it equals the sum; log `m` when `TitleCase(key)` gives it.
- **C1t**: C1 with `whenBlocked` as an integer server time instead of the date string.
- **C2**: C1t with each member packed into one string (`name\tclass\tlevel\tfaction\twhen\tcounts`; a record with flags or a note stays a table).

### 3.1 Results, 3.4.0.28 (KB; memory per table on its own, overhead removed)
| Layout | guildData disk | ids disk | blockLog disk | recent disk | Total disk | Options file | Logging file | guildData mem | ids mem | blockLog mem | recent mem |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cur | 391.5 | 0 | 211.6 | 18.8 | **621.9** | 397.7 | 211.7 | 1025.8 | 0 | 392.2 | 49.7 |
| A0 IDs | 309.1 | 34.7 | 197.2 | 10.7 | 551.8 | 350.1 | 197.2 | 955.3 | 106.9 | 361.0 | 43.9 |
| A1 IDs + sparse | 165.9 | 34.7 | 197.2 | 10.7 | 408.6 | 206.9 | 197.2 | 549.1 | 106.9 | 361.0 | 43.9 |
| B nested | 431.6 | 0 | 155.2 | 18.8 | 605.7 | 437.8 | 155.3 | 1142.1 | 0 | 242.8 | 49.7 |
| C1 sparse | 194.0 | 0 | 204.7 | 18.8 | 417.4 | 200.1 | 204.7 | 645.6 | 0 | 373.4 | 49.7 |
| C1t sparse + int time | 182.8 | 0 | 204.7 | 18.8 | 406.2 | 189.0 | 204.7 | 587.1 | 0 | 373.4 | 49.7 |
| C2 packed member | 115.0 | 0 | 204.7 | 18.8 | 338.5 | 121.2 | 204.7 | 383.2 | 0 | 373.4 | 49.7 |

### 3.2 Results, 3.2.0-dev011
| Layout | guildData disk | ids disk | blockLog disk | recent disk | Total disk | guildData mem | ids mem | blockLog mem | recent mem |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cur | 356.0 | 0 | 219.0 | 5.5 | 580.5 | 943.9 | 0 | 395.2 | 15.1 |
| A0 | 282.4 | 31.5 | 205.4 | 3.2 | 522.5 | 877.8 | 99.4 | 365.8 | 13.0 |
| A1 | 154.9 | 31.5 | 205.4 | 3.2 | 395.0 | 511.9 | 99.4 | 365.8 | 13.0 |
| B | 395.2 | 0 | 164.5 | 5.5 | 565.2 | 1055.7 | 0 | 249.2 | 15.1 |
| C1 | 180.6 | 0 | 212.5 | 5.5 | 398.6 | 604.2 | 0 | 377.4 | 15.1 |
| C1t | 170.3 | 0 | 212.5 | 5.5 | 388.4 | 548.2 | 0 | 377.4 | 15.1 |
| C2 | 108.4 | 0 | 212.5 | 5.5 | 326.5 | 365.7 | 0 | 377.4 | 15.1 |

### 3.3 What the numbers say (3.4.0.28)
- **Always-loaded memory** (guildData + ids + recent): cur 1075.5; A0 1106.1; A1 699.9; C1 695.3; C1t 636.8; C2 432.9 KB. With IDs the chat path also needs a name-to-ID index: **80.9 KB for 1208 names** (measured, `idx.lua`), since chat events arrive with names. The existing member index (`memberIndexG` / `memberIndexK`, canon -> gkey, stored key) would have to map to ids as well, so A1 really costs about 780 KB against C1's 695 KB.
- **Disk:** A1 beats C1 by 8.8 KB (2%): 7.5 KB in the log and 8.1 KB in recent, less 6.8 KB more in the Options file (the names table is bigger than the keys it replaces once records are sparse).
- **IDs alone (A0)** save 70 KB on disk, nearly all of it by dropping `_playerKey` / `_canon` / `_gkey`, which C1 drops without IDs.
- **(b) Nested under the member** moves 56 KB of log lines into the always-loaded Options file (+40 KB disk, +116 KB memory at every login) and breaks the Logging on-demand split (04 section 2): rejected. The v2 saved log already is "grouped under the person's key", in the Logging file where it belongs.
- **C2 packed** is the smallest (-64% memory on guildData) but every member read and every count would go through pack and unpack, touching the guild engine's hot path and most of `PSS_GuildIgnoreList.lua`; worth it only as a later step for members with no counts and no flags (captured /who data, about two thirds of the records).

### 3.4 Purging one person's lines (proto/purge.lua; log 2017 lines, keep filled to its 2000-line cap over 174 people)
| Operation | 3.4.0.28 | dev011 | Garbage |
| --- | ---: | ---: | ---: |
| Today, `History.Clear(function(h) return h.o == owner end)`: walks the log and **unpacks every kept line** into a table | 5552 us | 2405 us | 750.5 KB |
| By owner key (`ClearOwner`): log walk comparing `o`, then `keep[o] = nil` | 71 us | 67 us | 0 |
| The same with integer owners (IDs) | 73 us | 74 us | 0 |
| Loading Logging first (`UnpackSaved`, needed today when the person has counts) | 3890 us | 4381 us | about 1.5 MB built |
| Tombstone instead (core records `o`; `UnpackSaved` skips that saved group next time Logging loads) | 0.16 us now; the later load 3691 us (cheaper, not dearer) | 0.12 us | 0 |
| `ForgetRecent` (144 slots) | 6.2 us | 3.8 us | 0 |

The purge is already keyed by owner in the keep and in the saved log; IDs make no difference (an integer compare costs the same as an interned string compare). The 75x gain is a code change that works with names.

### 3.5 Projection: many players listed (proto/synth_players.lua)
Dan's Player Ignore List is empty in every real save, so this is synthetic: 1000 listed players (names taken from his members), 400 of them with 5 log lines each, 100 with recent counts.

| Layout | Players disk | ids disk | log disk | recent disk | Total disk | Players mem | ids mem | log mem | recent mem |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cur | 416.6 | 0 | 80.9 | 17.5 | 515.0 | 859.4 | 0 | 176.9 | 44.9 |
| IDs | 329.0 | 26.9 | 54.2 | 6.4 | 416.5 | 718.7 | 71.2 | 93.4 | 32.3 |
| sparse | 177.7 | 0 | 66.9 | 17.5 | 262.1 | 429.9 | 0 | 142.7 | 44.9 |
| IDs + sparse | 127.3 | 26.9 | 54.2 | 6.4 | 214.8 | 288.5 | 71.2 | 93.4 | 32.3 |

Here IDs on top of sparse records save 47 KB on disk (18%) and about 50 KB of always-loaded memory once the 40 KB name-to-ID index is counted (1000 names). Sparse records alone save 253 KB (49%). The player store's parallel arrays (`notes[i] = ""`, `typeList[i] = "player"`, `syncInfo[i] = {}`) and all-true W I G P C flags are most of its cost.

## 4. Native identity options considered
| Option | Verdict |
| --- | --- |
| **The name-realm key (canon)** | Already the key of `playerData`, `members`, log groups, keep lists and recent owners; the member index resolves every chat spelling to it. Unique per character name at a time; free; readable in exports. **Keep it.** |
| Monotonic integer counter in the save (high-water, never decremented) | Unique and never reused, small on disk; needs a names table (always loaded), a name-to-ID index on the chat path (40 to 81 KB), and remapping on import. Gains only in recent counts and the log's key and `m` (16 KB on Dan's save). Not worth it now. |
| Player GUID (`Player-<realm>-<hex>`, 20+ chars) | Longer than most names; not given by /who, guild rosters or the shipped lists; secret under chat lockdown on Retail 12.x (PSS 02 section 10), so it cannot be a key. Survives a rename, not a realm transfer. At most an optional extra field later. |

Rename and realm transfer: an ID minted from a name follows the name exactly as the key does, so IDs do not solve renames either; only a GUID would, and it is unavailable where PSS needs it.

## 5. Recommendation
**Keep names as the identity. Make the records sparse, and make the purge targeted.** No ID generator.

### 5.1 What changes
1. **Guild member records (always loaded):** never store `_playerKey`, `_canon`, `_gkey`, `_managed`, `_virtual` (work them out from the key, the parent rule and the shipped list when the record is read, as `vrec` already does for unsaved shipped members); `guild` only when it differs from the rule's name (3 records); `name` only when `TitleCase(key)` does not give it; no `whenBlocked` for managed records; `blockCounts` without zero fields, `total` only when it differs from the sum (`History.EnsureCounts` already rebuilds both). Optional C1t: `whenBlocked` as server time (displayed through `History.FormatTime`), -11 KB disk, -58 KB memory.
2. **Player records:** the W I G P C flags stored only when false (nil reads true, as `ensurePlayer` already treats it), no `name` when derivable, sparse counts; list arrays without `""` notes, `"player"` types or empty `syncInfo` tables (the readers already default them).
3. **Log save:** drop `m` from a group when `TitleCase(owner key)` gives it.
4. **Purge:** `History.ClearOwner(o)` (log walk by `o`, `keep[o] = nil`, saved group dropped) used by `M.PSS_ForgetPlayer`, member and guild removal; when Logging is not loaded, a tombstone `PourSocialScoreDB.purge[o] = true` (core, capped) that `UnpackSaved` applies by skipping the group and then clears. Removal then never loads Logging (closes the known gap in 01 section 5).

Expected on 3.4.0.28: Options file 397.7 -> 189 to 200 KB, always-loaded memory -380 to -440 KB (guildData 1026 -> 587 to 646 KB); purge 5.6 ms / 750 KB garbage -> 71 us / 0, and no Logging load for it.

### 5.2 Migration shape
- **Upgrade step 8** (numbered, run once, recorded in `PourSocialScoreDB.upgrade`; safe to run twice): for every `guildData[g].members[k]` and `playerData[k]`, apply 5.1 items 1 and 2 in place (no copies; the existing `compactAllMembers` is the natural home). Count before and after with `M.PSS_Validate` (members, players, per-owner block totals); on any difference undo and retry next login, as `PSS_PrepareSavedData` does.
- **Logging side** (when Logging loads, baseline D8): item 3 happens in `PackForSave` at the next logout, so no separate step; `UnpackSaved` keeps accepting `m`.
- Every reader of the dropped fields goes through one accessor (`M.PSS_MemberGuildName(m, gkey)`, `M.PSS_MemberCanon(k)`, and `History.EnsureCounts` for counts) so nothing reads a missing field raw; `check_layers` style grep in `check_rules.sh` for `_playerKey` / `_canon` / `_gkey` outside the accessor.
- Combine with the planned 3.4.1 member cap (1500 per rule) and the `memberCount` drop (review L12): one step, one Dan OK (baseline D9), one validation.
- Validate on all four real saves (2.0.44, 3.0.0, 3.2.0-dev011, 3.4.0.28): `validate_all.sh`, plus a new check that every member's derived fields equal the old stored ones, every counter (session, recent, all-time, `M.PSS_ListTotals`, `check_viewquery.lua`) is identical before and after, and save sizes are measured.

### 5.3 Risks
| Risk | Cover |
| --- | --- |
| Counters drift | Counts are never derived from lines (02 section 3); sparse counts read through `EnsureCounts`; step validates totals before and after and undoes on difference |
| A reader expects `_playerKey` / `guild` / `name` | Accessors plus a rules-check grep; `check_guilds.lua`, `check_players.lua`, `check_menus.lua` in all three looks; `tui_compare.sh` identical |
| Name casing lost | `name` kept whenever `TitleCase(key)` differs (132 of 1208 today, e.g. "McX", accented names) |
| Rename or realm transfer | Same as today (name keys); IDs would not help; GUID unavailable |
| Import / export | Export copies fields through `copyFields(m, MEMBER_FIELDS)`: it must fill derived fields, so exports stay byte-compatible with older versions; import of an old export lands in full records that the next login tidy makes sparse. With IDs this would have needed remapping on every import (another reason not to) |
| Managed lists | Managed records are rebuilt from the shipped list (`vrec`); only counts, notes and flags are stored, as `managedDirty` already decides |
| Logging split | Nothing moves between folders; the tombstone lives in core and is applied only when Logging loads |
| Tombstone and re-add | Waiting outbox lines are separate from the saved group, so a person removed and re-added before Logging loads keeps only their new lines; the tombstone is cleared once applied |
| Older versions reading a new save (downgrade) | A downgrade sees missing fields; every reader already tolerates nil (`ensurePlayer`, `EnsureCounts`, member index falls back to `canonPlayer(m.name)` or the key) but this needs one check run of the previous release on a migrated save |

### 5.4 Staged rollout (3.4.1 line, one build per stage)
1. **ClearOwner and the tombstone** (no save layout change, no Dan OK needed for layout): `History.ClearOwner`, purge tombstone, removal never loads Logging; harness proves identical counters and lines.
2. **Accessors only**: every read of the derivable fields goes through accessors; look-compare identical; no data change.
3. **Upgrade step 8** (Dan's OK first, D9): sparse members and players, with the 1500 member cap and `memberCount` drop; validated on the four real saves; sizes before and after in the PR.
4. Optional: `whenBlocked` as an integer (C1t), then packed strings for count-less captured members (C2) only if the measured always-loaded memory still matters.
5. Revisit integer IDs only if a real save shows thousands of listed players with recent counts; the projection puts the gain at about 18% on disk on top of sparse records, at a 40 KB index cost.
