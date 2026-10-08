# EllesmereUI: the reference for UI work, and the old integration

From 3.4.0.25 PSS has one window (`PourSocialScore_GUI`, 09) and no EllesmereUI integration. EllesmereUI stays useful: it is a mature UI framework, and the window was ported from our EllesmereUI window. Section 0 is how to use it now (Dan, 2026-10-08); sections 1 to 7 are the history of the integration (3.1.0 to 3.4.0.24), kept for its lessons.

## 0. EllesmereUI as the reference for building UI elements (Dan, 2026-10-08)
When building or changing a UI element needs more information than our own code and Blizzard's give (how a control behaves, lays out, skins, scrolls, pools or handles a corner case), **check out the EllesmereUI repo and reference it wherever possible, as a mature framework for UI porting.**
1. **Where to look, in this order:** our window as it is (`PourSocialScore_GUI`, the kit, CLAUDE.md Interface, 09 code map); our own EllesmereUI window, the port's reference, in git history (`git fetch origin tag v3.4.0.24` then `git show v3.4.0.24:PourSocialScore_EllesmereUI/<file>`; or the tag `v3.3.1`); then EllesmereUI itself, `EllesmereGaming/EllesmereUI`.
2. **Getting EllesmereUI into a session:** add it with `add_repo` (read access; never push), then a shallow or sparse clone outside the addon repo (for example the session scratchpad). If it cannot be added, say so and ask; never guess its behaviour.
3. **Read only, all rights reserved.** EllesmereUI is a reference, never a source: read it to learn how it solves a problem, then **rewrite the solution to suit our rules**; never copy its code verbatim, and never copy its media, fonts (Expressway is "Do not distribute"), IDs or names. The baseline's I1 to I4 and H3, H4 still apply.
4. **What "rewrite to our rules" means:** Lua 5.1 and tabs (02 section 1); our kit and the three looks, every element in Modern, Classic and Dark (CLAUDE.md Interface, the first rule); logic in `PourSocialScore_Libraries`, drawing only in `PourSocialScore_GUI`; PSS names only, no `EUI` or `Ellesmere` names (`check_rules.sh`); zero cost until opened, no OnUpdate polling, frames reused (baseline C); taint and secret values (baseline 02 J, PSS 02 section 10); Blizzard's or our own resources only (baseline I1).
5. **Say where it came from:** a PR that ports behaviour from EllesmereUI names the EllesmereUI file or feature it studied, and what was rewritten and why.

## History: the integration (3.1.0 to 3.4.0.24)
How PSS applied the baseline's UI suite pattern (baseline 05) to EllesmereUI (EUI): configured the same as the native window, assets in different places. The folder `PourSocialScore_EllesmereUI`, the bridge `PSS_EUI.lua`, `check_rules_eui.sh` and the EUI harness were deleted at 3.4.0.25 (D2); the names below are as they were in 3.4.0.24.

## 1. The pattern
| Layer | Where it lives | Shared? |
| --- | --- | --- |
| Data, rules, counts, setters, events | `PourSocialScore/` (core, always loaded) | Both UIs |
| Option definitions | `M.PSS_OPTIONS` in core; values via `M.PSS_Opt` / `M.PSS_SetOpt`; stored in PSS_OptionsDB (non-defaults only) | Both UIs render pages from this one table, so they never drift |
| Query code both UIs need (guild lists, filter rows, import/export, commands) | `PourSocialScore_Libraries/` (load on demand) | Both UIs depend on it |
| Native UI | `PourSocialScore_GUI/` (PSS_UI, PSS_UIKit, PSS_Widgets, PSS_PlayerDetail, ...) | Native only |
| EUI UI | `PourSocialScore_EllesmereUI/` in the core repo since 3.2.0-dev008, same version as core (EUI_Main, EUI_Window, EUI_Skin, EUI_Options, EUI_Players, EUI_Guilds, EUI_Filters, EUI_History, EUI_HistoryView, EUI_Detail, EUI_Rows, EUI_Pie) | EUI only; SavedVariables `PSS_EllesmereUIDB` for EUI-only state (window position, last tab saved as its builder name) |
| Bridge | `PourSocialScore/PSS_EUI.lua` | Core side of the switch |

Rules that make this work:
- A UI never writes saved data directly. It calls core setters and listens to `M.Events` (e.g. `OPTION_CHANGED`).
- Any function both UIs need goes in Libraries (not either UI folder, and not core unless core itself calls it). Prove the placement with a measured resident cost.
- A new feature is built in both UIs or the core gets a neutral query function first and each UI draws it.
- One release zip and one scratch test zip hold all seven folders.
- **No application or service logic in either UI folder** (02_RULES G1). The UIs draw; Libraries and core compute.
- **Feature parity is the goal, separation is the rule** (00_PRIMARY_OBJECTIVE.md).

