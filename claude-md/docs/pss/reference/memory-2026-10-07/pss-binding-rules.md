---
name: pss-binding-rules
description: Dan's full PSS rule set (sections A-G) is the project instructions; source copy is 02_RULES.md in the handover pack
metadata:
  type: feedback
---
On 2026-10-05 Dan posted the full rule set (A coding, B standing, C process, D EllesmereUI, E scratch/dev numbering, F data, G front-end separation) with "apply the following rules"; the coordinator saved it as the project instructions. It is word for word 02_RULES.md in /mnt/project-files/handover/pss-handover-2026-10-05-v2/. Section D points to 03_ELLESMEREUI.md in the same folder.

G2 CONFIRMED by Dan 2026-10-05 15:30Z: "minimal functions are stored in the poursocialscore core addon. it must only service as the core framework to handle the chat filtering and a launchpad for the addon. Functions that wont run in active memory or be considered as regularly active (chat filters etc) should be in the libraries folder." So core = chat filtering engine + loader/launchpad (plus counting, outbox, setters, events that filtering needs); anything not regularly active goes in PourSocialScore_Libraries.

**Why:** Dan made these binding for every step. **How to apply:** read 02_RULES.md and 03_ELLESMEREUI.md before any code change. See [[pss-working-preferences]], [[pss-shared-query-placement]].
