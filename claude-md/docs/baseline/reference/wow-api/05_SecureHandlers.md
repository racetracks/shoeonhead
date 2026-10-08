# SecureHandlers (+ RestrictedEnvironment & SecureStateDriver)

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary sources: https://warcraft.wiki.gg/wiki/SecureHandlers ,
> https://warcraft.wiki.gg/wiki/RestrictedEnvironment , https://warcraft.wiki.gg/wiki/SecureStateDriver
> Blizzard source: `SecureHandlerTemplates.xml`, `SecureHandlers.lua`, `RestrictedEnvironment.lua`,
> `RestrictedFrames.lua`, `SecureStateDriver.lua` - https://www.townlong-yak.com/framexml/live
> Deep dive: Iriel's *Field Guide to Secure Handlers* (4.0 r1) - http://www.iriel.org/wow/docs/SecureHeadersGuide-4.0-r1.pdf
> Compiled 2026-10-08.

SecureTemplates (`04_SecureTemplates.md`) let a frame do one predetermined thing per click.
**SecureHandlers** (Patch 3.0) go further: they run **snippets of restricted Lua** securely,
**even in combat**, so protected frames can react to clicks, attribute changes, state changes
(macro conditionals), mouse-over, show/hide, etc. - without addon (tainted) code being on the
call path.

The trade-off: snippets run inside the **RestrictedEnvironment**, a sandbox with a deliberately
tiny API that cannot read most game state, so it can't be used to automate decisions.

---

## 1. Snippets - what they are

- A **snippet** is a **string** containing the *body* of a Lua function.
- It is compiled and executed in the restricted environment, with named arguments supplied by
  the handler type (e.g. `self, button, down` for clicks).
- Snippets are usually stored in **underscore-prefixed attributes** (`_onclick`, `_onstate-foo`)
  which **restricted code cannot read or write** (handles reject names beginning with `_`),
  preventing snippets from rewriting themselves.
- Use long-bracket strings for readability: `[[ ... ]]` or `[=[ ... ]=]` if the body contains `]]`.
- Each **owner** (the SecureHandler frame) has its own private restricted environment; variables
  assigned without `local` persist in that environment between snippet runs (this is how
  snippets keep state).

```lua
local f = CreateFrame("Button", "MyToggle", UIParent, "SecureHandlerClickTemplate")
f:RegisterForClicks("AnyUp")
f:SetAttribute("_onclick", [=[
    -- args: self, button, down
    if button == "RightButton" then
        self:Hide()
    end
]=])
```

---

## 2. Template catalogue

All inherit **`SecureHandlerBaseTemplate`**, whose `OnLoad` adds the four methods in section 3.

| Template | Fires on | Attribute(s) & snippet arguments |
|---|---|---|
| `SecureHandlerBaseTemplate` | - | Adds methods only |
| `SecureHandlerStateTemplate` | `state-xxx` attribute changes | `_onstate-xxx` (self, stateid, newstate) |
| `SecureHandlerAttributeTemplate` | Any attribute change | `_onattributechanged` (self, name, value) |
| `SecureHandlerClickTemplate` | Clicks | `_onclick` (self, button, down) |
| `SecureHandlerDoubleClickTemplate` | Double clicks | `_ondoubleclick` (self, button, down) |
| `SecureHandlerDragTemplate` | Drag | `_ondragstart` (self, button); `_onreceivedrag` (self, button, kind, value, ...) |
| `SecureHandlerMouseUpDownTemplate` | Mouse up/down | `_onmouseup` (self, button); `_onmousedown` (self, button) |
| `SecureHandlerMouseWheelTemplate` | Mouse wheel | `_onmousewheel` (self, delta) |
| `SecureHandlerEnterLeaveTemplate` | Mouse enter/leave | `_onenter` (self); `_onleave` (self) |
| `SecureHandlerShowHideTemplate` | Show/hide | `_onshow` (self); `_onhide` (self) |

Templates can be combined: `"SecureHandlerStateTemplate, SecureHandlerClickTemplate"`.

---

## 3. Methods added by SecureHandlerBaseTemplate

Call these from **insecure** (addon) code, **out of combat**, to set up secure behavior.

| Method | Purpose |
|---|---|
| `frame:Execute(body)` | Run a snippet once in this frame's restricted environment (initialization, e.g. building handle tables). |
| `frame:WrapScript(targetFrame, script, preBody [, postBody])` | Wrap `targetFrame`'s `script` (e.g. `"OnClick"`) so `preBody` runs securely before the original handler and `postBody` after. The wrapper runs in **this** frame's environment (`owner`). |
| `frame:UnwrapScript(targetFrame, script)` | Remove and return the outermost wrapper. |
| `frame:SetFrameRef(id, refFrame)` | Expose another frame to snippets; retrieved inside via `self:GetFrameRef(id)` / `owner:GetFrameRef(id)`. |

