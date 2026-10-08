# Layout: easily human-readable folders

```
readme.md                               the index: one line per folder, newest file named
CLAUDE.md                               Claude's criteria for this repo
SavedVariables/<version>/               the author's WTF saves written by that version (*.lua)
releases/                               <Name>-<version>-<YYYY-MM-DD-hh-mm>.zip  every dev/test/bugfix build
latest/                                 the newest build zip only
docs/
  README.md                             handover packs, which to use and how to restart (read when confused)
  <name>-<date>-vN.zip                  every docs release / handover pack, zipped
  <project-or-feature>/                 history for a project or feature release
  latest/<project-or-feature>/          the newest markdown, unzipped, readable in the browser
summary/                                <project>-<YYYY-MM-DD-hh-mm>.md  status summaries
```

## Naming
- Folder names are plain words, not codes.
- Timestamps are `YYYY-MM-DD-hh-mm`; pack versions are `<date>-v1`, `-v2`, ...
- Zip names carry the version: `<Name>-1.4.0.4-2026-10-07-21-44.zip`, `<pack>-2026-10-07-v3.zip`.
- Saves are filed by the version the author names ("this is a 1.2.0 save"), not by the date.
