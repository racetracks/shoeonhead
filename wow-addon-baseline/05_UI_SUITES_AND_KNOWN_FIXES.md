# UI suites and known fixes

## Part 1: Integrating a UI suite (configured the same, assets in different places)
The author's requirement for every project that offers a UI-suite front end (a full UI replacement such as EllesmereUI or ElvUI) beside its native Blizzard-styled UI: **both front ends are configured the same way, but their assets live in different locations.**

### The pattern
| Layer | Where | Shared? |
| --- | --- | --- |
| Data, counts, setters, the event bus | Core (always loaded) | Both UIs |
| Option definitions | One table in core; only non-defaults stored | Both UIs render their option pages from it |
| Logic both UIs need | Library folder (on demand) | Both UIs depend on it |
| **UI resources both UIs call** (shared functions, data tables) | Library folder, or core if always-loaded code needs it. **Never in either UI folder** | Both |
| Native UI | Its own folder; Blizzard templates and textures | Native only |
| Suite UI | Its own folder, same repo and version as the addon; fonts, colours and skins taken from the suite at run time; its own SavedVariables only for suite-only state (window position, last tab) | Suite only |
| Bridge | One small file in core (04_ARCHITECTURE.md) | Core side of the switch |

- The native UI never reads or loads a file from the suite folder, and the reverse, so a user never needs both loaded.
- No application or service logic in either UI folder.
- Same features, same numbers, each drawn in its own look.

### Detection and loading
- The suite is loaded (`C_AddOns.IsAddOnLoaded`) **and** the user's integration option is on (default OFF). Load the suite folder on demand only when both are true.
- Switching the option asks for a reload, through the suite's own popup when inside the suite.
- Zero cost when off: nothing from the suite folder loads.

### Working with any suite
- Read the suite's contributor guide and API docs first; follow its house rules for tooltips, confirmation popups and options layout inside its windows.
- Use only documented API and public helpers. Never read or write private fields, never hook its functions, never load its own options addon yourself.
- Check the licence. Many suites are all rights reserved: reading their code to learn behaviour is fine, copying it is not.
- Prefer the suite's plugin or module registration (its own sidebar section or page) over injecting into its frames.
- Take fonts, accent colours and skins from the suite at run time; never copy its media into your folders.
- Skinning callbacks often run only when the user has the suite's skin module enabled. Always ship a **plain fallback look** (a dark panel with the suite's font) for when they don't, and treat it as a first-class look.
- Suites usually target Retail only; if the addon supports classic clients, keep the suite folder gated by detection rather than adding version checks of your own.
- Harness: a stub of the suite's API beside the WoW stub, a check per tab, and a look-compare tour of the suite window (06_HARNESS.md).

## Part 2: Known fixes
Problems seen in practice, what triggered them and the fix. Check this list before guessing at a UI bug.

### 1. A "ghost" second label behind faded text (font shadow)
- **Seen when:** the addon drew its own tab buttons and dimmed the unselected ones to show which tab was active, in the plain fallback look (the suite's skin module was off on the user's client). Each unselected tab label showed a faint copy offset just behind it; the selected tab looked clean.
- **Cause:** the labels were faded with `FontString:SetTextColor(r, g, b, 0.5)`. **Text colour alpha does not fade the font's shadow**, so the black shadow at offset (1, -1) stayed at full strength behind half-transparent letters and read as a second label.
- **Fix:** fade text with `FontString:SetAlpha(a)`, which fades the letters and the shadow together:
  ```lua
  local fs = tab:GetFontString()
  if fs then fs:SetAlpha(selected and 1 or 0.5) end
  ```
- **Related, in the skinned look:** the suite's tab skin drew its own label over the button and hid the original only by colour. The button reapplies its font object's colour on state changes (hover, press, enable), which brought the original label back as a ghost. Fix: after applying the suite's tab skin, hide your own label with `SetAlpha(0)`. Use the suite's own "set tab selected" call when it offers one (guard the call: it may be undocumented).
- **Rule that came from it:** every frame must look right skinned and unskinned; never fade text with colour alpha.
- **Lesson:** read the screenshot first. The plain border and missing title strip showed it was the fallback look, which made two earlier guesses about the skinned look irrelevant.

### 2. Hovering a link opened a window
- **Seen when:** list rows showed chat messages containing links, and hovering a row showed the link's tooltip with `GameTooltip:SetHyperlink`.
- **Cause:** some link kinds have no tooltip and instead act on `SetHyperlink`; a profession (`trade:`) link opened the profession window on hover.
- **Fix:** an allow list of link kinds that have tooltips (item, spell, achievement, quest and similar); anything else shows plain text.
- **Rule:** hover must never open a window.

### 3. A window anchored to the Friends list lost its anchor
- **Seen when:** a window was placed at the Friends window's top right on Retail.
- **Cause:** the newer Social UI hides the old `FriendsFrame`, and UI suites may draw their own friends window.
- **Fix:** anchor to whichever friends window is visible, falling back to a saved position.

### 4. Blizzard tab labels sat low or were cut short
- **Seen when:** an addon used Blizzard's top tab template for its own tab row (shorter tabs than Blizzard's) and selected tabs with `PanelTemplates_SelectTab` / `PanelTemplates_DeselectTab`.
- **Cause:** those functions re-anchor the label themselves (for top tabs 4 px below centre when selected, 8 px when not, made for Blizzard's 32 px tabs), overriding any anchor the addon set; the template's `OnShow` also resized the tab to Blizzard's own padding, truncating long labels.
- **Fix:** on your own tab buttons, set the label anchor and show the idle or active art yourself, and clear the template's resize scripts (`SetScript("OnShow", nil)`, its display-size event) so your row sizes the tabs.
- **Lesson:** before fixing a region's anchor, check what else re-anchors it. A fix that is overridden does nothing.

### 5. A one-pixel line looked blurred or the wrong colour
- **Seen when:** a 1-unit accent underline at a UI scale under 1.
- **Fix:** size thin lines and edges in physical pixels (768 / physical screen height / effective scale) and turn grid snapping off (`SetSnapToPixelGrid(false)`, `SetTexelSnappingBias(0)`, feature-detected).

### 6. A wide window on small screens
- **Seen when:** a window's minimum width grew to make room for a side pane.
- **Fix:** keep it resizable, clamp it to the screen (`SetClampedToScreen`), cap the maximum size at the screen size, and check the default size on a small UI scale before shipping.
