# TOC Format & Client Version <-> Interface Number Map

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Sources: https://warcraft.wiki.gg/wiki/TOC_format , https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID ,
> https://warcraft.wiki.gg/wiki/Public_client_builds , https://warcraft.wiki.gg/wiki/API:GetBuildInfo ,
> https://warcraft.wiki.gg/wiki/API_change_summaries - compiled 2026-10-08.

**Values change every patch.** Always confirm in-game with:

```
/dump select(4, GetBuildInfo())
```

Live lists: https://warcraft.wiki.gg/wiki/Public_client_builds and
https://www.townlong-yak.com/framexml/builds (FrameXML builds and TOC numbers).

---

## Part A - Current game types (snapshot 2026-10-08)

### A.1 Live and test interface numbers

| Game type (TOC / `[Game]`) | Product | Channel | Client version | **Interface** | Build (approx.) |
|---|---|---|---|---|---|
| `standard` | Retail - *Midnight* | Live | 12.1.0 | **120100** | 69814 |
| `standard` | Retail - *Midnight* | PTR | 12.1.0 | 120100 | 69587 |
| `standard` | Retail - *Midnight* | PTR 2 / Test | 12.1.5 | 120105 | 69848 |
| `standard` | Retail - *Midnight* | Alpha/Beta | 12.0.1 | 120001 | 66220 |
| `camelot` | *World of Warcraft: Forever* | Beta | 1.60.1 | **16001** | 69893 |
| `mists` | Mists of Pandaria Classic | Live | 5.5.4 | **50504** | 69585 |
| `mists` | Mists of Pandaria Classic | PTR | 5.5.4 | 50504 | 67849 |
| `cata` | Cataclysm Classic | (last listed) | 4.4.2 | **40402** | - |
| `wrath` | Titan Reforged (Wrath-based) | Live | 3.80.2 | **38002** | 69874 |
| `wrath` | Wrath of the Lich King Classic | (last listed; China client) | 3.4.5 | **30405** | - |
| `tbc` | Burning Crusade Classic Anniversary Edition | Live | 2.5.6 | **20506** | 69795 |
| `vanilla` | Classic Era (incl. Anniversary/SoD realms) | Live | 1.15.9 | **11509** | 69722 |
| `vanilla` | Classic Era | Test | 1.15.8 | 11508 | - |

Notes:
- The `camelot` game type and the `_Camelot` TOC suffix are only recognized by *Forever* and
  **may change before launch**.
- Titan Reforged is a Wrath-family product and uses the `wrath` game type (and `_Wrath` suffix),
  but its interface number is in the 38xxx range.
- Plunderstorm (`plunderstorm` / `wowlabs`) and Talebound (`wowhack`) are Mainline-family
  game types that may restrict third-party addons.

### A.2 Recommended multi-client TOC line (current)

```toc
## Interface: 120100, 50504, 40402, 38002, 30405, 20506, 11509
```

(Drop any you don't support. Comma-separated interfaces require a client that includes the
Modern 10.2.7 TOC changes - all current clients do.)

---

## Part B - Interface number encoding

**Formula (modern):** `interface = major x 10000 + minor x 100 + patch`

| Client version | Interface |
|---|---|
| 12.1.0 | 120100 |
| 12.0.7 | 120007 |
| 5.5.4 | 50504 |
| 3.80.2 | 38002 (minor "80" -> 8000) |
| 1.60.1 | 16001 (minor "60" -> 6000) |
| 1.15.9 | 11509 |

**Historical caveat (Retail before ~9.0):** older Retail clients frequently did **not** bump the
interface number for "x.y.5"-style minor patches, and expansion-final patches used `...00` endings
(e.g. 3.3.5 used 30300, not 30305). The formula is reliable for Retail from **9.0.1 onward** and
for every modern Classic client. For older Retail, see Part D (legacy values flagged as
unverified in this crawl).

---

## Part C - Full client-version -> interface map (modern era)

