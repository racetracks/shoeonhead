# Working with the author

"The author" is the person who owns the addon and the Claude project. These are the working habits that have proven right; the addon pack or project memory may add the author's own preferences.

## The step loop
1. **Plan first.** For anything big the author asks for a sanity check and recommendations. Claude writes a short plan with numbered steps, says plainly what is impossible, and asks numbered questions, each with a recommendation.
2. **The author answers by number** ("1: yes 2: no, keep it 3: your call"). Play the final decisions back in the next reply before building.
3. **One step at a time.** The author names a step from the feature's stage plan (10_FEATURE_DESIGN_AND_DELIVERY.md); Claude ships exactly that step: one branch from the latest main and one PR per repo; every TOC bumped to the next build (`X.Y.Z.B`); a history section; checks green; a hosted test zip with the link; exact in-game checks.
4. **The author tests in game and merges** before the next stage starts. Merging a version bump publishes the release (a pre-release for every build).
5. **Bugs** found in testing become the next build, zipped and hosted like any build.
6. **One step per session** (02 E9 to E11): the author resets the session after each step; the step's PR updates the plan's stage table, the status, and the preferences file, so the next session starts from the project instructions alone.
7. **Long threads end with a handover**: this baseline plus an addon-specific pack.

## Communication
- **Plain language, answer first, short.** The author may read on the go.
- **Numbered questions with one-word answers** and the recommendation marked.
- **Always a zip link**; attachment slots in a thread run out, so zips are hosted and linked.
- **Exact in-game checks**, numbered.
- **Measured numbers**, never estimates, for memory, CPU and save size.
- **Short asks want the thing**: "PR?" means open it now with the link; "where release" wants the link.
- **Re-read the newest message before building.** The author may refine decisions mid-flight ("wait hold..."); restate the final rule set back.
- **Study screenshots closely**, zooming into the crop, before guessing a fix. Two guessed fixes once missed a cause the screenshot showed.
- **Saves come with their version** ("this is a 1.2.0 save"); file them by that version.
- **Forks get a default.** Ask once with options and a recommendation, keep building on the recommendation, and change course if the author picks another.
- Expect a request for a **code review pass before merging**; do it and fix what it finds.
- Ask how much the author wants to hear about progress and keep to it.

## Values
- **Performance and memory first.** Zero cost when off, lazy UI, garbage collection only at safe requested moments, nothing grows without a cap.
- **Upgrades are sacred.** Expect the author to keep WTF backups and to test upgrades closely. Every SavedVariables change has a validated migration and prunes old data.
- **Ask before anything hard to undo:** SavedVariables layout, deleting data, production releases.
- **Copy logic, never code or IDs**, from other addons. Respect licences.
- **TOC Title and Notes are the author's.**
- **Native Blizzard look**, unless drawing inside a UI suite, which is matched through its documented API, skinned and unskinned.
- **Hover must never open a window** (a link hover once opened a profession window).
- **Front ends are independent**: a user never needs two UI folders loaded.
- **One plain merge flow**: one PR per step based on main, not stacks.
