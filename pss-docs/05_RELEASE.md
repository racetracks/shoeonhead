# Release: what PSS does on top of the baseline pipeline

The pipeline is the baseline's (baseline 09). The live files are `.github/workflows/release.yml`, `.github/workflows/rules.yml` and `tools/`. PSS-specific details:

## Names and paths
- Main TOC (version source): `PourSocialScore/PourSocialScore.toc`. Zip: `PourSocialScore-<version>.zip` holding every `PourSocialScore*` folder (eight from 3.4.0-dev001 with `PourSocialScore_UI`, six from 3.4.0.25), readme.txt and history.txt copied into the core folder.
- Release title: `Pour Social Score <version>`. Tags `v<version>`.
- history.txt opens with "POUR SOCIAL SCORE - VERSION HISTORY" and "(newest first)"; each section is `=> X.Y.Z.B - Title`, a blank line, then plain bullets (`tools/bump_version.sh` writes it).

## CI jobs (rules.yml)
- `check`: `sh tools/check_rules.sh` (Lua 5.1 syntax, ASCII, tabs, layers, TOCs, the history check; `tools/check_rules_eui.sh` is gone with the EUI folder, 3.4.0.25).
- `harness`: the window's checks (the EllesmereUI checks went at 3.4.0.25) (`check_tui`, `check_viewquery`, `check_players`, `check_guilds`, `check_filters`, `check_events`, `check_options`, `check_menus` (3.4.0.21)) and `check_secrets.lua` (3.4.0.14).
- `upgrades` (3.4.0.14): `sh tools/harness/validate_all.sh` on a full clone (`fetch-depth: 0`), without real saves: upgrades from every old layout, data, on demand, growth, the window checks. The real-save run stays local (saves built from scratch).
- `check` also runs `tools/check_toc.sh` on every `PourSocialScore_*` folder (three TOCs agree, files exist, Version = core's) and the PSS-names check.

## Release history
| Version | Kind | Notes |
| --- | --- | --- |
| 3.0.0 | Full | Load-on-demand split |
| 3.1.0 | Full | EllesmereUI integration |
| 3.2.0 | Full, 2026-10-05 | **Last full release** |
| 3.3.0-dev001 to dev003 | Pre-releases | Parity stages, published on merge |
| 3.3.1 | Full, 2026-10-07 | Parity project closed (dev001 to dev005) |
| 3.4.0-dev001 to dev012 | Pre-releases | The new PSS window (09) |
| 3.4.0.13 on | Pre-releases | Build numbers replace `-devNNN` and `_N` (Dan, 2026-10-08) |
| 3.3.0-dev004 | **Not published** | PR #82 merged 2026-10-05 20:45Z, but the Release and Rules runs on main (5c39f62) were **cancelled**, so no release or tag exists. Fix: run the Release workflow by hand (`workflow_dispatch`) on main while 3.3.0-dev004 is still the version, or let the next stage (dev005) publish and leave dev004 as test-zip only. **Dan chose skip (2026-10-07)**: dev004 is test-zip only |

## Tools (3.4.0.20, Dan, 2026-10-08)
- `sh tools/bump_version.sh build "Title"`: every TOC to the next build, the build recorded in `versions.json`, a history section on top (fill in the bullets). `release "Title"` makes the next build the release (only when Dan says it is a release; the pre-releases move under it in `versions.json`); `line X.Y.Z "Title"` starts a line with the next build number (3.4.0.27). `pr <number>` records the PR that carries the new builds. `python3 tools/versions.py prs [<version>]` lists the versions and PRs between the previous release and a version.
- `sh tools/host_build.sh <scratch checkout>`: builds the test zip from HEAD the way `release.yml` does, puts it in scratch `releases/` and `latest/` (replacing the old one), updates the index rows, commits and pushes, and prints the links. `--no-commit` stages only, so docs join the same commit; `--no-push` commits without pushing.
- `check_rules.sh` fails a history.txt whose top section is not the TOC version or still holds a placeholder bullet, and runs `versions.py check` (CI: every entry has its PR; a pull request's newest entry is its own number, `PSS_PR` in rules.yml).

## Full releases: notes and the mirror (3.4.0.20, Dan, 2026-10-08)
- A full release's notes are its history section only, under "Changes since <previous release>": one summary of every change since the previous release, written by Claude at release time from the PRs `versions.json` lists between the two (Dan, 2026-10-08, 3.4.0.27; `CLAUDE.md`, Full releases). No API key in the pipeline; `tools/collect_notes.sh` is gone. Builds keep their own history section as notes. `release.yml` reads `versions.py kind`: a version not recorded is not published, and only the recorded release is published as a full release (`--latest`).
- Job `mirror` keeps **`racetracks/Pour-Social-Score`** on the latest full release (3.4.1.30, Dan, 2026-10-08): the release zip's contents committed as the repo's files (the addon folders at the root; the mirror's own readme.md stays), then the release, with the same zip and notes, on that commit. It runs after every push and does nothing when the mirror is up to date, so it repaired 3.4.0.29 (its release went across without the files) (`MIRROR_REPO` in release.yml). It needs the secret `MIRROR_TOKEN` (a fine-grained token with Contents: Read and write on that repo only) on the addon repo; the mirror repo already has a commit, which it needs. Builds are not mirrored. After fixing a secret, run Actions > Release > Run workflow on main.

## Build numbers (Dan, 2026-10-08)
Every build is `X.Y.Z.B` (02 section 8): the next build number for every test zip, a stage or a fix, merged or not, and for a release (from 3.4.0.27 the number never resets: release `3.4.0.29`, then `3.4.1.30`); every TOC, a history section and the zip name carry it. `check_toc.sh` accepts only `X.Y.Z.B`. `release.yml` asks `versions.json` what a version is: the latest release is published as a full release and mirrored, a recorded pre-release as a pre-release (and kept one), anything else not at all.

Until 3.4.0-dev012 a round of fixes on an unmerged dev build was `devNNN_N` (`3.4.0-dev002_2`, `_3`, ...).

## Test zips
- Scratch (`racetracks/Pour-Social-Score_Scratch`, from 2026-10-08): `releases/PourSocialScore-<version>-<YYYY-MM-DD-hh-mm>.zip`, and the same commit replaces the zip in `latest/` with it. Link `https://github.com/racetracks/Pour-Social-Score_Scratch/raw/main/<path>`.
- Builds up to 3.4.0-dev005 are on the old `racetracks/scratch` (`PourSocialScore/test-builds/`, dev001 to dev003 of 3.3.0 also in `pss-builds/`); those links stay, nothing new goes there.

## PSS pitfalls seen
- 3.2.0: PRs #71 to #74 were stacked and merged into stale branches; PR #75 carried them to main. Never stack.
- The first EUI release was dev3 because release.yml arrived late in that repo.
- 3.3.0-dev001 to dev003 test zips first went to `pss-builds/` by mistake.
- Assign PRs to `racetracks` (requesting the owner as reviewer returns 422).
