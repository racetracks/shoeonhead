> Appendix of the core uplift plan (`00_CORE_UPLIFT.md`, locked 2026-10-08). Findings as reviewed at 3.4.1.30; the plan's decisions win where they differ.

# E: name bugs on Camelot / WoW Forever (duplicates, realm suffix, "First Last")

Read-only investigation, 2026-10-08. Code at main (3.4.0.x / 3.4.1 line), files in
`/workspace/PourSocialScore`. Evidence from the real saves on scratch:
`SavedVariables/3.4.0.28/` (primary, Camelot, own realm `ClassicBetaPvP`) and
`SavedVariables/3.2.0-dev011/` (for comparison). Analysis scripts (throwaway,
Lua 5.1) are in the scratchpad `review/an*.lua`; they mirror `M.PSS_CanonPlayer`
exactly and decode the shipped lists in `PourSocialScore_Communities`.

## 0. The one root cause behind most of it

On the Camelot client (WoW Forever realms) a character is called "First Last".
The game hands that name to addons in two shapes:

| Source | Shape PSS receives | Example in the 3.4.0.28 save |
| --- | --- | --- |
| Chat event author, `/who` (`C_FriendList.GetWhoInfo().fullName`), chat links | `First Last` (own realm, no suffix) or `First Last-Realm` | blockLog owner `g:egg benedict-classicbetapvp`, `g:marika goldfield-classicbetapvp` |
| Unit APIs (`UnitName(unit)`) on target, mouseover, nameplates, group, unit menus | the surname arrives where the realm should be: `UnitName` returns `"First", "Last"` (or a "First-Last" string) | guild member key `thunder-bobby`, name `Thunder-Bobby`; delList `Hatti-Fnatt`, `Erlirrin-Softgale` |

Every PSS code path that builds a name from a unit joins the second value with
"-" as if it were a realm, so the surname becomes a fake realm. Every key
function (`M.PSS_NormalizePlayer`, `M.PSS_CanonPlayer`, the managed index) then
treats `first-last` and `first last-classicbetapvp` as two different people.
That single fact produces bug 1 (duplicates of shipped members), most of bug 2
(two spellings of the same person) and bug 3 (only the first name shown and
stored, and the entry never blocks).

The surname-in-realm-slot behaviour is inferred from the data (below), not from
client docs (baseline 02 J11: unverified). Confirm in game on Camelot with a
"First Last" target: `/dump UnitName("target")`, `/dump UnitFullName("target")`,
`/dump GetUnitName("target", true)`, `/dump UnitRealmRelationship("target")`,
`/dump GetPlayerInfoByGUID(UnitGUID("target"))`, `/dump GetNormalizedRealmName()`.

Proof it is the unit path: of the 499 stored members keyed `first-last` in the
3.4.0.28 save, 495 carry `faction` and `class`. Only `M.PSS_UpdateGuildMember`
with a `unit` argument writes `faction` (`PSS_GuildIgnoreList.lua:361-366`), and
only `M.PSS_UpdatePlayerUnit` (called by `scanUnit`) passes one. `/who` results
never set `faction`.

Proof it never blocks: all 174 blockLog owners in the 3.4.0.28 Logging save are
`first last-classicbetapvp` (174 of 174 contain a space; 0 are `first-last`),
and 0 of the 499 `first-last` member records has a block count. Chat authors
arrive as "First Last", so a `first-last` record can never match a chat line.

---

## Bug 1: shipped (managed) members stored again by discovery

### Code path
Discovered members are written into `PSS_GuildsDB.guildData[gkey].members[key]`
(key = `M.PSS_NormalizePlayer(name)`) by:

