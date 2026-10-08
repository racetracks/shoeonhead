# Feature design and delivery

How a feature goes from an idea to a production release: **design it, plan the implementation, cut it into stages, deliver each stage as its own small PR that can be tested on its own, and validate between PRs.** No big bang: no PR should be the first time two untested pieces meet.

## 1. Feature design (before any code)
One document per feature (or per agreed feature set), beside the plans in the hosting location. It holds:

| Section | What it says |
| --- | --- |
| Goal | What the user will see and do, in a few lines, from the author's request |
| What exists | The code, data and UI it touches; gaps; anything that already counts or draws something similar |
| Constraints | The rules that bite (02_RULES.md: zero cost when off, default OFF, no taint, SavedVariables growth, separation of logic and UI), API limits (01) |
| Design | Where each piece lives (core, library folder, each UI folder, 04_ARCHITECTURE.md); new settings and their defaults; new events; data layout and its migration; how each front end draws it |
| Decisions | Every open choice, numbered, with options and a recommendation. The author answers by number; record the answers with the date |
| Version line | The `X.Y.Z` line this feature owns (02 F); its builds take the next build numbers, which never reset |
| Implementation plan | The stage table below |
| Validation | How each stage and the whole feature will be proven (section 4) |
| Risks | What could break existing users, and how a stage will catch it |

Rules for the design:
- **Settle data before drawing.** Counting, storage and migrations come before any UI that shows them. If two places would count the same thing differently, the first stage makes them read one counter.
- **Design for zero cost when off.** Name what loads, what registers and what is allocated only when the user enables the feature.
- **Recommend a default for every fork** and say which one the stages are built on, so work never waits on an answer.
- Play the final decisions back to the author before the first stage starts.

## 2. Implementation plan: stages
Cut the feature into stages. Each stage is one PR and one build (`X.Y.Z.B`, the next build number) on the feature's line; a fix to a stage is the next build too. The table numbers a first line from 1; build numbers never reset (02 F2), so a later line carries on from the last build (`1.5.0.9`, `1.5.0.10`, ...).

| Stage | Build | Change | Visible? | How it is validated |
| --- | --- | --- | --- | --- |
| 1 | `X.Y.0.1` | Groundwork: shared logic moved or added in the library folder, nothing visible changes | No | Harness green; look-compare "identical"; measured resident cost |
| 2 | `X.Y.0.2` | Data: new counters or storage, with the migration | No | Migration run on every old layout and the author's real saves; save size measured |
| 3 | `X.Y.0.3` | The smallest visible slice of the feature, behind its option (default OFF) | Yes | In-game checks; option off = no cost and no change |
| 4.. | `X.Y.0.4`.. | One more visible piece per stage (one tab, one chart, one front end) | Yes | In-game checks for that piece, plus the earlier stages still passing |
| Last | `X.Y.0.B` | Polish, readme, edge cases from testing | Yes | Full regression: harness, look-compare, numbers match, real saves |
| Release | `X.Y.0.B` (the next build) | Version only, recorded as the release in `versions.json`; its history section is one summary of every change since the previous release, written from the PRs between them (02 F5) | | The author confirms the feature is complete |

How to cut stages:
- **Each stage is installable and testable on its own**: it builds, loads, passes the checks and leaves the addon usable. A half-done feature hides behind its option, never behind a broken window.
- **Order by dependency and risk**: invisible groundwork first (proven identical), then data, then the smallest visible piece, then one piece at a time.
- **A refactor that should change nothing is its own stage**, proven unchanged, never mixed with new behaviour.
- **Keep stages small**: one concern per PR, ideally one folder or one window. If a stage grows while building, stop, split it, and tell the author before carrying on.
- **One PR per stage, based on main**, after the previous stage has merged. Never stack PRs; a stage branch is cut from the main that already contains the stage before it.
- Each stage's PR names its stage, its build, what it changes and the measured cost of what it adds.

## 3. Delivering a stage
1. Branch from the latest `origin/main` (which carries the previous stage).
2. Build only that stage. Match the surrounding code (02 A3).
3. Bump every TOC to the next build and add its history section (`sh tools/bump_version.sh build "Title"`); update the readme if users see a change.
4. Run the validation for the stage (section 4) and fix until clean.
5. Open the PR; build and host the test zip (`sh tools/host_build.sh`); give the author the link and a numbered list of exact in-game checks.
6. The author tests and merges. Merging publishes the stage as a **pre-release** (09_RELEASE_PIPELINE.md).
7. In the same PR, update the status and the stage table (state, PR, next build) and anything else a fresh session needs (02 E10). The author resets the session; the next stage starts in a new one (02 E9).

## 4. Validation between PRs
Nothing starts on stage N+1 until stage N is merged and has passed:

| Check | When | Proves |
| --- | --- | --- |
| Rules check (CI) | Every PR | Lua 5.1, ASCII, style, no UI calls in core logic |
| Harness checks (06) | Every PR | Behaviour, events, setters, option table, loading on demand |
| Migrations on every old layout and the author's real saves | Any stage that touches saved data | No data loss, no growth, old leftovers pruned |
| Look-compare between main and the branch | Any stage that should not change a window | "Identical", or only the intended differences |
| Numbers match | Any stage where two places show the same count | Every front end shows the same numbers from one counter |
| Measured cost | Any stage that adds or moves code or data | Resident memory, compiled size, CPU, save size; numbers go in the PR |
| Option off | Any stage that adds a feature behind an option | No events, frames, hooks or memory when off; no change for users who never enable it |
| Test zip in game | Every PR | The author's numbered in-game checks pass on the real client and real saves |
| Earlier stages | Every PR | Earlier stages' checks still pass (the harness keeps them) |

If a stage fails in game: fix it as the next build on the same line (a new PR from main) before the next planned stage. Never fold a fix into an unrelated stage.

## 5. Finishing the feature
- When every stage has merged and passed, run the full regression on the last build.
- Ask the author to confirm the feature is complete. Only then does a PR make the next build the release (`sh tools/bump_version.sh release`), with one summary of every change since the previous release, written from its PRs; merging it publishes the full release.
- Re-summarize the done stages into the addon's state document (how it works at this release) and take them out of the plan (02 E11); mark the design document done, record anything learned in the preferences file or the rules, and park leftover ideas for a later line.

## 6. A worked shape (generic)
A feature "show a breakdown chart in the options window", line `1.5.0`:
1. `1.5.0.1`: move the totals query the chart needs into the library folder; the existing window calls it; look-compare identical.
2. `1.5.0.2`: add a capped per-type counter with a migration; validated on real saves; no UI.
3. `1.5.0.3`: draw the chart in the native window behind a new option (default OFF); option-off check; in-game checks.
4. `1.5.0.4`: the same chart in the suite front end from the same library call; numbers-match check.
5. `1.5.0.5`: fixes from testing, readme.
6. `1.5.0.6`: the release once the author confirms, recorded in `versions.json`, with one summary of every change since the previous release, written from the PRs of 1 to 5.
