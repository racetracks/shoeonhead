# Why a scratch repo

- Claude project threads can attach only a few files, and attachment slots run out. Anything the author needs to download or read goes in scratch (`racetracks/Pour-Social-Score_Scratch`) and the reply carries a link.
- One private repo serves every addon project, so links look the same everywhere and nothing gets lost between threads.
- It keeps files that must never enter an addon repo: the author's real SavedVariables, test zips, handover packs.

## What goes in scratch
| Kind | Example |
| --- | --- |
| Test builds | An installable zip for every dev build and bugfix |
| Handover packs | The zips (and their markdown, readable in the browser) a fresh Claude project starts from |
| SavedVariables | The author's real WTF saves, filed by the addon version that wrote them |
| Project plans | Analysis, plan and decision documents for a piece of work |
| Issue notes | Longer write-ups linked from an addon repo issue |

## What never goes in scratch
- Secrets, tokens or anything credential-like.
- Code that belongs in an addon repo (scratch hosts builds of it, not its source of truth).
- Files over GitHub's 100 MB limit.