## 2. The bridge (PSS_EUI.lua)
- `M.PSS_HasEUI()`: EllesmereUI is loaded.
- `M.PSS_UseEUI()`: EUI present and the `euiIntegration` option is on (default off).
- `M.PSS_OpenUI(force)`: opens the EUI window when in use, else the native GUI; `force` always opens native.
- `M.PSS_RegisterEUI()`: registers the plugin modules ("Options" with one page per options section, `M.PSS_EUI_PAGES`; "Import/Export").
- `M.PSS_OpenEUIPanel()`, `M.PSS_SetEUI(on)`, `M.PSS_AskReload(text)` (EUI secure popup under EUI; StaticPopup on Retail; "/reload" hint on Camelot).
- Loader: `NEEDS = {GUI="Libraries", EllesmereUI="Libraries"}`; `M.PSS_Need("EllesmereUI")` loads Libraries first.
- Commands: `/pss gui` and `/pss eui` open the EUI front end when on; `/pss gui force` opens native; `/pss eui enable|disable`.

## 3. EUI rules (from EUI's CONTRIBUTING.md and Dan)
1. Zero cost unless enabled. 2. New settings default OFF. 3. Low cost when enabled: event-driven, no OnUpdate, no per-frame allocations. 4. Zero taint risk. 5. "Midnight only" conflicts with our Camelot support, so we add no version gates of our own.

Quoted verbatim by Dan:
> House UI systems, not Blizzard defaults: plain-text tooltips use EllesmereUI.ShowWidgetTooltip / HideWidgetTooltip (item/spell tooltips via GameTooltip:SetHyperlink and friends are fine); confirmations use EllesmereUI:ShowConfirmPopup, never StaticPopup_Show.

> Options pages use two-slot rows (W:DualRow). Fill slots left to right with no gaps; never pass nil as the right slot (use EllesmereUI.BlankRowCfg(), a fresh blank label on every call); only the last row of a section may have an empty slot.

Licence: EUI is "all rights reserved". Write original code, use only documented API and public helpers, never read or write `_` fields, never hook EUI functions, never load EllesmereUIOptions ourselves.

## 4. EUI APIs used
- **Plugin API (PLUGINS_API.md):** own sidebar section only (bottom or top; "QoL Addons" placement impossible). Plugin id = folder name `PourSocialScore_EllesmereUI` (`^%a[%w_%-]*$`, max 40 chars). Label "Pour Social Score" (may not start with EUI/EllesmereUI). `buildPage(pageName, parent, yOffset)` returns height, no side effects while `EllesmereUI.IsSearchPrebuild()`. OpenPlugin refuses in combat (`/pss eui` prints a message; our window still opens). `EllesmereUI:RefreshPage()` refreshes in place; keys via `EllesmereUI.GetPluginModuleKey(id, moduleKey)`; `onPageCacheRestore` redraws cached pages.
- **DualRow cfg types used:** toggle, input (text, inputWidth, getValue, setValue), dropdown (values, order), labeledButton, disabled/disabledTooltip.
- **Popups:** ShowConfirmPopup{title, message, confirmText, cancelText, onConfirm, reload}, ShowCopyPopup, ShowImportPopup.
- **Skinning API (SKINNING_API.md):** `EllesmereUI.RegisterSkin(name, fn(S))` gives S.Shell, Panel, Button, EditBox, Checkbox, Dropdown, ScrollBar, Tab, SetTabSelection, CloseButton, Font, GetAccentColor, GetFont, OnLooksChanged. It only runs when third-party skinning is on for our addon (and EUI's "Blizz UI Enhanced" child is enabled). Otherwise our plain dark fallback with EUI's font.
- **Skinned templates in our window:** UICheckButtonTemplate (S.Checkbox), InputBoxTemplate (S.EditBox), WowStyle1DropdownTemplate (S.Dropdown), UIPanelButtonTemplate (S.Button + S.WhiteButtonLabel), ScrollFrameTemplate (S.ScrollBar on .ScrollBar).

## 5. Window
- Opening Friends shows the EUI-styled PSS window at the Friends window's top right (modelled on EUI's bags window). On Midnight the new Social UI hides the old FriendsFrame and EUI draws its own friends window, so the anchor follows whichever is visible.
- Six tabs (Player Ignore List, Guild Ignore List, Chat Filters, Events, Import/Export, Options); drag to move (saved in PSS_EllesmereUIDB); Escape closes. Tabs build on first open.
- 3.2.0: pies on list totals, guild groups and detail panes; type ticks filter pies that have a type breakdown (`SM.typed`); the Events tab (Time, Types, Source drop-downs, custom range; `ns.OpenEvents` from every pie and View Events button; sources register with `ns.RegisterEventSource`); navigation (`navState`, `navApply`, `navTitle`, `navReset`, clickable breadcrumb `win.crumbs`, click empty space or click again to deselect, a tab click resets that tab).
- Earlier 1.1 detail pane: Summary page (period pie: session / 24 h / all time; time picker; Guilds drop-down), Event History page (expired rows per type per 10-minute slot "Data expired from logs"; "Not stored" rows for world/guild chat of people), View/Edit Rule page. The "Stored:" line shows only once Logging is loaded.

