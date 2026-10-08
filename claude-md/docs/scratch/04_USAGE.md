# Using scratch from a Claude session

## Links
| Purpose | Form |
| --- | --- |
| Download a file | `https://github.com/racetracks/Pour-Social-Score_Scratch/raw/main/<path>` |
| Read a file in the browser | `https://github.com/racetracks/Pour-Social-Score_Scratch/blob/main/<path>` |
| Browse a folder | `https://github.com/racetracks/Pour-Social-Score_Scratch/tree/main/<path>` |

Every reply that delivers a file gives the link in the text.

## Pushing
```sh
cd <scratch checkout>                 # the attached checkout, or a fresh clone of racetracks/Pour-Social-Score_Scratch in a unique directory
git pull -q origin main               # always start from the latest
mkdir -p <folder> && cp <file> <folder>/
git add <folder> && git commit -m "<what, with version>" && git push origin HEAD:main
```
- Pull first; other threads push to scratch too.
- One commit per delivery, with a message that names the thing and its version.
- Build zips in a fresh, uniquely named directory; don't `rm -rf` globs (sandboxes block it).
- Scratch is the project files (Dan, 2026-10-08): nothing is copied anywhere else; other threads read it from here.

## Test builds (rules 9, 12)
1. Build the zip from the committed branch (`git archive HEAD`), with every addon folder at the zip root.
2. Store it as `releases/<Name>-<version>-<YYYY-MM-DD-hh-mm>.zip` and, in the same commit, replace the zip in `latest/` with it.
3. Commit, push, reply with the link and the in-game checks.
A bugfix is the next build number (`X.Y.Z.B`) and is hosted exactly the same way.

## SavedVariables (rules 4, 13)
The only location is `SavedVariables/<version>/` in `racetracks/Pour-Social-Score_Scratch`. The old `racetracks/scratch` `PourSocialScore/savedvariables/` was ported here on 2026-10-07; don't read from or add to it.

1. The author uploads the files from `WTF/Account/<account>/SavedVariables/` and names the version.
2. Commit them to `SavedVariables/<version>/` with a line in `SavedVariables/README.md` (what is in it, the size).
3. Scratch is the project files: there is no other copy. The harness builds its input from here (`sh tools/harness/build_saves.sh <scratch checkout> <out dir>` in the addon repo).
4. Never commit real saves to an addon repo.

## Docs and handover packs (rule 10)
1. Put the newest markdown in `docs/latest/<project-or-feature>/`, organised into folders.
2. Zip each docs release / handover pack as `<name>-<date>-vN.zip` in the root of `docs/`.
3. When it is a project or feature release, also keep its files in `docs/<project-or-feature>/` for history.
4. Update `docs/README.md`: what each pack is for, when to use it, the restart steps, a version line.
5. Reply with the zip link and a link to the folder of unzipped files.
- Plans/analysis for a piece of work and long issue write-ups are docs too: `docs/latest/<project>/`, linked from the issue.

## Summaries
- Status summaries go in `summary/<project>-<YYYY-MM-DD-hh-mm>.md`.

## Keeping it readable
- Update `readme.md` whenever a folder is added or the newest file in it changes.
- Never delete or rename a file someone was given a link to. Add the new one beside it; if something moved, leave the old path in place.
