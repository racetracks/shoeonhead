#!/bin/sh
# Checks that the UI looks the same as another version: builds every window
# and tab of both with the WoW stub (ui_tour.lua) and compares the frames,
# anchors, sizes, texts, dialogs and slash command output.
#   sh tools/harness/ui_compare.sh [git ref, default origin/main] [save.lua]
# Exit 0 when identical; the differences are printed otherwise.
here=$(dirname "$0")
ref=${1:-origin/main}
sv=${2:--}
work=${TMPDIR:-/tmp}/myaddon-ui-compare
rm -rf "$work"; mkdir -p "$work/base"
git archive "$ref" | tar -x -C "$work/base"
cp "$here/ui_tour.lua" "$work/ui_tour.lua"
MYADDON_UI_DUMP="$work/base.txt" lua5.1 "$here/run.lua" "$work/base" "$sv" - "$work/ui_tour.lua" | grep '^ui tour\|^ERROR'
MYADDON_UI_DUMP="$work/head.txt" lua5.1 "$here/run.lua" . "$sv" - "$work/ui_tour.lua" | grep '^ui tour\|^ERROR'
if diff "$work/base.txt" "$work/head.txt"; then
	echo "UI identical to $ref"
else
	echo "UI DIFFERS from $ref"
	exit 1
fi
