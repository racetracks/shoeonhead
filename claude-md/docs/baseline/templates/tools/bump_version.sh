#!/bin/sh
# Sets the next version in every TOC, records it in versions.json and adds
# its history.txt section on top (02 F). Every
# version is X.Y.Z.B and the build number B never resets: a release is a
# build too, and later lines count on from it (02 F).
#   sh tools/bump_version.sh build "Title"         the next build:    1.4.0.6 -> 1.4.0.7
#   sh tools/bump_version.sh release "Title"       a full release:    1.4.0.7 -> 1.4.0.8 (release)
#   sh tools/bump_version.sh line X.Y.Z "Title"    a new line:        -> 1.4.1.9
#   sh tools/bump_version.sh pr <number>           the PR that carries the new builds
#                                                  (once it is open; the rules check
#                                                  fails a pull request without it)
# Run from the repo root (needs python3), then fill in the history bullets.
# For a release, write them at release time: one summary, for players, of
# every change since the previous release, from the PRs that
# "python3 tools/versions.py prs" lists (02 F5).
mode=$1
case "$mode" in
	line) line=$2; title=$3 ;;
	build|release) title=$2 ;;
	pr) python3 tools/versions.py pr "$2" && echo "PR $2 recorded"; exit $? ;;
	*) echo "usage: sh tools/bump_version.sh build|release \"Title\"  or  line X.Y.Z \"Title\"  or  pr <number>"; exit 1 ;;
esac
if [ -z "$title" ]; then echo "a title is needed"; exit 1; fi

ver=$(sed -n 's/^## Version: *//p' MyAddon/MyAddon.toc | tr -d '\r')
case "$mode" in
	build) new=$(python3 tools/versions.py next build) || { echo "$new"; exit 1; } ;;
	release) new=$(python3 tools/versions.py next release) || { echo "$new"; exit 1; } ;;
	line) new=$(python3 tools/versions.py next line "$line") || { echo "$new"; exit 1; } ;;
esac
if [ "$mode" = release ]; then
	prev=$(python3 -c 'import json; print(json.load(open("versions.json"))["latestRelease"] or "the start")')
	python3 tools/versions.py release "$new" || exit 1
	bullet="- Summary of every change since $prev, written at release time from the PRs (python3 tools/versions.py prs $new)."
else
	python3 tools/versions.py add "$new" || exit 1
	bullet="- What changed, in plain words."
fi

for toc in MyAddon*/*.toc; do
	sed "s/^## Version: .*/## Version: $new/" "$toc" > "$toc.new" && mv "$toc.new" "$toc"
done
{
	sed -n '1,/^$/p' history.txt
	printf '=> %s - %s\n\n%s\n\n' "$new" "$title" "$bullet"
	sed '1,/^$/d' history.txt
} > history.txt.new && mv history.txt.new history.txt
echo "$ver -> $new$( [ "$mode" = release ] && echo ' (release)')"
