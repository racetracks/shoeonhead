# SecureTemplates

> Part of the WoW AddOn reference set. Hub: https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization
> Primary sources: https://warcraft.wiki.gg/wiki/SecureTemplates ,
> https://warcraft.wiki.gg/wiki/SecureActionButtonTemplate ,
> https://warcraft.wiki.gg/wiki/SecureStateDriver (UnitWatch)
> Blizzard source: `SecureTemplates.xml` / `SecureTemplates.lua` (FrameXML)  - 
> https://www.townlong-yak.com/framexml/live
> Compiled 2026-10-08.

**SecureTemplates** are Blizzard-defined protected frame/button templates. By inheriting one
and configuring it with **attributes** (out of combat), an addon gains access to protected
functionality - casting, targeting, unit frames, group layouts - that tainted Lua cannot
perform directly. The template's handlers (e.g. `OnClick`) run securely, and the player's
hardware click is what triggers the action.

> Background on why this is necessary: `03_Secure_Execution_and_Tainting.md`.

---

## 1. Template catalogue

| Template | Widget | Purpose |
|---|---|---|
| `SecureActionButtonTemplate` | Button | Perform protected actions (spell, item, macro, target...) |
| `InsecureActionButtonTemplate` | Button | Same attribute API, **not protected**; only works out of combat (7.2.0+) |
| `SecureUnitButtonTemplate` | Button | Clickable unit frames |
| `SecureAuraHeaderTemplate` | Frame | Secure layout of buff/debuff buttons |
| `SecureGroupHeaderTemplate` | Frame | Secure layout of group-member unit buttons |
| `SecurePartyHeaderTemplate` | Frame | Party members |
| `SecureRaidGroupHeaderTemplate` | Frame | Raid group members |
| `SecureGroupPetHeaderTemplate` | Frame | Group pets |
| `SecurePartyPetHeaderTemplate` | Frame | Party pets |
| `SecureRaidPetHeaderTemplate` | Frame | Raid pets |
| `SecureHandler*Template` | Frame/Button | Restricted-code handlers - see `05_SecureHandlers.md` |

Inheriting any of these makes the frame **protected** (and propagates restrictions to parents
and anchor targets).

---

## 2. Universal rules

1. **Create secure frames out of combat** - ideally at file load or `PLAYER_LOGIN`.
2. **Set/change attributes only out of combat** (`InCombatLockdown()` check + queue).
3. **Never `SetScript` a handler the template defines** (especially `OnClick`) - doing so
   replaces the secure handler with your tainted function. Use `HookScript` for cosmetics.
4. **Register the clicks you need**: `btn:RegisterForClicks("AnyUp", "AnyDown")`. Non-left
   buttons do nothing unless registered.
5. Attribute changes of a secure frame from insecure code **in combat** are blocked.
6. Secure buttons can be clicked by keybinds: `SetBindingClick` / `SetOverrideBindingClick`
   (out of combat) or the `/click ButtonName` macro command - so give such buttons a global
   **name**.
7. `useOnKeyDown` (attribute) overrides the `ActionButtonUseKeyDown` CVar per button; when the
   CVar is on, registering `"AnyDown"` is needed for keybind/`/click` activation.

---

## 3. SecureActionButtonTemplate

### 3.1 Creation

**XML:**

```xml
<Button name="MyActionButton" inherits="SecureActionButtonTemplate" parent="UIParent"
        registerForClicks="AnyUp, AnyDown">
  <Size x="36" y="36"/>
  <Anchors><Anchor point="CENTER"/></Anchors>
  <Attributes>
    <Attribute name="type" value="action"/>
    <Attribute name="action" value="1" type="number"/>
    <Attribute name="useOnKeyDown" value="false" type="boolean"/>
  </Attributes>
</Button>
```

**Lua:**

```lua
local btn = CreateFrame("Button", "MyActionButton", UIParent, "SecureActionButtonTemplate")
btn:SetSize(36, 36)
btn:SetPoint("CENTER")
btn:RegisterForClicks("AnyUp", "AnyDown")
btn:SetAttribute("type", "spell")
btn:SetAttribute("spell", 774)          -- number => CastSpellByID; string => CastSpellByName
btn:SetAttribute("unit", "player")
```