Legend: **yes** = value directly observed in crawled sources; **calc** = computed from the formula,
which is exact for these clients. All patch numbers come from the wiki's
*API change summaries* index.

### C.1 Retail (Mainline, `standard` game type, `WOW_PROJECT_MAINLINE` = 1)

| Expansion (`LE_EXPANSION_*`) | Patch | Interface | |
|---|---|---|---|
| Midnight (11) | 12.1.5 *(PTR)* | 120105 | yes |
| | 12.1.0 | 120100 | yes |
| | 12.0.7 | 120007 | yes |
| | 12.0.5 | 120005 | calc |
| | 12.0.1 | 120001 | yes |
| | 12.0.0 | 120000 | calc |
| The War Within (10) | 11.2.7 | 110207 | yes |
| | 11.2.5 | 110205 | calc |
| | 11.2.0 | 110200 | calc |
| | 11.1.7 | 110107 | calc |
| | 11.1.5 | 110105 | calc |
| | 11.1.0 | 110100 | calc |
| | 11.0.7 | 110007 | calc |
| | 11.0.5 | 110005 | calc |
| | 11.0.2 | 110002 | yes |
| | 11.0.0 | 110000 | yes |
| Dragonflight (9) | 10.2.7 | 100207 | yes |
| | 10.2.6 | 100206 | calc |
| | 10.2.5 | 100205 | calc |
| | 10.2.0 | 100200 | calc |
| | 10.1.7 | 100107 | calc |
| | 10.1.5 | 100105 | calc |
| | 10.1.0 | 100100 | calc |
| | 10.0.7 | 100007 | calc |
| | 10.0.5 | 100005 | calc |
| | 10.0.2 | 100002 | calc |
| | 10.0.0 | 100000 | calc |
| Shadowlands (8) | 9.2.7 | 90207 | calc |
| | 9.2.5 | 90205 | calc |
| | 9.2.0 | 90200 | calc |
| | 9.1.5 | 90105 | calc |
| | 9.1.0 | 90100 | calc |
| | 9.0.5 | 90005 | calc |
| | 9.0.2 | 90002 | yes |
| | 9.0.1 | 90001 | calc |

### C.2 Forever (`camelot`, `WOW_PROJECT_CAMELOT` = 18, expansion level 0)

| Patch | Interface | |
|---|---|---|
| 1.60.1 *(Beta)* | 16001 | yes |

Forever 1.60.1 includes all Modern TOC changes up to 12.1.5.

### C.3 Mists of Pandaria Classic (`mists`, `WOW_PROJECT_MISTS_CLASSIC` = 19, `LE_EXPANSION_MISTS_OF_PANDARIA` = 4)

| Patch | Interface | |
|---|---|---|
| 5.5.4 | 50504 | yes |
| 5.5.3 | 50503 | calc |
| 5.5.2 | 50502 | calc |
| 5.5.1 | 50501 | calc |
| 5.5.0 | 50500 | yes |

### C.4 Cataclysm Classic (`cata`, `WOW_PROJECT_CATACLYSM_CLASSIC` = 14, `LE_EXPANSION_CATACLYSM` = 3)

| Patch | Interface | |
|---|---|---|
| 4.4.2 | 40402 | yes |
| 4.4.1 | 40401 | calc |
| 4.4.0 | 40400 | yes |

### C.5 Titan Reforged (`wrath`, `WOW_PROJECT_WRATH_CLASSIC` = 11, `LE_EXPANSION_WRATH_OF_THE_LICH_KING` = 2)

| Patch | Interface | |
|---|---|---|
| 3.80.2 | 38002 | yes |
| 3.80.1 | 38001 | yes |
| 3.80.0 | 38000 | calc |

### C.6 Wrath of the Lich King Classic (`wrath`, `WOW_PROJECT_WRATH_CLASSIC` = 11)

