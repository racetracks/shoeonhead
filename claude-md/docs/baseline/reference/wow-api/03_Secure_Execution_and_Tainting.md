# Secure Execution and Tainting

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary source: https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting
> Related: https://warcraft.wiki.gg/wiki/Object_security , https://warcraft.wiki.gg/wiki/SecureTemplates ,
> https://warcraft.wiki.gg/wiki/SecureHandlers , https://warcraft.wiki.gg/wiki/Secret_Values ,
> https://warcraft.wiki.gg/wiki/Category:World_of_Warcraft_API/Protected_Functions
> Original design write-up: Iriel's "Guide to Secure Execution and Tainting" (13 Oct 2006, archived).
> Compiled 2026-10-08.

## 1. Purpose of the model

The UI API **mandates human decision-making, particularly in combat**. Since Patch 2.0 (2006),
many functions are *protected*: they only work when the code calling them is trusted
("secure"). Before 2.0, addons could pick targets and spells automatically; afterwards they
can still *present information and suggestions*, but the player must make the choice (e.g.
by clicking a particular button).

Blizzard's 2006 statements summarized: addons and macros may still cast spells **with user
interaction**, but may no longer use logic to intelligently pick spells or targets.

WoW Classic runs the modern API, so the same model applies to all Classic clients.

---

## 2. Taint - the core rules

### 2.1 Where taint comes from

- When the UI loads, **Blizzard-signed FrameXML and Blizzard addons** (and their saved
  variables) are **secure**.
- **All third-party addon code and data** (and their saved variables), plus anything run via
  `/script` or `/run`, are **tainted**.
- Each addon's taint is labelled with its name, which is how error messages attribute blame.

### 2.2 How taint propagates

Execution begins **secure**. It becomes **tainted** as soon as it reads tainted data or runs
tainted code, and anything written while tainted is itself tainted.

All Lua values and references can carry taint: locals, globals, table keys, table values,
and function closures.

| Operation | Result |
|---|---|
| Create a new value (`local x = 2`) | Value inherits the **current execution's** taint |
| Read a **secure** value from tainted execution | The copy you get is tainted; the original stays clean |
| Read a **tainted** value | Value is tainted **and the execution path becomes tainted** |
| Write a global / table field | Stored value carries the **execution's** taint |
| Call a tainted **function closure** | Its taint is applied to the current execution |

**Taint persists until `/reload` or relog.** There is no "un-taint" API for addons.

### 2.3 The honey analogy (intuition)

Think of taint as honey. Addon code always has sticky hands; anything it touches becomes
sticky. Blizzard starts clean-handed, but touching something an addon made sticky makes
Blizzard's hands sticky too, and it spreads onward. An **error happens only when Blizzard
tries to call a protected function while sticky.** Every addon's honey has a different
flavour, so the error report "tastes" it to name the responsible addon - but that is the
addon that *last* stuck something, which is not always the root cause
(see `06_How_to_Deal_with_Taint.md`).

### 2.4 What taint breaks

- **Protected functions** refuse to run on a tainted path. Depending on the function and
  state, the client fires:
  - **`ADDON_ACTION_BLOCKED`** - action blocked (typically protected in combat only), and
  - **`ADDON_ACTION_FORBIDDEN`** - action never allowed for addons.
- **Protected frames** refuse protected methods in combat (`02_Object_Security.md`).
- **Retail 12.x:** tainted execution sees **secret values** from combat APIs and cannot
  operate on them (`07_Secret_Values_Midnight.md`).

---

## 3. Terminology

| Term | Meaning |
|---|---|
| **Secure** | Without taint |
| **Secure code** | An untainted current execution, or an untainted function |
| **Clean** | Same as secure (used for values/references/parameters) |
| **Protected function** | Only succeeds from a secure execution state |
| **Protected frame** | Locked down during combat |
| **Protected method** | A method that cannot succeed on a protected frame from tainted execution during combat |
| **Secure template** | XML template defining secure script handlers; usually creates protected frames |
| **Combat lockdown** | State in which protected frames are locked; test with `InCombatLockdown()` |
| **Restricted environment** | Sandboxed Lua environment where SecureHandler snippets run (`05_SecureHandlers.md`) |
| **Secret value** (12.x) | A value tainted code may hold/pass but not inspect (`07_...`) |

---

## 4. Securely post-hooking

Two APIs let addons react to Blizzard code **without spreading taint into it**:

| API | Behavior |
|---|---|
| `hooksecurefunc([table,] "name", func)` | Runs `func` **after** the original secure function, with a copy of the same arguments. The original's return values are **not** provided. The original remains untainted. |
| `frame:HookScript("OnX", func)` | Like `SetScript`, but `func` runs **after** existing handlers with the same arguments; doesn't taint the earlier handlers. |

Never hook secure functions by reassignment:

```lua
-- WRONG: taints the global; every Blizzard caller now runs your (tainted) closure.
local orig = UseAction
UseAction = function(...) MyLog(...); return orig(...) end

-- RIGHT:
hooksecurefunc("UseAction", function(slot, checkCursor, onSelf) MyLog(slot) end)
```

- `hooksecurefunc` hooks cannot be removed; gate with a flag.
- Your hook body is still tainted code. Doing harmless reads/prints is fine; mutating
  Blizzard state from inside the hook can still spread taint.

---

## 5. Protected frames and secure templates

Patch 2.0 also introduced **protected frames**, which can perform restricted interactions
during combat - **because they were configured out of combat** with predefined attributes.

- Once combat starts, the game itself manages showing/hiding/sizing/positioning these frames
  according to their attributes. Attribute logic is intentionally limited to rules that keep
  a human involved.
