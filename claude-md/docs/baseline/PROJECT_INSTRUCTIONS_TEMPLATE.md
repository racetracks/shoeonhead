# <Addon> project instructions (fill in and paste)

You are working on <Addon>, <Author>'s World of Warcraft addon: <one-line purpose>. Lua 5.1, WoW API only, no libraries. Clients: <Retail interface>, <other clients>; three TOCs per addon folder.

Repos: <owner>/<addon repo> (the addon, private) and <hosting repo>. Read-only references: <suite repos, documented API only, copy nothing>; Gethe/wow-ui-source.

Read the WoW addon baseline pack (README, 02_RULES, 07_WORKING_WITH_THE_AUTHOR, 10_FEATURE_DESIGN_AND_DELIVERY) and the addon pack before the first step. The baseline's rules are mandatory; the addon pack overrides one only in its Overrides table. Key rules:
- Lua 5.1, ASCII only, tabs, match the surrounding code, one namespace table, no UI code in core logic.
- No application or service logic in any UI folder. Minimal functions in the always-loaded core (the always-on engine and the launchpad); anything not regularly active goes in the load-on-demand library folder, with a measured resident cost.
- Front ends are independent: a UI never reads another UI's folder; UI resources both need live in the library folder. One config table, assets in each UI's own folder.
- One step per PR, based on main. Every change bumps all TOCs, adds a history.txt section and ships a test zip.
- Every version is X.Y.Z.B and the build number B never resets (every test zip, stage, fix and release takes the next one, never reused). Every build publishes as a GitHub pre-release; the completed feature, when the author says so, is the next build recorded as the release in versions.json (never shipped), and its notes are one summary of every change since the previous release, written at release time from the PRs between them. `sh tools/bump_version.sh build|release "Title"` (or `line X.Y.Z`, `pr <number>`) sets it; `sh tools/host_build.sh <hosting checkout>` hosts the test zip; the rules check rejects any other shape.
- Host test zips, handovers and saves as the hosting pack describes; always reply with links.
- Before pushing: the rules check, the harness against the author's real saves, the look-compare for any window that changes.
- SavedVariables must not grow; layout changes need a validated migration and the author's OK first.
- Zero cost unless enabled; new settings default OFF; low cost when enabled (event-driven, no OnUpdate polling, no timers as logic gates); zero taint risk (02 J: never write or replace Blizzard state, post-hooks only, combat guards, secret values on Retail 12.x). Localize everything, one global root table, localized API shortcuts. Lazy UI and lazy indexes, reuse frames, unregister unneeded events, batch and cache. SavedVariables minimal; database separate from runtime cache.
- Performance first; measure, don't estimate. Ask numbered questions with a recommendation; lead with the answer. The author tests in game and merges.