| Patch | Interface | |
|---|---|---|
| 3.4.5 *(China client)* | 30405 | yes |
| 3.4.4 *(China client)* | 30404 | calc |
| 3.4.3 | 30403 | calc |
| 3.4.2 | 30402 | calc |
| 3.4.1 | 30401 | calc |
| 3.4.0 | 30400 | calc |

### C.7 Burning Crusade Classic & Anniversary (`tbc`, `WOW_PROJECT_BURNING_CRUSADE_CLASSIC` = 5, `LE_EXPANSION_BURNING_CRUSADE` = 1)

| Patch | Product | Interface | |
|---|---|---|---|
| 2.5.6 | Anniversary Edition | 20506 | yes |
| 2.5.5 | Anniversary Edition | 20505 | calc |
| 2.5.4 | BC Classic (2021-22) | 20504 | calc |
| 2.5.3 | BC Classic | 20503 | calc |
| 2.5.2 | BC Classic | 20502 | calc |
| 2.5.1 | BC Classic | 20501 | calc |

### C.8 Classic Era (`vanilla`, `WOW_PROJECT_CLASSIC` = 2, `LE_EXPANSION_CLASSIC` = 0)

| Patch line | Interface pattern | Verified examples |
|---|---|---|
| 1.15.0 - 1.15.9 | 11500 - 11509 | 11503 yes, 11508 yes, 11509 yes |
| 1.14.0 - 1.14.4 | 11400 - 11404 | calc |
| 1.13.2 - 1.13.7 | 11302 - 11307 | calc |

---

## Part D - Legacy Retail (pre-9.0) - reference only, **unverified in this crawl**

These are long-standing community values for expansion-final patches. Confirm against
https://www.townlong-yak.com/framexml/builds before relying on them.

| Expansion | Final patch | Interface (legacy) |
|---|---|---|
| Vanilla | 1.12.x | 11200 |
| The Burning Crusade | 2.4.3 | 20400 |
| Wrath of the Lich King | 3.3.5 | 30300 |
| Cataclysm | 4.3.4 | 40300 |
| Mists of Pandaria | 5.4.8 | 50400 |
| Warlords of Draenor | 6.2.4 | 60200 |
| Legion | 7.3.5 | 70300 |
| Battle for Azeroth | 8.3.7 | 80300 |

---

## Part E - Runtime identification

### E.1 `WOW_PROJECT_ID`

| Value | Constant | Product(s) |
|---|---|---|
| 1 | `WOW_PROJECT_MAINLINE` | Retail |
| 2 | `WOW_PROJECT_CLASSIC` | Classic Era, Classic 20th Anniversary |
| 3 | `WOW_PROJECT_WOWLABS` | Plunderstorm |
| 5 | `WOW_PROJECT_BURNING_CRUSADE_CLASSIC` | BC Classic, BC Anniversary |
| 11 | `WOW_PROJECT_WRATH_CLASSIC` | Wrath Classic, Titan Reforged |
| 14 | `WOW_PROJECT_CATACLYSM_CLASSIC` | Cataclysm Classic |
| 18 | `WOW_PROJECT_CAMELOT` | Forever |
| 19 | `WOW_PROJECT_MISTS_CLASSIC` | MoP Classic |

Constants may be **nil** on clients that predate them - compare against the constant, never
against a bare number, and guard with `and`:

```lua
local function IsProject(c) return c ~= nil and WOW_PROJECT_ID == c end
local IS_RETAIL  = IsProject(WOW_PROJECT_MAINLINE)
local IS_FOREVER = IsProject(WOW_PROJECT_CAMELOT)
local IS_MISTS   = IsProject(WOW_PROJECT_MISTS_CLASSIC)
local IS_CATA    = IsProject(WOW_PROJECT_CATACLYSM_CLASSIC)
local IS_WRATH   = IsProject(WOW_PROJECT_WRATH_CLASSIC)
local IS_TBC     = IsProject(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local IS_ERA     = IsProject(WOW_PROJECT_CLASSIC)
```

### E.2 `LE_EXPANSION_*`

