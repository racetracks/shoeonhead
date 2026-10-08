# Current project: core uplift (3.4.1 to 3.4.3)

**The implementation plan, locked (Dan, 2026-10-08).** Every decision in section 5 is answered; build on it as written. A change to the plan needs Dan's OK and a line in section 5.

Design and findings: scratch `docs/latest/core-uplift/` (this file is `00_CORE_UPLIFT.md` there; the five appendices are `01_CORE_LIBRARIES.md` (N1 to N48), `02_GUI.md` (G1 to G30), `03_SAVEDVARIABLES.md`, `04_UPGRADE_HELPER.md`, `05_NAME_BUGS.md`). Read an appendix only for the stage that uses it. It replaces the 3.4.1 part of the first review (`docs/latest/code-review/`), whose L12, L14 to L17 and L20 are folded in below. Reviewed at main **3.4.1.30** (`d2ab159`) on Dan's saves 3.4.0.28 (Camelot), 3.2.0-dev011, 3.0.0, 2.0.44.

**How each stage is worked (02 E9 to E11 in the baseline):** one stage per session. Dan resets the session after each stage. A fresh session reads `CLAUDE.md`, this file's stage table and 06, and builds the next stage. Every stage's PR updates this table, 06, and anything else a fresh session needs. At each release, the done stages are re-summarized into `01_HANDOVER.md` (the addon as it works) and leave this table.

## 1. Goal
Fix what players hit today, halve the always-loaded saved data, make every upgrade readable and every save forward compatible, then make the core and the window cheaper and tidier, with nothing visible changing unless a stage says so.

## 2. Design (what changes, where)

### 2.1 Names (appendix 05)
- **Cause.** On Camelot / WoW Forever the unit APIs return the surname where the realm should be. Names built from a unit become `First-Last`, while chat and /who give `First Last-ClassicBetaPvP`. **Confirm in game before N1 (decision 12):** on Camelot, target a "First Last" player and run
  - `/dump UnitName("target")`
  - `/dump UnitFullName("target")`
  - `/dump GetUnitName("target", true)`
  - `/dump UnitRealmRelationship("target")`
  - `/dump GetPlayerInfoByGUID(UnitGUID("target"))`
  - `/dump GetNormalizedRealmName()`
- **`M.PSS_NormName(name, realm)`** in core (`PSS_ChatBlock.lua`). It checks for a secret value first, applies the Camelot surname rule and uses one realm spelling (`GetNormalizedRealmName`). `NormalizePlayer`, `CanonPlayer`, `DisplayPlayer`, `M.PSS_UnitFullName` and every name builder call it (about 14 places today).
- **Callers to change:**
  - `scanUnit` (`PSS_GuildIgnoreList.lua:106`) and the unit menu (`PSS_BlizzardUI.lua:233`).
  - The ignore hooks and `M.ignoreFromCmd` (`PSS_PlayerIgnoreList.lua:597`, which passes `exactName` for the target).
  - `M.PSS_SplitNameArg` (`PSS_Globals.lua:145`): multi-word names.
  - Import (`PSS_ImportExport.lua:344`): normalise, and check the shipped lists.
  - `PSS_FlushManaged`: stops saving the runtime fields `_canon`, `_gkey`, `_managed` and `_virtual`.
- **Shipped lists:** `tools/PSS_BuildManaged.lua` rejects or converts surname-as-realm names. Of its 212 entries, 196 are dropped and 16 converted (decision 6); the data file is rebuilt and re-measured.

### 2.2 SavedVariables (appendix 03)
- **Identity stays the lowercase `name-realm` key.** There is no ID generator for players or guilds (decision 2): IDs measured 11% smaller on disk and larger in memory. Player GUIDs are not available from /who or the shipped lists, are secret under chat lockdown, and are long.
- **Custom filters get a never-reused integer id** (decision 3). A counter, `nextFilterId`, is stored once and only ever goes up. History and recent counts key on `f:<id>` instead of the filter text (N43), so editing a filter keeps its history and Copy starts a new one. Built-in filters keep `PSS00NN`.
- **Sparse records:** derivable data is not saved.
  - Member records drop `_playerKey`, `_canon`, `_gkey`, `_managed` and `_virtual`.
  - `guild` is saved only when it differs from the rule, `name` only when `TitleCase(key)` differs, and there is no `whenBlocked` on managed records.
  - Counts drop zero fields, and `total` is saved only when it differs from the sum.
  - Player records save W I G P C only when false.
  - Lists drop empty notes, types and `syncInfo`.
  - Log groups drop `m` when it is derivable.
  - Every read of a dropped field goes through one accessor (`M.PSS_MemberGuildName`, `M.PSS_MemberCanon`, `History.EnsureCounts`), and a rules-check grep keeps raw reads out.
  - Expected on 3.4.0.28: Options file 397.7 KB to about 196 KB, always-loaded memory down 380 to 440 KB.
