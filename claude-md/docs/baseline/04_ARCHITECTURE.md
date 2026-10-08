# Addon architecture that worked

Names below describe roles, not required identifiers; each addon picks its own.

## Folders: an always-loaded core and load-on-demand parts
| Folder | Loaded | Holds |
| --- | --- | --- |
| Core | Always | The always-on engine, counters, setters, the event bus, the loader, the bridge to any UI suite. Small SavedVariables |
| Options / data | Always, data only | SavedVariables needed at login (options, lists, rules, counts) when they are big enough to split from core |
| Library | On demand | Logic more than one UI needs: queries, totals, event lists, commands, scans, import/export |
| Native UI | On demand | The Blizzard-styled window and its UI kit |
| Shipped data | On demand | Large lists that ship with the addon, packed |
| Suite UI | On demand, only when the integration is on | The suite-styled window (05) |

- All folders share one version and one release zip.
- A suite integration lives in its own folder and never shares UI code with the native folder.

## The loader
- Core keeps one table of every on-demand part and what each part needs loaded first (for example both UIs need the library).
- One loader function enables and loads a part and its prerequisites (`C_AddOns.EnableAddOn`, `C_AddOns.LoadAddOn`). The TOC dependencies say the same, so the client agrees.
- A part whose version differs from core's prints a warning (a half-updated install).

## Namespace
- One global root table named after the addon is the only global the code adds. It holds a functions table that every folder adds its shared functions to, plus small tables for runtime state and strings.
- Everything else in a file is `local`, with frequently used API functions localized at the top.
- Lua 5.1 allows at most 60 upvalues per closure and 200 locals per function, so large builders keep their state in one table.

## Events between layers
- Core owns a small **event bus**: logic fires a named event when data changes ("an option changed", "a list changed"); UIs subscribe while they are open and unsubscribe when closed.
- Logic never calls into a UI, and a UI never writes saved data directly: it calls a core setter, which saves and fires the event.
- A rules script checks that core logic files make no UI calls (06_HARNESS.md).

## One config, several UIs
- Options are defined once in a table in core: key, type, default, section, label.
- Only non-default values are stored. One getter reads (falling back to the default) and one setter writes and fires the change event.
- Each UI renders its option pages from that table, so a native UI and a suite UI never drift.

## The bridge to a UI suite (core)
A small core file answers: is the suite loaded; is the integration in use (suite present and the user's option on, default off); which window to open (the suite's when in use, native otherwise, with a way to force native); register the addon's pages with the suite; ask for a reload when the switch changes (the suite's popup inside the suite, a StaticPopup otherwise, a "/reload" hint where neither works). Slash commands open either front end and switch the integration.

## Upgrades
- Numbered run-once steps in an upgrade record in SavedVariables.
- Cleanups that touch load-on-demand data run when that data loads, guarded until earlier steps have run.
- A login tidy-up removes leftovers; every old store is pruned when it is replaced.

## UI kit (native)
One file of builders taken from the best-looking page: windows (PortraitFrameTemplate, an inset panel, a bottom button bar, a resize grip), summary lines, Who-list style column headers that sort, 20 px rows with the quest-title highlight, 20 x 20 check boxes, standard button sizes. Every window closes on Escape (`UISpecialFrames`) and remembers its size.
