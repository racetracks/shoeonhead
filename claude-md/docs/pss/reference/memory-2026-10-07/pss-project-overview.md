---
name: pss-project-overview
description: What PourSocialScore is, its repos, addon layout, and where the handover pack and baseline save live in this project
metadata:
  type: project
---
PourSocialScore (PSS): Dan's WoW chat moderation addon (GitHub racetracks, in-game Boaties). Lua 5.1, WoW API only, no libraries. Retail/Midnight 120007 + Camelot 16001; three TOCs per addon (base, _Mainline, _Camelot).

Repos (private, saved to this project 2026-10-05): racetracks/PourSocialScore (seven folders: core + _Options always loaded; _GUI, _Libraries, _Logging, _Communities, _EllesmereUI load on demand; tools/ harness; one version for all) and racetracks/scratch (test zips, handovers, saves). racetracks/PourSocialScore-EllesmereUI is RETIRED (merged into core at 3.2.0-dev008): never attach or write to it.

Handover pack v2 (binding rules): /mnt/project-files/handover/pss-handover-2026-10-05-v2/ (00_README, 00_PRIMARY_OBJECTIVE, 02_RULES binding). Baseline save: /mnt/project-files/baselines/2.0.44/ (never commit). lua5.1 installs with apt; check_rules, check_eui_all and validate_all all passed on main 0d47591 (3.2.0) on 2026-10-05.

Primary objective of this project: feature parity between native GUI (PourSocialScore_GUI) and the EllesmereUI front end (PourSocialScore_EllesmereUI), same features and same numbers, folders kept separate, no logic in UI folders (shared code in Libraries). Step 1 is a side-by-side audit confirmed with Dan before porting.

See [[pss-current-status]], [[pss-working-preferences]], [[pss-shared-query-placement]].
