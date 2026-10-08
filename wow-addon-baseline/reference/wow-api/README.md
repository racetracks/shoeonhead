# WoW API reference set (Warcraft Wiki, compiled 2026-10-08)

A condensed rewrite of the Warcraft Wiki "Interface customization" hub and the security pages it links (https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Interface_customization). Source content is CC BY-SA 4.0. Converted to ASCII on import (baseline 02 A2); nothing else changed.

**It is reference, not rules.** The rules it supports are in `02_RULES.md` section J (security, taint and secret values) and B (TOCs). Where this set and the baseline differ, the baseline wins, and the addon pack wins over both for its addon. Where this set and the live wiki or Blizzard's source differ, the live source wins (03_REPOS_AND_REFERENCES.md).

## Files
| File | Read when |
| --- | --- |
| 00_WoW_Addon_Development_Reference.md | Any API question: load order, events, SavedVariables, hooking, Retail 12.x limits, debugging tools, links |
| 01_TOC_Format_and_Client_Versions.md | Interface numbers, TOC suffixes and directives, `WOW_PROJECT_ID`, a client patch |
| 02_Object_Security.md | Protected, forbidden, anchor-restricted and inaccessible objects |
| 03_Secure_Execution_and_Tainting.md | The taint model, protected functions, combat lockdown |
| 04_SecureTemplates.md | Secure action and unit buttons, group and aura headers |
| 05_SecureHandlers.md | SecureHandler templates, the restricted environment, state drivers |
| 06_How_to_Deal_with_Taint.md | Diagnosing a taint report ("Interface action failed because of an AddOn") |
| 07_Secret_Values_Midnight.md | Retail 12.x secret values, secret and forbidden aspects, restriction CVars |

## Where this set differs from the baseline (the baseline wins)
| This set says | The baseline rule | What to do |
| --- | --- | --- |
| Throttle `OnUpdate` or replace it with `C_Timer` (00 section 3.3, 16) | C3: event-driven, no OnUpdate polling, no wall-clock timers as logic gates | Drive work from events. `C_Timer` only for UI-bound delays (a cooldown display, a fade), never to decide when logic runs |
| Merge defaults into the saved table on load (`ApplyDefaults`, 00 section 5) | D3: no default-valued fields stored; options keep only non-defaults | Read defaults through an accessor (the options getter); never copy them into SavedVariables |
| Libraries: LibStub, Ace3, LibUIDropDownMenu, LibActionButton (00, 01 Part K, 06) | A10: no libraries unless the author agrees | WoW API only; ask the author before any library |
| Create all secure frames at load or login (03 section 7, 04 section 2) | C5: no UI at login | The only exception is a frame from a secure template that must work in combat (J5). Every other frame stays lazy |
| Prefer one TOC with comma-separated interfaces over suffixed TOCs (00 section 9, 01 Part G) | B1: three TOCs per folder; one combined TOC has broken a classic client | Keep the base TOC plus the flavour TOCs. Per-file conditions inside a TOC are fine where the client supports them |
| Template TOC: `## Version: @project-version@`, `## Category: Combat`, localized titles (01 Part K) | B2 to B4, F: one version written into every TOC by the step's PR; Category, Group and Title follow the addon pack; Title and Notes are the author's | Use the addon pack's TOC values, never the template's |
| Frame names create globals; pass `nil` unless needed (00 section 3.1) | A6: no new globals beyond SavedVariables and frame names the client needs | Agrees: name a frame only for `UISpecialFrames` (Escape), keybinds, `/click` or XML references |
