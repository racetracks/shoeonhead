# How to Deal with Taint

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary source (linked from the hub as "How to deal with taint"): WoWInterface thread
> "How to deal with taint issues?" (May 2020), especially the reply by MunkDev  - 
> https://www.wowinterface.com/forums/showthread.php?t=58021 (archive: https://wowinterface.com/forums/archive/index.php/t-58021.html)
> Also: https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting , https://warcraft.wiki.gg/wiki/Hooking_functions ,
> WoWInterface "The Big Taint thread" and 5.2 verbose taint log notes.
> The Townlong Yak "About taint" page linked from the hub was robots-blocked at crawl time.
> Compiled 2026-10-08. Content below is paraphrased and expanded; code samples are original.

Theory lives in `03_Secure_Execution_and_Tainting.md`. This file is the **practical** playbook:
how taint gets *into* Blizzard code, how to read a taint log, and how to avoid or fix it.

---

## 1. The one-sentence mental model

> Taint problems happen when your addon **replaces or writes** something that secure Blizzard
> code later **reads**, or when you **call** Blizzard Lua that has **side effects** on shared state.

Taint is not caused by *your own* frames and tables. It's caused by your code touching
**Blizzard-owned** functions, variables, tables, and frame fields. So the most effective way
to hunt taint is: **look for every place your code modifies or invokes existing Blizzard code
without going through the provided widget API.** The forum advice is explicit that this is
usually easier than trying to follow a taint stack trace.

---

## 2. The four classic ways addons spread taint

### 2.1 Calling Blizzard Lua methods that have side effects

```lua
-- Risky: if this Blizzard method (written in Lua) stores state on the frame
-- or in a shared table, that state is now tainted by YOUR call.
SomeBlizzardFrame:MethodImplementedInLua(arg)
```

Imagine the Blizzard method ends with `self.needsUpdate = true`. When **Blizzard** calls it, the
field is written securely. When **you** call it, the field is written by tainted execution - and
the next secure code that reads `self.needsUpdate` becomes tainted.

**Heuristic:** if you can find the function's definition in FrameXML Lua source, calling it
yourself is *risky*. Methods that **add things to a dataset or store them in a normal table**
(registries, data providers, pools, "Add.../Register.../Set..." helpers) are the usual culprits.
Pure C widget methods (`SetTexture`, `SetText` on your own regions) are not.

