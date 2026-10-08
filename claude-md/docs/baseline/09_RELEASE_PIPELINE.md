# Tag and release pipeline: full setup

Every new project struggles with this. The whole pipeline is **two workflow files, one rules script and one rule: the version in the main TOC is the release.** Nobody tags by hand; merging a version bump to main publishes the release: a pre-release for every build, a full release for the build `versions.json` names the latest release. Every version is `X.Y.Z.B` and the build number `B` never resets (v7).

## 1. What you end up with
- Every PR runs the **Rules** check (`.github/workflows/rules.yml` running `tools/check_rules.sh`).
- Every push to main runs **Release** (`.github/workflows/release.yml`). If the main TOC's version has no release yet, it builds `<Addon>-<version>.zip`, creates the tag `v<version>` and the GitHub release with that version's history section as notes, and marks it a pre-release unless `versions.json` names that version the latest release. A full release's notes are one summary of every change since the previous release, written by Claude at release time from the PRs `versions.json` lists (section 6), and a `mirror` job can publish it on a second repo.
- Merges that don't change the version publish nothing.

## 2. Repo layout the workflows expect
```
<Addon>/                    main addon folder (its name = the TOC name = ADDON in release.yml)
  <Addon>.toc               base TOC: "## Version: X.Y.Z.B" (the version is read from here)
  <Addon>_Mainline.toc      flavour TOCs, same version
  <Addon>_Camelot.toc
  *.lua
<Addon>_<Part>/             any other addon folders (all zipped; each with its own three TOCs)
tools/check_rules.sh        the rules check (plus check_style.lua, check_layers.lua if used)
tools/bump_version.sh       sets the next version in every TOC, records it and adds the history section
tools/versions.py           the versions file's tool: next version, record, PRs between releases, check
tools/host_build.sh         builds the test zip from HEAD and hosts it (hosting pack)
versions.json               latest release, pre-releases in order with their PRs, past releases (never shipped)
.github/workflows/rules.yml
.github/workflows/release.yml
readme.txt                  copied into <Addon>/ inside the zip
history.txt                 copied into <Addon>/ inside the zip; release notes come from it
```
Every folder named `<Addon>` or `<Addon>_*` at the repo root goes into the zip, at the zip's root, so it extracts straight into `Interface/AddOns`. `.github`, `tools`, `versions.json` and anything else stay out (never put `versions.json` in an addon folder; the check fails if one does).

## 3. Step by step, from an empty repo
1. **Create the repo** (private is fine) with a default branch named `main`.
2. **Workflow permissions.** The release job writes tags and releases with the built-in `GITHUB_TOKEN`. `release.yml` asks for `permissions: contents: write`, which is enough on a personal repo. In an organisation, or if the run fails with "Resource not accessible by integration", open **Settings > Actions > General > Workflow permissions** and choose **Read and write permissions**. No personal token or secret is needed.
3. **Actions enabled.** Settings > Actions > General > "Allow all actions" (or at least GitHub-authored ones: the workflows use `actions/checkout@v4`, `gh` and apt).
4. **Copy the templates** from `templates/`: `.github/workflows/release.yml`, `.github/workflows/rules.yml`, `tools/check_rules.sh`, `tools/bump_version.sh`, `tools/versions.py`, `tools/host_build.sh`, the TOC set, history.txt. Start `versions.json` at the repo root as `{ "latestRelease": null, "preReleases": [], "releases": [] }`, then `sh tools/bump_version.sh line 1.0.0 "First build"`. Copy `examples/check_style.lua`, `examples/check_layers.lua` and `examples/lua_segments.lua` into `tools/`, or delete their lines from `check_rules.sh`.
5. **Rename.** Set `ADDON:` in release.yml to the main folder name. Replace `MyAddon` in `check_rules.sh` (the file globs), in the TOCs and in check_layers' file list.
6. **Make check_rules.sh pass locally:** `sudo apt-get install -y lua5.1` then `sh tools/check_rules.sh` from the repo root.
7. **First version:** set `## Version: 0.1.0.1` in every TOC and write the first history section (or run `sh tools/bump_version.sh line 0.1.0 "First build"` once the TOCs exist):
   ```
   => 0.1.0.1 - First build

   - What changed, in plain words.
   ```
   The heading must start exactly with `=> <version> ` (arrow, space, version, space): the notes step finds the section by that prefix and stops at the next line starting with `=> `.
