# The offline harness

WoW can't run in CI, so the addon runs under plain `lua5.1` with a stub of the WoW API. Starting points are in `examples/`.

## Pieces
| Piece | What it does |
| --- | --- |
| `wow_stub.lua` | Fake globals: CreateFrame (frames, textures, font strings, lines), C_AddOns, C_Timer (queued, run by the harness), GetTime/time with a settable clock, chat events, StaticPopup, GameTooltip, GetCursorPosition. Grow it as the addon uses more API |
| `run.lua <addonDir> <svIn or -> <svOut or -> [script.lua]` | Reads TOCs like the client (dependencies first, LoadOnDemand only on LoadAddOn, a private `...` per addon, ADDON_LOADED after files run), loads SavedVariables, logs in, runs a check script with the stub and the addon's root table as globals, logs out and writes SavedVariables back |
| `check_*.lua` | One script per behaviour; prints PASS / FAIL lines |
| `validate_all.sh` | Generates saves for every old layout, runs the migrations on them and on **the author's real saves**, then every check; must end with 0 FAIL |
| `ui_compare.sh <ref> <save>` | Builds every native window and tab on both trees, snapshots every frame (anchors, sizes, texts, calls) and diffs |
| A suite tour and `suite_compare.sh` | The same for a suite UI, with a tour that clicks every tab, rows, slices, ticks and searches, snapshotting after each step |
| `check_style.lua`, `check_layers.lua` | Lua 5.1 bans, tabs, trailing whitespace (`--fix`); no UI calls in core logic files. Called from `check_rules.sh` |

## What to test
- Migrations from every released version's save and from every real save the author sends.
- Caps: fill a store past its cap; it trims and the save shrinks (a growth check).
- Load on demand: a part stays unloaded through login and normal events and loads only when called.
- Counting: counts at event time match; nothing doubles.
- **Numbers match** when two windows show the same data: read both on every real save and fail on any difference.
- Each UI: every page builds, every option has a row, a change in one UI shows in the other.

## Habits that paid off
- **Look-compare every UI change** against the base branch on a real save. A UI-neutral change comes out identical; a UI change differs only where intended, and the PR lists which differences remain.
- **Sabotage each new check once**: break the code on purpose, see it fail, restore.
- **Silence setup phases** whose failures are expected.
- **Real saves by version**: `/mnt/project-files/savedvariables/<version>/` holds the author's files; `/mnt/project-files/baselines/<version>/<Addon>.lua` is those files concatenated (core first) for the runner.
- A check that needs a load-on-demand part loads it first through the loader.

## Setup in a session
```sh
sudo apt-get install -y lua5.1   # if missing
git fetch --depth=1000 origin main
MYADDON_REAL_SAVES=/mnt/project-files/baselines sh tools/harness/validate_all.sh
sh tools/harness/ui_compare.sh origin/main /mnt/project-files/baselines/<version>/MyAddon.lua
```
