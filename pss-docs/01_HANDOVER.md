# PourSocialScore (PSS): the addon as it works (state at release 3.4.0.29)

**The state document (baseline 02 E11, Dan, 2026-10-08):** how the addon works at the last full release. It is re-summarized at every full release from the plan's done stages (next: at 3.4.1.43, from `10_CORE_UPLIFT.md`). Status is in 06; Dan's preferences are in 11.

## 1. Purpose
PourSocialScore is Dan's World of Warcraft chat moderation addon (GitHub `racetracks`, in-game author Boaties). Clients: Retail (Midnight, Interface **120007**) and Camelot (Interface **16001**).

What it does:
- **Player Ignore List.** Unlimited and account-wide (players, NPCs, whole servers), with notes, expiry, per-player **W I G P C** flags (whisper, invite, guild, party, chat; ticked = allowed), exceptions to the defaults for listed people (3.4.0.22), a detail pane, auto-decline of duels/trades/invites, and Player Search via /who.
- **Guild Ignore List.** /who scans split until each query returns under 50, Scan All (keybind), Custom Scan, 6 s cooldown, level cap, Guild Search, Guild Exclusion List.
- **Managed community lists.** Shipped guild lists ("Managed Communities - Asmongold", 119 guilds), switched on by Chat Filters guild rules, off by default. Built with `tools/PSS_BuildManaged.lua`.
- **Chat filter engine.** Built-in filters off by default. Custom rules use a tag language compiled to closures (about 30 us per line). A chat link converter on the Chat Filters tab.
- **Block history and counts.** Counts per session, per 24 h and all time; the block log (2000 lines) plus kept lines per listed person (04).
- **One window** (from 3.4.0.25; 09) in three looks: Modern, Classic and Dark. Until 3.4.0.24 there were two front ends: the native window, and an EllesmereUI window when EllesmereUI was installed and the integration option on (03).

Goal: "global" moderation through shared lists. Sharing happens through shipped lists and Import/Export.

## 2. Repos
| Repo | Role |
| --- | --- |
| `racetracks/PourSocialScore` (private) | The addon: six folders (eight until 3.4.0.24), one version, `tools/` (rules checks, harness, managed list builder), readme.txt, history.txt, `.github/workflows` (release.yml, rules.yml) |
| `racetracks/Pour-Social-Score_Scratch` (private) | Hosting (layer 2 pack, `docs/scratch/`). Paths: `releases/` (test zips, versioned and dated), `latest/` (the newest test zip), `SavedVariables/<version>/` (saves), `docs/` (plans, issue notes, handover packs; newest markdown in `docs/latest/<project>/`), `summary/` (status summaries). Replaces `racetracks/scratch`, no longer used |
| `racetracks/PourSocialScore-EllesmereUI` | **Retired.** Held the EllesmereUI folder on its own 1.1 version line until 3.2.0-dev008 merged it into the addon repo. Dan is to archive it and close its PR #18. Never write to it |

