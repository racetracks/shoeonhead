# PourSocialScore: rules and context for Claude

Three packs, read in layer order. **The baseline's rules are mandatory**
(Dan, 2026-10-08): PSS overrides one only where `docs/pss/02_RULES.md`
section 12 (the Overrides table) lists it, with Dan's OK; any other difference
is a bug to fix, and a new difference needs a row (and Dan's OK) first.
"Baseline 02 C3" style references point into layer 1.

| Layer | Folder | Holds |
| --- | --- | --- |
| 1 | `docs/baseline/` | WoW addon baseline v9 (2026-10-08): how any addon is built, released and delivered; mandatory; v5 02 J (taint, secret values) and `reference/wow-api/`, v6 `X.Y.Z.B` and the version tools, v7 build numbers that never reset and `versions.json`, v8 the mirror carries the release's files, v9 one step per session, context updated in every PR, state re-summarized at release, the author's preferences in one file (02 E9 to E11) |
| 2 | `docs/scratch/` | Scratch repo usage pack v4 (2026-10-07; the v2 pack adapted to `racetracks/Pour-Social-Score_Scratch`): how scratch hosts builds, saves, docs and summaries. Live copy on scratch `docs/latest/scratch-repo-usage/`, criteria in its `CLAUDE.md` |
| 3 | `docs/pss/` | PSS pack, kept current: only what is true of PourSocialScore (01 the addon as it works, 06 status, 10 the current project, 11 Dan's preferences; 02 section 12 the Overrides table). Newest copies on scratch `docs/latest/pss-docs/` |

Loaded in every session (kept lean, Dan, 2026-10-08; everything else is read when a step needs it):

@docs/pss/11_PREFERENCES.md
@docs/baseline/02_RULES.md
@docs/baseline/10_FEATURE_DESIGN_AND_DELIVERY.md
@docs/scratch/05_RULES.md
@docs/pss/01_HANDOVER.md
@docs/pss/02_RULES.md
@docs/pss/06_STATUS_AND_NEXT.md
@docs/pss/10_CORE_UPLIFT.md

Read when the task touches the topic:
- `docs/pss/10_CORE_UPLIFT.md`'s appendices on scratch `docs/latest/core-uplift/` (01 core and Libraries findings N1 to N48, 02 GUI findings G1 to G30, 03 SavedVariables, 04 upgrade helper, 05 name bugs): only the one the current stage names
- `docs/pss/09_PSS_UI_PROJECT.md`: the closed window project's code map and lessons, for any window change
- `docs/baseline/README.md`, `07_WORKING_WITH_THE_AUTHOR.md` (generic; `11_PREFERENCES.md` wins), `docs/scratch/04_USAGE.md` (scratch procedures), `docs/pss/00_README.md` (pack index)
- `docs/pss/03_ELLESMEREUI.md`: EllesmereUI as the reference for building UI elements (section 0, Dan, 2026-10-08), and the history of the old integration (deleted at 3.4.0.25): bridge, APIs, house rules, the tab shadow fix
- `docs/pss/04_DATA_AND_LOGGING.md`: SavedVariables, outbox, Logging on demand, grouped save, recent counts, real saves
- `docs/pss/05_RELEASE.md`: PSS release names, CI jobs, release history, pitfalls
- `docs/pss/07_HARNESS.md`: PSS harness commands
- `docs/pss/08_PARITY_PROJECT.md`: the closed 3.3.0 parity project (shipped as 3.3.1), decisions and stage table
- `docs/pss/reference/`: original 3.3 analysis and plan, issue #77 notes, 2026-10-07 memory snapshot (history; 06 and 08 are newer)
- `docs/baseline/01, 03, 04, 05, 06, 08, 09`: API limits, references, architecture, suite integration and known fixes, harness, lifecycle, release pipeline
- `docs/baseline/templates/`, `docs/baseline/examples/`: generic; the live copies in `tools/` and `.github/workflows/` win
- `docs/baseline/reference/wow-api/` (start with its README): WoW API reference from the Warcraft Wiki. Read for any hook, Blizzard frame, combat or instance path, chat event handling, secret values, a taint report, a TOC or Interface change, or an API that differs between clients. Reference only; baseline 02 J and B carry the rules, and its README lists where it differs from the baseline

## Short form
- The live release is **3.4.0.29** (full, the new PSS window, 2026-10-08). Main is on the 3.4.1 line (3.4.1.30 on); status in 06.
- **Current project: core uplift** (`docs/pss/10_CORE_UPLIFT.md`, locked 2026-10-08): line 3.4.1 (name bugs, fixes, the upgrade report, sparse and forward-compatible saves), then 3.4.2 (core performance) and 3.4.3 (window tidy). The window (3.4.0, closed) is drawn in `PourSocialScore_GUI` with logic in `PourSocialScore_Libraries`; `/pss` opens it (`gui`, `ui`, `eui` aliases).
- The window, its three looks (Modern the default, then Classic and Dark) and its popups: the **Interface** section below.
- **Versions are `X.Y.Z.B` and the build number never resets (Dan, 2026-10-08; 3.4.0.27):** every build that gets a test zip, a stage or a fix, merged or not, takes the next build number, and so does a full release (`3.4.0.29`); a new line counts on (`3.4.1.30`), never back to 1. Every TOC, the history section and the zip name carry it. **`versions.json`** (repo root; `tools/versions.py`) records the latest release, every pre-release since it in order with its PR, and each past release with its pre-releases: references only, no text. It is never in a release zip, a test zip or the mirror. The pipeline publishes a version as a full release only when `versions.json` names it the latest release, and refuses a version it does not record. Bump with `sh tools/bump_version.sh build "Title"` (`release "Title"`, `line X.Y.Z "Title"`), then `sh tools/bump_version.sh pr <number>` once the PR is open; the rules check fails a missing or wrong PR in CI, a placeholder history bullet, and a history.txt whose top section is not the TOC version. Older names (`-devNNN`, `_N`, plain `3.3.1`) stay as they were. Baseline v7 (02 F).
- **Full releases: one summary of every change between releases (Dan, 2026-10-08).** At release time Claude lists the PRs between the previous release and this one (`python3 tools/versions.py prs <version>`, after `bump_version.sh release`), reads each PR (title, description, diff as needed) through the GitHub tools, and writes **one player-facing summary of all the changes** as the release's history section, replacing the placeholder bullet. The release notes are that summary only (no per-build lists, no PR text). Full releases are mirrored to `racetracks/Pour-Social-Score` (job `mirror`; secret `MIRROR_TOKEN`; `docs/pss/05_RELEASE.md`): the release zip's contents are committed as that repo's files and the release goes on that commit (Dan, 2026-10-08); pre-releases keep their own history section as notes and are not mirrored. No Claude API summary in the pipeline.
- Everything on `M` via `PourSocialScore_NS`; core fires `M.Events`; UIs write only through core setters. Tabs everywhere.
- Core holds only the chat filtering engine and the launchpad; anything not regularly active, or shared by both UIs, goes in `PourSocialScore_Libraries`, with a measured resident cost.
- No application or service logic in `PourSocialScore_GUI`. The EllesmereUI window is gone (3.4.0.25); read it, when needed, from git history (3.3.1 or 3.4.0.24).
- Every number the window shows comes from the core's counters, the same definitions as before (`check_viewquery.lua`). Logging loads only when logs are called.
- Taint and secrets (baseline 02 J, PSS 02 section 10): never write or replace Blizzard state; post-hooks and `Menu.ModifyMenu` only; every chat, unit and hook value goes through `M.PSS_IsSecret` before any compare or index; a secret line is neither filtered nor counted.
- Never change TOC Title or Notes. SavedVariables layout changes need Dan's OK and a migration validated on the three real saves.
- Never write to `racetracks/PourSocialScore-EllesmereUI` (retired). Read only: `EllesmereGaming/EllesmereUI` (all rights reserved; the reference for UI elements, 03 section 0), `Gethe/wow-ui-source`.
- Before pushing: `sh tools/check_rules.sh` (it also runs `check_toc.sh` on every folder and the PSS-names check), `PSS_REAL_SAVES=<out dir> sh tools/harness/validate_all.sh` on the saves built from scratch (below; includes `check_tui.lua` and every tab's check), and `tui_compare.sh` (the window, all three looks) for any change that should not show.

## Interface: the PSS window (PourSocialScore_GUI; PourSocialScore_UI until 3.4.0.24)
The one place for the window's rules (Dan, 2026-10-08). Details (decisions, code map, lessons) in `docs/pss/09_PSS_UI_PROJECT.md`; look numbers on scratch `docs/latest/ui uplift/04_LOOK_SPEC.md`.

### Every element works in all three looks (the first rule)
The window has three looks (option `uiSkin`), listed in this order everywhere (Options, docs):
1. **Modern** (value 2, **the default**): Blizzard's 12.x Social window art.
2. **Classic** (value 0, an option): Blizzard's classic templates; internal name "blizzard" (named Blizzard (Default) until dev008_4).
3. **Dark** (value 1, an option): the EllesmereUI port's flat style.

The saved values never change (old saves keep their look). Nothing ships that works or looks right in only one or two looks.
1. **One element, three paints.** Every control, row, pane, popup, menu and tooltip is built once, with the parts each look needs, and painted by the look shown (`ns.OnPaint`; Dark parts in `widget.pssParts`). Switching the look or the font (`uiFont`) repaints it in place, with no reload.
2. **Only the paint differs.** Layout, sizes, places, text, behaviour, keys (Escape, Back, Enter) and numbers are identical in all three. A look never adds, hides or moves a feature.
3. **Modern falls back to Classic** where the client has no Modern art (Camelot, or a missing atlas): check the art, never assume it. Dark falls back to its own parts when a Blizzard template is missing.
4. **Use the kit, not raw frames:** `ns.NewButton`, `ns.NewCheck`, `ns.NewEditBox` / `NewNumberBox` / `NewSearchBox`, `ns.NewPanel`, `ns.NewRows`, `ns.NewTab`, `ns.NewDropdown` / `ns.ContextMenu` (Blizzard's Menu API in Modern and Classic, our list in Dark or without the Menu API), `ns.Tip` (GameTooltip in Modern and Classic, our tooltip in Dark), `ns.Confirm` / `ns.CopyText` / `ns.ImportText` (the window's own frame art, `ns.NewFrameArt`, in Modern and Classic; the flat panel in Dark). A new kind of control is added to the kit in all three looks first, and to the kit preview (`tools/harness/kit_page.lua`).
5. **Per element, check:** its Modern art, its Classic template, its Dark parts; text faded with `SetAlpha`, never colour alpha; lines and edges one physical pixel (`ns.OnePixel`, `ns.NoSnap`); the accent is the class colour (`ns.Accent()`) in every look, with no option; fonts through `ns.Font` so `uiFont` applies (LibSharedMedia only read, only when another addon loaded it); anything that must show over Blizzard frame art sits on a frame raised above its NineSlice (level about 500).
6. **Prove it in all three looks:** `sh tools/harness/tui_compare.sh` (the window step by step in Modern, Classic and Dark; "identical" for a change that should not show, only the intended lines otherwise), `check_tui.lua` (the kit in every look), and in-game checks that name each look, on Retail and Camelot.

### Titles and popups
- **Only the main window's title carries the addon's name** ("Pour Social Score"). Popup and dialog titles say what they ask ("Remove Player?", "Remove Guild?", "Remove Rule?", "Prune Players?"), never the addon name, and sit in the title bar in Modern and Classic (Dan, 2026-10-08).
- The window's popups are our own frames (no `StaticPopupDialogs` entries from the window); each registers for Escape through `ns.EscapeCloses` after its own scripts are set. One Escape closes the top popup or menu, then steps the window up one level, then closes it.
- **Core's note, party warning and reload popups stay Blizzard StaticPopups in every look** (Dan, 2026-10-08): core never loads the GUI folder for a popup.

### The other interface rules
- **The EllesmereUI port is the reference** for layout, features and feel (as it shipped in 3.3.1; in git history from 3.4.0.25); the old GUI is not authoritative. Blizzard's Social window is the reference for Modern. Copy behaviour and numbers, never EllesmereUI's code or media.
- **EllesmereUI is the reference framework for UI elements** (Dan, 2026-10-08): when building a UI element needs more information, add `EllesmereGaming/EllesmereUI` to the session (`add_repo`, read only), check it out and reference it wherever possible, as a mature framework for UI porting. When porting, rewrite to suit our rules (the kit, all three looks, Libraries for logic, PSS names, zero cost, J rules) and use it as a reference; never copy it verbatim, and never its media. How: `docs/pss/03_ELLESMEREUI.md` section 0.
- **Logic in `PourSocialScore_Libraries`, drawing only in `PourSocialScore_GUI`.** No state, query, validation or flow in a drawing file; UIs write through core setters (`check_layers.lua`). No `EUI` or `Ellesmere` names in new code (`check_rules.sh`).
- **Zero cost until opened:** `/pss gui` loads Libraries and the GUI folder; each tab is built on first open; core events are heard only while the window shows (`ns.Listen`), and the window drops what it read and requests a GC on close.
- **Taint and secrets:** baseline 02 J and PSS 02 section 10 apply to every UI hook and every unit or chat value the window shows or acts on.
- **Saved state:** window place, last tab and new settings live in `PSS_OptionsDB` (routed `PourSocialScoreDB` UI keys); no new SavedVariables.

## Working in a Claude Code session
- Develop on the session's `claude/...` branch from the latest `origin/main`; one step per PR, based on main; never stack.
- If `gh` is not available, use the GitHub tools the session provides instead of the `gh` commands in the packs.
- **Scratch is `racetracks/Pour-Social-Score_Scratch`** (branch `main`; scratch rules 1 to 14 in `docs/scratch/05_RULES.md`). Every "scratch" in these docs means it; the old `racetracks/scratch` is no longer used. Add it to the session to read or write there (`add_repo`); if it cannot be added, say so and ask. Pull before every change, one commit per delivery, update its `readme.md` index when a folder's newest file changes, and always reply with links (`https://github.com/racetracks/Pour-Social-Score_Scratch/raw/main/<path>`, `/blob/` to read, `/tree/` for a folder).
- **The project files are the scratch repo** (Dan, 2026-10-08): saves, plans, docs, test zips and summaries are all there, and there is no `/mnt/project-files`. Wherever the packs say "project files" or `/mnt/project-files/...`, read scratch: `SavedVariables/<version>/` (saves), `docs/latest/` (plans and docs), `releases/` and `latest/` (zips).
- **Real saves are never committed here** (baseline 02 D10). They live on scratch at `SavedVariables/<version>/` (2.0.44, 3.0.0, 3.2.0-dev011). For the real-save run: `sh tools/harness/build_saves.sh <scratch checkout> <out dir>` (out dir in the session scratchpad; it defaults to `/tmp/pss-baselines`), then `PSS_REAL_SAVES=<out dir> sh tools/harness/validate_all.sh` (needs `lua5.1` from apt). If scratch cannot be read, say the real-save run did not happen; never claim it did.
- Test zips go to scratch `releases/PourSocialScore-<version>-<YYYY-MM-DD-hh-mm>.zip`, and the same commit replaces the zip in `latest/` with it (scratch rule 9); `sh tools/host_build.sh <scratch checkout>` does it from HEAD (`--no-commit` to add docs to the same commit); link it as `https://github.com/racetracks/Pour-Social-Score_Scratch/raw/main/<path>`.
- **One step per session (Dan, 2026-10-08; baseline 02 E9 to E11).** Dan resets the session after each step of an implementation plan: build only the stage named (the next one in `docs/pss/10_CORE_UPLIFT.md`'s table unless Dan names another), then stop.
- **Update the context in every PR:** the current project's stage table (state, PR, next build), `docs/pss/06_STATUS_AND_NEXT.md`, `02_RULES.md` for a new rule, `11_PREFERENCES.md` for a new preference, and the scratch copies (`docs/latest/pss-docs/`, `docs/latest/core-uplift/`) in the same delivery, so a fresh session starts from this file alone.
- **At each full release** re-summarize the done stages into `docs/pss/01_HANDOVER.md` (the addon as it works) and take them out of the plan; this file only points to the plan and design, never copies them. Dan's preferences live only in `docs/pss/11_PREFERENCES.md`.
- **Project data on scratch: always read `docs/latest/` first** (`docs/README.md` is the docs index, `readme.md` the repo index). It holds the newest markdown: the current project's plan (`docs/latest/ui uplift/`, the pss-ui project) and these PSS docs (`docs/latest/pss-docs/`). Each docs release is also zipped in the root of `docs/` (`<name>-<date>-vN.zip`) and a project or feature release keeps a history folder `docs/<project>/` (scratch rule 10). When a plan or these docs change, refresh `docs/latest/` in the same scratch commit. Status summaries go in `summary/<project>-<YYYY-MM-DD-hh-mm>.md`.
- The clone is shallow: before `validate_all.sh`, run `git fetch --depth=2000 origin main` (its upgrade checks rebuild old versions from history; without it the "split" checks fail on 2.0.1 and 2.0.40).
- Blizzard's UI source for a template or atlas question: a sparse clone of `Gethe/wow-ui-source` (for example `Interface/AddOns/Blizzard_SharedXML`, `Blizzard_SocialUI`); read only.
