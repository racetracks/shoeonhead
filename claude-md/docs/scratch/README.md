# Scratch repo usage (2026-10-07, v4)

How the author's **scratch** repo, `racetracks/Pour-Social-Score_Scratch`, is set up and used as the file host for every Claude project: test builds, handover packs, saves, docs and summaries. Attach this pack to a fresh Claude project alongside the baseline and the project-specific pack.

| File | What it holds |
| --- | --- |
| 01_PURPOSE.md | Why a scratch repo exists and what goes in it |
| 02_SETUP.md | Creating the repo and connecting it to Claude projects |
| 03_LAYOUT.md | The folder layout and naming |
| 04_USAGE.md | How to host each kind of file from a Claude session, and how to link it |
| 05_RULES.md | The rules for using scratch (the author adds more here) |

## Changes in v4
- SavedVariables location is `SavedVariables/<version>/` in this repo; `racetracks/scratch` `PourSocialScore/savedvariables/` was ported here and is no longer used.

## Changes in v3
- The scratch repo is `racetracks/Pour-Social-Score_Scratch` (was `<owner>/scratch`).
- Layout follows the author's rules 4-10: `SavedVariables/`, `releases/`, `latest/`, `docs/`, `summary/` replace `<Addon>/test-builds`, `<Addon>/savedvariables`, `<addon>-projects`, `<addon>-issues` and `handover-packs/`.
- Timestamps are `YYYY-MM-DD-hh-mm` (rule 2).
- Rule 6 corrected: the mandatory folder is `docs` (v2 said "features").
- The templates are now the live READMEs in the repo (`readme.md`, `docs/README.md`, and each folder's README).

## Changes in v2
- Written for any author: no personal names.