8. **Open the first PR.** Confirm the **Rules** check appears and passes.
9. **Branch protection (recommended).** Settings > Branches > add a rule (or ruleset) for `main`: require a pull request and require the status check `check` (the Rules job name). The check appears in the list only after it has run once, so do this after step 8.
10. **Merge.** Watch Actions > Release. When it finishes, Releases shows `v0.1.0.1` marked **Pre-release** with the zip attached, and Tags shows `v0.1.0.1`.
11. **Every later step:** `sh tools/bump_version.sh build "Title"` (every TOC to the next build, a history section on top), fill in the bullets, merge. That's the whole release process.

## 4. release.yml, explained
```yaml
# Publishes a GitHub release whenever the version in $ADDON/$ADDON.toc changes
# on main: tags v<version> and attaches $ADDON-<version>.zip (every addon folder
# $ADDON and $ADDON_*, readme.txt and history.txt inside $ADDON; no .github or
# tools). Does nothing if the release exists.
# Every version is X.Y.Z.B (B = the build number, which never resets; a
# release is a build too, 02 F). versions.json (tools/versions.py, never
# shipped) says what each one is: the latest release, or a pre-release
# recorded with its PR; a version it does not record is not published.
# A pre-release's notes are its history section. A full release's notes are
# its history section only: one summary of every change since the previous
# release, written at release time from the PRs versions.json lists between
# the two (02 F5). Job "mirror" keeps $MIRROR_REPO on the latest full
# release: the zip's contents committed as its files, and the release with the
# same zip and notes on that commit (secret MIRROR_TOKEN: contents read and
# write on that repo); delete the job if there is no mirror. Pre-releases
# are not mirrored.
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

env:
  ADDON: MyAddon                     # main folder / TOC name
  MIRROR_REPO: <owner>/<mirror repo>  # where full releases are mirrored

jobs:
  release:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.v.outputs.version }}
      kind: ${{ steps.v.outputs.kind }}
    steps:
      - uses: actions/checkout@v4

      - name: Read version
        id: v
        run: |
          ver=$(sed -n 's/^## Version: *//p' "$ADDON/$ADDON.toc" | tr -d '\r')
          kind=$(python3 tools/versions.py kind "$ver")
          if [ "$kind" = unknown ]; then
            echo "::error::$ver is not in versions.json (sh tools/bump_version.sh records it)"
            exit 1
          fi
          echo "version=$ver" >> "$GITHUB_OUTPUT"
          echo "kind=$kind" >> "$GITHUB_OUTPUT"
          if gh release view "v$ver" >/dev/null 2>&1; then
            echo "exists=true" >> "$GITHUB_OUTPUT"
          else
            echo "exists=false" >> "$GITHUB_OUTPUT"
          fi
        env:
          GH_TOKEN: ${{ github.token }}

      - name: Build zip and notes
        if: steps.v.outputs.exists == 'false'
        run: |
          ver=${{ steps.v.outputs.version }}
          mkdir -p build
          for d in "$ADDON" "$ADDON"_*/; do
            if [ -d "$d" ]; then cp -r "${d%/}" build/; fi
          done
          cp readme.txt history.txt "build/$ADDON/"
          (cd build && zip -qr "../$ADDON-$ver.zip" .)
          {
            echo "**Install:** extract the zip into \`World of Warcraft/_retail_/Interface/AddOns/\`."
            echo
            if [ "${{ steps.v.outputs.kind }}" = release ]; then
              prev=$(python3 -c 'import json; print(json.load(open("versions.json"))["releases"][0]["previous"])')
              echo "### Changes since $prev"
            else
              echo "### Changes"
            fi
            awk -v v="$ver" '
              index($0, "=> " v " ") == 1 { on = 1; next }
              on && /^=> / { exit }
              on { print }
            ' history.txt
            echo
            echo "Full changelog: history.txt"
          } > notes.md
          cat notes.md

      - name: Publish release
        if: steps.v.outputs.exists == 'false'
        run: |
          ver=${{ steps.v.outputs.version }}
          pre="--latest"
          [ "${{ steps.v.outputs.kind }}" = release ] || pre="--prerelease"
          gh release create "v$ver" "$ADDON-$ver.zip" $pre \
            --target "$GITHUB_SHA" --title "$ADDON $ver" --notes-file notes.md
        env:
          GH_TOKEN: ${{ github.token }}

      - name: Keep pre-releases marked as pre-releases
        run: |
          gh release list --limit 100 --json tagName,isPrerelease \
            --jq '.[] | select(.isPrerelease | not) | .tagName' |
          while read -r tag; do
            v=${tag#v}
            case "$v" in *-*) gh release edit "$tag" --prerelease; continue ;; esac
            if [ "$(python3 tools/versions.py kind "$v")" = pre-release ]; then gh release edit "$tag" --prerelease; fi
          done
        env:
          GH_TOKEN: ${{ github.token }}

  mirror:
    # Keeps $MIRROR_REPO on the latest full release (versions.json
    # latestRelease): the release zip's contents committed as the repo's files
    # (every addon folder at the root; files of the mirror's own, such as its
    # readme.md, are kept), and the release, with the same zip and notes, on
    # that commit. Runs after every push and does nothing when the mirror is
    # already there, so a release that went across without its files is
    # repaired by the next push (or Actions > Release > Run workflow).
    needs: release
    if: ${{ always() && needs.release.result == 'success' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check the latest release and the mirror
        id: m
        run: |
          VER=$(python3 tools/versions.py latest)
          echo "version=$VER" >> "$GITHUB_OUTPUT"
          if [ -z "$VER" ]; then echo "skip=true" >> "$GITHUB_OUTPUT"; echo "No release yet: nothing to mirror"; exit 0; fi
          if [ -z "$GH_TOKEN" ]; then
            echo "::error::Add a MIRROR_TOKEN secret with contents read and write on $MIRROR_REPO"
            exit 1
          fi
          git clone -q "https://x-access-token:${GH_TOKEN}@github.com/${MIRROR_REPO}.git" mirror
          toc() { sed -n 's/^## Version: *//p' | tr -d '\r'; }
          files=$( { toc < "mirror/$ADDON/$ADDON.toc"; } 2>/dev/null || true)
          tagged=$(git -C mirror show "v$VER:$ADDON/$ADDON.toc" 2>/dev/null | toc || true)
          if [ "$files" = "$VER" ] && [ "$tagged" = "$VER" ] && gh release view "v$VER" --repo "$MIRROR_REPO" >/dev/null 2>&1; then
            echo "skip=true" >> "$GITHUB_OUTPUT"
            echo "The mirror is on $VER"
          else
            echo "skip=false" >> "$GITHUB_OUTPUT"
            echo "The mirror needs $VER (files: ${files:-none}, tagged: ${tagged:-none})"
          fi
        env:
          GH_TOKEN: ${{ secrets.MIRROR_TOKEN }}

      - name: Fetch the zip and notes
        if: steps.m.outputs.skip == 'false'
        run: |
          gh release download "v$VER" --repo "$GITHUB_REPOSITORY" --pattern "$ADDON-$VER.zip"
          gh release view "v$VER" --repo "$GITHUB_REPOSITORY" --json body --jq .body > notes.md
        env:
          VER: ${{ steps.m.outputs.version }}
          GH_TOKEN: ${{ github.token }}

      - name: Commit the release's files to the mirror
        id: c
        if: steps.m.outputs.skip == 'false'
        run: |
          cd mirror
          for d in "$ADDON" "$ADDON"_*/; do
            if [ -d "$d" ]; then git rm -rq "${d%/}"; fi
          done
          unzip -q "../$ADDON-$VER.zip" -d .
          git add -A
          if ! git diff --cached --quiet; then
            git -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
              commit -q -m "$ADDON $VER"
            git push -q origin HEAD
          fi
          echo "sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
        env:
          VER: ${{ steps.m.outputs.version }}

      - name: Publish the release on the mirror
        if: steps.m.outputs.skip == 'false'
        run: |
          # a release whose tag is not on the release's files (made before the
          # files were copied) is made again on them
          tagged=$(git -C mirror show "v$VER:$ADDON/$ADDON.toc" 2>/dev/null | sed -n 's/^## Version: *//p' | tr -d '\r' || true)
          if [ "$tagged" != "$VER" ] && gh release view "v$VER" --repo "$MIRROR_REPO" >/dev/null 2>&1; then
            gh release delete "v$VER" --repo "$MIRROR_REPO" --cleanup-tag --yes
          fi
          if ! gh release view "v$VER" --repo "$MIRROR_REPO" >/dev/null 2>&1; then
            gh release create "v$VER" "$ADDON-$VER.zip" --repo "$MIRROR_REPO" --target "$SHA" \
              --title "$ADDON $VER" --notes-file notes.md --latest
          fi
        env:
          VER: ${{ steps.m.outputs.version }}
          SHA: ${{ steps.c.outputs.sha }}
          GH_TOKEN: ${{ secrets.MIRROR_TOKEN }}
```

