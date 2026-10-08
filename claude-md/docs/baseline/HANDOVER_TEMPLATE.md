# Addon-specific handover pack layout

This baseline stays general. When a thread gets long, write an addon pack next to it and host it as the hosting pack describes (versioned, with the markdown readable unzipped).

```
00_README.md            how to restart; file index
01_HANDOVER.md          the addon's purpose, repos written and reviewed, crucial context,
                        plans with status, observations specific to this addon
02_RULES.md             only the rules this addon adds to the baseline, dated
03_<INTEGRATION>.md     the addon's suite integration: its files, APIs used, lessons
04_DATA.md              SavedVariables layout, caps, upgrade steps
05_RELEASE.md           anything the addon does differently from the baseline pipeline
06_STATUS_AND_NEXT.md   merged and open PRs, the current project, the next step, items waiting on the author
PROJECT_INSTRUCTIONS.md paste-ready, filled in from the baseline template
savedvariables/<version>/  the author's real saves
ci/                     copies of the live workflows and check scripts
reference/              plans, older handovers, memory snapshots
```
Write it so a fresh Claude never has to ask the author something already decided.