**Macro button (per mouse button):**

```lua
local m = CreateFrame("Button", "MyMacroButton", UIParent, "SecureActionButtonTemplate")
m:RegisterForClicks("AnyUp", "AnyDown")
m:SetAttribute("type1", "macro")
m:SetAttribute("macrotext1", "/cast [@mouseover,help,nodead][] Renew")
```

### 3.2 Modified attributes

Most attributes can vary by **modifier keys** and **mouse button**. Name format:

```
[modifiers-]name[button]
```

- Modifiers: `alt-`, `ctrl-`, `shift-` - combined **in exactly that order**
  (`alt-ctrl-shift-`). `*` as prefix = "any modifiers".
- Button suffix: `1`-`5`, or `-customname`; `*` = "any button".
- Resolved by `SecureButton_GetModifiedAttribute`; precedence rules are implemented in
  `Frame:GetAttribute`.

| Attribute name | Applies to |
|---|---|
| `type` | Any click |
| `*type1` | Any left click (any modifiers) |
| `type1` | Unmodified left click |
| `shift-type2` | Shift+right click (not Alt+Shift+right) |
| `shift-type*` | Shift + any button |
| `alt-ctrl-shift-type*` | Alt+Ctrl+Shift + any button |
| `ctrl-alt-shift-type*` | **Invalid** - wrong modifier order |

### 3.3 Help/harm button remapping

`helpbutton` / `harmbutton` attributes remap the clicked button to a virtual button name when
the unit is assistable/attackable; other attributes are then resolved with that suffix.

| Attribute | Value | Effect |
|---|---|---|
| `unit` | `target` | All actions use the target |
| `*harmbutton1` | `nuke1` | Hostile left click -> virtual button `nuke1` |
| `*harmbutton2` | `nuke2` | Hostile right click -> `nuke2` |
| `helpbutton1` | `heal1` | Friendly unmodified left click -> `heal1` |
| `type` | `spell` | Every click casts a spell |
| `spell-nuke1` | *(damage spell A)* | Hostile left |
| `spell-nuke2` | *(damage spell B)* | Hostile right |
| `alt-spell-nuke2` | *(damage spell C)* | Hostile Alt+right |
| `spell-heal1` | *(heal spell)* | Friendly left |

After remapping, `unit` is re-resolved with the new suffix - so one unit can be tested for
hostility and the action applied to another.

### 3.4 Action types (`type` attribute)

| `type` | Attributes used | Behavior |
|---|---|---|
| `actionbar` | `action` | Change action bar: number, `"increment"`/`"decrement"`, or `"a, b"` toggle |
| `action` | `unit`, `action`, [`actionpage`] | Use action slot; paging if `GetID() > 0` |
| `pet` | `unit`, `action` | `CastPetAction(action, unit)` |
| `spell` | `unit`, `spell` | `CastSpellByID` (number) or `CastSpellByName` (string) |
| `toy` | `toy` | `UseToy(itemID)` or `UseToyByName` |
| `item` | `unit`, `item` *or* `bag`+`slot` | Use/equip via `SecureCmdItemParse`; `item` may be a name, macro-conditional string, or `"bag slot"`; `bag`/`slot` attributes deprecated |
| `macro` | `macro` *or* `macrotext` | `RunMacro(macro, button)` or `RunMacroText(text, button)`; **255-char limit**; cannot `/click` buttons that run other macros |
| `flyout` | `spell` (flyout ID), [`flyoutDirection`] | Toggle spell flyout (`UP`/`DOWN`/`LEFT`/`RIGHT`) |
| `glyph` | `glyph`, `slot` | Apply glyph (clients with glyphs) |
| `worldmarker` | `marker`, `action` (`set`/`clear`/`toggle`) | World markers |
| `cancelaura` | `unit`, `spell`[, `rank`] / `target-slot` / `index`[, `filter`] | Cancel buff / weapon enchant |
| `stop` | - | `SpellStopTargeting()` |
| `target` | `unit` | Target unit (or target for pending spell / trade); `unit = "none"` clears |
| `focus` | `unit` | `FocusUnit` |
| `assist` | `unit` | `AssistUnit` |
| `mainassist` / `maintank` | `action` (`set`/`clear`/`toggle`), `unit` | Raid role assignment |
| `click` | `clickbutton` | `clickbutton:Click(button)` |
| `attribute` | [`attribute-frame`], `attribute-name`, `attribute-value` | `frame:SetAttribute(name, value)` (self if no frame) |
| `togglemenu` | `unit` | Unit popup menu at cursor (5.2+) |
| `destroytotem` | `totem-slot` | `DestroyTotem(slot)` |
| `multispell` | `spell`, [`action`], [`actionpage`, ID] | Legacy/deprecated |
| *any other string* | `_<type>` | Runs the modified `"_" .. type` attribute, or `rawget(button, type)`. A **function** is called as `(self, unit, button, actionType)`; a **string** names an attribute holding a restricted snippet executed like `OnClick`. |