| Value | Enum | Expansion |
|---|---|---|
| 0 | `LE_EXPANSION_CLASSIC` | Vanilla / Classic / Forever |
| 1 | `LE_EXPANSION_BURNING_CRUSADE` | TBC |
| 2 | `LE_EXPANSION_WRATH_OF_THE_LICH_KING` | Wrath |
| 3 | `LE_EXPANSION_CATACLYSM` | Cataclysm |
| 4 | `LE_EXPANSION_MISTS_OF_PANDARIA` | MoP |
| 5 | `LE_EXPANSION_WARLORDS_OF_DRAENOR` | WoD |
| 6 | `LE_EXPANSION_LEGION` | Legion |
| 7 | `LE_EXPANSION_BATTLE_FOR_AZEROTH` | BfA |
| 8 | `LE_EXPANSION_SHADOWLANDS` | Shadowlands |
| 9 | `LE_EXPANSION_DRAGONFLIGHT` | Dragonflight |
| 10 | `LE_EXPANSION_WAR_WITHIN` | The War Within |
| 11 | `LE_EXPANSION_MIDNIGHT` | Midnight |

`LE_EXPANSION_LEVEL_CURRENT` gives the client's expansion; `GetExpansionLevel()` returns the
account's level.

### E.3 `GetBuildInfo()`

```lua
-- Mainline:
local version, build, date, interface, localizedVersion, buildInfo = GetBuildInfo()
-- Classic adds a 7th return, currentVersion, formatted like an interface number (e.g. "11505")
```

### E.4 TOC variables read back at runtime

```toc
## X-Family: [Family]
## X-Game: [Game]
```

```lua
local Family = C_AddOns.GetAddOnMetadata("MyAddOn", "X-Family") -- "Mainline" | "Classic"
local Game   = C_AddOns.GetAddOnMetadata("MyAddOn", "X-Game")   -- "Standard", "Mists", "TBC", "Vanilla", ...
```

---

## Part F - TOC file rules

