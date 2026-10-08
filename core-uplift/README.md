# core uplift (authoritative, 2026-10-08)

The current PourSocialScore project: lines 3.4.1 (fixes and data), 3.4.2 (core performance), 3.4.3 (window tidy). **This folder is the authoritative design and plan**; it supersedes `docs/latest/code-review/` (its 3.4.1 plan is folded in) and the draft `docs/drafts/review-roadmap-2026-10-08-draft1/`.

| File | What |
| --- | --- |
| `00_CORE_UPLIFT.md` | The locked implementation plan, with Dan's decisions (same text as the addon repo's `docs/pss/10_CORE_UPLIFT.md`) |
| `01_CORE_LIBRARIES.md` | Review of core, Libraries, Logging, Options: N1 to N48 |
| `02_GUI.md` | Review of the window: G1 to G30 |
| `03_SAVEDVARIABLES.md` | IDs vs sparse records, measured on the real saves |
| `04_UPGRADE_HELPER.md` | Questie's model and the PSS upgrade report |
| `05_NAME_BUGS.md` | Camelot / WoW Forever name bugs |

Working rule (baseline v9): one stage per session; every PR updates `00_CORE_UPLIFT.md`'s stage table here and in the addon repo.