**Item targeting:** `target-item` (or `target-bag` + `target-slot`) targets an inventory item
for a spell that is awaiting a target - applied after the main action:

```lua
btn:SetAttribute("type", "spell")
btn:SetAttribute("spell", "Disenchant")
btn:SetAttribute("target-item", "1 1")   -- bag 1, slot 1
```

### 3.5 Other attributes

| Attribute | Values | Effect |
|---|---|---|
| `useOnKeyDown` | bool | Per-button override of `ActionButtonUseKeyDown` |
| `downbutton` | string | Remap mouse button on *down* clicks (applied first) |
| `unitsuffix` | `pet`, `target`... | Appended to `unit` |
| `toggleForVehicle` | bool | Swap owner/vehicle units when owner is in a vehicle |
| `allowVehicleTarget` | bool | Lets `toggleForVehicle` remap `party1target` -> `partypet1target` |
| `checkselfcast` | bool | SELFCAST modifier forces `player` |
| `checkfocuscast` | bool | FOCUSCAST modifier forces `focus` |

### 3.6 InsecureActionButtonTemplate (7.2.0+)

Same attribute interface but **not protected**: protected actions only succeed while combat
lockdown is **not** in effect. Useful for out-of-combat utility buttons that you want to move
or hide freely. Still create it out of combat, or `SetAttribute` may be unusable in combat.

---

## 4. SecureUnitButtonTemplate

Clickable unit frames (target on click, menu on right-click, etc.).

```lua
local f = CreateFrame("Button", "MyParty1Frame", UIParent, "SecureUnitButtonTemplate")
f:SetAttribute("unit", "party1")
f:RegisterForClicks("AnyUp")
f:SetAttribute("*type1", "target")       -- left: target
f:SetAttribute("*type2", "togglemenu")   -- right: unit menu
RegisterUnitWatch(f)                     -- secure show/hide when unit exists
f:SetSize(120, 30)
f:SetPoint("CENTER")
```

- Accepts the same `type` attributes as action buttons (so click-casting works by setting
  `type`/`spell` attributes with modifiers).
- **`RegisterUnitWatch(frame [, asState])`** - securely shows/hides the frame when its unit
  exists (`asState = false/nil`), or sets attribute `state-unitexists` (`asState = true`) for
  a SecureHandlerStateTemplate to react to. `UnregisterUnitWatch(frame [, asState])` cancels.
- Health/power display is **your** (insecure) code updating child regions - that's fine; only
  the frame's protected methods are restricted. On Retail 12.x, feed secret health values
  straight into `StatusBar:SetMinMaxValues/SetValue` rather than computing percentages.

---

## 5. Group headers (SecureGroupHeaderTemplate family)

Headers create and lay out child unit buttons securely, so group changes in combat are
handled without addon intervention.

Commonly used attributes (from FrameXML `SecureGroupHeaders.lua`; verify on your target client):