| Part | Why |
| --- | --- |
| `on: push: branches: [main]` | Runs after every merge; the version check makes non-bump merges a no-op |
| `workflow_dispatch` | A "Run workflow" button under Actions, to retry after fixing a failed run |
| `permissions: contents: write` | Lets `github.token` create tags and releases |
| `sed -n 's/^## Version: *//p' ... \| tr -d '\r'` | Reads the version; strips Windows line endings, which otherwise end up in the tag name |
| `gh release view "v$ver"` | Skips everything if that release already exists |
| The copy loop over `"$ADDON" "$ADDON"_*/` | Puts every addon folder at the zip root; nothing else |
| The awk block | Copies that version's history section into the release notes |
| `python3 tools/versions.py kind "$ver"` | `release` (the latest release in `versions.json`: published `--latest` and mirrored), `pre-release` (`--prerelease`), or `unknown`: the run fails and nothing is published |
| The notes block | A pre-release's notes are its history section; a release's are its history section under "Changes since <previous release>": the summary written at release time |
| `gh release create "v$ver" ... --target "$GITHUB_SHA"` | **Creates the tag and the release together** at the merged commit. Never push tags by hand |
| The last step | Turns any recorded pre-release (or an older `-` suffixed one) that someone marked as full back into a pre-release |

