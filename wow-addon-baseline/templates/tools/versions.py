#!/usr/bin/env python3
# The versions file, versions.json at the repo root (the author's rule, baseline 02 F):
# which build is the latest release, every pre-release since it in order,
# and every past release with the pre-releases that led to it. Each entry is
# a version and the PR that carried it: references only, never text. It is
# not in any addon folder, so it is never in a release zip, a test zip or the
# mirror (check fails if one turns up there).
#
# Build numbers never reset: every version is X.Y.Z.B, a release too, and B
# counts on across lines (1.4.0.7, release 1.4.0.8, then 1.4.1.9).
#
#   python3 tools/versions.py next build|release      the next version
#   python3 tools/versions.py next line X.Y.Z         the next version on a new line
#   python3 tools/versions.py add <version>           record a pre-release
#   python3 tools/versions.py release <version>       record a release: the
#                                                     pre-releases move under it
#   python3 tools/versions.py pr <number>             set the PR of entries without one
#   python3 tools/versions.py kind <version>          release | pre-release | unknown
#   python3 tools/versions.py latest                  the latest release (empty if none)
#   python3 tools/versions.py prs [<version>]         the versions and PRs between the
#                                                     release before <version> and
#                                                     <version> (default: the pending
#                                                     pre-releases), one "version pr" a line
#   python3 tools/versions.py check [--pr N] [--strict] [--toc VERSION]
#       the file is well formed, B never goes back, the TOC version is the
#       newest entry, nothing is in an addon folder; --strict (CI) or --pr
#       (a pull request) also fail an entry without its PR
import json
import os
import re
import sys

FILE = "versions.json"
ADDON = "MyAddon"	# the addon folders: ADDON and ADDON_*
FOUR = re.compile(r"^(\d+)\.(\d+)\.(\d+)\.(\d+)$")
LINE = re.compile(r"^\d+\.\d+\.\d+$")


def load():
	with open(FILE) as fh:
		return json.load(fh)


def save(data):
	# tabs, one entry a line, so a diff shows one line per build
	def entries(items, ind):
		rows = []
		for e in items:
			rows.append(ind + '{ "version": %s, "pr": %s }' % (json.dumps(e["version"]), json.dumps(e.get("pr"))))
		return ",\n".join(rows)
	out = ["{"]
	out.append('\t"latestRelease": %s,' % json.dumps(data["latestRelease"]))
	out.append('\t"preReleases": [')
	if data["preReleases"]:
		out.append(entries(data["preReleases"], "\t\t"))
	out.append("\t],")
	out.append('\t"releases": [')
	rel = []
	for r in data["releases"]:
		s = "\t\t{\n"
		s += '\t\t\t"version": %s,\n' % json.dumps(r["version"])
		s += '\t\t\t"pr": %s,\n' % json.dumps(r.get("pr"))
		s += '\t\t\t"previous": %s,\n' % json.dumps(r.get("previous"))
		s += '\t\t\t"preReleases": [\n'
		if r["preReleases"]:
			s += entries(r["preReleases"], "\t\t\t\t") + "\n"
		s += "\t\t\t]\n\t\t}"
		rel.append(s)
	if rel:
		out.append(",\n".join(rel))
	out.append("\t]")
	out.append("}")
	with open(FILE, "w") as fh:
		fh.write("\n".join(out) + "\n")


def build_of(v):
	m = FOUR.match(v)
	return int(m.group(4)) if m else None


def all_entries(data):
	# oldest first
	out = []
	for r in reversed(data["releases"]):
		out.extend(r["preReleases"])
		out.append({"version": r["version"], "pr": r.get("pr")})
	out.extend(data["preReleases"])
	return out


def last_build(data):
	b = [build_of(e["version"]) for e in all_entries(data)]
	b = [x for x in b if x is not None]
	return max(b) if b else 0


def newest(data):
	e = all_entries(data)
	return e[-1]["version"] if e else None


def fail(msg):
	print("versions.json: " + msg)
	sys.exit(1)


def cmd_next(args):
	data = load()
	b = last_build(data) + 1
	if args[0] == "line":
		if len(args) < 2 or not LINE.match(args[1]):
			fail("a line is X.Y.Z")
		print("%s.%d" % (args[1], b))
		return
	cur = newest(data)
	if cur is None:
		fail("nothing recorded yet: start with 'line X.Y.Z'")
	m = FOUR.match(cur or "")
	if m:
		base = "%s.%s.%s" % m.group(1, 2, 3)
	else:
		base = re.match(r"^(\d+\.\d+\.\d+)", cur).group(1)
	if args[0] == "build" and cur == data["latestRelease"]:
		fail(cur + " is a release: start a new line with 'line X.Y.Z'")
	print("%s.%d" % (base, b))


