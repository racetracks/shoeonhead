Copy into the new repo: .github/workflows/*, tools/*.sh, and the TOC set
into the main addon folder (MyAddon/). Rename MyAddon everywhere. Add
tools/check_style.lua and tools/check_layers.lua from ../examples (adapt names)
or drop their lines from check_rules.sh. history.txt and readme.txt sit at the
repo root; release.yml copies them into the main folder of the zip.
tools/bump_version.sh sets the next version (build, release or a new line) in
every TOC, records it in versions.json (tools/versions.py; python3) and adds
the history section; "bump_version.sh pr <number>" records the PR once it is
open. Start versions.json at the repo root (never in an addon folder) as
{ "latestRelease": null, "preReleases": [], "releases": [] }. tools/host_build.sh
builds the test zip from HEAD and hosts it (set SCRATCH_URL). A full
release's notes are its history section: Claude writes one summary of every
change since the last release from "python3 tools/versions.py prs <version>"
(02 F5). Set MIRROR_REPO in release.yml, or delete the mirror job.