- Extension `.toc`; **file name must equal folder name** (`AddOns\Foo\Foo.toc`).
- Lines may be: `## Directive: Value` (metadata), `# comment`, or a file path.
- Only Lua and XML files are listed; loaded top-to-bottom.
- XML can load more files with `<Script file=...>` / `<Include file=...>`.
- Prefer backslashes (`\`) in paths (Include compatibility).
- Whitespace before `#` makes the line a filename; whitespace around metadata values is trimmed.
- Max 1024 characters per line read.
- `/reload` detects new files and TOC changes; deleting/renaming a loaded TOC requires restart.
- If a directive appears more than once, the **last** applicable one wins, except the
  list-appending directives noted below.

---

## Part G - TOC file-name suffixes (per-game TOCs)

The client first looks for a game-type-specific TOC, then a family TOC, then the unsuffixed TOC.

| Game type | Suffix(es) |
|---|---|
| `standard` (Midnight) | `_Standard.toc` *(added 12.1.5 PTR)* |
| `camelot` (Forever) | `_Camelot.toc` *(may change)* |
| `mists` | `_Mists.toc` |
| `cata` | `_Cata.toc` |
| `wrath` (Wrath Classic & Titan Reforged) | `_Wrath.toc`, legacy `-WOTLK.toc` |
| `tbc` | `_TBC.toc`, legacy `-BCC.toc` (**no longer supported from 2.5.5**) |
| `vanilla` | `_Vanilla.toc` |
| `plunderstorm` / `wowlabs` | `_Plunderstorm.toc`, `_WoWLabs.toc` |
| `wowhack` (Talebound) | `_WoWHack.toc` |

| Family | Members | Suffix |
|---|---|---|
| `mainline` | standard, camelot, plunderstorm, wowlabs, wowhack | `_Mainline.toc` |
| `classic` | vanilla, tbc, wrath, cata, mists | `_Classic.toc` |

- Game-type suffixes beat family suffixes (`_Standard` beats `_Mainline` on Midnight).
- Since Cataclysm Classic 4.4.0 / Titan 3.80.0 / Anniversary 2.5.5, `_Classic.toc` loads on
  **all** Classic clients, not just Era.
- The wiki recommends comma-separated `## Interface` and conditional directives over separate
  per-game TOC files where possible.

---

## Part H - Conditional directives and variables

### H.1 Conditions (append to a file line or a metadata line)

| Condition | Effect |
|---|---|
| `[AllowLoadGameType a, b]` | Only load in listed game types / families |
| `[ExcludeLoadGameType a, b]` | Never load in listed game types / families (12.0.0+) |
| `[AllowLoadTextLocale enUS, frFR]` | Only for these client locales (11.2.0+) |
| `[Bootstrap]` | Only during the bootstrap step of a LoadOnDemand addon |
| `[AllowLoad ...]`, `[AllowLoadEnvironment ...]`, `[LoadIntoEnvironment ...]` | Blizzard-only in practice (glue / secure environment) |

- Per-file conditions: 11.1.5+. Per-metadata conditions: 12.0.7+.
- Values are case-insensitive. Place conditions at the **end** of the line for compatibility.
- **Gotcha:** if *none* of the listed game types are recognized by the client, an
  `AllowLoadGameType` condition is treated as **satisfied**. Pair new/unrecognized game types
  with `[ExcludeLoadGameType ...]` to be safe.

```toc
## Title: My Cool AddOn
## Title: My Cool AddOn (Classic) [AllowLoadGameType classic]
StandardOnly.lua [AllowLoadGameType standard]
ForeverOnly.lua [AllowLoadGameType camelot][ExcludeLoadGameType standard, classic]
VanillaOrTBC.lua [AllowLoadGameType vanilla, tbc]
```

### H.2 Variables (expand inside paths and metadata)

| Variable | Expands to |
|---|---|
| `[Family]` | `Mainline` or `Classic` |
| `[Game]` | `Standard`, `Camelot`, `Mists`, `Cata`, `Wrath`, `TBC`, `Vanilla`... |
| `[TextLocale]` | `enUS`, `deDE`, `frFR`... (11.2.0+) |

```toc
[Family]\Core.lua
[Game]\Specific.lua
Locales\[TextLocale].lua
```

---

## Part I - Directive reference

### I.1 Interface
`## Interface: 120100[, 50504, ...]` - comma-separated list since 10.2.7.

### I.2 Display (all may be localized with `-xxXX`, e.g. `Title-deDE`; put the unlocalized fallback first; values accept `|c...|r` colour codes)

| Directive | Purpose |
|---|---|
| `Title` | Name in AddOn List |
| `Notes` | Tooltip text |
| `Category` | Collapsible header in AddOn List (11.1.0+); use the translated names on https://warcraft.wiki.gg/wiki/Addon_Categories |
| `Group` | Name of the parent addon to group under (11.1.0+); auto-deduced for prefix-named addons with a dependency relation |
| `IconTexture` | Texture path for AddOn List icon (10.1.0+) |
| `IconAtlas` | Atlas name icon; lower priority than IconTexture (10.1.0+) |

### I.3 Addon compartment (Retail/Forever, 10.1.0+)

| Directive | Value |
|---|---|
| `AddonCompartmentFunc` | **Required** to appear; global function name called on click |
| `AddonCompartmentFuncOnEnter` | Global function on hover |
| `AddonCompartmentFuncOnLeave` | Global function on un-hover |

### I.4 Loading

| Directive | Notes |
|---|---|
| `LoadOnDemand: 1` | Load only when `C_AddOns.LoadAddOn` is called |
| `Dependencies` (aliases `RequiredDeps`, any word starting `Dep`) | Must load first; **appends** if repeated |
| `OptionalDeps` | Load first if present |
| `LoadWith` | Load when listed addon loads; implies LoadOnDemand; appends |
| `LoadManagers` | Becomes LoadOnDemand if a manager is present; appends |
| `AllowLoadGameType` | Restrict to game types/families; usable by insecure addons since 11.1.5; appends |
| `ExcludeLoadGameType` | Exclude game types/families (12.0.0+); appends |
| `OnlyBetaAndPTR: 1` | Only loadable on Beta/PTR |
| `DefaultState: disabled` | User must enable manually |

### I.5 Saved variables

| Directive | Notes |
|---|---|
| `SavedVariables` | Per-account; appends |
| `SavedVariablesPerCharacter` | Per-character; appends |
| `LoadSavedVariablesFirst: 1` | Load SVs before scripts (11.1.5+); cannot be turned off later in the file |

### I.6 Informational (readable via `C_AddOns.GetAddOnMetadata`)

`Author`, `Version` (start with a number for updater friendliness), `X-*` custom fields
(`X-Website`, `X-License`, `X-Curse-Project-ID`, ...).

### I.7 Other

`AllowAddOnTableAccess: 1` - expose the namespace table to `C_AddOns.GetAddOnLocalTable` (11.1.7+).

### I.8 Restricted (Blizzard only - have no effect for third-party addons)

`AllowLoad`, `EscalateErrorDuringLoad`, `LoadFirst` (formerly `GuardedAddOn`),
`SavedVariablesMachine`, `UseSecureEnvironment`.

---

## Part J - TOC feature timeline

| Patch | Change |
|---|---|
| 12.1.5 (PTR) | `_Standard` suffix |
| 12.0.7 | Per-metadata conditional directives |
| 12.0.0 | `ExcludeLoadGameType` field & per-file condition |
| 11.2.0 | `[TextLocale]` variable, `AllowLoadTextLocale` |
| 11.1.7 | `AllowAddOnTableAccess` |
| 11.1.5 | Per-file conditions & variables; `LoadSavedVariablesFirst`; `AllowLoadGameType` usable by addons |
| 11.1.0 | `Category`, `Group` |
| 11.0.0 | Restricted `UseSecureEnvironment`; removed `SuppressLocalTableRef` |
| 10.2.7 | Comma-separated `Interface`; renamed `AllowLoadByGameMode`->`AllowLoadGameType`, `GuardedAddOn`->`LoadFirst` |
| 10.1.0 | `IconAtlas`, `IconTexture`, addon compartment fields |
| 9.1.0 | Multiple suffixed TOC files (Classic/BCC/Retail) |
| 9.0.1 | `/reload` detects TOC metadata changes and new files |
| 4.0.1 | `/reload` detects file-order changes |
| 2.1.0 | `LoadManagers` |
| 1.9.0 | `LoadWith` |

Classic-family clients inherit Modern TOC behaviour in batches:
MoP Classic 5.5.4 ~ Modern up to 12.0.7; Classic Era 1.15.9 ~ up to 12.0.7; Titan Reforged
3.80.2 ~ up to 12.0.7; Anniversary 2.5.6 ~ up to 12.0.7; Cataclysm Classic 4.4.1 ~ up to 11.0.0;
Forever 1.60.1 ~ up to 12.1.5.

---

## Part K - Template TOC (multi-client, current)

```toc
## Interface: 120100, 50504, 40402, 38002, 20506, 11509
## Title: MyAddOn
## Title-deDE: MeinAddOn
## Notes: Does a thing.
## Category: Combat
## Author: You
## Version: @project-version@
## IconTexture: Interface\Icons\INV_Misc_QuestionMark
## SavedVariables: MyAddOnDB
## SavedVariablesPerCharacter: MyAddOnCharDB
## OptionalDeps: LibStub
## AddonCompartmentFunc: MyAddOn_OnCompartmentClick
## X-Website: https://example.com/myaddon

Libs\LibStub\LibStub.lua
Locales\enUS.lua
# Loads Locales\deDE.lua etc. on matching clients (enUS loads twice harmlessly if the file is idempotent)
Locales\[TextLocale].lua
Core.lua
Retail.lua [AllowLoadGameType mainline]
Classic.lua [AllowLoadGameType classic]
UI.xml
```