Real-world example from the thread: calling `WorldMapFrame:AddDataProvider(...)` (Lua, mutates
the map canvas's provider table) tainted the world map; later, clicking a dungeon pin in combat
opened the Encounter Journal via `ShowUIPanel`, which then failed because the execution path
was tainted.

### 2.2 Writing keys on Blizzard tables/frames

```lua
-- Taints this key; any secure code that reads it becomes tainted.
SomeBlizzardFrame.someKeyBlizzardUses = value
```

This includes setting fields on Blizzard frames, mixins, and global tables (e.g. adding entries to
Blizzard's `UnitPopupMenus`-style tables, changing `StaticPopupDialogs` entries Blizzard owns,
overwriting `CHAT_FRAMES`, etc.).

### 2.3 Replacing (insecurely hooking) functions/methods

```lua
-- Wrong way to hook: the variable now holds YOUR (tainted) closure.
local orig = SomeBlizzardFrame.FunctionToHook
function SomeBlizzardFrame:FunctionToHook(...)
    DoSomethingNew()
    return orig(self, ...)
end
```

The only correct way to hook Blizzard functions is **`hooksecurefunc`** (or `HookScript` for
script handlers):

```lua
hooksecurefunc(SomeBlizzardFrame, "FunctionToHook", function(self, ...)
    DoSomethingNew()            -- runs after the original; original stays clean
end)
```

The same applies to "neutering" Blizzard methods:

```lua
-- Classic anti-pattern for locking a Blizzard frame in place:
PetFrame.SetPoint = function() end      -- taints PetFrame; Blizzard's later Show/Hide may be blocked
```

Instead, re-apply your position in a secure post-hook, guarded for combat:

```lua
local applying = false
hooksecurefunc(PetFrame, "SetPoint", function(self)
    if applying or InCombatLockdown() then return end
    applying = true
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "CENTER", -200, -150)
    applying = false
end)
```

(Even this re-positioning is your tainted call on a possibly protected frame - it's only safe out
of combat. For Blizzard frames, prefer Edit Mode / supported settings where available.)

### 2.4 Writing Blizzard globals

```lua
-- Any global Blizzard reads (constants, strings, state) - writing it taints every reader.
A_BLIZZARD_GLOBAL_USED_SOMEWHERE = value
```

Includes accidental writes: an addon that declares a non-`local` variable with the same name as a
Blizzard global (e.g. `GetItemInfo = ...`, `MAX_PARTY_MEMBERS = ...`, `L = ...` colliding with a
Blizzard local-turned-global) silently taints it. **Always use `local` and your namespace table.**

---

## 3. How Blizzard defends itself (and what that means for you)

- **`securecall(fn, ...)`** - Blizzard wraps calls into code that might be tainted so that any
  taint picked up *inside* doesn't leak into the caller's execution. You'll see this around
  callback dispatch; your callbacks still run tainted, but Blizzard's caller is protected.
- **`secureexecuterange(tbl, fn, ...)`** - same idea across a list of callbacks.
- **`forceinsecure()`** - Blizzard marks "what follows isn't trusted" deliberately.
- **Event dispatch** is isolated per handler; a tainted `OnEvent` doesn't taint the next frame's.

Implication: taint usually enters Blizzard code through **shared mutable state** (tables, fields,
globals, replaced functions), not through ordinary event handlers.

---

## 4. Reading the taint log

### 4.1 Enabling

```
/console taintLog 1      -- basic: logs blocked actions and their taint source
/console taintLog 2      -- more detail (logs global variable taint as well)
/console taintLog 11     -- verbose: logs EVERY taint event (added 5.2); files get huge
/reload
```

Output: `World of Warcraft\_<flavor>_\Logs\taint.log`. Reproduce the problem, then log out
or `/reload` to flush. Set back to `0` afterwards - verbose logging is expensive.

### 4.2 Anatomy of an entry (paraphrased from the thread's example)

```
Global variable INTERFACE_ACTION_BLOCKED_SHOWN tainted by MyAddon - ...UIParent.lua: DisplayInterfaceActionBlockedMessage()
    ...UIParent.lua: CheckProtectedFunctionsAllowed()
    ...UIParent.lua: ShowUIPanel()
    ...Blizzard_EncounterJournal.lua: EncounterJournal_OpenJournal()
    ...DungeonEntranceDataProvider.lua: <unnamed>:OnClick()
Execution tainted by MyAddon while reading EncounterJournalBossButton1 - ...Blizzard_EncounterJournal.lua: EncounterJournal_ClearDetails()
    ...
```

How to read it:

- **"An action was blocked ... because of taint from X - Frame:Method()"** - the *symptom*: a
  protected call failed. X is the addon whose taint was on the path **at that moment**.
- **"Execution tainted by X while reading Y"** - the moment the secure path *first picked up*
  taint: it read `Y`, which X had previously written (or which was created/initialized on a
  tainted path).
- **"Global variable G tainted by X"** - X wrote global G.

### 4.3 "You can't trust the log" - what that really means

The log is accurate about **where execution became tainted**, but that is often far from **where
your mistake is**. In the example, the addon never touched the Encounter Journal: an earlier
action (adding a map data provider) caused Blizzard to create/initialize objects on a tainted
path; much later, Blizzard read one of those objects and the taint surfaced. Rules:

1. Treat the blamed addon as a **lead**, not a verdict (another addon may have started the chain).
2. Scroll **earlier** in the log to find when `Y` was first tainted.
3. Map that back to anything in your code that modifies/invokes the relevant Blizzard system.
4. Prefer auditing your code for section 2 patterns over reverse-engineering long stacks.

### 4.4 Useful runtime probes

```lua
/dump issecurevariable("SOME_GLOBAL")                 -- true/false, taintedBy
/dump issecurevariable(SomeBlizzardFrame, "someKey")  -- for table fields
/dump issecure()                                      -- current path (from /dump it's tainted)
```

Also listen for `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN` (args: addon name, function)
in a dev build to report exactly which call failed.

---

## 5. Systematic diagnosis procedure

1. **Reproduce** with only your addon enabled (plus its libraries). If it disappears, bisect
   other addons.
2. **Enable `taintLog`** (start with 1, escalate to 11), reproduce, `/reload`, read the log.
3. **Find the first taint** of the variable/frame named in the failing chain.
4. **Grep your code** for:
   - assignments to Blizzard globals or Blizzard frame/table fields,
   - `function BlizzardThing:Method(` / `BlizzardThing.Method = ` (replacements),
   - `:SetScript(` on frames you didn't create,
   - calls to Blizzard Lua helpers that register/add/store (`Add*`, `Register*`, `Acquire*`,
     `Set*` on Blizzard mixins, `UIDropDownMenu_*`, `ShowUIPanel` on Blizzard panels from
     insecure code, `StaticPopup_Show` with Blizzard-owned dialogs),
   - inheriting Blizzard templates whose Lua mutates shared globals (historically
     `ActionBarButtonTemplate` / ActionButton code, `UIDropDownMenuTemplate`).
5. **Replace** each with a taint-safe alternative (section 6).
6. **Verify** with `issecurevariable` and a clean log, both in and out of combat.

---

## 6. Taint-safe alternatives cheat sheet

| Instead of... | Do... |
|---|---|
| Replacing a Blizzard function/method | `hooksecurefunc(tbl, "Method", postHook)` |
| `BlizzFrame:SetScript("OnShow", fn)` | `BlizzFrame:HookScript("OnShow", fn)` |
| Writing fields on Blizzard frames | Store your data in your own weak table keyed by the frame: `local data = setmetatable({}, {__mode="k"}); data[frame] = ...` |
| Writing Blizzard globals | Never; keep everything `local` / in your namespace |
| `BlizzFrame.Method = function() end` to suppress | `hooksecurefunc` + re-apply out of combat; or `frame:SetParent(hiddenFrame)` / `UnregisterAllEvents` **out of combat only**, acknowledging the frame may be protected |
| Calling Blizzard Lua mutators (`AddDataProvider`, registries) | Use public C APIs / documented extension points; if unavoidable, call at load time (out of combat) and test thoroughly |
| `UIDropDownMenu` templates/functions | Modern Menu API (`MenuUtil`, `DropdownButton`) on Retail, or a self-contained library (e.g. LibUIDropDownMenu) on Classic |
| Inheriting Blizzard action-button templates | `SecureActionButtonTemplate` + your own visuals, or a library like LibActionButton |
| Showing Blizzard panels via `ShowUIPanel` from addon code in combat | Defer until `PLAYER_REGEN_ENABLED` |
| Moving/showing protected frames in combat | State drivers / SecureHandlers (`05_SecureHandlers.md`), or queue |
| Reading back secret-tainted widget state (12.x) | Keep your own copy of non-secret inputs; don't call getters for computation |

---

## 7. Known historical taint hotspots

- **UIDropDownMenu** - shared global state (`UIDROPDOWNMENU_*` vars, `DropDownList` frames);
  initializing a dropdown from an addon could taint Blizzard's dropdowns (e.g. unit popups,
  raid frame menus). Hence the struck-through Townlong Yak link and the "UIDropDownMenu issues"
  archive on the wiki.