- **Secure code** (SecureHandlers, 3.0+) can run additional, still-limited logic in combat.
- A frame, once protected, **cannot become unprotected**. Protection usually comes from
  inheriting **SecureTemplates** (2.0) or **SecureHandlers** (3.0).
- Restrictions of a protected frame also apply to its **parents** and to frames it is
  **anchored to** (temporary; re-anchor/re-parent out of combat to release).
- Secure templates provide one or more **secure handlers** (usually `OnClick`) that read frame
  attributes to perform actions. Inherited handlers stay secure **unless the inheriting frame
  (or another template) overrides them**. Calling `SetScript("OnClick", ...)` on a secure
  button destroys its security - use `HookScript` or `SecureHandlerWrapScript` instead.
- Configure with `frame:SetAttribute(name, value)` **only out of combat**. Always check
  `InCombatLockdown()` before creating secure frames or changing their attributes.

```lua
local btn = CreateFrame("Button", "MyHealButton", UIParent, "SecureActionButtonTemplate")
btn:RegisterForClicks("AnyUp", "AnyDown")
local function Configure(spell)
    if InCombatLockdown() then return QueueAfterCombat(Configure, spell) end
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spell)
    btn:SetAttribute("unit", "mouseover")
end
```

Details: `04_SecureTemplates.md`, `05_SecureHandlers.md`.

---

## 6. Secure-execution global API

| Function | Purpose |
|---|---|
| `issecure()` | Is the **current** execution path secure? (Debugging; addon code will virtually always get false.) |
| `issecurevariable([table,] "name")` | Returns `isSecure, taintedBy` for a global or table field - the go-to taint investigation tool. |
| `securecall(func or "name", ...)` | Calls a function in a way that **restores** the caller's security state afterwards, so taint picked up *inside* the call doesn't leak out. Blizzard uses it to isolate addon callbacks. |
| `secureexecuterange(tbl, func, ...)` | Calls `func(key, value, ...)` for each entry, isolating each call securely (Blizzard uses it for callback lists). |
| `forceinsecure()` | Marks the current execution as insecure - Blizzard uses it to say "what follows isn't trusted". |
| `hooksecurefunc(...)` | Secure post-hook (section 4). |
| `InCombatLockdown()` | True during combat lockdown. |
| `RegisterStateDriver` / `RegisterAttributeDriver` / `RegisterUnitWatch` | Secure, conditional state changes (section `05`). |

Category of protected functions:
https://warcraft.wiki.gg/wiki/Category:World_of_Warcraft_API/Protected_Functions

Examples of protected operations (non-exhaustive): casting spells (`CastSpellByName`,
`CastSpellByID`), using actions/items (`UseAction`, `UseItemByName`), targeting
(`TargetUnit`, `AssistUnit`, `FocusUnit`, `ClearTarget`), movement helpers, running macros
(`RunMacroText`), and `Show/Hide/SetPoint/SetAttribute` on protected frames in combat.

---

## 7. Combat-lockdown lifecycle (canonical pattern)

```lua
local addonName, ns = ...
local queue = {}

function ns.RunOutOfCombat(fn, ...)
    if not InCombatLockdown() then return fn(...) end
    queue[#queue + 1] = { fn = fn, n = select("#", ...), ... }
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_REGEN_ENABLED")   -- lockdown has ended
f:SetScript("OnEvent", function()
    for i = 1, #queue do
        local job = queue[i]
        job.fn(unpack(job, 1, job.n))
        queue[i] = nil
    end
end)
```

- `PLAYER_REGEN_DISABLED` fires as lockdown **begins** - it is the last moment to prepare
  secure frames, but treat it as already too late for heavy reconfiguration.
- `PLAYER_REGEN_ENABLED` fires after lockdown **ends**.
- Create all secure frames at load/login time, not lazily.

---

## 8. What addons can and cannot do (practical boundary)

| Allowed | Not allowed (from addon logic) |
|---|---|
| Show information, timers, warnings, suggestions | Choose a target or spell automatically |
| Provide buttons whose action was configured out of combat | Change what a button does *in combat* based on addon logic (except via restricted snippets/state drivers keyed to macro conditionals and the click itself) |
| Different actions per mouse button / modifier / help-vs-harm | Cast in response to an event |
| Move/show/hide **non-protected** frames any time | Move/show/hide **protected** frames in combat from Lua |
| Secure post-hooks of Blizzard functions | Replacing Blizzard functions or writing Blizzard tables |
| Read most game state (Retail 12.x: possibly as secret values) | Inspect secret values on tainted paths (Retail 12.x) |

---

## 9. Patch timeline

| Patch | Change |
|---|---|
| 2.0.1 (2006) | Secure execution, taint, protected functions/frames, SecureTemplates |
| 2.1.0 (2007) | State drivers and UnitWatch |
| 3.0 (2008) | SecureHandlers + RestrictedEnvironment |
| 4.0.1 (2010) | AttributeDriver; `control` handle merged into general frame handles |
| 5.2 | Verbose taint log mode (`taintLog 11`) for diagnosis |
| 5.4.0 (2013) | Forbidden objects |
| 8.2.0 (2019) | Anchor-restricted regions |
| 10.1.0 (2023) | Inaccessible objects (Private Auras) |
| 12.0.0 (2026) | Secret values / secret aspects; combat log removed from addons |

---

## 10. External links

- Taint in World of Warcraft (Townlong Yak), archived: https://web.archive.org/web/20210518120056/https://www.townlong-yak.com/taint.log/about.html
- UIDropDownMenu taint issues (Townlong Yak), archived: https://web.archive.org/web/20200715202710/https://www.townlong-yak.com/bugs/PfF9rr-UIDropDownMenu
- Practical guide: `06_How_to_Deal_with_Taint.md`
