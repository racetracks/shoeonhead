# Secret Values (Retail 12.x / Midnight)

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary source: https://warcraft.wiki.gg/wiki/Secret_Values (page flagged "needs cleanup" at crawl time)
> Official posts: https://warcraft.wiki.gg/wiki/Patch_12.0.0/Planned_API_changes and the "Blue posts" sections of
> 12.0.1, 12.0.5, 12.0.7, 12.1.0 API change pages.
> Generated docs: `SecretPredicatesDocumentation.lua`, `SecretAspectConstantsDocumentation.lua` in
> https://github.com/Gethe/wow-ui-source (live branch), browsable at
> https://www.townlong-yak.com/framexml/latest/Blizzard_APIDocumentation
> Compiled 2026-10-08.

**Applies to:** Retail (Midnight, Patch **12.0.0+**, interface 120000+) and potentially other
Mainline-family clients that inherit 12.x API (check Forever). Classic-family clients
(Era, TBC Anniversary, Titan, Cata, MoP) **do not** use secret values as of this compilation  - 
feature-detect with `if issecretvalue then`.

---

## 1. Concept

Secret values restrict what **tainted** code (all addons) can do with certain Lua values.

- Combat-related APIs may return **secret values**, e.g. `UnitHealth(unit)`.
- On **untainted** (Blizzard) paths, secrets behave like normal values.
- On **tainted** paths, addons may **hold and forward** secrets but not **inspect** them.
- A small set of native APIs **accept** secrets from tainted callers (e.g.
  `StatusBar:SetValue`), so addons can still *display* secret data.

This lets addons build health bars, cast bars, aura icons etc. while preventing them from
**deciding** based on combat data (the same philosophy as the 2.0 security model, applied to
information instead of actions).

### 1.1 Test functions

| Function | Returns true when... |
|---|---|
| `issecretvalue(v)` | `v` is a secret value |
| `canaccessvalue(v)` | the caller is permitted to operate on `v` |
| `issecrettable(t)` | table `t` is secret |
| `canaccesstable(t)` | the caller can access `t` without erroring |

---

## 2. What tainted code may and may not do

Violations raise an **immediate Lua error**.

