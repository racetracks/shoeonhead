# World of Warcraft AddOn Development - Master Reference

> **Primary reference for WoW API / AddOn development:**
> **https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization**
>
> This is the hub page of the Warcraft Wiki's "Interface customization" project. Every
> API page, widget page, event page, and HOWTO on the wiki links back to it. When this
> document and the live wiki disagree, **the live wiki (and Blizzard's own FrameXML
> source) wins**.

- **Compiled:** 2026-10-08, from a crawl of the hub page and its linked pages.
- **License of source material:** Warcraft Wiki content is CC BY-SA 4.0. This document is a
  rewritten, condensed derivative intended as AI rule context.
- **Companion files in this set:**

| File | Covers |
|---|---|
| `00_WoW_Addon_Development_Reference.md` | This file - the whole landscape, rules, patterns, links |
| `01_TOC_Format_and_Client_Versions.md` | TOC directives, file suffixes, game types, interface number <-> client version map |
| `02_Object_Security.md` | Protected, forbidden, anchor-restricted, inaccessible objects |
| `03_Secure_Execution_and_Tainting.md` | The taint model, protected functions, combat lockdown |
| `04_SecureTemplates.md` | SecureActionButton, SecureUnitButton, group/aura headers |
| `05_SecureHandlers.md` | SecureHandler templates, RestrictedEnvironment, frame handles, SecureStateDriver |
| `06_How_to_Deal_with_Taint.md` | Practical taint diagnosis and avoidance |
| `07_Secret_Values_Midnight.md` | Patch 12.x secret values, secret aspects, forbidden aspects |

---

## 0. How an AI should use this reference (rule priority)

1. **Determine the target game type(s) first.** Retail (Midnight, 12.x), Forever, MoP Classic
   (5.5.x), Titan Reforged (3.80.x), Cataclysm Classic (4.4.x), Wrath Classic (3.4.x), TBC
   Anniversary (2.5.x), and Classic Era (1.15.x) all run the *modern* Lua API but differ in
   which functions exist and which restrictions apply. See `01_TOC_Format_and_Client_Versions.md`.
2. **Never generate code that automates combat decisions.** The security model exists to
   force a human to choose targets and spells. Code that tries to bypass this will fail at
   runtime ("action blocked") - it is not merely discouraged.
3. **Assume addon code is always tainted.** Any design that requires calling a protected
   function from addon logic in combat is wrong; use secure templates/handlers configured
   out of combat instead.
4. **On Retail 12.x (Midnight), assume combat data may be secret.** Do not compare, do
   arithmetic on, or use as table keys any value returned from combat APIs without checking
   `issecretvalue()` / `canaccessvalue()`. See `07_Secret_Values_Midnight.md`.
5. **Prefer documented, current APIs** (`C_*` namespaces) over deprecated globals. When
   unsure whether an API exists on a given client, say so and point to the wiki page or
   Townlong Yak's API documentation browser rather than guessing a signature.
6. **Never modify Blizzard tables/globals directly.** Use `hooksecurefunc`,
   `frame:HookScript`, or your own frames. See `06_How_to_Deal_with_Taint.md`.

---

## 1. What an AddOn is

AddOns are folders of **Lua** and **XML** files that modify the WoW User Interface. They are
installed by extracting the addon folder into:

```
World of Warcraft\_retail_\Interface\AddOns\<AddOnName>\
```

(Other game types use sibling directories such as `_classic_`, `_classic_era_`, `_ptr_`,
`_xptr_`, `_beta_`.)

Minimum viable addon:

```
Interface\AddOns\MyAddOn\
    MyAddOn.toc        <- manifest; file name MUST match folder name
    MyAddOn.lua
```

```toc
## Interface: 120100
## Title: My AddOn
## Notes: One-line description shown in the AddOn List tooltip
## Version: 1.0.0
## Author: Me
## SavedVariables: MyAddOnDB

MyAddOn.lua
```

Key rules (full detail in `01_TOC_Format_and_Client_Versions.md`):

- Only Lua and XML files are listed in the TOC; media (textures, fonts, sounds) is referenced by path.
- Files load **top to bottom**, in TOC order.
- The client reads at most 1024 characters per TOC line.
- `/reload` picks up new files and TOC metadata changes; deleting/renaming a TOC that was
  already loaded requires a full client restart.