def cmd_add(args):
	data = load()
	v = args[0]
	if not FOUR.match(v) or build_of(v) <= last_build(data):
		fail("%s is not the next build (last build %d)" % (v, last_build(data)))
	data["preReleases"].append({"version": v, "pr": None})
	save(data)


def cmd_release(args):
	data = load()
	v = args[0]
	if not FOUR.match(v) or build_of(v) <= last_build(data):
		fail("%s is not the next build (last build %d)" % (v, last_build(data)))
	data["releases"].insert(0, {"version": v, "pr": None, "previous": data["latestRelease"],
		"preReleases": data["preReleases"]})
	data["latestRelease"] = v
	data["preReleases"] = []
	save(data)


def cmd_pr(args):
	data = load()
	n = int(args[0])
	for e in data["preReleases"]:
		if e.get("pr") is None:
			e["pr"] = n
	for r in data["releases"]:
		if r.get("pr") is None:
			r["pr"] = n
	save(data)


def cmd_kind(args):
	data = load()
	v = args[0]
	if v == data["latestRelease"] or any(r["version"] == v for r in data["releases"]):
		print("release")
	elif any(e["version"] == v for e in all_entries(data)):
		print("pre-release")
	else:
		print("unknown")


def cmd_latest(args):
	print(load()["latestRelease"] or "")


def cmd_prs(args):
	data = load()
	if not args:
		items = data["preReleases"]
	else:
		v = args[0]
		rel = [r for r in data["releases"] if r["version"] == v]
		if rel:
			items = rel[0]["preReleases"] + [{"version": v, "pr": rel[0].get("pr")}]
		else:
			items = [e for e in data["preReleases"]]
			names = [e["version"] for e in items]
			if v not in names:
				fail(v + " is not a recorded version")
			items = items[:names.index(v) + 1]
	for e in items:
		print("%s %s" % (e["version"], e.get("pr") if e.get("pr") is not None else "-"))


def cmd_check(args):
	strict = "--strict" in args
	pr = None
	toc = None
	if "--pr" in args:
		pr = args[args.index("--pr") + 1]
		strict = strict or bool(pr)
	if "--toc" in args:
		toc = args[args.index("--toc") + 1]
	try:
		data = load()
	except (OSError, ValueError) as e:
		fail("cannot read: %s" % e)
	for k in ("latestRelease", "preReleases", "releases"):
		if k not in data:
			fail("no " + k)
	if data["releases"] and data["releases"][0]["version"] != data["latestRelease"]:
		fail("latestRelease is not the newest release")
	prev = 0
	seen = set()
	bad = 0
	for e in all_entries(data):
		v = e["version"]
		if v in seen:
			fail(v + " is recorded twice")
		seen.add(v)
		b = build_of(v)
		if b is not None:
			if b <= prev:
				fail("%s: build %d does not follow build %d" % (v, b, prev))
			prev = b
		if e.get("pr") is None:
			if strict:
				print("versions.json: %s has no PR (sh tools/bump_version.sh pr <number>)" % v)
				bad += 1
		elif pr and v == newest(data) and str(e["pr"]) != str(pr):
			print("versions.json: %s is PR %s, this is PR %s" % (v, e["pr"], pr))
			bad += 1
	if toc and newest(data) != toc:
		fail("the TOCs say %s, the newest recorded version is %s" % (toc, newest(data)))
	for d in os.listdir("."):
		if os.path.isdir(d) and d.startswith(ADDON) and os.path.exists(os.path.join(d, FILE)):
			fail("%s/%s: the versions file must never ship" % (d, FILE))
	if bad:
		sys.exit(1)


CMDS = {"next": cmd_next, "add": cmd_add, "release": cmd_release, "pr": cmd_pr, "kind": cmd_kind, "latest": cmd_latest,
	"prs": cmd_prs, "check": cmd_check}

if __name__ == "__main__":
	if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
		print(open(__file__).read().split("import json")[0])
		sys.exit(1)
	CMDS[sys.argv[1]](sys.argv[2:])