Global equivalents also exist: `SecureHandlerExecute(frame, body)`,
`SecureHandlerWrapScript(frame, script, header, preBody, postBody)`,
`SecureHandlerUnwrapScript(frame, script)`, `SecureHandlerSetFrameRef(frame, id, ref)`.

### 3.1 WrapScript - pre/post body semantics

- **preBody** receives the script's normal arguments (for `OnClick`: `self, button, down`) and
  can:
  - return `false` to **cancel** the original handler,
  - return a new **button** value to change what the original sees (for click handlers),
  - return a second value (a "message") that is passed to **postBody**.
- **postBody** receives `self, message, ...` and runs after the original.
- Wrapping a `SecureActionButtonTemplate` button's `OnClick` is the standard way to add
  combat-time logic (e.g. "remap this click based on a state the driver set") without
  breaking its security.

```lua
local owner = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
owner:WrapScript(MyActionButton, "OnClick", [=[
    -- self = MyActionButton handle, owner = the wrapping frame
    if IsShiftKeyDown() then
        return "RightButton"          -- treat shift-click as right-click
    end
]=])
```

---

## 4. The RestrictedEnvironment

### 4.1 Available global API (complete list per wiki)

Conditionals & state: `SecureCmdOptionParse("conditional")`, `GetShapeshiftForm()`,
`IsStealthed()`, `IsMounted()`, `IsSwimming()`, `IsSubmerged()`, `IsFlying()`,
`IsFlyableArea()`, `IsIndoors()`, `IsOutdoors()`, `PlayerInCombat()`, `PlayerInGroup()`,
`PlayerIsChanneling()`, `PlayerPetSummary()`, `PlayerCanAttack(unit)`, `PlayerCanAssist(unit)`.

Units: `UnitExists`, `UnitIsDead`, `UnitIsGhost`, `UnitPlayerOrPetInParty`,
`UnitPlayerOrPetInRaid`, `UnitHasVehicleUI`.

Input: `IsAltKeyDown`, `IsLeftAltKeyDown`, `IsRightAltKeyDown`, `IsControlKeyDown`,
`IsLeftControlKeyDown`, `IsRightControlKeyDown`, `IsShiftKeyDown`, `IsLeftShiftKeyDown`,
`IsRightShiftKeyDown`, `IsModifierKeyDown`, `IsModifiedClick(type)`, `GetMouseButtonClicked()`,
`GetBindingKey(action)`.

Action bars: `GetActionBarPage`, `GetBonusBarOffset`, `HasAction(slot)`, `GetActionInfo(slot)`
(limited), `HasVehicleActionBar`, `HasOverrideActionBar`, `HasTempShapeshiftActionBar`,
`HasOverrideUI`, `HasExtraActionBar`, `GetVehicleBarIndex`, `GetOverrideBarIndex`,
`GetTempShapeshiftBarIndex`, `CanExitVehicle`.

Spells/items: `IsHarmfulSpell`, `IsHelpfulSpell`, `IsHarmfulItem`, `IsHelpfulItem`.

Drivers: `RegisterStateDriver(frame, state, conditional)` (call it on a handle).

Notably **absent**: health, power, auras, cooldowns, range, positions of units, combat log  - 
anything that would let a snippet "decide" based on combat data.

### 4.2 Lua libraries

- `math` and `string` tables in full.
- Globals: `select tonumber tostring print format gmatch gsub strbyte strchar strconcat
  strfind strjoin strlen strlower strmatch strrep strrev strsplit strsub strtrim strupper abs
  acos asin atan atan2 ceil cos deg exp floor frexp ldexp log log10 max min mod rad random
  sin tan`.

### 4.3 Restricted tables

Only **restricted tables** exist inside the environment (real tables are kept outside). Use the
restricted-aware functions:

| Library | Functions |
|---|---|
| `rtable.*` | `next pairs ipairs unpack newtable maxn insert remove sort concat wipe type rtgsub` |
| `table.*` (restricted-aware) | `maxn insert remove sort concat wipe new` |
| Globals | `newtable pairs ipairs next unpack wipe tinsert tremove type rtgsub` |

- Create tables with `newtable()` (or `table.new()`), **not** `{}` literals for shared state.
- `table.sort` cannot take a comparison function (no real function references exist inside).
- Plain `gsub` isn't restricted-table aware; use `rtgsub` when the replacement is a table lookup.

