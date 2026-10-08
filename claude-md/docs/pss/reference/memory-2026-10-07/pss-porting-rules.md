---
name: pss-porting-rules
description: G7-G10 - features ported from the EllesmereUI front end to the native GUI use only our own or Blizzard resources and look as close as possible while staying Blizzard-styled
metadata:
  type: feedback
---
Dan, 2026-10-05 15:30Z (saved as G7 and G8 in the project instructions):
- G7: when porting a feature from the EllesmereUI integration to the native GUI, every resource must be our own or a native Blizzard resource. No external dependency (nothing from EllesmereUI or any other addon).
- G8: ported assets must look as close as graphically possible to the EUI version while still representing the Blizzard UI. No external dependency.
- G9 (15:33Z): if porting a UI component from our EllesmereUI integration would give a lower footprint without bloating the project, copy that code out as functions into PourSocialScore_GUI only (no other addon folder in the stack depends on it). This is a copy, not shared code, so G3 separation still holds. It applies to OUR PourSocialScore_EllesmereUI code only: EllesmereUI's own addon code is all rights reserved and is never copied.
- G10 (15:37Z): the port must preserve the EllesmereUI integration; treat PourSocialScore_EllesmereUI as READ ONLY during parity work. Shared functions serving calls from both UIs (Libraries/core) must be optimized for performance (measure).
- G10 EXCEPTION (Dan, issue #77, 16:09Z, option b): logic in the EUI folder MOVES to PourSocialScore_Libraries (new PSS_EventsQuery.lua) and the EUI file calls it. Only that edit is allowed: a function body swapped for a Libraries call, nothing visible changing, ui_compare.sh "UI identical" + check_eui_all.sh green before the PR. Plan step 3 (3.3.0-dev003).

**Why:** the native GUI must work for every user with no other addons installed. **How to apply:** for each port (pies, Events tab, type ticks, breadcrumbs), name the Blizzard template/texture or our own built asset that replaces the EUI one; never reference EllesmereUI fonts, media, skins or API from PourSocialScore_GUI. In the audit, note the native resource each port would use, and whether each port is a G9 copy (with measured footprint) or a rewrite. See [[pss-binding-rules]], [[pss-project-overview]].
