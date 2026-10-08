# Dan's preferences and approach (the one file)

Everything about how Dan works and what he wants from Claude lives here (Dan, 2026-10-08). `CLAUDE.md` loads it in every session. Other docs stay technical and close to the addon. Add new preferences here, dated, and never spread them across other files. Baseline 07 is the generic version; where they differ, this file wins.

## Sessions and context
- **One step per session (2026-10-08).** Dan resets the session after each step of every implementation plan. Build only the named step, then stop.
- **Context is updated in every PR (2026-10-08).** Before a step's PR is final, update everything a fresh session needs to carry on:
  - the current project's stage table (state, PR, next build);
  - `06_STATUS_AND_NEXT.md`;
  - `02_RULES.md` for a new rule;
  - this file for a new preference;
  - the scratch copies (`docs/latest/pss-docs/`, the project's `docs/latest/<project>/`).

  A fresh session must be able to start from `CLAUDE.md` alone.
- **Plans and designs are references (2026-10-08).** `CLAUDE.md` points to them and never copies them. At each full release, the done stages are re-summarized into `01_HANDOVER.md`, which describes how the addon works at that release, and leave the plan.
- **Keep the memory lean and technical (2026-10-08).** Load only what the step needs. Read an appendix or a reference only for the stage that uses it. Delegate wide reading to subagents, and keep only their conclusions.

## Communication
- Plain language, answer first, short; Dan may read on the go.
- Numbered questions, each with a recommendation; Dan answers by number ("1: yes 2: recommended"). Play the final decisions back before building.
- Always give links: scratch `raw` links for zips, `blob` links for docs, `tree` links for folders. Never only a path.
- Give exact numbered in-game checks for every build, naming each look (Modern, Classic, Dark) and each client (Retail, Camelot) where it matters.
- Use measured numbers, never estimates, for memory, CPU and save size.
- Short asks want the thing: "PR?" means open it and give the link; "where release" wants the link.
- Re-read the newest message before building; Dan may refine mid-flight ("wait hold").
- Study screenshots closely before guessing a fix, and ask which object a screenshot shows when `/fstack` cannot tell.
- When Dan doesn't answer a fork, build on the recommended option and say so.
- Expect a code review pass before merging.

## How Dan works
- Dan tests every build in game and merges himself. "Branch, PR and release" is approval to merge and verify the release.
- Production is explicit: a full release happens only when Dan says the feature is done. Before a full release goes live, he tests a very old save on the final pre-release.
- Dan uploads his WTF saves and names the version ("this is a 3.4.0.28 save"); file them on scratch under `SavedVariables/<version>/`.
- Build numbers stay consistent: every build, a release included, takes the next number, and later lines count on.
- Dan reads GitHub Releases himself. Release notes are one player-facing summary of every change since the previous release.
- Dan answers decision cards. An unanswered card means the recommended option, said so in the PR.

## Values
- **Performance and memory first:** zero cost until used, lazy UI, GC only at safe requested moments, nothing grows without a cap. Smaller saves and less resident memory are goals in themselves.
- **Upgrades are sacred.** Every save change gets Dan's OK first, a validated migration on all his real saves, and identical counters. **Saves should never need readdressing again** (core uplift 2.3): forward compatible, unknown data kept, incompatible rules reported and exportable.
- **Lean on native tools, and build only what the stated goal needs:** Blizzard's APIs and the existing keys first, and a new mechanism (an ID generator, a library) only where it is measured to pay.
- **Human-readable output:** upgrade lines name features ("Chat Filtering", "SavedVariables performance cleanup"), not internals.
- **Native Blizzard look in Modern and Classic, and every element works in all three looks.** The EllesmereUI port is the reference for layout and feel; EllesmereUI is the reference framework for UI elements, read only.
- **Copy logic, never code or media,** from other addons, and respect licences.
- **TOC Title and Notes are Dan's;** never change them unless asked.
- **Hover never opens a window.**
- **One plain merge flow:** one PR per step, based on main, never stacked.
- **Ask before anything hard to undo:** save layout, deleting data, production releases.