- An addon whose `## Interface:` doesn't match the client is flagged out-of-date.

### 1.1 The addon namespace (private table)

Every Lua file listed in a TOC receives two values through the vararg `...`:

```lua
local addonName, ns = ...   -- ns is a table shared privately by all files of this addon
```

Use `ns` to share state between your files instead of creating globals. Fewer globals means
fewer collisions with other addons and fewer chances to accidentally overwrite a Blizzard
global (which is a classic source of taint). The TOC directive `## AllowAddOnTableAccess: 1`
lets other code retrieve this table via `C_AddOns.GetAddOnLocalTable` (11.1.7+).

Reference: https://warcraft.wiki.gg/wiki/Using_the_AddOn_namespace

### 1.2 Load and login sequence

1. Blizzard FrameXML code loads and executes.
2. Each enabled addon's files execute in TOC order (dependencies first).
3. For each addon, its SavedVariables are loaded, then **`ADDON_LOADED`** fires with that
   addon's name as the first argument. (With `## LoadSavedVariablesFirst: 1`, saved
   variables are loaded *before* the addon's script files.)
4. **`PLAYER_LOGIN`** fires once, after all non-load-on-demand addons are loaded and the
   player is fully logged in.
5. **`PLAYER_ENTERING_WORLD`** fires on login, `/reload`, and every loading screen.
6. **`PLAYER_LOGOUT`** fires just before SavedVariables are written to disk - the last
   chance to mutate them.

**Rule:** initialize saved variables in `ADDON_LOADED` filtered on your own addon name. Do
not read them at file scope - at that point they have not been loaded yet, and any default
you assign at file scope will be overwritten when they load.

---

## 2. API surface map

All links are on warcraft.wiki.gg unless noted.

| Area | What it is | Link |
|---|---|---|
| **Global API** | Thousands of C functions, mostly in `C_Namespace.Function` form (e.g. `C_AddOns.GetAddOnMetadata`) | https://warcraft.wiki.gg/wiki/World_of_Warcraft_API |
| **Lua API** | The Lua 5.1 standard library *as exposed by WoW* (some functions removed, some aliases like `strsplit`, `tinsert`, `wipe` added) | https://warcraft.wiki.gg/wiki/Lua_functions |
| **Widget API** | Methods on UI objects (Frame, Button, Texture, FontString, StatusBar, Cooldown, EditBox...) | https://warcraft.wiki.gg/wiki/Widget_API |
| **ScriptObject API** | Non-region script objects (e.g. Curve, ColorCurve, Duration objects, animation objects) | https://warcraft.wiki.gg/wiki/ScriptObject_API |
| **Script types** | Widget script handlers (`OnEvent`, `OnUpdate`, `OnClick`, `OnShow`...) | https://warcraft.wiki.gg/wiki/Widget_script_handlers |
| **Events** | Messages the client sends to frames | https://warcraft.wiki.gg/wiki/Events |
| **CVars** | Console variables (`GetCVar`/`SetCVar`, `C_CVar.*`) | https://warcraft.wiki.gg/wiki/CVars |
| **API changes** | Per-patch API diffs - check these when targeting a specific client | https://warcraft.wiki.gg/wiki/API_change_summaries |
| **XML overview** | Declarative UI definitions | https://warcraft.wiki.gg/wiki/XML_user_interface |
| **XML schema** | Every element and attribute | https://warcraft.wiki.gg/wiki/XML_schema |
| **Macro commands** | `/cast`, `/use`, `/target`, `/click`... | https://warcraft.wiki.gg/wiki/Macro_commands |
| **Macro conditionals** | `[combat]`, `[@mouseover,help]`, `[mod:shift]`... (also used by state drivers) | https://warcraft.wiki.gg/wiki/Macro_conditionals |
| **TOC format** | Addon manifest | https://warcraft.wiki.gg/wiki/TOC_format |
| **UnitId** | Unit tokens (`player`, `target`, `party1`, `nameplate3`, `boss1`...) | https://warcraft.wiki.gg/wiki/UnitId |
| **GUID** | Unique identifier strings for units, items, etc. | https://warcraft.wiki.gg/wiki/GUID |
| **Combat Log** | `COMBAT_LOG_EVENT(_UNFILTERED)` payload (Classic only - see section 8) | https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT |
| **UI escape sequences** | `|c`, `|r`, `|T`, `|A`, `|H`, `|n`... | https://warcraft.wiki.gg/wiki/UI_escape_sequences |
| **Hyperlinks** | Item/spell/quest link formats | https://warcraft.wiki.gg/wiki/Hyperlinks |
| **Object security** | See `02_Object_Security.md` | https://warcraft.wiki.gg/wiki/Object_security |
| **Secure Execution and Tainting** | See `03_...` | https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting |
| **SecureTemplates** | See `04_...` | https://warcraft.wiki.gg/wiki/SecureTemplates |
| **SecureHandlers** | See `05_...` | https://warcraft.wiki.gg/wiki/SecureHandlers |
| **Secret Values** | See `07_...` | https://warcraft.wiki.gg/wiki/Secret_Values |
| **FrameXML functions** | Lua utilities Blizzard ships (mixins, pools, utilities) | https://warcraft.wiki.gg/wiki/FrameXML_functions |
| **HOWTOs** | Tutorial index | https://warcraft.wiki.gg/wiki/HOWTOs |