Read only: `EllesmereGaming/EllesmereUI` (all rights reserved; the reference framework for building UI elements, rewritten to our rules and never copied, 03 section 0, Dan, 2026-10-08), `Gethe/wow-ui-source`. References actually used on PSS: an ElvUI zip Dan uploaded (the load-on-demand split), a DBM AddOns list screenshot (Category/Group/coloured titles), a Questie zip (upgrade output idea, issue #45), wago.tools, and the Warcraft Wiki reference set Dan uploaded on 2026-10-07 (`docs/baseline/reference/wow-api/`; rules in baseline 02 J and PSS 02 section 10).

## 3. Folders (one release zip holds all six from 3.4.0.25)
| Folder | Loads | Holds |
| --- | --- | --- |
| `PourSocialScore` (core) | Always | Chat filtering engine, block counting, outbox, setters, events, loader, options definitions, the window's openers and core popups (`PSS_BlizzardUI.lua`), upgrades, GC helper. SavedVariables `PourSocialScoreDB` (upgrade record, outbox, recent counts, sessionStart) |
| `PourSocialScore_Options` | Always | Data only: `PSS_OptionsDB`, `PSS_PlayersDB`, `PSS_GuildsDB`, `PSS_RulesDB`, `PSS_CountsDB` |
| `PourSocialScore_GUI` | On demand | The PSS window (09; from 3.4.0.25, before that the old native window): PSS_Skin, PSS_Kit, PSS_Tooltip, PSS_Menu, PSS_Popups, PSS_Rows, PSS_Pie, PSS_Detail, PSS_History, PSS_Players, PSS_Guilds, PSS_Filters, PSS_Events, PSS_Options, PSS_Window. Drawing only; no SavedVariables |
| `PourSocialScore_Libraries` | On demand | Commands and the window's logic: PSS_Commands, PSS_GuildQuery, PSS_FilterQuery, PSS_TotalsQuery, PSS_EventsQuery, PSS_ImportExport, and the view files PSS_ViewNav, PSS_DetailQuery, PSS_PlayerView, PSS_GuildView, PSS_FilterView, PSS_EventsView, PSS_OptionsView, PSS_RowMenus (09) |
| `PourSocialScore_Logging` | On demand, only when logs are called | `PSS_LoggingDB` (blockLog, blockKeep); PSS_SavedLog.lua, PSS_LoggingData.lua |
| `PourSocialScore_Communities` | On demand | Packed shipped lists (~460 KB) |
| `PourSocialScore_EllesmereUI`, `PourSocialScore_UI` | Deleted at 3.4.0.25 (D2) | The EllesmereUI window (03) and the new window while it was built; read them from git history (3.4.0.24) |

## 4. Real names (the project's own objects)
- **Namespace:** everything hangs on `M`, shared through the global `PourSocialScore_NS`. The window's private file table is `ns` (`PourSocialScore_GUI`).
- **Events:** `M.Events` (core bus). UIs listen (for example `OPTION_CHANGED`) and write through core setters.
- **Loader** (`PSS_Loader.lua`): `M.PSS_PARTS`; `NEEDS = {GUI="Libraries"}` (3.4.0.25; the `UI` and `EllesmereUI` parts are gone); `M.PSS_Need(key)` loads a part and what it needs; a part whose version differs from core's prints a warning. Logging: `M.PSS_LoadLogging()`.
- **Options:** `M.PSS_OPTIONS` (one table; the window's Options tab renders from it); read `M.PSS_Opt`, write `M.PSS_SetOpt`; only non-defaults stored.
- **Helpers and kit:** `M.ShowMsg`, `M.Trim`; the window's kit (`ns.NewButton`, `ns.NewCheck`, `ns.NewEditBox`, `ns.NewRows`, ...; CLAUDE.md Interface, 09 code map).
- **Counting and history:** `History.*` (04); totals `M.PSS_ListTotals` (Libraries).
- **Guild rules:** `M.PSS_GuildRuleActive`, `M.PSS_IsOwnGuild`.
- **GC helper:** `PSS_Perf.lua` (stepped collection; option `gcEnabled`).
- **Commands:** `/pss` on its own opens or closes the window, and `/pss gui`, `ui` and `eui` are the same command (one alias table, `OPEN` in `PSS_Commands.lua`; Dan, 2026-10-08, 3.4.0.28); every other word is its own command and `/pss help` (or any word it does not know) lists them; `/pss tui` is gone.
- **New window (09):** looks `M.PSS_UISkin()` (option `uiSkin`), accent `M.PSS_UIAccent()` (class colour), font `M.PSS_UIFontPath()` / `M.PSS_UIFontChoices()` (option `uiFont`), place `M.PSS_UIPlace` / `M.PSS_SetUIPlace` (Libraries `PSS_ViewNav.lua`); window `PSS_Window`, entry `M.PSS_OpenUI` (core) -> `M.PSS_OpenWindow`.

## 5. Crucial context
- Three TOCs per folder; one combined TOC broke Camelot in 3.0.0-dev6.
- **Measured hot spots:** `PSS_GetGuildBlockCounts`, the shipped member walk and `PSS_GetMemberBlockCounts` make about 200 to 350 KB of garbage per full pass on Dan's save. An estimate of 6 to 8 KB once measured 22 KB.
- **Known gaps:** removing a guild member who was blocked loads Logging (to clear their lines); removing one never blocked, or a guild, does not (3.4.0.15). Full parity was not reached; the project closed at 3.3.1 (08).
- **Known breaches of the baseline** are listed, with the line that fixes each, in 02 section 12 (the Overrides table, Dan, 2026-10-08): the idle GC cycle in `PSS_Perf.lua` (3.4.1), (the old window's totals pane and OnUpdate helpers went with it at D2, 3.4.0.25). The new window's pie hover OnUpdate is an approved override (Dan, 2026-10-08).

## 6. Plans and status
| Plan | Status |
| --- | --- |
| 2.0 line (to 2.0.44) | Done |
| Dashboard tab (2.0 era) | Paused, branch `claude/project-thread-pa7y7o` |
| Global moderation ideas (sync, curated lists, scoring) | Not started |
| 3.0 load-on-demand split | Done, v3.0.0 |
| EllesmereUI integration E.1 to E.7 | Done, v3.1.0 |
| Detail pane redesign, log every line, grouped save, EUI merged into the repo, EUI navigation, Events tab | Done, **v3.2.0** (full release, 2026-10-05) |
| Native GUI parity with the EllesmereUI window (3.3.0, issue #78) | Closed at **v3.3.1** (2026-10-07): dev001 to dev005 shipped, the rest dropped. 08 and 06 |
| **The new PSS window (3.4.0)**: one window in the port's layout, three looks, replaces both old windows | Done, **v3.4.0.29** (full release, 2026-10-08); started 2026-10-07; the cutover (D2) merged at 3.4.0.25. 09; plan on scratch `docs/latest/ui uplift/` |
| **Core uplift (3.4.1 to 3.4.3)**: name bugs, fixes, upgrade report, sparse and forward-compatible saves, then core performance and the window tidy | **Current**, locked 2026-10-08 (`10_CORE_UPLIFT.md`; design on scratch `docs/latest/core-uplift/`) |

## 7. Dan's preferences
All in `11_PREFERENCES.md` (the one file, Dan, 2026-10-08).
