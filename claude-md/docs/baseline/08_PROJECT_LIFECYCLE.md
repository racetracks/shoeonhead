# Project lifecycle for a fresh addon

How a new addon project runs from an empty repo to production releases and long-term maintenance, and which documents carry it. Each phase ends with something the author can install and test. Inside every phase, features follow 10_FEATURE_DESIGN_AND_DELIVERY.md: designed first, then delivered in small validated PRs.

## Phase 0: Bootstrap the repo
**Goal:** an empty addon that releases itself.
- Create the repo, the main addon folder and its three TOCs (01, 02 B), readme.txt and history.txt.
- Add the Rules CI and the release workflow before the first version you want released (09_RELEASE_PIPELINE.md).
- Add the harness skeleton (06_HARNESS.md): the WoW stub, the runner, one check that loads the addon.
- First version `0.1.0.1`: confirm the Rules check runs on the PR and a pre-release appears on merge.

**Documents:** the project instructions (from the template), readme.txt, history.txt.

## Phase 1: Plan
**Goal:** agree what the addon does before building it.
- Claude writes an **analysis**: the problem, what the WoW API allows and forbids (01), comparable addons and what to learn from them (03), risks.
- Then a **plan**: numbered steps, smallest visible feature first, each with its build number, what it does and how the author validates it in game.
- Every open choice becomes a **numbered decision** with options and a recommendation. The author answers by number; record the answers with the date.

**Documents:** `01_ANALYSIS.md`, `02_PLAN.md` (a step table), the decisions list, and a feature design per feature (10).

## Phase 2: Core feature (first usable build)
**Goal:** the always-on job working, with the smallest UI that proves it.
- Core: the always-on engine, setters, events, the option table, the first SavedVariables with an upgrade record from day one.
- A minimal native UI built with a UI kit file (04).
- Checks for the engine, the option table and the upgrade record.

**Documents:** history sections per build; the plan's step table marked as steps merge.

## Phase 3: Harden
**Goal:** safe to leave running.
- Caps on every store, pruning on upgrade, garbage collection only at safe moments (02 C, D).
- Migrations validated against every old layout and the author's real saves.
- Measure resident memory and CPU; record the numbers in each PR.
- A look-compare for the UI (06), so later UI-neutral changes can prove they changed nothing.

## Phase 4: Split for memory
**Goal:** only the always-on job stays resident.
- Move everything not regularly active into load-on-demand folders: the UI, the library folder for shared logic, large shipped data (04).
- Add the loader and the folders' TOC dependencies; group the folders in the AddOns list.
- Measure the resident cost before and after.

## Phase 5: Integrations (optional)
**Goal:** an alternative front end inside a UI suite, (05_UI_SUITES_AND_KNOWN_FIXES.md).
- Off by default, its own folder, the bridge in core, both looks working.
- Logic either UI needs goes in the library folder first, as its own step with no visible change.

## Phase 6: Parity and polish (when there are several front ends)
**Goal:** the same features and numbers in every front end.
- Audit both UIs feature by feature in a table (both / one only), confirm it with the author, and plan one feature per PR.
- Make both read the same counters before porting anything that draws them.
- Add a numbers-match check to the harness.

## Phase 7: Production release
**Goal:** a full release.
- The author confirms the feature (or feature set) that owns this line is complete and tested.
- A PR makes the next build the release (`sh tools/bump_version.sh release "Title"`, recorded in `versions.json`), with one summary of every change since the previous release as its history section, written from the PRs between them (02 F5); merging it publishes the full release.
- Update the readme for users.

## Phase 8: Maintenance
- Each client patch: check interface numbers and API changes on wago.tools, bump the TOCs, run the harness.
- Bugs become the next build with a hosted zip and in-game checks.
- New work starts the next minor line (`X.Y+1.0`, with the next build number; `B` never resets) with its own analysis and plan.
- Track issues on the addon repo; small notes for an issue go beside the plans.

## The documents that carry a project
| Document | Holds | Updated |
| --- | --- | --- |
| Project instructions | The rules in short, the repos, how to start | When a rule changes |
| `01_ANALYSIS.md` | What exists, gaps, constraints, numbered decisions with recommendations | Start of each project; decisions as the author answers |
| `02_PLAN.md` | The step table: build number, change, how to validate | As steps merge or split |
| Status | Merged and open PRs, next build number, open issues, parked ideas, items waiting on the author | Every step |
| history.txt | One section per version, newest first, plain bullets | Every version |
| readme.txt | What the addon does for users | When features change |
| Project memory | Decisions, preferences and facts a new thread would otherwise ask again | Whenever one is learned |
| Handover packs | This baseline, the hosting pack, and an addon pack (HANDOVER_TEMPLATE.md) | When a thread gets long |

## Habits across every phase
- One step per PR, based on main; the author tests in game and merges.
- If a step turns out bigger than it looks, split it and tell the author before building.
- Harness and number checks come before anything new is drawn.
- Any change to code that should look unchanged is its own step, proven identical.