| Writer | File:line | Managed check before storing |
| --- | --- | --- |
| Unit discovery: `scanUnit` -> `M.PSS_UpdatePlayerUnit` -> `M.PSS_UpdateGuildMember` | `PSS_GuildIgnoreList.lua:89-118`, `307-331`, `334-372` | Yes (`322-327`): `M.PSS_IsManagedStaticMember(guildKey, canonPlayer(name))` |
| `/who` scan, Scan All, Guild Search save: `addWhoResultToGuildMember` | `PSS_GuildIgnoreList.lua:1348-1416` (check `1372-1385`) | Yes, `isStaticMember(rowKey, wck)` |
| Guild invite from an unscanned member: `inviteByGuild` | `PSS_GuildIgnoreList.lua:2426-2443` | Yes, `isStaticMember(bestKey, ick)` |
| Logout flush of changed shipped records: `M.PSS_FlushManaged` | `PSS_GuildIgnoreList.lua:921-950` | Writes on purpose (the delta: note, block choices, counts) |
| Import: guild members section | `PourSocialScore_Libraries/PSS_ImportExport.lua:343-357` | **None**; key taken verbatim from the export (`me.key`) |

The managed check itself is right, but it compares canonical keys
(`shippedOf(ck)`, `PSS_GuildIgnoreList.lua:627-648`, which needs `name-realm` and
looks the realm up in the shipped buckets). For a unit-discovered "First Last",
`ck` is `first-last`; the shipped entry is `first last-classicbetapvp`; the check
says "not shipped" and the member is stored. **Root cause: the name is wrong
before the dedupe runs (section 0), not a missing dedupe.**

Secondary causes:
1. `tools/PSS_BuildManaged.lua:352-361` (`full`) and `:48-56` accept any
   `X-Y` as name-realm, so the 2026-10-03 merges from SavedVariables shipped the
   unit-discovered `First-Last` keys too. The shipped data has 212 entries whose
   "realm" is a surname (realms table line 15 of `PSS_GuildIgnore_Managed.lua`:
   `"Styx", "Kekw", "Wife", "Youtube", ...`); 196 of them are also shipped in
   the correct `First Last-ClassicBetaPvP` form, 16 only in the bad form. Those
   212 never match chat.
2. `M.PSS_FlushManaged` saves runtime-only fields with the record: 254 stored
   members carry `_canon`, `_gkey`, `_managed` (one even `_virtual`); they are
   rebuilt at run time and only cost save size (`DROP_ALWAYS`,
   `PSS_GuildIgnoreList.lua:464`, does not list them).
3. Import stores members without the managed check or key normalisation.

### Evidence (3.4.0.28 save; 3.2.0-dev011 in brackets)
- Stored members: 1208 (1088), 1138 on managed rows.
- Same canonical key stored AND shipped: 393 (353). All are intended deltas:
  389 have block counts, 2 notes, 3 block choices; 254 were written by
  `PSS_FlushManaged`, 139 by discovery before the 2026-10-03 lists shipped them
  (136 of those have counts). Exact-key pure duplicates: 0 (the 2 under another
  row, `berek galewyn`, `anne flankz`, are correctly tombstoned in
  `managedGone` after a guild move).
- **Real duplicates (cross-form): 184 (169)** stored `first-last` records whose
  `First Last-ClassicBetaPvP` form is shipped (179 under the same guild row, 5
  under another), plus 48 (41) whose space form is also stored. 66 `first-last`
  records were created on 2026-10-08 (for example `olympus xxvi | fosta-poo`,
  `olympus vii | obey-trueshot`, whenBlocked `08 Oct 2026 ...`), so the bug is
  live in 3.4.0.x.
- Total `first-last` member records: 499 (452), every one dead weight for
  blocking.

### Fix
1. One normaliser used before any check or store (section "Shared fix").
2. Keep the managed check where it is; it works once the name is right. Add it
   to the import (`PSS_ImportExport.lua:343`): canonical key, then
   `M.PSS_IsManagedStaticMember(gkey, ck)` -> merge into the shipped record
   (`M.PSS_ManagedRecord` + `M.PSS_KeepManaged`) instead of storing a copy.
3. `PSS_FlushManaged`: strip `_canon`, `_gkey`, `_managed`, `_virtual` before
   writing (add them to the flush, not to `DROP_ALWAYS`, since the live record
   needs them); the record is recognised as shipped by its key on load.
