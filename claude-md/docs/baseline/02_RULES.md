# Rules for every addon

These are every rule the author has applied, written so they fit any addon. "Core" means the always-loaded addon folder; "library folder" means the load-on-demand folder that holds shared logic.

**These rules are mandatory.** An addon-specific pack may add rules and never needs to repeat these. It may override one only by listing it in its **Overrides table** (rule, what applies instead, the author's OK with its date); a known breach waiting for a fix is listed there too, with the version line that fixes it. A difference that is not in the table is a bug to fix, not a local rule.

## A. Code
1. **Lua 5.1 only.** No goto/labels, table.unpack, table.pack, bit32, utf8, _ENV, rawlen or 4-arg load.
2. **ASCII only** in code, comments, strings, TOCs, readme.txt and history.txt. Non-ASCII as Lua decimal escapes ("\195\169"). No em dashes or curly quotes.
3. **Match the surrounding code.** Copy the shape of the nearest existing example before writing anything new: naming, comment density, idiom.
4. **Tabs, not spaces** for indentation; no alignment spaces; no trailing whitespace. Exception: a folder that integrates a UI suite follows that suite's own style guide (some use spaces).
5. **Localize everything.** Every function and variable in a file is `local` unless it explicitly needs to be shared. Global variables pollute the global environment and collide with other addons.
6. **A single global table.** When the addon needs a global handle (slash commands, inter-addon communication, sharing across its own folders), create one root table named after the addon (`local addonName, ns = ...`, then `_G[addonName] = ns` or a fixed `MyAddon` name) and attach everything shared to it (shared functions, runtime state, strings), grouped in a few sub-tables by role. No other new globals beyond SavedVariables and frame names that the client needs.
7. **Localize API shortcuts.** Map frequently used global WoW API and library functions to locals at the top of the file (`local UnitName = UnitName`, `local floor = math.floor`, `local pairs = pairs`). Global lookups cost more than local or upvalue access, and it reads cleaner. Mind Lua 5.1's limits (200 locals per function, 60 upvalues per closure): localize what is used often, not everything.
8. **Function and module driven.** Shared helpers (message output, trimming) and UI kit builders (window, input box, number box, text area, scroll list, check box) instead of raw CreateFrame code everywhere.
9. **No UI code in backend logic.** Core owns a small event bus (subscribe, unsubscribe, fire) on the root table. When data changes, core fires a named event saying what changed; it never calls a window. UIs subscribe while they are open, unsubscribe on close, redraw from the event, and write saved data only through core setters. A check in the rules script (06) fails the build if a core logic file creates frames, tooltips, popups or calls UI code.
10. **No libraries** (Ace, LibStub) unless the author agrees. WoW API only.
11. **No test-only globals** in addon code; the harness reaches the addon through its namespace and frames.
12. Enforce A1 to A4 (and A5's no-new-globals) with `sh tools/check_rules.sh`, locally and as the "Rules" CI check. It also fails a version that is not `X.Y.Z.B`, TOCs that disagree, a history.txt whose top section is another version or still holds a placeholder bullet, and a `versions.json` that disagrees or (in CI) lacks a PR (F).

## B. TOCs
1. Three TOCs per addon folder when supporting several clients (01_PURPOSE_AND_LANGUAGES.md).
2. One version in every TOC of the repo; all folders release together.
3. Group the folders in the AddOns list: `## Category`, `## Group`, a coloured `## Title` (`|cff69ccf0Name|r <Part>`), `## IconTexture`. (Learned from DBM's AddOns list; copy the idea, never its IDs.)
4. **Never change Title or Notes unless the author asks.** The Notes wording is the author's.
5. **Check interface numbers on every client patch** in game (`/dump select(4, GetBuildInfo())`) or on the Warcraft Wiki "Public client builds" page, and update every TOC together. Watch for new TOC suffixes: a game-type suffix beats the family one (`_Standard` from 12.1.5 beats `_Mainline` on Retail), and a pre-launch suffix such as `_Camelot` may change (reference/wow-api/01).
6. Feature-detect APIs that differ between clients (`if C_Foo and C_Foo.Bar then`). Compare `WOW_PROJECT_ID` against the named constants, guarded for nil, never against bare numbers.

## C. Performance and memory
1. **Zero cost unless enabled.** If a change adds a setting, users who never turn it on pay nothing: no event registrations, no hooks doing work, no frames created, no OnUpdate, nothing loaded or allocated. Build lazily on first enable and register events only while the feature is active.
2. **Zero behaviour change without opt-in.** New settings default OFF. A feature that appears for everyone after an update is a violation, even if it is good. Only genuine bug fixes may change behaviour without opt-in.
3. **Low cost when enabled.** Opted-in features stay cheap: event-driven, never OnUpdate polling; no wall-clock timers as logic gates; no per-frame table allocations in hot paths; small loops.
4. **Zero taint risk, no exceptions.** Never touch secure frames or protected functions from insecure code, never replace Blizzard functions (use `hooksecurefunc` only where a post-hook is safe), and defer anything protected until out of combat. Section J has the full rule set.
5. **No UI at login or startup.** Windows, tabs and their frames are built on first open, never at load or PLAYER_LOGIN.
6. **Reuse frames** instead of destroying and recreating them whenever practical: pools of rows and widgets, hidden and re-shown.
7. **Don't retain references unnecessarily.** When a possibly large object (a table, a list, a built index) is no longer needed, drop the reference (`t = nil`, clear the cache) so it can be collected.
8. **Unregister events** as soon as they are no longer needed (one-shot login events, a feature switched off, a window closed).
9. **Don't refresh the UI unnecessarily.** Redraw only what is shown, only when its data changed; coalesce bursts into one redraw.
10. **Batch expensive operations.** Group work (scans, list rebuilds, saves, redraws) and do it once, at a quiet moment, rather than per event.
11. **Cache and queue API calls.** Where practical, cache results and send queued requests in a paced loop rather than flooding the API (for example /who or server queries).
12. **Don't use `table.insert()` when you don't need it.** Append with `t[#t + 1] = v` (or a kept counter); use `table.insert` only to insert in the middle.
13. **No load-time memory growth;** no needless tables; no per-record tables on hot read paths.
14. Systems not needed at login live in **load-on-demand** folders.
15. **Garbage collection only on request** (login, after a big job such as a scan or an import, on window close), deferred until a quiet moment: out of combat and not in an instance (`IsInInstance`), detected from events (PLAYER_REGEN_ENABLED, zone changes), not from wall-clock timers. No timer- or heap-growth triggers.
16. No discovery work on mouseover or nameplates in combat.
17. **Measure, never estimate:** `loadfile` plus `collectgarbage("count")` for resident cost, `luac -s` for compiled size, a benchmark for CPU. An estimate of 6 to 8 KB once measured 22 KB.
18. "**The performance option**" means: benchmark the candidates and pick the fastest or smallest, with the numbers in the reply.

## D. Data and SavedVariables
1. **SavedVariables are a major memory cost.** Everything saved stays in memory all session, so design them for minimal storage and memory: compact keys and values, no duplication, nothing derivable.
2. **SavedVariables must not grow.** Every store has a cap and is pruned on upgrade.
3. No default-valued fields in stored records; options store only non-default values.
4. **Design with indexes.** Look things up by key (a table keyed by name or ID) instead of scanning lists.
5. **Lazy indexes.** Don't make the client rebuild an index at login; build it on first use and keep it only while it is needed.
6. **Separate the database from the runtime cache** when it gives a performance benefit: the saved table holds the compact truth; a runtime cache (unpacked, indexed, sorted) is built on demand and never saved.
7. **Counters are kept at event time** and nothing is counted twice. When two places show the same count, they read the same counter.
8. **Every layout change has a numbered, run-once migration** tracked in an upgrade record, plus a login tidy-up of leftovers. Cleanups for load-on-demand data run when that data loads.
9. **Ask the author before any SavedVariables layout change**, and validate the migration against every old save and the author's real saves first.
10. Keep the author's real saves by the version that wrote them, outside the addon repo (in the project files and the project's hosting location); **never commit real saves to the addon repo.**
11. Removing an entry deletes all of its saved data.
12. Pack bulky data as strings when it is read rarely (packing per-line tables into strings cut one store by about 80%).

## E. Process
1. Branch from the latest `origin/main`. **One step per PR per repo, based on main.** Avoid stacked PRs (09_RELEASE_PIPELINE.md). Features are designed, staged and delivered in small validated PRs (10_FEATURE_DESIGN_AND_DELIVERY.md).
2. Every change: bump the version in every TOC and add a history.txt section at the top (`=> X.Y.Z.B - Title`, plain bullets), both with `sh tools/bump_version.sh build "Title"`; update the readme when features change.
3. Every step ships an installable test zip, hosted with a link (`sh tools/host_build.sh`), and an exact list of what to check in game.
4. Before pushing: the rules check, the harness against the author's real saves, and the look-compare for any window that may change (06_HARNESS.md).
5. **The author merges.** "Branch, PR and release" is approval to merge and verify the release. Claude cannot delete branches; the author does.
6. When `gh pr create` is blocked (GraphQL), create PRs through REST: `gh api repos/<owner>/<repo>/pulls -f title=... -f head=... -f base=main -f body=...`.
7. Commits and PRs carry the attribution lines the session gives; no model names in repo files.
8. Each PR reports the measured size of anything added or moved and what the look-compare showed.
9. **One step per session (v9).** The author resets the session after each step of an implementation plan. A session builds only the step it was given and ends with that step's PR; a fresh session picks up from the project instructions file (`CLAUDE.md`) alone.
10. **Context is updated in every PR (v9).** Before a step's PR is final, it updates what a fresh session needs: the current plan's stage table (state, PR, next build), the status file, the rules file for a new rule, the author's preferences file for a new preference, and the hosted copies of those docs. Nothing a later step needs may live only in the session.
11. **Plans are references; state is re-summarized at release (v9).** The project instructions file points to the current plan and design and never copies them. At each full release the done stages are re-summarized into the addon's state document (how the addon works at that release) and leave the plan. The author's preferences and approach live in **one** file that the project instructions load; every other doc stays technical.

## F. Versions and releases (09_RELEASE_PIPELINE.md)
1. **Releases are defined by feature.** A feature, or an agreed set of features, owns one version line `X.Y.Z`. Its design names the line before work starts (10_FEATURE_DESIGN_AND_DELIVERY.md).
2. **Every version is `X.Y.Z.B`, and the build number `B` never resets** (v7). Every build that gets a test zip, a stage or a fix, merged or not, takes the next number and none is reused; the full release is a build too, and a new line counts on from it. Example: `1.4.0.1` (first stage), `1.4.0.2` (a fix to it), `1.4.0.3` (the next stage), release `1.4.0.4`, then `1.4.1.5`. Every TOC, the history section, the tag, the release and the zip name carry it. `sh tools/bump_version.sh build "Title"` works out the next number; the rules check fails any other shape.
3. **`versions.json` records every version** (repo root, `tools/versions.py`): the latest release, every pre-release since it in order with its PR, and each past release with its pre-releases. References only, never text. It is never shipped: not in a release zip, a test zip or a mirror. The release workflow publishes a full release only for the version it names the latest release, a pre-release for any other recorded version, and nothing for an unrecorded one.
4. **Fixes** during a line are the next build: bump the TOCs, add a history section, build the zip, host it and give the author the link. After a full release, fixes start a new line (`X.Y.Z+1`) with the next build number.
5. **The full release is the completed feature, and its notes are one summary of every change since the previous release.** Only when the author confirms the feature is done does a PR make the next build the release (`sh tools/bump_version.sh release "Title"`). At that time Claude lists the PRs between the previous release and this one (`python3 tools/versions.py prs <version>`), reads each, and writes one player-facing summary of all the changes as the release's history section; the release notes are that summary only. Merging publishes the full release and mirrors it where a mirror repo is set.
6. The next feature starts the next line (`X.Y+1.0`), or `X+1.0.0` for a breaking change the author agrees to, with the next build number.

## G. Separation of logic and UI
1. **No application or service logic in a UI folder.** A UI folder only draws and calls core setters. Counting, queries, totals, event lists, import parsing and scans live in core or the library folder.
2. **Minimal functions in the always-loaded core.** Core is only the framework for the addon's always-on job and a launchpad for everything else (event handling, the always-on engine, counting, setters, events, the loader). Functions that do not run in active memory or are not regularly active go in the library folder. Prove each placement with a measured resident cost.
3. **Several front ends stay independent.** Each UI lives in its own folder and never reads or loads a file from the other, so a user never has to load two UI folders. Both show the same numbers because both call the same library function.
4. **UI resources that both front ends call live outside both UI folders.** A function, data table or texture that a suite integration needs cannot be stored in the native UI folder, and the reverse. Put it in the library folder, or in core when always-loaded code needs it.
5. **One config, assets in different places.** Every UI renders its options from one definitions table in core; each UI keeps only its own look-specific state.

## H. UI suite integration (applies when an addon integrates a full UI replacement suite)
1. **Off by default, zero cost when off** (C1 to C4 apply in full). Detect the suite and require a user option (default off); load the integration folder on demand only when both are true. Switching it prompts a reload.
2. **Same config, different assets.** Both UIs render from the one option table and save through the same setters. Native uses Blizzard templates and textures; the suite folder takes fonts, colours and skins from the suite at run time. Never copy the suite's media files.
3. **Documented API only.** Never read or write private (`_`) fields, never hook the suite's functions, never load its options addon yourself.
4. **Respect the licence.** Many suites are all rights reserved: write original code; reading their code to learn behaviour is fine, copying it is not.
5. **Follow the suite's house rules** for tooltips, confirmations and options layout (05_UI_SUITES_AND_KNOWN_FIXES.md).
6. **Every frame must look right with the suite's skin on and off** (the plain fallback).
7. **Fade text with the FontString's `SetAlpha`, never `SetTextColor` alpha** (the shadow stays at full strength and reads as a second label; 05, known fix 1).
8. **Link hover:** only call `GameTooltip:SetHyperlink` for link kinds that have a tooltip (an allow list); a profession `trade:` link opens a window on hover otherwise (05, known fix 2).
9. Keep the integration in the same repo and version as the addon unless a licence forces otherwise: one version, one release, one CI.
10. Same features and same numbers in both UIs, each drawn in its own look. That is parity, not shared UI code.

## I. Porting a feature from one front end to another
1. **Use only our own or Blizzard resources.** A feature moved from the suite UI to the native UI uses no texture, font, template or API from the suite or any other addon.
2. **Look as close as possible** to the source version while still looking like the Blizzard UI.
3. **Copy our own code when it is smaller.** If copying our own suite-folder code into the native folder gives a lower footprint, copy it as functions into the native folder only. It is a copy, not shared code. Never copy the suite's own code.
4. **Treat the source UI folder as read only** while porting. The one allowed edit is moving logic found there into the library folder, with the source UI calling it and nothing visible changing (prove it with the look-compare).
5. **Shared functions that serve both UIs are performance-optimized and measured.**
6. Settle any counting differences first: two windows that count differently cannot show the same numbers, so make both read one counter before porting what draws them.
7. Build each port on the recommended layout when a design fork is open, ask once with a card, and change the PR if the author picks another option.

## J. Security, taint and secret values (reference/wow-api/)
Addon code is always tainted: it can never call a protected function or change a protected frame in combat, and on Retail 12.x it cannot inspect secret values. Taint enters Blizzard code through shared state an addon writes or replaces, not through the addon's own frames and tables.
1. **Never automate a decision the security model reserves for the player** (choosing a target or spell, acting on an event in combat). It fails at run time; it is not merely discouraged.
2. **Never write to anything Blizzard owns:** no Blizzard globals, Blizzard table keys or fields on Blizzard frames. Keep per-frame data in your own weak-keyed table (`setmetatable({}, {__mode = "k"})`). Adding your own uniquely prefixed key to a registry meant for addons (`StaticPopupDialogs["MYADDON_X"]`, `SlashCmdList`, `SLASH_*`, appending your frame's name to `UISpecialFrames`) is the accepted exception; never change an entry Blizzard owns.
3. **Never replace a Blizzard function or method**, not even to neuter it (`Frame.SetPoint = function() end`). Post-hook only, with `hooksecurefunc` or `HookScript`. Never `SetScript` on a frame you did not create. Hooks cannot be removed: gate the hook body with a flag so it costs nothing while its feature is off (C1).
4. **Avoid calling Blizzard Lua that stores state** (`Add*`, `Register*`, data providers, pools, `UIDropDownMenu_*`, `ShowUIPanel` on Blizzard panels from addon code in combat): the state it writes is tainted by your call. Prefer C APIs and documented extension points. Menus use the Menu API (`MenuUtil`, `Menu.ModifyMenu`) where the client has it, never `UIDropDownMenu`.
5. **Protected frames:** guard every `Show`, `Hide`, `SetPoint`, `SetSize`, `SetParent` and `SetAttribute` on a frame that is or may be protected with `InCombatLockdown()`, and queue it for `PLAYER_REGEN_ENABLED`. Never anchor or parent your own frames to protected frames (the lock spreads to them). Avoid secure templates unless the feature needs one; a frame from a secure template that must work in combat is created out of combat at load or login, the one exception to C5. Never `SetScript` a handler a secure template defines.
6. **Check `IsForbidden()`** before touching a tooltip or any frame you do not own, and bail out if it is. Never read positions of nameplates or chat bubbles (anchor-restricted); call `ClearAllPoints()` before re-anchoring anything attached to them. Never try to find or restyle Private Aura frames.
7. **Retail 12.x secret values.** Treat values from unit, aura, cooldown, cast, threat, stat and loss-of-control APIs, identity APIs such as `UnitName` for units other than you, your pet and your group while restricted, and chat event arguments under chat messaging lockdown (encounters, Mythic+, PvP, restricted maps) as possibly secret. Never compare, do arithmetic on, take `#` of, index, or use as a table key a value unless `issecretvalue` says it is not secret or `canaccessvalue` allows it; feature-detect (`if issecretvalue then`) so classic clients keep working. Degrade gracefully: skip the record, never error. Send secret data straight to widgets that accept it, never read widget state back (`GetText`, `GetValue`, `IsShown`) for logic after feeding it a secret, and never anchor layout frames to widgets that show secrets.
8. **No `COMBAT_LOG_EVENT(_UNFILTERED)` on Retail 12.x:** registering it is forbidden. Design around Blizzard's provided systems.
9. **Test under restrictions** before shipping anything that runs in combat, instances or chat: the session-only CVars `addonCombatRestrictionsForced`, `addonEncounterRestrictionsForced`, `addonChallengeModeRestrictionsForced`, `addonPvPMatchRestrictionsForced`, `addonMapRestrictionsForced` and `addonChatRestrictionsForced` (`/console <cvar> 1`).
10. **Taint reports:** ask for `Logs\taint.log` (`/console taintLog 1`, `11` for verbose, then `/reload`; set back to 0 afterwards). Treat the blamed addon as a lead, find the first "Execution tainted ... while reading" entry, and audit the code for J2 to J4 before chasing the stack.
11. **Never guess an API signature or its secrecy.** Check the client's generated documentation (`/api`, Townlong Yak's API documentation, `Gethe/wow-ui-source`) and the API change summaries for the target client, or say it is unverified.
12. Every taint-sensitive change (a new hook, a new Blizzard frame touched, anything that runs in combat) says in its PR which J rules apply and how the in-game checks cover them.
