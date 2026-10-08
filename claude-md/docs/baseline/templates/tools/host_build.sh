#!/bin/sh
# Builds the test zip from the committed HEAD, as release.yml builds it
# (every MyAddon folder, readme.txt and history.txt in the core
# folder), and hosts it (the hosting pack):
# releases/MyAddon-<version>-<YYYY-MM-DD-hh-mm>.zip, the same zip in
# latest/ in place of the one there, and the releases/ and latest/ rows of
# the hosting repo's readme.md index. Prints the links. Run from the addon repo root.
#   sh tools/host_build.sh <hosting checkout> [--no-commit | --no-push]
# --no-commit stages the files only, so docs can join the same commit (one
# commit per delivery); --no-push commits without pushing.
ADDON=MyAddon
SCRATCH_URL=https://github.com/OWNER/HOSTING-REPO   # set to the hosting repo
scratch=$1
mode=$2
if [ -z "$scratch" ] || [ ! -d "$scratch/.git" ]; then
	echo "usage: sh tools/host_build.sh <hosting checkout> [--no-commit | --no-push]"
	exit 1
fi
if [ -n "$(git status --porcelain -- "$ADDON" "$ADDON"_* readme.txt history.txt)" ]; then
	echo "Commit the addon changes first: the zip is built from HEAD"
	exit 1
fi

ver=$(sed -n 's/^## Version: *//p' "$ADDON/$ADDON.toc" | tr -d '\r')
stamp=$(date -u +%Y-%m-%d-%H-%M)
name=$ADDON-$ver-$stamp.zip

work=$(mktemp -d)
git archive HEAD | tar -x -C "$work" || exit 1
mkdir "$work/zip"
for d in "$work/$ADDON" "$work/$ADDON"_*/; do
	if [ -d "$d" ]; then cp -r "${d%/}" "$work/zip/"; fi
done
cp "$work/readme.txt" "$work/history.txt" "$work/zip/$ADDON/"
(cd "$work/zip" && zip -qr "../$name" .) || exit 1

cd "$scratch" || exit 1
git pull -q origin main || exit 1
cp "$work/$name" "releases/$name"
for old in latest/$ADDON-*.zip; do
	if [ -f "$old" ]; then git rm -q "$old"; fi
done
cp "$work/$name" "latest/$name"
sed "s/$ADDON-[0-9][0-9.]*-[0-9-]*\.zip/$name/g" readme.md > readme.md.new && mv readme.md.new readme.md
rm -rf "$work"

git add "releases/$name" "latest/$name" readme.md
if [ "$mode" != "--no-commit" ]; then
	git commit -q -m "$ADDON $ver test zip ($stamp)" || exit 1
	if [ "$mode" != "--no-push" ]; then
		git push -q origin HEAD:main || exit 1
	fi
fi
echo "$SCRATCH_URL/raw/main/releases/$name"
echo "$SCRATCH_URL/raw/main/latest/$name"