## 5. rules.yml and check_rules.sh
```yaml
# Rules check on every pull request and push to main: tools/check_rules.sh
name: Rules

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Lua 5.1
        run: sudo apt-get update -q && sudo apt-get install -y -q lua5.1
      - name: Check rules
        run: sh tools/check_rules.sh
```

`tools/check_rules.sh` compiles every `.lua` with `luac5.1 -p` (Lua 5.1 syntax), runs `check_style.lua` (no Lua 5.2+ features, tabs, no trailing whitespace; `--fix` repairs), checks that TOCs, XML, readme.txt and history.txt are ASCII, that every TOC carries one version shaped `X.Y.Z` or `X.Y.Z.B` and that history.txt starts with that version's section, and runs `check_layers.lua` (no UI calls in core logic files). It exits non-zero on any failure, which fails the PR check. Add more jobs to rules.yml (for example a harness job) as the project grows.

## 6. Versions: releases are defined by feature
A version line belongs to a feature (or an agreed set of features), not to a date or a pile of changes. Every version is `X.Y.Z.B`, and the build number `B` never resets (v7).

| Kind | Example | Published as |
| --- | --- | --- |
| A stage of the feature | `1.4.0.1`, `1.4.0.2`, ... | **Pre-release** (a build); the same zip is the stage's hosted test build |
| A fix while the feature is in progress | the next build (`1.4.0.5` after `1.4.0.4`) | **Pre-release**, like any build |
| The feature complete | the next build, `1.4.0.8`, recorded as the release | **Full release**, only when the author confirms the feature is done |
| A fix after the release | `1.4.1.9`, ... then its release `1.4.1.11` | Pre-releases, then a full release |
| The next feature | `1.5.0.12` | Pre-release |

