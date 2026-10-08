---
name: pss-baseline-saves
description: Where Dan's real SavedVariables live (2.0.44, 3.0.0, 3.2.0-dev011) and how the harness runs them
metadata:
  type: reference
---
- 2.0.44: /mnt/project-files/baselines/2.0.44/PourSocialScore.lua (one file).
- 3.2.0-dev011 (uploaded 2026-10-05; folders are named by the save's upgrade.version, Dan's rule "by version"): the four split files are in /mnt/project-files/savedvariables/3.2.0-dev011/. The harness reads one PourSocialScore.lua per folder, so /mnt/project-files/baselines/3.2.0-dev011/PourSocialScore.lua is the four concatenated (core, Options, Logging, EllesmereUI).
- 3.0.0 (uploaded 2026-10-05 16:23Z): three files in /mnt/project-files/savedvariables/3.0.0/ (no EllesmereUI file), concatenated at /mnt/project-files/baselines/3.0.0/PourSocialScore.lua.
- Central copy on scratch: pss-projects/savedvariables/<version>/ with a README (the PourSocialScore/savedvariables/<version>/ copies stay for old links). Add new versions to pss-projects. Never commit real saves to the code repo.
- Dan's scratch layout for this work: pss-projects/<project>/ for plans (pss-native-gui-port/), pss-issues/ for issue notes.
- Run all three: PSS_REAL_SAVES=/mnt/project-files/baselines sh tools/harness/validate_all.sh. From 3.3.0-dev001 (PR #79) the split check skips saves with PSS_OptionsDB (3.x layout), so all pass. Look checks per save: ui_compare.sh and eui_compare.sh <ref> <save>.

See [[pss-current-status]], [[pss-working-preferences]].