### 4.4 Frame handles

Real frame userdata never enters the environment. Snippets get **handles**:

- `self` - handle of the frame the snippet is running for.
- `owner` - handle of the frame that owns the environment (`control` is a legacy alias).
- More handles via `owner:GetFrameRef("name")` after `frame:SetFrameRef("name", realFrame)`.

Methods marked * are callable on handles to **non-protected** frames; all others require the
target to be protected.

**Accessors**

| * | Method | Returns |
|---|---|---|
| * | `GetName()` | Frame name |
| * | `GetObjectType()` | Widget type |
| * | `IsObjectType(t)` | Type check |
| * | `IsProtected()` | Protected? |
| | `GetID()` | Frame ID |
| | `IsShown()`, `IsVisible()` | Shown / effectively visible |
| | `GetWidth()`, `GetHeight()`, `GetRect()`, `GetScale()`, `GetEffectiveScale()` | Geometry |
| | `GetFrameLevel()` | Level |
| | `GetAttribute(name)` | Attribute (name must not start with `_`) |
| | `GetEffectiveAttribute(name, button, prefix, suffix)` | Modified-attribute resolution |
| | `GetFrameRef(name)` | Handle set by `SetFrameRef` |
| | `GetChildren()`, `GetChildList(tbl)`, `GetParent()` | Hierarchy handles |
| | `GetMousePosition()` | Mouse pos relative to frame (0,0 = bottom-left) |
| | `IsUnderMouse(recursive)` | Hover test |
| | `GetNumPoints()`, `GetPoint(i)` | Anchors |

**Setters**

| Method | Effect |
|---|---|
| `Show(skipAttr)`, `Hide(skipAttr)` | Show/hide; unless `skipAttr`, also sets/clears `statehidden` attribute |
| `SetID`, `SetWidth`, `SetHeight`, `SetScale`, `SetAlpha` | Basic properties |
| `ClearAllPoints()`, `SetPoint(p, rel, rp, x, y)`, `SetAllPoints(rel)` | Anchoring (rel is a handle) |
| `SetAttribute(name, value)` | Name must not start with `_` |
| `ClearBindings()`, `ClearBinding(key)` | Remove override bindings owned by this frame |
| `SetBindingClick(priority, key, name, button)` | Override binding that clicks a button |
| `SetBindingSpell`, `SetBindingMacro`, `SetBindingItem` | Other override bindings |
| `Raise()`, `Lower()`, `SetFrameLevel(n)`, `SetParent(h)` | Layering / hierarchy |
| `RegisterAutoHide(sec)`, `UnregisterAutoHide()`, `AddToAutoHide(h)` | Hide after mouse leaves |
| `Enable()`, `Disable()` | Button click handling |

**Control flow**

| * | Method | Effect |
|---|---|---|
| * | `CallMethod("name", ...)` | **Insecurely** call `realFrame:name(...)` - the bridge back to addon Lua (e.g. for cosmetics). Taint stays out of the secure path. |
| | `Run(body, ...)` | Run a snippet in handle's environment with `(handle, ...)` |
| | `RunFor(otherHandle, body, ...)` | Run snippet with `(otherHandle, ...)` |
| | `RunAttribute("attr", ...)` | Run snippet stored in an attribute |
| | `ChildUpdate("scriptid", message)` | Run `_childupdate-scriptid` (or `_childupdate`) on all protected descendants with `(self, scriptid, message)` |

---

## 5. SecureStateDriver

Drives secure state from **macro conditionals**, evaluated by Blizzard's
`SecureStateDriverManager`.

### 5.1 AttributeDriver

```lua
RegisterAttributeDriver(frame, attribute, conditional)
UnregisterAttributeDriver(frame, attribute)
RegisterStateDriver(frame, state, conditional)   -- legacy; = RegisterAttributeDriver(frame, "state-"..state, ...)
UnregisterStateDriver(frame, state)
```

- `attribute = "state-visibility"` -> securely `Show()` when the conditional yields `show`,
  `Hide()` when it yields `hide`.
- Any other attribute -> securely `SetAttribute(attribute, result)`. With
  `SecureHandlerStateTemplate`, a `state-xxx` change runs `_onstate-xxx`.
- Attribute names are lower-cased.

### 5.2 UnitWatch

```lua
RegisterUnitWatch(frame [, asState])
UnregisterUnitWatch(frame [, asState])
```

For `SecureUnitButtonTemplate` frames with a `unit` attribute. `asState` false/nil ->
show/hide by unit existence; true -> sets `state-unitexists`.

### 5.3 Evaluation timing