- **Action button templates/Lua** (`ActionBarFrame.xml`, `ActionButton.lua`,
  `ActionButtonTemplate.xml`) - inheriting/using them from addons spread taint into action bars.
- **Edit Mode / unit frames** (Retail 10.x+) - moving Blizzard frames by replacing `SetPoint`
  or writing layout fields.
- **World map** data providers and pins - as in the thread example.
- **Nameplates** - `SetScale`/`SetPoint` from addons; anchor-restricted since 8.2.0.
- **Static popups / chat frames / interface options** - writing Blizzard-owned dialog entries
  or chat frame fields.

---

## 8. Rules for AI code generation (taint)

1. **Never** assign to a Blizzard global, Blizzard table key, or Blizzard frame field.
2. **Never** redefine a Blizzard function/method; only `hooksecurefunc` / `HookScript`.
3. **Never** `SetScript` on a frame you didn't create.
4. **Avoid** calling Blizzard Lua functions that register/store data unless documented for addon
   use; prefer C APIs.
5. **Every** variable is `local` or lives in the addon namespace table.
6. **Every** protected-frame mutation is combat-guarded and queued.
7. Keep per-frame addon data in your own weak-keyed tables.
8. When a user reports "Interface action failed because of an AddOn", ask for (or instruct them to
   capture) `taint.log` with `/console taintLog 1` (escalate to 11), and audit for section 2 patterns
   before chasing the stack trace.
