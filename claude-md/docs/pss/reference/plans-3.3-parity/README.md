# pss-native-gui-port

Porting the EllesmereUI front end's features into the native PourSocialScore
GUI, so both windows have the same features and the same numbers while
staying in separate folders.

| File | What it holds |
| --- | --- |
| 01_ANALYSIS.md | Both windows feature by feature, the gaps each way, four issues, where shared code belongs, and six decisions for Dan |
| 02_PLAN.md | Ten steps and twelve PRs from 3.3.0-dev001 to the 3.3.0 release, with what to validate at each step |

Status at 2026-10-05: analysis written, nothing built. Decision 6 (issue
#77) settled as option b; decisions 1 to 5 still open. Related: issue
[#77](https://github.com/racetracks/PourSocialScore/issues/77) and
`pss-issues/eui-read-only-vs-logic-move.md`.
