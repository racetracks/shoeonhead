# Object Security

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary source: https://warcraft.wiki.gg/wiki/Object_security (with cross-references to
> https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting and https://warcraft.wiki.gg/wiki/Secret_Values).
> Compiled 2026-10-08.

**Object security traits** are protections that UI objects (frames, regions, script objects)
carry to restrict what **insecure code** - i.e. every addon and every `/script` - may do with
them. They complement *execution* security (taint, see `03_Secure_Execution_and_Tainting.md`):
taint describes **who is running**; object security describes **what the object allows**.

There are four classic levels, introduced over time, plus the Midnight-era aspect system:

| Level | Introduced | What it blocks | Query |
|---|---|---|---|
| **Protected** | 2.0.1 (2006-12-05) | Changing secure attributes, position, size, visibility *in combat* from insecure code | `region:IsProtected()` |
| **Forbidden** | 5.4.0 (2013-09-10) | Almost **all** method calls from insecure code, **always** | `obj:IsForbidden()` |
| **Anchor-restricted** | 8.2.0 (2019-06-25) | Reading position info; anchoring across two anchor families | `region:IsAnchoringRestricted()` |
| **Inaccessible** | 10.1.0 (2023-05-02) | Obtaining any reference to the object at all | *(no direct test)* |
| Secret / Forbidden **aspects** | 12.0.0+ | Per-property secrecy of returns / per-feature prohibition | `HasSecretAspect`, `HasAnyForbiddenAspect`... - see `07_Secret_Values_Midnight.md` |

---

## 1. Protected regions (2.0.1)

**What:** While the player is in combat (combat lockdown), insecure code cannot modify a
protected region's:

- secure execution **attributes** (`SetAttribute`),
- **position** (`SetPoint`, `ClearAllPoints`, `SetAllPoints`),
- **size** (`SetWidth`, `SetHeight`, `SetSize`, scale),
- **visibility** (`Show`, `Hide`, `SetShown`),
- **parent** and similar layout state.

These are the *protected methods*. Out of combat, insecure code may call them freely.

**Typical examples:** Blizzard action bar buttons, unit frames, and *any* frame you create
from a secure template (`SecureActionButtonTemplate`, `SecureUnitButtonTemplate`,
`SecureHandler*Template`, group headers...).

**Key facts:**

- Test with `region:IsProtected()` (returns whether it *will be* protected in combat; a second
  return indicates explicit protection).
- **Once protected, always protected.** A frame cannot be made unprotected.
- Protection is normally **inherited from a secure template**; you don't flip it on manually.
- **Restriction propagation:** protected-frame control restrictions also apply to the
  protected frame's **parents** and to any frames it is **anchored to**. Anchoring a
  protected button to your ordinary container makes that container effectively locked in
  combat. The propagation is *temporary*: re-anchoring or re-parenting out of combat releases it.
- Violations from insecure code in combat produce **`ADDON_ACTION_BLOCKED`** and the familiar
  "Interface action failed because of an AddOn" message.

**Rules for code generation:**

```lua
local function SafeShow(frame)
    if InCombatLockdown() and frame:IsProtected() then
        pendingShow[frame] = true                -- defer
        return
    end
    frame:Show()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")         -- fires when combat lockdown ends
ev:SetScript("OnEvent", function()
    for f in pairs(pendingShow) do f:Show() end
    wipe(pendingShow)
end)
```

- In combat, protected frames are moved/shown/hidden **only** by secure code: Blizzard's own,
  secure template logic, SecureHandler snippets, or state drivers (`05_SecureHandlers.md`).
- `frame:CanChangeProtectedState()` (ScriptRegion) reports whether the current context may
  change protected state.

---

## 2. Forbidden objects (5.4.0)

**What:** Insecure code may call **almost no methods** on a forbidden object, in or out of combat.

- First implemented to protect the **In-Game Store**; used for other sensitive Blizzard UI
  (e.g. some nameplate/secure UI internals).
- Test with `obj:IsForbidden()` - this is one of the few methods always callable.
- The only other methods insecure code can call on a forbidden object are
  `Frame:GetAttribute()` and `Frame:SetAttribute()`.
- Forbidden objects are **omitted** from enumeration APIs such as `EnumerateFrames()` and
  `C_System.GetFrameStack()`.
- Attempting to call a disallowed method raises an error / fires `ADDON_ACTION_FORBIDDEN`.

**Rule:** if an addon iterates or hooks frames it doesn't own (e.g. nameplate skinning,
tooltip hooks), check `IsForbidden()` first and bail out:

```lua
-- Classic-family example. (Retail 10.0.2+ uses TooltipDataProcessor.AddTooltipPostCall
-- instead of OnTooltipSetUnit; the IsForbidden() guard applies the same way.)
GameTooltip:HookScript("OnTooltipSetUnit", function(tt)
    if tt:IsForbidden() then return end
    -- safe to touch tt
end)
```

---

## 3. Anchor-restricted regions (8.2.0)

**What:** Two restrictions for insecure code:

1. **No position queries.** `ScriptRegion:GetRect()`, `GetPoint()`, `GetLeft/Right/Top/Bottom`,
   `GetCenter()` etc. cannot be called on the region from insecure code.
2. **No bridging anchor families.** `SetPoint()` fails with a *forbidden action* error if the
   resulting anchors would position the region relative to **two distinct anchor families**
   at once.