4. Builder: reject (or convert, see bug 2) a `Name-X` whose `X` is not a known
   realm of the data set; rebuild the lists, dropping the 212 bad entries (the
   196 with a correct twin are pure drops; the 16 others are converted).

---

## Bug 2: names stored with and without "-Realm", and in two spellings

### Every place a name is built or normalised
| Function / site | File:line | What it does | Problem |
| --- | --- | --- | --- |
| `M.PSS_NormalizePlayer` (storage key) | `PSS_ChatBlock.lua:71-83` | trim; bare -> `-<GetNormalizedRealmName>`; strips spaces in realm; lower | Keeps double spaces in the name part (Canon collapses them) |
| `M.PSS_CanonPlayer` (match key) | `PSS_ChatBlock.lua:86-95` | as above, also strips `'`, collapses spaces | Two key functions that disagree on `"A  B"` and `Aman'Thul` |
| `M.PSS_DisplayPlayer` | `PSS_ChatBlock.lua:115-118` | `Proper(addServer(name))` | Realm spelling from `V.serverName` |
| `M.addServer` / `V.serverName` | `PSS_Globals.lua:393-401`, `408` | bare -> `-Proper(GetRealmName())` = `-Classicbetapvp` | Differs from `ownRealm()` (`GetNormalizedRealmName` = `ClassicBetaPvP`): stored `name` says `Classicbetapvp`, shipped says `ClassicBetaPvP` |
| `M.removeServer(name, strict)` | `PSS_Globals.lua:368-391` | strict strips any realm | Shows `First` for `First-Last` (history, Events: `PSS_History.lua:77`, `PSS_EventsView.lua:413`) |
| `M.Proper(name, okSpaces)` | `PSS_Globals.lua:90-129` | keeps spaces only when there is a dash or okSpaces | A bare `First Last` without okSpaces becomes `FirstLast` |
| `M.PSS_UnitFullName(unit)` | `PSS_ChatBlock.lua:45-53` | `UnitName` -> `name-server` | Surname as realm on Camelot (section 0) |
| `scanUnit` | `PSS_GuildIgnoreList.lua:106-117` | own join, `realm ~= GetNormalizedRealmName()` | Same; source of the 499 records |
| `M.PSS_UnitMenuPlayer` | `PSS_BlizzardUI.lua:231-247` | own join from `UnitName` or `contextData.name/server` | Same (bug 3) |
| `M.PSS_AddOrDelIgnore` | `PSS_PlayerIgnoreList.lua:818-922` | resolves a realm for a bare name from group / chat history | Own copy of the join |
| `addFromBlizzard` (Blizzard Ignore hook) | `PSS_PlayerIgnoreList.lua:946-958` | `Proper(addServer(name))` of what Blizzard was given | Takes Blizzard's `First-Last` as is |
| `addWhoResultToGuildMember` | `PSS_GuildIgnoreList.lua:1349`, `1367`, `1398`, `1407` | `info.fullName` (bare on own realm) | Correct; this is the form chat uses |
| Whois chat-line fallback | `PSS_Whois.lua:262` | `|Hplayer:([^:|]+)` | Correct |
| Roster warning | `PourSocialScore.lua:207-211` | `GetUnitName(prefixN, true)` | Same unit issue (display only) |
| Import members | `PSS_ImportExport.lua:344` | `me.key` verbatim if it has a dash | No normalisation |

### Evidence (3.4.0.28)
- Storage keys: 1208 of 1208 carry a suffix (no bare keys; normalisation adds
  the own realm). The bare names users see are display: `removeServer(...,
  true)` strips the suffix in history and Events, and a `First-Last` record
  displays as "First" there.
- 487 distinct "realm" parts in member keys; only `classicbetapvp` (709) is a
  realm. The other 499 keys are `first-last` (top: `pewpew` 3, `forever` 3,
  `baggins`, `liongard`, `me`, `dawg`, `hunt`, `rock`, `warr`, `bane`, `poo` 2
  each).
- The same person in both forms: 48 stored pairs (`first-last` and
  `first last-classicbetapvp`), plus 184 against the shipped list (bug 1).