### 2.1 Authoritative "source of truth" outside the wiki

The wiki is contributor-maintained and an API-maintenance banner was present on several pages
at crawl time. For exact signatures, consult Blizzard's own code and generated documentation:

- **wow-ui-source** (mirror of Blizzard's interface code): https://github.com/Gethe/wow-ui-source
- **BlizzardInterfaceResources** (API/event/CVar dumps): https://github.com/Ketho/BlizzardInterfaceResources
- **Townlong Yak FrameXML browser**: https://www.townlong-yak.com/framexml/live
- **Townlong Yak API Documentation** (Blizzard's generated docs, incl. secret-value annotations): https://www.townlong-yak.com/framexml/live/Blizzard_APIDocumentation
- **Townlong Yak Globe / "who uses that?"**: https://www.townlong-yak.com/globe/ and https://www.townlong-yak.com/globe/wut/
- **wago.tools** file search and DB2 browser: https://wago.tools/files , https://wago.tools/db2
- In-game: `/api` (APIDocumentation addon) lists the client's own documented API.
- Guide: https://warcraft.wiki.gg/wiki/Viewing_Blizzard%27s_interface_code

---

## 3. Frames, widgets and scripts

### 3.1 Creating frames

```lua
-- CreateFrame(frameType [, name [, parent [, template [, id]]]])
local f = CreateFrame("Frame", "MyAddOnFrame", UIParent, "BackdropTemplate")
f:SetSize(200, 100)
f:SetPoint("CENTER")            -- anchor to parent's CENTER
f:Show()
```

- **Name** (2nd arg) creates a global. Pass `nil` unless the frame genuinely needs a global
  name (e.g. for `/click`, keybinding, or XML `$parent` references).
- **Templates** are comma-separated virtual XML templates (e.g. `"SecureActionButtonTemplate"`,
  `"BackdropTemplate"`). `SetBackdrop` requires `BackdropTemplate` since 9.0.
- **Frames cannot be destroyed.** Hide and reuse them (or use Blizzard object pools such as
  `CreateFramePool`).
- Common widget types: `Frame`, `Button`, `CheckButton`, `EditBox`, `ScrollFrame`, `Slider`,
  `StatusBar`, `Cooldown`, `GameTooltip`, `MessageFrame`, `Model`/`PlayerModel`, `SimpleHTML`.
  Regions (non-frames): `Texture`, `FontString`, `Line`, `MaskTexture` - created via
  `frame:CreateTexture()`, `frame:CreateFontString()`.

### 3.2 Anchoring and layout

- `SetPoint(point, relativeTo, relativePoint, x, y)` - points: `TOPLEFT`, `TOP`, `TOPRIGHT`,
  `LEFT`, `CENTER`, `RIGHT`, `BOTTOMLEFT`, `BOTTOM`, `BOTTOMRIGHT`.
- `ClearAllPoints()` before re-anchoring. Re-anchoring is how you move frames.
- `SetAllPoints(other)` fills another region.
- Strata (`SetFrameStrata`) and level (`SetFrameLevel`) control draw order; textures also use
  draw layers (`BACKGROUND`, `BORDER`, `ARTWORK`, `OVERLAY`, `HIGHLIGHT`).
- Anchoring a normal frame to a **protected** frame (or vice-versa) propagates combat
  restrictions - see `02_Object_Security.md` and `03_Secure_Execution_and_Tainting.md`.

### 3.3 Script handlers

```lua
f:SetScript("OnShow", function(self) ... end)    -- replaces any existing handler
f:HookScript("OnShow", function(self) ... end)   -- runs AFTER the existing handler, taint-safe
```

- Use `HookScript` (never `SetScript`) on frames you don't own.
- `OnUpdate(self, elapsed)` runs every rendered frame - throttle it, or prefer
  `C_Timer.After(seconds, fn)` / `C_Timer.NewTicker(seconds, fn)`.
- Full list: https://warcraft.wiki.gg/wiki/Widget_script_handlers

### 3.4 XML (optional)

XML is a declarative alternative to Lua construction, and the only way to define reusable
**virtual templates** (`virtual="true"`) that Lua can then `inherits`.

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Script file="MyAddOn.lua"/>
    <Frame name="MyAddOnTemplate" virtual="true">
        <Size x="100" y="20"/>
        <Layers>
            <Layer level="ARTWORK">
                <FontString parentKey="Label" inherits="GameFontNormal"/>
            </Layer>
        </Layers>
        <Scripts>
            <OnLoad>self:RegisterEvent("PLAYER_LOGIN")</OnLoad>
        </Scripts>
    </Frame>
</Ui>
```

- `parentKey="Label"` makes the child reachable as `frame.Label` (preferred over `$parent`
  names, which create globals).
- `<Script file>` and `<Include file>` load further files; use backslashes in paths for
  Include compatibility.
- `mixin="MyMixin"` + `<OnLoad method="OnLoad"/>` binds a Lua mixin table - Blizzard's
  standard object pattern (`CreateFromMixins`, `Mixin`).
- Docs: https://warcraft.wiki.gg/wiki/XML_user_interface , https://warcraft.wiki.gg/wiki/XML_schema

---

## 4. Events

Events are delivered only to frames that have registered for them.

```lua
local f = CreateFrame("Frame")
local handlers = {}

function handlers:ADDON_LOADED(name)
    if name ~= addonName then return end
    MyAddOnDB = MyAddOnDB or {}               -- SavedVariables now available
    self:UnregisterEvent("ADDON_LOADED")
end

function handlers:PLAYER_LOGIN()
    -- all addons loaded, player in world
end

f:SetScript("OnEvent", function(self, event, ...)
    local h = handlers[event]
    if h then h(self, ...) end
end)

for event in pairs(handlers) do
    f:RegisterEvent(event)
end
```

- Handler signature: `(self, event, ...)`; event payload is in the vararg.
- `frame:RegisterUnitEvent(event, unit1 [, unit2])` filters unit events at the C level
  (cheaper than filtering in Lua).
- `frame:UnregisterEvent`, `frame:UnregisterAllEvents`.
- The old implicit globals `this`, `event`, `arg1...` were removed in 4.0.1 - never use them.
- Some events are now **restricted** on Retail 12.x: registering them fires
  `ADDON_ACTION_FORBIDDEN` (e.g. the combat log, see section 8).
- Event list: https://warcraft.wiki.gg/wiki/Events ; tutorial: https://warcraft.wiki.gg/wiki/Handling_events
- Debug with `/etrace` (Event Trace, 9.1.0+).

---

## 5. Saved variables

Declared in the TOC; persisted automatically on logout, disconnect, quit, and `/reload`.

| Directive | Scope | File |
|---|---|---|
| `## SavedVariables: A, B` | Per account | `WTF\Account\<ACCOUNT>\SavedVariables\<AddOn>.lua` |
| `## SavedVariablesPerCharacter: C` | Per character | `WTF\Account\<ACCOUNT>\<Realm>\<Char>\SavedVariables\<AddOn>.lua` |

Rules and pitfalls:

- Only **strings, numbers, booleans, and tables** persist. Functions, userdata, and coroutines
  do not. Circular/shared table references are not preserved (each reference is serialized
  as a separate copy).
- SavedVariables are **globals**. Prefer a single uniquely named table (`MyAddOnDB`) rather
  than many loose globals.
- Merge defaults on load so that new keys added in later versions appear:

```lua
local defaults = { scale = 1, enabled = true }
local function ApplyDefaults(db, def)
    for k, v in pairs(def) do
        if db[k] == nil then
            db[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(db[k]) == "table" then
            ApplyDefaults(db[k], v)
        end
    end
end
```

- `PLAYER_LOGOUT` is the last event before writing - use it for final cleanup.
- Tutorial: https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions

---

## 6. Slash commands

```lua
SLASH_MYADDON1 = "/myaddon"
SLASH_MYADDON2 = "/ma"
SlashCmdList.MYADDON = function(msg, editBox)
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    if cmd == "reset" then ... else print("Usage: /myaddon reset") end
end
```

- The key in `SlashCmdList` must equal the token between `SLASH_` and the trailing digit.
- Pick unique tokens; collisions silently override another addon's command.
- Tutorial: https://warcraft.wiki.gg/wiki/Creating_a_slash_command

---

## 7. Hooking

| Hook type | Mechanism | Taint-safe on Blizzard code? |
|---|---|---|
| Pre-hook / replace | Save original, assign new function, call original | **No** - taints the variable; never do this to secure functions |
| Post-hook (insecure) | Wrap original and run code after | **No** for Blizzard globals |
| Secure post-hook (function) | `hooksecurefunc([tbl,] "name", fn)` | **Yes** |
| Secure post-hook (script) | `frame:HookScript("OnX", fn)` | **Yes** |

```lua
hooksecurefunc("SomeBlizzardFunction", function(...)    -- receives same args, after original
    -- react here; return values of the original are NOT passed
end)

hooksecurefunc(SomeBlizzardMixin, "Method", function(self, ...) ... end)
hooksecurefunc(SomeFrame, "SetPoint", function(self, ...) ... end)
```

- `hooksecurefunc` hooks **cannot be removed**. Gate them with a flag if you need to "disable".
- Blizzard load-on-demand UI (`Blizzard_*` addons) cannot be hooked until loaded - hook in
  `ADDON_LOADED` for that addon name, or use `EventUtil.ContinueOnAddOnLoaded` where available.
- A hook that runs *during* a secure call stack is still your (tainted) code; avoid
  side-effects on Blizzard state inside it.
- Tutorial: https://warcraft.wiki.gg/wiki/Hooking_functions

---

## 8. Version-specific restrictions you must know (Retail Midnight 12.x)

These are the biggest behavioral differences an AI must apply when targeting Retail:

1. **Combat log is gone for addons.** `COMBAT_LOG_EVENT` / `COMBAT_LOG_EVENT_UNFILTERED` are
   no longer accessible to AddOns since 12.0.0; attempting to register fires
   `ADDON_ACTION_FORBIDDEN`. Classic-family clients still provide it (payload via
   `CombatLogGetCurrentEventInfo()`).
2. **Secret values.** Many combat APIs (e.g. `UnitHealth`, aura, cooldown, cast APIs) may
   return secret values to tainted code under combat/encounter/M+/PvP/restricted-map
   conditions. You may store, pass, concatenate/format them, and feed them to widget setters
   that accept secrets (e.g. `StatusBar:SetValue`), but you **may not** compare, do
   arithmetic, take `#`, index them, or use them as table keys. See `07_Secret_Values_Midnight.md`.
3. **Use display objects instead of math:** `C_CurveUtil.CreateCurve/CreateColorCurve` to map
   secret numbers to colors/values; `C_DurationUtil.CreateDuration` and
   `StatusBar:SetTimerDuration` for timers.
4. **Restriction state is queryable:** `C_RestrictedActions` (current restriction states),
   `C_Secrets` (evaluate secret predicates).
5. **Simulate restrictions while testing** with CVars `addonCombatRestrictionsForced`,
   `addonEncounterRestrictionsForced`, `addonChallengeModeRestrictionsForced`,
   `addonPvPMatchRestrictionsForced`, `addonMapRestrictionsForced`,
   `addonChatRestrictionsForced` (not persisted across restarts).

---

## 9. Supporting multiple game versions

Three complementary techniques (prefer them in this order):

1. **One TOC with comma-separated interface versions** (supported since 10.2.7 Retail and
   Classic clients that include those changes):
   ```toc
   ## Interface: 120100, 50504, 20506, 11509
   ```
2. **Per-file / per-metadata conditional directives and variables** in the TOC:
   ```toc
   Retail.lua [AllowLoadGameType standard]
   ClassicShared.lua [AllowLoadGameType classic]
   Locales\[TextLocale].lua
   [Family]\Core.lua
   ```
3. **Runtime checks:**
   ```lua
   local IS_RETAIL  = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
   local IS_ERA     = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
   local IS_MISTS   = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
   -- Feature-detect rather than version-detect where possible:
   local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
   ```
4. **Separate suffixed TOC files** (`MyAddOn_Mainline.toc`, `MyAddOn_Classic.toc`,
   `MyAddOn_Vanilla.toc`...) - still supported but the wiki recommends options 1-2 where possible.

Full tables: `01_TOC_Format_and_Client_Versions.md`.

---

## 10. Common feature areas (HOWTO index)

| Feature | Guidance | Link |
|---|---|---|
| Handling events | section 4 | https://warcraft.wiki.gg/wiki/Handling_events |
| Slash commands | section 6 | https://warcraft.wiki.gg/wiki/Creating_a_slash_command |
| Saved variables | section 5 | https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions |
| Options panel | Retail uses the `Settings` API (e.g. `Settings.RegisterCanvasLayoutCategory` / `Settings.RegisterVerticalLayoutCategory` + `Settings.RegisterAddOnCategory`); the legacy `InterfaceOptions_AddCategory` path is deprecated on Retail. Verify per client. | https://warcraft.wiki.gg/wiki/Using_the_Interface_Options_Addons_panel |
| Dropdown menus | Legacy `UIDropDownMenu` is a historic **taint vector** (it shares global state with Blizzard menus). Prefer the modern Menu system (`MenuUtil`, `DropdownButton`) where available, or a library. | https://warcraft.wiki.gg/wiki/Using_UIDropDownMenu |
| Hooking | section 7 | https://warcraft.wiki.gg/wiki/Hooking_functions |
| Localization | Locale tables keyed by `GetLocale()`; TOC `[TextLocale]` variable and `[AllowLoadTextLocale ...]` (11.2.0+); localized TOC fields like `## Title-deDE:` | https://warcraft.wiki.gg/wiki/Localizing_an_addon |
| Minimap / compartment | `## AddonCompartmentFunc: GlobalFuncName` (+ `...OnEnter`, `...OnLeave`) | https://warcraft.wiki.gg/wiki/Addon_compartment |
| Packaging / release | BigWigs Packager via GitHub Actions | https://warcraft.wiki.gg/wiki/Using_the_BigWigs_Packager_with_GitHub_Actions |

Tutorial track from the hub page: Introduction to Lua -> Create a WoW AddOn in 15 Minutes ->
Ace3 for Dummies -> BigWigs Packager.

- https://warcraft.wiki.gg/wiki/Introduction_to_Lua
- https://warcraft.wiki.gg/wiki/Create_a_WoW_AddOn_in_15_Minutes
- https://warcraft.wiki.gg/wiki/Ace3_for_Dummies

---

## 11. Technical details quick reference

### 11.1 Unit tokens (UnitId)

`player`, `pet`, `target`, `focus`, `mouseover`, `vehicle`, `none`, `partyN` (1-4),
`partypetN`, `raidN` (1-40), `raidpetN`, `bossN`, `arenaN`, `nameplateN`, `softenemy`,
`softfriend`, `softinteract`. Suffix `target` chains (`targettarget`, `party1target`).
On Retail 12.x, compound tokens (e.g. `boss1target`) are more likely to yield secret results.
https://warcraft.wiki.gg/wiki/UnitId

### 11.2 GUIDs

Hyphen-delimited strings whose first field is the type, e.g.
`Player-<serverID>-<playerUID>` and
`Creature-0-<serverID>-<instanceID>-<zoneUID>-<npcID>-<spawnUID>`.
Parse with `strsplit("-", guid)`. https://warcraft.wiki.gg/wiki/GUID

### 11.3 UI escape sequences

| Sequence | Meaning |
|---|---|
| `|cAARRGGBB ... |r` | Color text (alpha + RGB hex), `|r` resets |
| `|Tpath:height[:width...]|t` | Inline texture |
| `|Aatlas:height:width|a` | Inline atlas |
| `|Htype:data|h[text]|h` | Hyperlink |
| `|n` | Newline |
| `||` | Literal pipe |

https://warcraft.wiki.gg/wiki/UI_escape_sequences , https://warcraft.wiki.gg/wiki/Hyperlinks

### 11.4 Macro conditionals (used by state drivers & secure buttons)

Bracketed, comma = AND, semicolon = else-if:
`[@mouseover,help,nodead] heal; [@target,harm] nuke; fallback`.
Common: `combat`, `mod:shift`, `help`/`harm`, `exists`, `dead`, `stealth`, `form:N`,
`bar:N`, `vehicleui`, `overridebar`, `group:party/raid`, `pet`, `mounted`, `flying`, `indoors`.
https://warcraft.wiki.gg/wiki/Macro_conditionals

---

## 12. Security model - summary (read the dedicated files)

- **Taint:** all addon code and data is tainted; Blizzard-signed code starts secure. Reading
  tainted data or executing tainted functions taints the execution path. Taint persists until
  `/reload` or relog. -> `03_Secure_Execution_and_Tainting.md`
- **Protected functions** (targeting, casting, moving/showing protected frames in combat...)
  only work on a secure execution path; from tainted code they fail with
  `ADDON_ACTION_BLOCKED` (in combat) or `ADDON_ACTION_FORBIDDEN` (always).
- **Object security levels:** protected (2.0.1) -> forbidden (5.4.0) -> anchor-restricted
  (8.2.0) -> inaccessible (10.1.0) -> secret/forbidden *aspects* (12.x). -> `02_Object_Security.md`
- **The sanctioned way to do protected things:** inherit a **secure template**, configure it
  with `SetAttribute` **out of combat**, and let a hardware click drive it. ->
  `04_SecureTemplates.md`
- **Combat-time logic on protected frames:** **SecureHandler** snippets running in the
  **RestrictedEnvironment**, triggered by clicks, attributes, or **state drivers** (macro
  conditionals). -> `05_SecureHandlers.md`
- **Always gate secure configuration on `InCombatLockdown()`** and defer to
  `PLAYER_REGEN_ENABLED`. -> `06_How_to_Deal_with_Taint.md`

---

## 13. Debugging toolbox

| Tool | Use |
|---|---|
| `/reload` (`/rl` with some addons) | Reload UI; also clears taint |
| `/dump expr` | Pretty-print any Lua expression (e.g. `/dump select(4, GetBuildInfo())` for interface number) |
| `/fstack` | Frame stack under cursor (names, parentKeys, strata) |
| `/etrace` | Event trace window |
| `/api` | Browse Blizzard's API documentation in-game |
| `/console scriptErrors 1` | Show Lua errors in-game |
| `/console taintLog 1` (or `2`; `11` verbose since 5.2) | Write `Logs\taint.log` |
| BugGrabber/BugSack (community addons) | Capture and browse errors |
| `issecure()`, `issecurevariable([t,] "name")` | Inspect taint at runtime |

---

## 14. Development tools (from the hub page)

- **WoW Lua Language Server** (VS Code): https://marketplace.visualstudio.com/items?itemName=TradeSkillMaster.wowlua-ls
- **LuaLS** + **WoW API extension** (VS Code): https://marketplace.visualstudio.com/items?itemName=sumneko.lua , https://marketplace.visualstudio.com/items?itemName=ketho.wow-api
- **IntelliJ** EmmyLua WoW API: https://github.com/Ellypse/IntelliJ-IDEA-Lua-IDE-WoW-API
- **Sublime Text** WoWDevelopment: https://packagecontrol.io/packages/WoWDevelopment
- **WeakAuras Lua dev environment guide**: https://github.com/WeakAuras/WeakAuras2/wiki/Lua-Dev-Environment
- **wowprogramming.com** (older but useful reference): https://wowprogramming.com/
- Video series: Mayron "Creating WoW AddOns", Paul Halliday "WoW AddOn Development" (YouTube).

## 15. Communities

- WoWUIDev Discord: https://discord.gg/sVQCHr5 (also linked as https://discord.gg/txUg39Vhc6)
- WoW AddOns Discord: https://discord.gg/sXy46yZ
- WoWInterface forums: https://www.wowinterface.com/forums/
- r/wowaddons: https://www.reddit.com/r/wowaddons/
- Blizzard UI & Macro forums: US https://us.forums.blizzard.com/en/wow/c/guides/ui-macro/35 , EU https://eu.forums.blizzard.com/en/wow/c/guides/interface-and-macros/239
- Distribution: CurseForge https://www.curseforge.com/wow/addons , WoWInterface https://www.wowinterface.com/addons.php
- Bug tracker for UI/API bugs: https://github.com/Stanzilla/WoWUIBugs

---

## 16. Golden rules checklist (for code generation and review)

- [ ] TOC file name matches folder name; `## Interface:` lists every targeted client.
- [ ] No unnecessary globals; shared state lives in the addon namespace table.
- [ ] SavedVariables initialized in `ADDON_LOADED` for *this* addon, with defaults merged.
- [ ] No assignment to any Blizzard global, Blizzard table key, or Blizzard frame field.
- [ ] No replacing Blizzard functions/methods; only `hooksecurefunc` / `HookScript`.
- [ ] No calling Blizzard Lua methods that mutate shared state from addon code unless known safe.
- [ ] Every `SetAttribute`, `Show/Hide`, `SetPoint`, `SetParent`, `SetSize` on protected
      frames is guarded by `if InCombatLockdown() then <queue> end`.
- [ ] Secure frames are created out of combat (ideally at load time).
- [ ] Non-secure frames are not anchored to/parented under protected frames unless intended.
- [ ] Retail 12.x: combat-derived values are treated as potentially secret; no arithmetic,
      comparison, `#`, indexing, or table-key use without `canaccessvalue`.
- [ ] Retail 12.x: no registration of `COMBAT_LOG_EVENT_UNFILTERED`.
- [ ] `OnUpdate` throttled or replaced by `C_Timer`.
- [ ] Feature detection (`if C_Foo and C_Foo.Bar then`) for APIs that differ across clients.
- [ ] Never automate decisions the security model reserves for the player.

---

## 17. Crawled page index

| Page | URL |
|---|---|
| Interface customization (hub) | https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization |
| Object security | https://warcraft.wiki.gg/wiki/Object_security |
| Secure Execution and Tainting | https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting |
| SecureTemplates | https://warcraft.wiki.gg/wiki/SecureTemplates |
| SecureActionButtonTemplate | https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate |
| SecureHandlers | https://warcraft.wiki.gg/wiki/SecureHandlers |
| RestrictedEnvironment | https://warcraft.wiki.gg/wiki/RestrictedEnvironment |
| SecureStateDriver | https://warcraft.wiki.gg/wiki/SecureStateDriver |
| Secret Values | https://warcraft.wiki.gg/wiki/Secret_Values |
| TOC format | https://warcraft.wiki.gg/wiki/TOC_format |
| WOW_PROJECT_ID | https://warcraft.wiki.gg/wiki/WOW_PROJECT_ID |
| Public client builds | https://warcraft.wiki.gg/wiki/Public_client_builds |
| API change summaries | https://warcraft.wiki.gg/wiki/API_change_summaries |
| GetBuildInfo | https://warcraft.wiki.gg/wiki/API:GetBuildInfo |
| Handling events | https://warcraft.wiki.gg/wiki/Handling_events |
| Hooking functions | https://warcraft.wiki.gg/wiki/Hooking_functions |
| Saving variables between game sessions | https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions |
| COMBAT_LOG_EVENT | https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT |
| How to deal with taint issues? (WoWInterface thread) | https://www.wowinterface.com/forums/showthread.php?t=58021 (archive: https://wowinterface.com/forums/archive/index.php/t-58021.html) |
| Townlong Yak "About taint" (linked, struck-through on hub; robots-blocked at crawl time) | https://www.townlong-yak.com/taint.log/about |