| Attribute | Purpose |
|---|---|
| `template` | Template(s) for child buttons (usually includes `SecureUnitButtonTemplate`) |
| `templateType` | Widget type of children (default `Button`) |
| `showPlayer`, `showSolo`, `showParty`, `showRaid` | Which situations display units |
| `groupFilter` | e.g. `"1,2,3"`, or class/role tokens |
| `groupBy`, `groupingOrder` | Grouping (`GROUP`, `CLASS`, `ASSIGNEDROLE`) and order |
| `sortMethod`, `sortDir` | `INDEX` / `NAME`, `ASC` / `DESC` |
| `point`, `xOffset`, `yOffset` | Child anchoring within a column |
| `maxColumns`, `unitsPerColumn`, `columnSpacing`, `columnAnchorPoint` | Multi-column layout |
| `initialConfigFunction` | Restricted snippet run on each new child (set child attributes/size) |

```lua
local header = CreateFrame("Frame", "MyRaidHeader", UIParent, "SecureGroupHeaderTemplate")
header:SetAttribute("template", "SecureUnitButtonTemplate")
header:SetAttribute("showRaid", true)
header:SetAttribute("showParty", true)
header:SetAttribute("showPlayer", true)
header:SetAttribute("point", "TOP")
header:SetAttribute("yOffset", -2)
header:SetAttribute("initialConfigFunction", [[
    self:SetWidth(100); self:SetHeight(24)
    self:SetAttribute("*type1", "target")
    self:SetAttribute("*type2", "togglemenu")
]])
header:SetPoint("TOPLEFT", 20, -200)
header:Show()
```

Pet variants (`SecureGroupPetHeaderTemplate`, `SecurePartyPetHeaderTemplate`,
`SecureRaidPetHeaderTemplate`) work the same way for pets.

---

## 6. SecureAuraHeaderTemplate

Secure layout of aura buttons (allows right-click cancelling of buffs in combat).

Typical attributes: `unit`, `filter` (`HELPFUL`/`HARMFUL`), `template`, `point`, `xOffset`,
`yOffset`, `wrapAfter`, `wrapXOffset`, `wrapYOffset`, `maxWraps`, `minWidth`, `minHeight`,
`sortMethod` (`INDEX`/`NAME`/`TIME`), `sortDirection`, `separateOwn`, `includeWeapons`,
`weaponTemplate`. Child buttons typically set `type = "cancelaura"` on right click.
On Retail 12.x, aura data shown on these buttons may be **secret** - display it, don't compute
with it.

---

## 7. Complete minimal example (XML only, from the wiki pattern)

```xml
<Ui>
  <Button name="MyBuffButton" inherits="SecureActionButtonTemplate" parent="UIParent">
    <Attributes>
      <Attribute name="type"  type="string" value="spell"/>
      <Attribute name="spell" type="string" value="Mark of the Wild"/>
      <Attribute name="unit"  type="string" value="player"/>
    </Attributes>
    <Size x="64" y="64"/>
    <Layers>
      <Layer level="OVERLAY">
        <Texture parentKey="Icon" file="Interface\Icons\Spell_Nature_Regeneration" setAllPoints="true"/>
      </Layer>
    </Layers>
    <Anchors><Anchor point="CENTER"/></Anchors>
  </Button>
</Ui>
```

---

## 8. Common mistakes (and fixes)

| Mistake | Symptom | Fix |
|---|---|---|
| `SetAttribute` in combat | "Interface action failed" / `ADDON_ACTION_BLOCKED` | Queue until `PLAYER_REGEN_ENABLED` |
| `btn:SetScript("OnClick", ...)` on a secure button | Button stops casting | Use `HookScript` or `SecureHandlerWrapScript` |
| Right-click does nothing | - | `RegisterForClicks("AnyUp")` (+ `"AnyDown"` for key-down) |
| Keybind/`/click` does nothing with key-down CVar on | - | Register `"AnyDown"` or set `useOnKeyDown` |
| Wrong modifier order in attribute name | Attribute ignored | Use `alt-ctrl-shift-` order |
| Secure button anchored to your movable container | Container can't move in combat | Anchor the container to the button's secure header, or accept lockdown |
| Creating secure frames on demand mid-session | Fails if in combat | Pre-create at load; reuse/hide |
| `macrotext` > 255 chars | Truncated/failed macro | Split across buttons with `/click` chains (no nested macro-running clicks) |