- First names shared by several fake-realm records (cannot be merged without
  the full name): `big-leon / big-tuunuh / big-attitude / big-lezs`,
  `thunder-bobby / thunder-cnntt`, `sneaky-allen / sneaky-stahr`, ... (7 groups).
- Player list delList: `Erlirrin Softgale-Classicbetapvp` and
  `Erlirrin-Softgale` (same person, both forms), `Hatti-Fnatt`,
  `Archdruid-Classicbetapvp` (first name only, bug 3).
- Realm casing: stored `name` `Stardazzle Sparklenova-Classicbetapvp`
  (`V.serverName`) against shipped `...-ClassicBetaPvP`; keys agree (lower case),
  display does not.

### Fix: one normaliser in core
`PSS_ChatBlock.lua` (core; it is on the chat path already):

```lua
-- M.PSS_NormName(name [, realm]) -> display "First Last-Realm", key, canon
-- or nil when secret / empty. The one place a name and realm are joined.
```
- Input either a full string or `(name, realm)` from a unit API.
- Secret check first (`M.PSS_IsSecret`, 02 section 10.1), return nil.
- Trim, collapse inner spaces in the name part.
- Realm: empty -> own realm (`ownRealm()`, `GetNormalizedRealmName`); else
  stripped of spaces; **on a client where the second value can be a surname**
  (Camelot, feature-detected per baseline 02 B6 through `WOW_PROJECT_ID` guarded
  for nil, or by checking that the "realm" is not a realm the client knows:
  `UnitRealmRelationship(unit) == LE_REALM_RELATION_SAME`, or
  `GetPlayerInfoByGUID(guid)` realm empty) join it to the name with a space and
  use the own realm.
- Display realm from one source (`ownRealm()` with `M.prettyServer`), never
  `V.serverName`.
- Returns display, key (`NormalizePlayer` rule) and canon (`CanonPlayer` rule);
  `NormalizePlayer` and `CanonPlayer` become thin wrappers so existing callers
  keep working. Better still, make the storage key equal the canon key (one
  key); that is a layout change (see Upgrade).

Replace the joins in `scanUnit`, `M.PSS_UnitFullName`, `M.PSS_UnitMenuPlayer`,
`M.PSS_AddOrDelIgnore`, `addFromBlizzard`, the roster warning and the import
with `M.PSS_NormName`. Measured cost to add: a few hundred bytes resident
(measure with `loadfile` + `collectgarbage("count")`, baseline C17).

---

## Bug 3: "First Last" stored as the first name only

### Paths and where the name breaks
1. **Right-click unit menu (PSS entry)**: `M.PSS_UnitMenuPlayer`
   (`PSS_BlizzardUI.lua:227-264`). `target, server = UnitName(contextData.unit)`
   (`:233`) gives `"First", "Last"` on Camelot; `:244-248` builds
   `"First-Last"`; `M.PSS_AddOrDelIgnore` (`PSS_PlayerIgnoreList.lua:818`) sees a
   dash, skips realm resolution, and `M.PSS_AddIgnore(name, nil, true)` stores
   `First-Last`. Shown as "First" wherever the realm is stripped, never blocks
   (canon `first-last` against chat author `first last-classicbetapvp`), and
   with Blizzard sync on, `BlizzardAddIgnore(M.removeServer(name))` sends
   `First-Last` to the server (wrong player or refused). Evidence: delList
   `Hatti-Fnatt`, `Erlirrin-Softgale`.
2. **Blizzard's own "Ignore" menu entry and `/ignore`**: PSS only post-hooks
   `C_FriendList.AddIgnore` / `AddOrDelIgnore` (`PSS_PlayerIgnoreList.lua:1003-1007`,
   handlers `:961-990`, pending toggle read at `:992-1001`) and stores what
   Blizzard was given through `addFromBlizzard` (`:946-958`). Blizzard's unit
   popup builds its name from the same unit API, so the same `First-Last`
   arrives (unverified: confirm with `/dump` above; PSS cannot change what
   Blizzard sends, J2/J3, but it can normalise what it stores).