## 6. Lessons (apply to every EUI frame)
- Every frame must look right in **both looks**: EUI skin (ns.S set) and plain fallback (ns.S nil). Dan's client showed the fallback at first.
- Never fade a label with SetTextColor alpha: the shadow stays full strength and reads as a second, offset label. Fade with the FontString's SetAlpha. S.Tab draws its own label, so our label gets SetAlpha(0) under the skin. See section 7.
- No test-only globals in addon code: tests reach the addon through panel cfgs and window frames.
- Harness: `tools/harness/eui_stub` and the check_eui_*.lua scripts; `sh tools/harness/check_eui_all.sh` uses the in-repo folder. The Rules CI runs it in its `harness` job. `tools/check_rules_eui.sh` enforces the 4-space style and Version = core's.
- Link tooltips: only call `GameTooltip:SetHyperlink` for kinds that have a tooltip (`TIP_LINKS` in EUI_Rows.lua). A `trade:` link opens the profession window on hover otherwise.

## 7. The tab label "double shade" fix (Step E.2, 2026-10-04)
The general lesson is baseline 05 known fix 1. These are the PSS specifics.

### Symptom
In the EUI-styled Pour Social Score window (at Friends and with /pss gui), the tab labels at the top looked shaded twice: each unselected label had a faint second copy slightly offset behind it. The selected tab (Options) looked clean.

### What it turned out to be
Dan's window was running our **plain fallback look**. The screenshot showed a grey 0.25 border and no EUI title strip, which is what we draw when EUI's skinning callback never fires. That happens when EUI's "Blizz UI Enhanced" child addon is disabled or third-party skinning is off for PourSocialScore_EllesmereUI.

In the fallback, `ns.SetTabSelected` dimmed unselected labels with `fs:SetTextColor(1, 1, 1, 0.5)`. **Text colour alpha does not dim the font shadow.** GameFontHighlightSmall's black shadow stayed at full strength, offset (1, -1) behind half-transparent letters, and read as a second label. The selected tab (alpha 1) looked normal.

### The fix (in `PourSocialScore_EllesmereUI/EUI_Skin.lua`, merged via EllesmereUI PR #2)
```lua
-- S.Tab draws its own label over ours; our label is faded only by colour,
-- which the button resets on state changes, so it showed through as a ghost.
function ns.Tab(tab)
    if ns.S then
        ns.S.Tab(tab)
        local fs = tab:GetFontString()
        if fs then fs:SetAlpha(0) end
        return
    end
    PlainFill(tab, 0.9)
    PlainBorder(tab)
end

-- Visual selection of a tab this addon switches itself.
function ns.SetTabSelected(tab, selected)
    if ns.S and ns.S.SetTabSelection then
        ns.S.SetTabSelection(tab, selected)
    else
        -- Alpha, not text colour: colour alpha leaves the shadow at full
        -- strength, which read as a second, offset label.
        local fs = tab:GetFontString()
        if fs then fs:SetAlpha(selected and 1 or 0.5) end
    end
end
```

### The path there (three commits on EllesmereUI PR #2)
1. **Guess 1 (wrong, reverted):** `S.Shell(frame, { noTopBar = true })`, assuming EUI's dark title strip overlapped the tab row. SKINNING_API.md documents `noTopBar`, but it was not the cause.
2. **Guess 2 (kept, covers the skinned look):** EUI's `S.Tab` creates its own 11px label and hides the button's label only with `SetTextColor(0,0,0,0)`. Our buttons use `SetNormalFontObject`, which can reapply colour on state changes and bring our label back as a ghost. Fix: `fs:SetAlpha(0)` on our label after `S.Tab`.
3. **Real cause for Dan (plain look):** the shadow problem above, fixed by fading with `SetAlpha`.

### Lessons
- Read the screenshot first. The grey border and missing title strip showed it was the fallback look, which made the first two guesses irrelevant for Dan.
- Every UI change must work in both looks (skin on, skin off).
- Dim text with the FontString's `SetAlpha`, never with `SetTextColor` alpha.
- `S.SetTabSelection` exists (EUI skin apiVersion >= 2) even though SKINNING_API.md doesn't list it. Guard calls to it anyway.
- Reading EUI's code to learn behaviour is fine (`EllesmereUIBlizzardSkin_WindowEngine.lua`: WSkin.Tab and TabIsSelected; `EllesmereUIBlizzardSkin_SkinAPI.lua`: the dispatcher, gating and facade). Copying it isn't (all rights reserved).