- **Versions are `X.Y.Z.B` and `B` never resets:** every build that gets a test zip, a stage or a fix, merged or not, takes the next build number and none is reused; so does the full release, and a new line counts on from there. Every TOC, the history section, the tag, the release and the zip name carry it. `sh tools/bump_version.sh build "Title"` works out the next number; the rules check fails any other shape.
- **`versions.json`** (repo root, `tools/versions.py`) is the record the pipeline trusts: `latestRelease`, `preReleases` (every build since it, in order, each `{ "version", "pr" }`) and `releases` (each past release with its `previous` release and its own `preReleases`). References only: no text. It is never in an addon folder, so never in a release zip, a test zip or the mirror. `bump_version.sh` writes it; `sh tools/bump_version.sh pr <number>` records the PR once it is open; `check_rules.sh` runs `versions.py check` (in CI every entry needs its PR and a pull request's newest entry its own number, `PR_NUMBER` in rules.yml).
- **Every build is a pre-release.** `release.yml` asks `versions.py kind`: the latest release is published as a full release (`--latest`), a recorded pre-release as a pre-release, an unrecorded version not at all; the "keep" step re-flags any recorded pre-release marked full by hand (so "Latest" always points at a real full release).
- The feature design (10_FEATURE_DESIGN_AND_DELIVERY.md) names the line before work starts.
- **Going to production:** `sh tools/bump_version.sh release "Title"` makes the next build the release: `versions.json` moves the pending pre-releases under it and names it `latestRelease`. Then Claude writes the release's history section (below); merging the PR publishes the full release and the pre-releases stay as history.
- Ask the author which line the next piece of work belongs to when it is not obvious (a new feature line or a fix line).
- One repo, one version for every folder. A second repo means a second version line and a cross-repo token.

### Full release notes and the mirror
- **Notes: one summary of every change between releases, decided at release time.** After `bump_version.sh release`, `python3 tools/versions.py prs <version>` lists every pre-release since the previous release with its PR. Claude reads each PR (title, description, diff as needed) and writes **one player-facing summary of all the changes** as the release's history section, in place of the placeholder bullet (the rules check fails while the placeholder is there). The release notes are that summary only, under "Changes since <previous release>": no per-build lists, no PR text. No API key in the pipeline. Pre-releases keep their own history section as notes.
- **Mirror (optional):** the `mirror` job keeps `MIRROR_REPO` (set at the top of release.yml) on the latest full release in `versions.json`: it commits the release zip's contents as the repo's files (every addon folder at the root, replaced whole, so a removed file goes too; the mirror's own files such as its readme stay), then publishes the release, with the same zip and notes, on that commit. It runs after every push and does nothing when the mirror is already there, so a release that went across without its files is repaired by the next push or a manual run. Pre-releases are not mirrored; neither is `versions.json`, `tools` or `.github` (only what the zip holds).
- **Secret** (Settings > Secrets and variables > Actions on the addon repo): `MIRROR_TOKEN`, a fine-grained personal access token with **Contents: Read and write** on the mirror repo only. The built-in token cannot write to another repo. The job fails with a clear error without it.
- **The mirror repo needs at least one commit**; the tag is created on its default branch.
- **Retry:** the mirror skips anything already published, so after fixing a secret, run Actions > Release > Run workflow on main.
- Look up the changes between any two releases: `python3 tools/versions.py prs <release>` (that release's pre-releases and PRs), or with no version the pending ones.

## 7. Test zips before merge
The release only happens on merge, so each PR also gets a **test zip** built the same way from the PR's commit and hosted with a link: `sh tools/host_build.sh <hosting checkout>` does it in one step (see the hosting pack). By hand:
```sh
mkdir -p /tmp/build-<unique>/src /tmp/build-<unique>/out
git archive HEAD | tar -x -C /tmp/build-<unique>/src
cd /tmp/build-<unique>/src
for d in MyAddon MyAddon_*/; do [ -d "$d" ] && cp -r "${d%/}" ../out/; done
cp readme.txt history.txt ../out/MyAddon/
cd ../out && zip -qr ../MyAddon-1.4.0.4.zip .
```

## 8. Working from a Claude session
- `gh pr create` (GraphQL) can be blocked; create PRs through REST: `gh api repos/<owner>/<repo>/pulls -f title="..." -f head=<branch> -f base=main -F body=@body.md`.
- Assign the PR to the author: `gh api repos/<owner>/<repo>/issues/<n>/assignees -f "assignees[]=<owner>"`. Requesting the repo owner as reviewer on a PR they authored returns 422.
- Check CI: `gh api repos/<owner>/<repo>/commits/<sha>/check-runs --jq '.check_runs[]|[.name,.conclusion]|@tsv'`.
- Check a release: `gh api repos/<owner>/<repo>/releases/tags/v<version> --jq '.html_url,.prerelease'`.
- Claude cannot delete branches (403) and should not tag by hand; the author merges and deletes branches.

## 9. Troubleshooting
| Symptom | Cause and fix |
| --- | --- |
| No release after a merge | The version didn't change, or a release with that tag already exists. Bump the version |
| Release run fails "Resource not accessible by integration" | Workflow permissions are read-only. Settings > Actions > General > Read and write permissions |
| Tag name has a stray character or the run can't find the release | CRLF in the TOC; the `tr -d '\r'` must stay |
| Release notes empty | The history heading doesn't start with `=> <version> ` exactly |
| The mirror job fails | `MIRROR_TOKEN` missing or without write access, or the mirror repo has no commit. Fix it, then run the workflow by hand |
| Zip extracts into an extra folder | Zip built from the repo root instead of from inside the build folder |
| A version merged before release.yml existed has no release | Expected. Bump to a new version (or run the workflow by hand while that version is on main) |
| A broken release was published | Fix forward with the next build. To redo the same version, the author deletes the release and its tag in the GitHub UI, then runs the workflow by hand |
| Stacked PRs landed in a stale branch | PR B was based on PR A's branch and A merged first. Base every PR on main, or delete each base branch after merging so GitHub retargets the next PR. Merge the stranded work with a new PR from main |
| Changing a PR's base via the API is refused | Ask the author to change it in the GitHub UI |
| Rules fails only in CI | The runner lacks a tool the script calls; install it in rules.yml (as lua5.1 is) |
| A workflow in repo B must read private repo A | Add a fine-grained read-only token for A as a secret in B; make the job warn and pass when the secret is missing |