- **Purge by owner:** `History.ClearOwner(o)` replaces the six copies of the history clear (N16): 5.6 ms and 750 KB of garbage become about 70 us with none. When Logging is not loaded, a capped tombstone `PourSocialScoreDB.purge[o]` is applied when Logging next loads, so removing anyone never loads Logging.
- **Upgrade step 8, "SavedVariables performance cleanup"** (decision 4; Dan's OK given, D9): one run-once step for everything below, then one validation on all four saves with identical counters.
  - Sparse records, and the runtime fields dropped.
  - The 1500 member cap per rule, and `memberCount` no longer saved (L12, L16).
  - The Camelot name repair (decision 5), on Camelot saves only, and only for records with `faction` and no `_playerKey`:
    - About 184 records are merged into the shipped records, 48 into their stored twins, and about 267 re-keyed to `first last-realm`.
    - Player-list keys and `p:` / `g:` log owners get the same conversion.
    - First-name-only entries cannot be repaired. They are listed once in chat so Dan can re-add them.
  - `showIgnoreDebug` is no longer saved (N8).
  - Custom filter ids are assigned, and their history and recent keys moved to them.

### 2.3 Forward compatibility (decision 10, Dan's addition)
**The goal: this layout is the last time the saves are readdressed.** From 3.4.1 on, a save written by a newer version works in an older one, and the reverse, without loss:
1. **One schema map, `M.PSS_SCHEMA` (core, data only).** For every store it lists the saved fields, the function that reads each one and its default. A rules check fails any saved field the code writes that is not in the map. This is how each field is checked against a known function.
2. **Tolerant readers.** A missing field reads as its default. An unknown field is kept untouched and never deleted.
3. **Nothing is deleted by guesswork.** The cleanup removes only keys named in one `RETIRED` list, so an older version never strips a newer version's fields.
4. **Step numbers only grow, and each step is safe to run twice.** The upgrade record also keeps the highest version that has written the save.
5. **A newer save on an older version** (a downgrade) prints one line saying the save is from a newer version, keeps the newer record, and runs no step backwards.
6. **Rules this version cannot use are reported, kept and exportable.** After every version change, in either direction, each saved rule is checked against the code that applies it:
   - custom filters: does it compile with `M.PSS_CompileFilter`?
   - guild rules: are its kind and its fields in the schema map?
   - options: is it in `M.PSS_OPTIONS`?

   A rule that fails is not applied. It stays in the save unchanged, so moving back to a version that knows it restores it. The report names the rules and offers an export: "Chat Filtering: 2 rules this version cannot use (kept, not applied): /pss export unused". The command copies them to the Import/Export text so they can be saved outside the game. A rule becomes usable again the moment a version that knows it loads.
7. **Exports carry a format version** and every field (filled from the accessors), so an export is readable by older and newer versions alike. Import keeps unknown fields.
8. Releases up to 3.4.1.30 cannot run this; S3's validation runs 3.4.0.29 on a migrated save once to prove it tolerates the sparse records.

### 2.4 Upgrade report (appendix 04; issue #45)
- **A step registry in `PSS_Upgrade.lua`.** Each entry has `id`, `feature`, `always` (runs every upgrade), and `fields` / `data` functions that add their counts to an `out` table. Step 1 is split into feature-tagged parts. Retired keys are pruned in one loop over `RETIRED`.
- **At the first login after a version change, one batch prints all at once (decision 9):**
  - a header;
  - a line for each feature that changed (decision 7): Chat Filtering, Player Ignore List, Guild Ignore List, Managed Communities, Block History, Options;
  - **always** "SavedVariables performance cleanup", with its counts and the size before and after;
  - today's last line, "Saved data upgraded to X (step N).", unchanged.

  Example (numbers illustrative):
  ```
  PourSocialScore: updated from 3.4.0.29 to 3.4.1.43. Upgrading your saved data:
    Chat Filtering: 3 custom filters given an id
    Guild Ignore List: 48 duplicate members merged, 267 names repaired
    Managed Communities: 184 members already on the shipped lists dropped
    SavedVariables performance cleanup: 6 old settings removed, 1208 records tidied (397 KB to 196 KB)
  PourSocialScore: saved data upgraded to 3.4.1.43 (step 8).
  ```
- Today's data-move messages stay as they are and print before the report (decision 8). A downgrade prints one line (decision 10). A normal login builds no strings and costs nothing. All output goes through `M.ShowMsg`, in ASCII.
- **Harness:** `check_upgrade_report.lua`, 10 cases:
  - the registry's shape;
  - an upgrade from 2.0.44;
  - silence when the version is the same;
  - a fresh save;
  - a version-only bump;
  - planted retired keys;
  - a downgrade;
  - a paused step;
  - the four real saves;
  - a memory bound when nothing upgrades.

  Plus a "== upgrade report" section in `validate_all.sh`.

### 2.5 Fixes (appendices 01 and 02)
- **N40, expiry (decision 11):** applied at login, on a quiet event and when a list opens, as the readme says. This is a bug fix, so it needs no opt-in.
- **N41:** each hook body is gated by its option (J3), so the option applies without a /reload.
- **N42:** talent links convert to a tag the filter language knows.
- **N45:** Import with Replace on guilds keeps the shipped rules.
- **N46 to N48:** listener errors are reported, the group warning list is fixed, and `/pss list` no longer hits a nil.
- **G21 and G26:** the Filters tab's redraw is throttled, and the guild rows' rule dim refreshes on `FILTERS_CHANGED`.
- **G27:** Dark menus grow to their content, capped at the screen height.
- **G28:** the Modern art check covers every atlas Modern draws.

### 2.6 Performance and tidy (3.4.2, 3.4.3)
Listed in section 4. Each stage is invisible and proven with `tui_compare.sh` identical in all three looks, plus measured numbers.

## 3. Constraints
- Baseline 02 and PSS 02 in full.
- J rules on every name and hook path: `M.PSS_IsSecret` before any compare, plus a restriction-CVar run (02 10.6).
- No timers as logic gates (C3).
- Zero cost when nothing upgrades.
- Counters never derived from log lines, and identical before and after every data step.
- Logging loads only when called.
- No new SavedVariables. The `purge` tombstone and `nextFilterId` live in existing tables.

## 4. Stages
Build numbers never reset. 3.4.1.31 is this plan's own build (docs and working rules only). One stage per PR, per session.

### Line 3.4.1: fixes and data
| Stage | Build | Change | Visible? | Validated by | State |
| --- | --- | --- | --- | --- | --- |
| Plan | 3.4.1.31 | This plan; working rules (one stage per session, context updated in every PR, state re-summarized at release, Dan's preferences in `11_PREFERENCES.md`); baseline v9; CLAUDE.md loads less | No | `check_rules.sh` | PR #119 |
| (Dan) | | Run the six `/dump` lines of 2.1 on Camelot and paste the output | | Confirms the cause before N1 | Waiting on Dan |
| N1 | 3.4.1.32 | `M.PSS_NormName`; the existing name helpers call it; `check_names.lua` | No | Every key on the four saves unchanged except the Camelot surname case | |
| N2 | 3.4.1.33 | Every name caller (2.1), multi-word `/pss add/remove/expire`, import with the managed check, runtime fields not flushed | Yes | On Camelot, "First Last" added from the menu, Ignore and `/pss add`; Retail unchanged; the restriction CVars run | |
| N3 | 3.4.1.34 | Builder fix and the shipped lists rebuilt | Yes (lists) | `check_packed`, `check_communities_seen`; size measured | |
| F1 | 3.4.1.35 | N40, N41, N42, N45, N46 to N48 | Yes | A harness case for each; in-game checks | |
| F2 | 3.4.1.36 | G21 with G26, G27, G28 | Yes (G27 in Dark) | `tui_compare.sh`: only the Dark menu height; garbage per filter block measured | |
| U1 | 3.4.1.37 | Upgrade registry, invisible: step 1 split and tagged, `RETIRED`, counts returned, version compare | No | Saves byte-identical on all four saves | |
| U2 | 3.4.1.38 | The upgrade report (2.4); `check_upgrade_report.lua` | Yes (once per update) | 10 cases; in game, the batch prints once and the next login prints nothing | |
| U3 | 3.4.1.39 | Forward compatibility (2.3): `M.PSS_SCHEMA` and its rules check, tolerant readers, the downgrade line, unusable rules reported and kept, `/pss export unused`, the export format version | Yes (only when a rule cannot be used) | Planted newer fields survive; a planted unknown filter tag is reported, kept and exported; a downgrade case | |
| S1 | 3.4.1.40 | `History.ClearOwner` and the purge tombstone; the six copies call it | No | Identical lines and counters; 5.6 ms to about 70 us | |
| S2 | 3.4.1.41 | Accessors for every field S3 drops; the rules-check grep | No | `tui_compare.sh` identical | |
| S3 | 3.4.1.42 | Upgrade step 8 (2.2): sparse records, cap, `memberCount`, Camelot repair, `showIgnoreDebug`, filter ids | Yes (report, smaller save) | Four saves: counters identical, sizes before and after; 3.4.0.29 run on a migrated save | |
| R | 3.4.1.43 | Release: version only; one summary of 3.4.1.30 to 3.4.1.42 from their PRs; `01_HANDOVER.md` re-summarized | | Dan confirms | |

### Line 3.4.2: core performance and tidy (builds continue)
| Stage | Change |
| --- | --- |
| P1 | Dead code N1 to N15: 61 localization strings, about 25 unused `M.*` exports, `V.needSorted`, the reload popup, the compat globals, `/pss test` |
| P2 | Event-driven GC and `loadWhenQuiet` without timers (L14; closes the known breach in 02 section 12) |
| P3 | Capture events only when needed (L15) |
| P4 | Chat path: N26 (option reads without the router), N28 (guild path), N35 (per-line tables), N31 (outbox trim), benchmarked |
| P5 | Duplicated logic into functions: N17 to N25 |
| P6 | Core placement: L20 plus N37 to N39, measured before and after |
| R | Release; `01_HANDOVER.md` re-summarized |

### Line 3.4.3: window tidy
| Stage | Change |
| --- | --- |
| W1 | G11 to G14, G24, G25, G29 |
| W2 | Logic to Libraries: G1 to G10 |
| W3 | Kit functions in all three looks, plus the kit preview: G15 to G20 |
| W4 | Redraw cost: G22, G23, measured on the 3.4.0.28 save |
| R | Release; `01_HANDOVER.md` re-summarized |

## 5. Decisions (Dan, 2026-10-08; all as recommended)
1. Three lines: 3.4.1 fixes and data, 3.4.2 core performance, 3.4.3 window tidy.
2. No ID generator for players and guilds; keep the `name-realm` key and make records sparse.
3. Custom filters get a never-reused integer id.
4. One upgrade step 8 for the whole data change, with one validation (D9 OK given).
5. The Camelot name repair runs on Camelot saves only; first-name-only entries are listed once in chat.
6. The shipped lists are rebuilt: 196 entries dropped, 16 converted.
7. Report lines only for features that changed, plus the cleanup line always.
8. Today's data-move messages are kept, and the report prints after them.
9. Everything prints at once at login.
10. A downgrade prints one line and keeps the newer record. **Dan's addition:** check every saved field and rule against the code that uses it, tell the player which rules are incompatible, offer to export them, and make the layout as forward compatible as possible so the saves are not readdressed again (2.3).
11. Expiry is applied at login and when a list opens (a bug fix).
12. The name cause is confirmed in game with `/dump` before N1.

## 6. Risks
| Risk | Cover |
| --- | --- |
| Counters drift | Every data stage checks the counters before and after on four saves and undoes the step on any difference |
| A reader misses a dropped field | Accessors, a rules-check grep, every tab's check in all three looks |
| The Camelot repair touches a Retail save | It runs only on a Camelot realm and client, and only for unit-discovered records |
| An older version strips newer data | Only `RETIRED` keys are deleted; unknown fields are kept (2.3) |
| Imports between versions | The export format version; every field filled; import keeps unknown fields |