Conditionals are re-evaluated at most every `STATE_DRIVER_UPDATE_THROTTLE` (0.2 s) via
`OnUpdate`, **and immediately** on: `MODIFIER_STATE_CHANGED`, `ACTIONBAR_PAGE_CHANGED`,
`UPDATE_BONUS_ACTIONBAR`, `PLAYER_ENTERING_WORLD`, `UPDATE_SHAPESHIFT_FORM`, `UPDATE_STEALTH`,
`PLAYER_TARGET_CHANGED`, `PLAYER_FOCUS_CHANGED`, `PLAYER_REGEN_DISABLED`,
`PLAYER_REGEN_ENABLED`, `UNIT_PET`, `GROUP_ROSTER_UPDATE`.

---

## 6. Worked patterns

### 6.1 Combat-safe visibility (no snippet needed)

```lua
local bar = CreateFrame("Frame", "MyBar", UIParent, "SecureHandlerStateTemplate")
RegisterAttributeDriver(bar, "state-visibility", "[petbattle][vehicleui] hide; [combat] show; hide")
```

### 6.2 Custom state with a snippet

```lua
local f = CreateFrame("Frame", "MyStateFrame", UIParent, "SecureHandlerStateTemplate")
RegisterStateDriver(f, "petstate", "[@pet,noexists] nopet; [@pet,help] mypet; [@pet,harm] mcpet")
f:SetAttribute("_onstate-petstate", [[
    -- self, stateid, newstate
    if newstate == "nopet" then
        self:Hide()
    else
        self:Show()
    end
]])
```

### 6.3 Action bar paging (stance/form) with ChildUpdate

```lua
local header = CreateFrame("Frame", "MyPagedBar", UIParent, "SecureHandlerStateTemplate")
for i = 1, 12 do
    local b = CreateFrame("Button", "MyPagedBarButton"..i, header, "SecureActionButtonTemplate")
    b:SetID(i)
    b:SetAttribute("type", "action")
    b:SetAttribute("_childupdate-page", [[
        -- self, scriptid, message
        self:SetAttribute("action", (message - 1) * 12 + self:GetID())
    ]])
end
header:SetAttribute("_onstate-page", [[
    self:ChildUpdate("page", newstate)
]])
RegisterStateDriver(header, "page",
    "[vehicleui] 12; [possessbar] 12; [overridebar] 14; [bonusbar:1] 7; [bonusbar:2] 8; " ..
    "[bonusbar:3] 9; [bonusbar:4] 10; 1")
```

(Bar indices are illustrative; real bars typically use `GetVehicleBarIndex()` etc. evaluated
inside the snippet.)

### 6.4 Open/close a panel in combat by clicking a toggle

```lua
local panel  = CreateFrame("Frame", "MyPanel", UIParent, "SecureHandlerBaseTemplate")
local toggle = CreateFrame("Button", "MyPanelToggle", UIParent, "SecureHandlerClickTemplate")
toggle:RegisterForClicks("AnyUp")
toggle:SetFrameRef("panel", panel)
toggle:SetAttribute("_onclick", [[
    local p = self:GetFrameRef("panel")
    if p:IsShown() then p:Hide() else p:Show() end
]])
```

### 6.5 Bridging back to addon Lua for cosmetics

```lua
function MyPanel:OnSecureShown() self.Title:SetText("Open") end   -- insecure method
-- inside a snippet:
--   self:CallMethod("OnSecureShown")
```

### 6.6 Snippet state with Execute

```lua
owner:Execute([[ buttons = newtable() ]])               -- persistent in owner's env
owner:SetFrameRef("b1", MyButton1)
owner:Execute([[ tinsert(buttons, self:GetFrameRef("b1")) ]])
```

---

## 7. Rules for AI code generation

1. All `SetAttribute`, `SetFrameRef`, `WrapScript`, `Execute`, and driver registration calls
   happen **out of combat** (`InCombatLockdown()` guard + queue).
2. Snippets must only use the APIs in section 4; any other global is `nil` inside the sandbox.
3. Use `newtable()` for tables in snippets; no closures, no function values.
4. Never put secret or combat-derived numbers into snippet logic - the sandbox can't read them
   anyway, and attempting to pass them via attributes on Retail 12.x may produce secret
   attribute aspects.
5. Underscore attributes hold code; snippets cannot read/write them.
6. Use `CallMethod` for cosmetic updates in addon Lua, never the reverse.
7. Remember **restriction propagation**: a SecureHandler frame is protected; its parents and
   anchor targets become locked in combat.
8. Don't `SetScript` handlers the template defines; use `WrapScript` or `HookScript`.