3. **`/pss add` with a target and no text**: `M.ignoreFromCmd`
   (`PSS_PlayerIgnoreList.lua:585-599`) takes `M.PSS_UnitFullName("target")` and
   calls `M.PSS_AddIgnore(argStr)` **without `exactName`**, so the name goes
   through `M.PSS_SplitNameArg` (`PSS_Globals.lua:136-152`). When the client
   returns a bare `"First Last"` (no dash anywhere in the first 3 words) the rule
   "anything else: the first word is the name" stores **`First`** with note
   `Last`. Exact truncation point: `PSS_Globals.lua:145-152` (`last = 1`).
   Evidence: delList `Archdruid-Classicbetapvp`.
4. **Typed commands without quotes**: `/pss add First Last`,
   `/pss remove First Last` (`PSS_Commands.lua:222-224`),
   `/pss expire First Last 30` (`:236-256`) all store or look up `First` by the
   same split (documented: quotes or a realm are needed). `M.PSS_SlashPSS`
   splits on `%S+` (`PSS_Commands.lua:127-129`) only for keywords; names are
   re-split by `PSS_SplitNameArg`.
5. Side effect of the same split: a realm with a space (`Bob-Area 52`, from
   `UnitName` on Retail if it returns the realm with spaces; unverified) passed
   without `exactName` stores `Bob-Area` and reads `52` as days.

Paths that are already right: the window's Add Player and its target add
(`M.PSS_AddPlayer`, `PSS_PlayerIgnoreList.lua:710-714`, `exactName = true`;
`PSS_PlayerView.lua:143-160`), row menus (`PSS_RowMenus.lua:177-195`), `/who`
(Player Search, Guild scans). Other whitespace splits checked and not about
names: `PSS_ChatFilters.lua:770` (filter words), `PSS_WhoisHarvest.lua:118`
(/who filter tokens), `PSS_Globals.lua:40` (dates), `PSS_ImportExport.lua:143`
(export header). `M.Proper` without `okSpaces` drops spaces from a bare name
(`PSS_Globals.lua:117-125`): every current caller adds a realm first, so it is
safe today, but `M.PSS_NormName` should own this.

### Fix
1. Unit menu, `PSS_UnitFullName`, `scanUnit`, `addFromBlizzard`: build the name
   through `M.PSS_NormName(name, realm)` (Camelot surname rule).
2. `M.ignoreFromCmd`: a target name is a whole name; call
   `M.PSS_AddIgnore(name, nil, true)` (exactName) for the target case.
3. `M.PSS_SplitNameArg`: on Camelot (or always) treat two leading capitalised
   words with no digits as "First Last" when the second word is not a number;
   cheaper and safer: on a bare multi-word input, if `First Last` matches a
   listed or known person (`M.PSS_ListedPosition(canon)`, a guild member or a
   shipped member), take both words. Keep quotes as the explicit form and say so
   in `/pss help`.
4. `addFromBlizzard` / `removeFromBlizzard`: normalise, and on Camelot look the
   name up in both forms when removing.

---

## Shared fix plan (one build each, baseline 10)
1. **Groundwork (no visible change):** `M.PSS_NormName` in
   `PSS_ChatBlock.lua`; `NormalizePlayer`, `CanonPlayer`, `DisplayPlayer`,
   `PSS_UnitFullName` call it; harness proves every existing key unchanged on
   the three old saves and 3.4.0.28 (except the Camelot surname case).
2. **Callers:** `scanUnit`, unit menu, AddOrDelIgnore, Blizzard hooks,
   `/pss add` target (exactName), roster warning, import (normalise + managed
   check). `PSS_FlushManaged` strips runtime fields.