- Typical examples: **nameplates** and **chat bubbles**.
- Test with `region:IsAnchoringRestricted()`.
- The usual trigger for (2) is anchoring a restricted region to **both** the screen/WorldFrame
  family **and** `UIParent`. Call `ClearAllPoints()` before applying the new anchor set so the
  old anchors don't combine with the new ones.

```lua
-- Re-anchoring something attached to a nameplate:
myWidget:ClearAllPoints()                         -- drop previous family first
myWidget:SetPoint("BOTTOM", nameplate, "TOP", 0, 2)
```

- Don't attempt to compute screen coordinates of nameplates/chat bubbles from addon code.

---

## 4. Inaccessible objects (10.1.0)

**What:** Objects for which **no reference can be obtained** through any object method, and
whose names may be obscured.

- Used by the **Private Auras** UI (encounter debuff display that addons must not read).
- No dedicated test method exists.
- `Object:GetDebugName()` returns strings like `"$parent.inaccessible"` - `.inaccessible`
  repeated for each inaccessible, unnamed ancestor.
- `Object:GetParentKey()` always returns `nil`.
- `Frame:GetChildren()` and `Frame:GetRegions()` **never** return inaccessible children  - 
  **even to secure callers**.

**Rule:** don't design features that require discovering, reading, or restyling Private Aura
frames. Use the anchoring APIs Blizzard provides for private auras (e.g. the
`C_UnitAuras` private-aura anchor functions on Retail) when you need to position them.

---

## 5. Midnight (12.x) extensions: secret aspects & forbidden aspects

Patch 12.0.0 added two finer-grained, per-object mechanisms (details in
`07_Secret_Values_Midnight.md`):

- **Secret aspects** - when a widget setter receives a secret value (e.g. `FontString:SetText`
  with a secret name), the object gains an *aspect* (e.g. `Text`). Afterward the matching
  getters (e.g. `GetText`) return **secret values** to tainted code. Cleared only by
  `FrameScriptObject:SetToDefaults()`. Test with `HasSecretAspect(aspect)`,
  `HasAnySecretAspect()`, `HasSecretValues()`.
- **Secret anchors** - setters with no specific aspect (e.g. `StatusBar:SetValue(secret)`) mark
  the whole object as *having secret values*, which makes its anchoring/position data secret
  and **propagates to regions anchored to it**. Test with `IsAnchoringSecret()`; clearing
  anchors can reset it.
- **Forbidden aspects** - prohibit specific *capabilities* on an object (e.g.
  `ScriptBindings`, `UntrustedScriptExecution`, `EventRegistrations`, `ChangeParent`,
  `SetTexture`). Work alongside *Private Script Objects*. Test with `HasAnyForbiddenAspect()`.

---

## 6. Decision table for AI code generation

| Situation | Do | Don't |
|---|---|---|
| Need to move/show/hide a frame that is (or may become) protected | Check `InCombatLockdown()`; defer to `PLAYER_REGEN_ENABLED`; or drive it with a state driver / SecureHandler | Call `Show/SetPoint` unconditionally |
| Need a clickable spell/macro/target button | Inherit `SecureActionButtonTemplate`, set attributes out of combat | Call `CastSpellByName` from Lua |
| Hooking tooltips or third-party frames | Check `IsForbidden()` first | Assume every frame is accessible |
| Attaching widgets to nameplates | `ClearAllPoints()` then anchor; never read nameplate rects | Call `GetPoint/GetRect` on nameplates |
| Displaying private auras | Use Blizzard's private-aura anchor APIs | Enumerate children to find them |
| Retail 12.x: setting text/values from combat APIs | Expect getters to return secrets afterwards | Read back `GetText()`/`GetValue()` and compute with it |
| Container for secure buttons | Make the container itself secure (e.g. a `SecureHandlerStateTemplate` header) or accept it is locked in combat | Anchor secure buttons to a frame you plan to move in combat |

---

## 7. Related API

| API | Purpose |
|---|---|
| `ScriptRegion:IsProtected()` | Will this region be protected in combat? |
| `ScriptRegion:CanChangeProtectedState()` | May the current context change protected state? |
| `FrameScriptObject:IsForbidden()` | Is the object forbidden? |
| `ScriptRegion:IsAnchoringRestricted()` | Anchor-restricted? |
| `ScriptRegion:IsAnchoringSecret()` | (12.x) Anchoring data secret? |
| `FrameScriptObject:HasSecretAspect(aspect)` / `HasAnySecretAspect()` / `HasSecretValues()` | (12.x) Secret state |
| `FrameScriptObject:HasAnyForbiddenAspect()` | (12.x) Forbidden aspects present? |
| `FrameScriptObject:SetToDefaults()` | (12.x) Clears secret aspects (unless forbidden) |
| `Frame:CanChangeAttribute()` | May attributes be changed now? |
| `InCombatLockdown()` | Is combat lockdown active? |
| Events `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN`, `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED` | Diagnostics & lockdown transitions |

## 8. Patch history

| Patch | Date | Change |
|---|---|---|
| 12.0.0 | 2026-01-20 | Secret values, secret aspects, (later) forbidden aspects |
| 10.1.0 | 2023-05-02 | Inaccessible objects |
| 8.2.0 | 2019-06-25 | Anchor-restricted regions |
| 5.4.0 | 2013-09-10 | Forbidden objects |
| 2.0.1 | 2006-12-05 | Protected regions |