| Operation on a secret | Allowed for tainted code? |
|---|---|
| Store in a local / upvalue / table **value** | Yes |
| Pass to a **Lua** function | Yes |
| Pass to a **C** function | Yes only if the API is marked as accepting secrets from tainted callers |
| Concatenate (`..`) if string or number | Yes |
| `string.format`, `string.join`, `string.concat` with secrets | Yes (result is secret) |
| `type(secret)` | Yes returns the real type |
| Boolean test of a **non-boolean** secret (`if secret then`) | Yes (type isn't secret: nil -> false, others -> true) |
| Arithmetic (`+ - * / % ^`, unary minus) | No |
| Comparison (`== ~= < > <= >=`) | No |
| Boolean test of a **boolean** secret | No |
| Length `#secret` | No |
| Use as a table **key** | No |
| Index / assign (`secret.x`, `secret[k] = v`) | No |
| Call it as a function | No |

### 2.1 Secret tables

- A table can be flagged so **indexing always yields secrets**.
- A table can be flagged **inaccessible** to tainted code: indexing, assignment, `#`, or
  iteration errors with *"attempted to index a forbidden table"*.
- If **untainted** code stores a secret as a table **key**, that table is irrevocably given
  **both** flags.

---

## 3. Reading the API documentation for secrecy

Blizzard's generated docs (in-game `/api`, Townlong Yak, wow-ui-source) annotate functions:

| Annotation | Meaning |
|---|---|
| `SecretReturns = true` | Always returns secrets |
| `ConditionalSecret = true` (on a return field) | That return may be secret (e.g. `UnitClass` 1st return) |
| `SecretWhen...` / `SecretIn...` / `SecretOn...` predicate | Returns secrets when the predicate's restriction is active |
| `SecretArguments = "AllowedWhenUntainted"` | Accepts secrets only from untainted callers |
| `SecretArguments = "AllowedWhenTainted"` | Accepts secrets from anyone (addons can pass secrets) |
| `SecretArguments = "NotAllowed"` | Never accepts secrets |
| `SecretArgumentsAddAspect` / `SecretReturnsForAspect` | Widget aspect linkage (section 5) |
| `ConstSecretAccessor` | Doesn't mark the object, but returns become secret if any argument was secret (e.g. `ScriptRegion:GetHeight`) |

Example: `UnitName(unit)` returns secrets for non-player/non-pet units while in combat
(`SecretWhenUnitIdentityRestricted`).

### 3.1 Restriction states

Secrecy is mostly **conditional**, activated by *addon restriction* states:

- **Combat**, **Encounter**, **Challenge mode (Mythic+)**, **PvP match**, **restricted map**
  (dungeon/raid), **chat messaging lockdown**.
- Query current state: **`C_RestrictedActions`** namespace.
- Evaluate predicates directly: **`C_Secrets`** namespace.

### 3.2 Secret predicates (as of 12.1.5)

| Predicate | Since | Secret when... |
|---|---|---|
| SecretWhenInCombat | 12.0.0 | combat restrictions active |
| SecretWhenUnitAuraRestricted | 12.0.0 | combat/encounter/M+/PvP restrictions; per-spell never/always overrides |
| SecretWhenUnitHealthMaxRestricted | 12.0.0 | unit isn't player-controlled |
| SecretWhenUnitIdentityRestricted | 12.0.0 | unit isn't player-controlled or in party/raid; compound tokens secret if any link fails |
| SecretWhenUnitPowerRestricted | 12.0.0 | power types not flagged never-secret (unless unit lacks that power) |
| SecretWhenUnitPowerMaxRestricted | 12.0.0 | unit isn't player-controlled; per-power overrides |
| SecretWhenUnitSpellCastRestricted | 12.0.0 | cast info for units other than player/pet; per-spell overrides |
| SecretWhenUnitComparisonRestricted | 12.0.0 | on restricted maps, based on unit tokens; compound tokens always secret |
| SecretWhenTotemSlotSecret | 12.0.0 | combat/encounter/M+/PvP; per-totem overrides |
| SecretWhenAnchoringSecret | 12.0.0 | object has secret anchoring |
| SecretWhenCurveSecret | 12.0.0 | curve holds secrets |
| SecretInChatMessagingLockdown | 12.0.0 | encounter/M+/PvP restrictions and on comm-restricted maps |
| SecretInActivePvPMatch | 12.0.1 | PvP match restrictions |
| SecretWhenLossOfControlInfoRestricted | 12.0.1 | subject isn't the active player (except PvP spectator/commentator) |
| SecretWhenUnitThreatStateRestricted | 12.0.1 | depends on unit token pairing |
| SecretWhenUnitThreatValuesRestricted | 12.0.1 | depends on unit token pairing |
| SecretOnRestrictedMaps | 12.0.5 | on addon-restricted maps (dungeon/raid) |
| SecretWhenCooldownsRestricted | 12.0.5 | combat/encounter/M+/PvP; per-spell overrides |
| SecretWhenEncounterEvent | 12.0.5 | encounter events |
| SecretWhenNumericFormatterSecret | 12.0.5 | numeric formatter holds secrets |
| SecretWhenUnitStatsRestricted | 12.0.5 | unit stats would generally be secret |
| SecretWhenAurasRestricted | 12.1.0 | combat/encounter/M+/PvP |
| SecretWhenUnitNameIdentityRestricted | 12.1.0 | identity rules, except player units in PvP |
| SecretWhenUnitPossessionRestricted | 12.1.0 | aura secrecy, except tokens under player's control |
| SecretWhenLuaTableHasSecretKeys | 12.1.5 | subject table has secret keys |

### 3.3 Preconditions (APIs that refuse instead of returning secrets)

Failure modes: **ReturnNothing** (silently no values), **ReturnWithError**, **Error**.
Notable ones: `RequiresUnitIdentityAccess` (12.0.1), `RequiresDeclassifiedUnitIdentity` (12.0.5),
`RequiresUnitAuraAccess` (12.1.0, Error), `RequiresNonSecretAura` (returns nothing),
`RequiresComparableUnitTokens` (12.0.1 - e.g. `player`/`target` pairs OK, `nameplate3` vs
`boss1` not), `RequiresFontStringTextAccess` (getters on Text-aspected FontStrings return
nothing), `RequiresAssignableScript` / `RequiresSupportedScript` (12.1.0),
`RestrictedForMacroChatMessages` (12.0.1 - macro chat on externally visible channels during
encounters), `MouseFocusValidForLimitedInput` (12.0.7), `RequiresTimedSignalMapAccess` (12.1.5).

---

## 4. Display-without-inspection toolkit

| Need | Tool |
|---|---|
| Health/power bar | `StatusBar:SetMinMaxValues(0, UnitHealthMax(u))` + `StatusBar:SetValue(UnitHealth(u))` - both accept secrets |
| Text of a secret number/name | `FontString:SetText(secret)` / `SetFormattedText("%s", secret)` |
| Color by percentage (e.g. green -> red) | **ColorCurve**: `C_CurveUtil.CreateColorCurve()` |
| Map secret number -> another number | **Curve**: `C_CurveUtil.CreateCurve()` |
| Countdown / elapsed timers | **Duration** objects: `C_DurationUtil.CreateDuration()`, then `StatusBar:SetTimerDuration(duration)` |
| Cooldown swipes | `Cooldown:SetCooldown...` APIs accept secrets (apply the `Cooldown` aspect) |
| Show/hide or tint from a secret boolean | `SetAlphaFromBoolean`, `SetVertexColorFromBoolean` |

```lua
local function UpdateHealth(bar, unit)
    bar:SetMinMaxValues(0, UnitHealthMax(unit))   -- may be secret: fine
    bar:SetValue(UnitHealth(unit))                -- may be secret: fine
    -- DON'T: local pct = UnitHealth(unit) / UnitHealthMax(unit)  -- errors if secret
end

local function SafeNumber(v)                      -- only for optional, non-critical logic
    if issecretvalue and issecretvalue(v) and not canaccessvalue(v) then return nil end
    return v
end
```

---

## 5. Secret aspects (per-widget property secrecy)

When a widget setter receives a secret, it may apply an **aspect** to the object; matching
getters then return secrets to tainted callers.

- Example: `FontString:SetText(UnitName("target"))` while restricted -> `Text` aspect -> later
  `FontString:GetText()` returns a secret.
- Aspects are cleared **only** by `FrameScriptObject:SetToDefaults()` (unless the object has the
  `RemoveSecretAspects` forbidden aspect).
- Test with `HasSecretAspect(Enum.SecretAspect.X)`; `HasAnySecretAspect()`.

| Aspect (`Enum.SecretAspect`) | Set by (examples) | Getters affected (examples) |
|---|---|---|
| ObjectName / ObjectType / ObjectDebug / ObjectSecrets / ObjectSecurity / Hierarchy | - | `GetName`, `GetObjectType`, `IsObjectType`, `HasScript`, `GetSourceLocation`, `IsForbidden`, `IsProtected`, `GetChildren`, `GetParent`, ... |
| Attributes (12.0.1) | - | `GetAttribute`, `SetAttribute`, `ExecuteAttribute`, `ClearAttribute` |
| ID | `Frame:SetID` | `GetID` |
| Toplevel | `SetToplevel` | `IsToplevel` |
| Text | `SetText`, `SetFormattedText`, `SetTextToFit`, `EditBox:Insert/SetNumber/SetText`, `GameTooltip:SetText`, `SimpleHTML:SetText` | `GetText`, `GetDisplayText`, `GetNumber`, cursor/character-index queries |
| SecureText | `EditBox:SetSecureText` | `IsSecureText` |
| Shown | `SetShown` | `IsShown`, `IsVisible` |
| Scale | `SetScale` | `GetScale`, `GetEffectiveScale` |
| Alpha | `SetAlpha`, `SetAlphaFromBoolean`, `SetVertexColor*`, `SetTextColor`, `SetStatusBarColor` | `GetAlpha`, `GetEffectiveAlpha`, color getters |
| FrameLevel | `SetFrameLevel` | `GetFrameLevel` |
| ScrollRange | - | `GetHorizontal/VerticalScrollRange` |
| Cursor | `EditBox:SetCursorPosition` | cursor getters |
| VertexColor | `SetVertexColor*`, `SetTextColor`, `SetStatusBarColor` | color getters |
| Desaturation | `SetDesaturated/SetDesaturation`, StatusBar variants | desaturation getters |
| TexCoords | `SetTexCoord`, `SetSpriteSheetCell` | `GetTexCoord` |
| BarValue | `StatusBar:SetMinMaxValues`, `SetValue` | `GetValue`, `GetMinMaxValues`, `GetInterpolatedValue`, `IsInterpolating` |
| Cooldown | `Cooldown:SetCooldown*` | `GetCooldownTimes`, `GetCooldownDuration`, `GetCooldownDisplayDuration` |
| Rotation | `SetRotation` | `GetRotation` |
| MinimumWidth / Padding | `GameTooltip:SetMinimumWidth/SetPadding` | getters |
| CooldownStyle (12.0.1) | `SetDrawBling/Edge/Swipe`, `SetEdgeColor`, `SetSwipeColor` | `GetDraw*` |
| TooltipTexture (12.0.1) | - | - |
| ButtonState (12.0.7) | `Button:SetButtonState`, `SetEnabled` | `GetButtonState`, `IsEnabled` |
| ScrollOffset (12.0.7) | `SetHorizontal/VerticalScroll` | getters |
| RadialProgress (12.1.0) | `SetRadialProgressBarPercent` | getter |

### 5.1 Secret anchors

Setters that accept secrets **without** a specific aspect (e.g. `StatusBar:SetValue` per the wiki
example) mark the **whole object** as *having secret values*:

- All APIs on it return secrets unless they derive secrecy from an aspect.
- Its **anchoring/position data becomes secret**, and this **propagates to regions anchored to
  it** (child B anchored to A inherits secret anchors).
- Position/measurement calls return secrets. Test with `HasSecretValues()` and
  `ScriptRegion:IsAnchoringSecret()`. Clearing anchor points can reset the state.

**Design rule:** don't anchor layout-critical frames (whose sizes/positions you need to read) to
widgets that display secret values. Anchor display widgets *to* your layout frames, not the reverse.

### 5.2 Constant accessors

Some getters (e.g. `ScriptRegion:GetHeight(ignoreRect)`) never mark the object, but return secrets
if any argument passed was secret.

---

## 6. Forbidden aspects (with Private Script Objects)

Where secret aspects **obscure data**, forbidden aspects **prohibit capabilities**. Example from
Blizzard: with `UntrustedScriptExecution`, script handlers on the object only run if they live in the
object's *forbidden partition* and execution is untainted - addons can't install their own.

| `Enum.ForbiddenAspect` | Restricts |
|---|---|
| SetToDefaults | Resetting object (implied by any other) |
| ScriptBindings | Query/replace/hook scripts |
| UntrustedScriptExecution | Running scripts (propagates to children) |
| UntrustedLayoutScriptExecution | Layout scripts like `OnSizeChanged` (propagates to children and anchored objects) |
| EventRegistrations | Query/modify event registrations |
| AlwaysPropagateInput | Forces mouse/key input propagation (to children) |
| ScriptedInput | Synthetic input APIs (e.g. scripted clicks) |
| QueryFocus | Input-focus queries |
| ChangeAnimationTarget | Re-targeting animations |
| RemoveSecretAspects | Clearing secret aspects |
| ChangeParent | Re-parenting |
| SetTexture (12.1.5) | Setting textures |
| QueryRotation (12.1.5) | Texture rotation queries |
| QueryAnimationProgress (12.1.5) | Animation progress/state queries |
| AddAnimations (12.1.5) | Adding animations to groups |

Test with `FrameScriptObject:HasAnyForbiddenAspect()`.

---

## 7. Testing restrictions outside real combat

Session-only CVars (not saved across restarts):

| CVar | Forces |
|---|---|
| `addonCombatRestrictionsForced` | Combat restrictions |
| `addonEncounterRestrictionsForced` | Encounter restrictions |
| `addonChallengeModeRestrictionsForced` | Mythic+ restrictions |
| `addonPvPMatchRestrictionsForced` | PvP match restrictions |
| `addonMapRestrictionsForced` | Restricted-map rules |
| `addonChatRestrictionsForced` | Chat lockdown |

```
/console addonCombatRestrictionsForced 1
```

---

## 8. Related 12.x removals

- `COMBAT_LOG_EVENT` / `COMBAT_LOG_EVENT_UNFILTERED`: **not accessible** to addons since 12.0.0;
  registering fires `ADDON_ACTION_FORBIDDEN`. Damage meters, proc trackers, interrupt trackers
  etc. that relied on CLEU must be redesigned around Blizzard's provided systems or dropped on
  Retail. (Still available on Classic-family clients.)

---

## 9. Rules for AI code generation (Retail 12.x)

1. Treat every value from unit/aura/cooldown/cast/threat/stat/loss-of-control APIs as
   **possibly secret**.
2. **Never** do arithmetic, comparisons, `#`, indexing, or table-key use on such values unless
   `canaccessvalue(v)` is true - and design so the feature degrades gracefully when it's false.
3. Route secret data **directly into widgets** that accept secrets (StatusBar, FontString,
   Cooldown, Curves, Durations, `*FromBoolean` setters).
4. Don't read back widget state (`GetText`, `GetValue`, `GetPoint`, `IsShown`) for logic after
   feeding it secrets.
5. Don't anchor layout frames to secret-bearing widgets.
6. Don't register `COMBAT_LOG_EVENT_UNFILTERED` on Retail.
7. Feature-detect: `if issecretvalue then ... end` to keep Classic builds working.
8. Test with the `addon*RestrictionsForced` CVars.
9. Consult the generated API docs (`/api`, Townlong Yak) for each function's secret annotations
   before writing logic that depends on its return values.