3. **Upgrade step 8** (SavedVariables content change; Dan's OK first, baseline
   D9; validated on every real save):
   - Guild members: for each key `a-b` where `b` is not the own realm (or any
     realm in `GetNormalizedRealmName` / the shipped realm numbers 1-2): if
     `a b-<own realm>` is shipped in the same guild, merge the record into the
     shipped delta (`mergeMemberRecord`, `PSS_GuildIgnoreList.lua:1924-1950`
     shape) and drop it if nothing is left; if stored in the space form, merge
     into it; else re-key it to `a b-<own realm>` with `name` re-displayed.
     Expected on 3.4.0.28: 184 merged into shipped (all with no data, so
     dropped), 48 merged into stored twins, about 267 re-keyed.
   - Only on a Camelot save (own realm `ClassicBetaPvP*`, or the client check):
     a Retail save has real realms with these shapes and must not be touched.
     Safety rule: re-key only when the record has `faction` (unit-discovered)
     and no `_playerKey` from /who.
   - Player list (`ignoreList`, `delList`, `playerData` keys) and the blockLog
     owners `p:` / `g:`: same conversion; `Archdruid-Classicbetapvp`-style
     truncated entries cannot be repaired (the surname is lost): list them once
     in chat for the user.
   - Drop `_canon`, `_gkey`, `_managed`, `_virtual` from stored members (254).
   - Run the managed tidy (`PSS_FlushManaged` drop pass) only with the lists
     loaded; today the drop pass is a no-op when the Communities part is not
     loaded (`isStaticMember` -> `shippedOf` returns nil with no lists).
4. **Builder and lists:** `tools/PSS_BuildManaged.lua` rejects or converts
   surname-as-realm names; rebuild `PSS_GuildIgnore_Managed.lua` (212 entries:
   196 dropped, 16 converted); re-measure the data file size.
5. **Commands:** `PSS_SplitNameArg` multi-word names, help text.

## Harness checks to add (`tools/harness/`)
- `check_names.lua` (new): table-driven `M.PSS_NormName` cases with the stub's
  `UnitName` returning `("First", "Last")` on a Camelot stub and
  `("Name", "Area 52")` on Retail: `"First Last"`, `"first  last"`,
  `"First Last-ClassicBetaPvP"`, `"First-Last"` (Camelot: one person; Retail:
  realm Last), `"Name-Aman'Thul"`, secret values return nil (via the stub's
  `issecretvalue`). Asserts NormalizePlayer and CanonPlayer agree with it and
  that display, key and canon round-trip.
- `check_players.lua`: unit menu add, `/pss add` with a "First Last" target,
  Blizzard `AddOrDelIgnore("First-Last")` hook on Camelot: the stored entry is
  `First Last-<realm>`, `M.PSS_IsPlayerListed("First Last")` is true and a chat
  line from "First Last" is blocked.
- `check_communities_seen.lua`: a mouseover of a shipped "First Last" member on
  the Camelot stub stores nothing (member count unchanged).
- `check_guilds.lua`: `/who` result and unit sighting of the same person give
  one record.
- Import: a guild export holding a shipped member adds no stored copy.
- Upgrade step 8 in `validate_all.sh` on 3.4.0.28 and 3.2.0-dev011: zero
  member keys whose realm part is not a realm, zero cross-form duplicates,
  shipped deltas kept with their counts and notes (389 counts, 2 notes on
  3.4.0.28), save size smaller; and on the 2.0.44 and 3.0.0 saves (Retail
  realms) nothing changes.
- `check_packed.lua`: every shipped name's realm is in the data set's realm
  list (`ClassicBetaPvP`, `ClassicBetaPvP2`, ...), none is a surname.

## Numbers at a glance (3.4.0.28 save)
| What | Count |
| --- | --- |
| Stored guild members | 1208 (1138 on managed rows) |
| Keyed `first-last` (surname as realm), all from unit sightings | 499 (66 created 2026-10-08) |
| ... of which duplicate a shipped `First Last` | 184 |
| ... of which duplicate a stored `First Last` | 48 |
| ... with any block count | 0 |
| Stored and shipped with the same key (intended deltas) | 393 (254 carry runtime fields) |
| blockLog owners in the `first last-realm` form | 174 of 174 |
| Shipped entries with a surname as realm | 212 (196 have a correct twin) |
