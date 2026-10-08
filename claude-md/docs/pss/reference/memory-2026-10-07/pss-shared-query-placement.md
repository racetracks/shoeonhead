---
name: pss-shared-query-placement
description: Core holds only chat filtering + launchpad; anything not regularly active (incl. code shared by both UIs) goes in PourSocialScore_Libraries; measure resident cost
metadata:
  type: feedback
---
Dan, 2026-10-05 15:30Z: core is only "the core framework to handle the chat filtering and a launchpad for the addon". Functions that do not run in active memory or are not regularly active go in PourSocialScore_Libraries (LoD). Front-end query code shared by both windows goes there too. The older exception "unless core itself calls it" (e.g. PSS_PlayerQuery in core) now holds only if that call is on a regularly active path such as filtering; flag other core functions as move candidates.

**Why:** an estimated 6-8 KB move to core measured 22 KB resident; Dan wants measured numbers. Known garbage hot spots: PSS_GetGuildBlockCounts, shipped member walk, PSS_GetMemberBlockCounts (~200-350 KB per full pass on Dan's save).

**How to apply:** before proposing code moves, state where it lives now, whether it is regularly active, and the measured cost. See [[pss-binding-rules]], [[pss-working-preferences]].
