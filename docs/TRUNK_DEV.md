# TRUNK_DEV — shared workflow rules for direct-to-main commits

**If your team chooses to push directly to `main` instead of using the PR + merge-captain model in `OWNERSHIP.md`, follow these rules religiously.**

## Why trunk-based dev for a 3-hour hackathon?

- **No PR latency.** Ship code in seconds, not minutes.
- **Forced small commits.** You can't hide a 200-line monster in a PR.
- **Simpler workflow.** One branch (`main`), three people, three pushes.

The tradeoff: **you must enforce discipline at the local level**, because there's no gate between you and breaking everyone else.

## The three non-negotiable rules

### 1. Rebase before every push (always)

```bash
git pull --rebase origin main
```

Run this *every single time* before `git push`. No exceptions, not even "I'm just pushing a README edit."

**Why:** This avoids merge commits and keeps the history linear. If someone else pushed while you were coding, your commits stack cleanly on top instead of creating a tangled merge node.

**If you get conflicts:** Resolve them locally, stage everything (`git add .`), then `git rebase --continue`. Do NOT merge. That defeats the purpose.

### 2. Tests must pass before push

```bash
flutter test
```

Only push if all tests pass locally. This is your safety net — the three TDD invariants in `OWNERSHIP.md` (language-outranks-distance, coords-truncated, request-writes) must stay green.

**Why:** `main` is always demo-ready. A failing test on `main` means you've broken someone's build or the demo.

### 3. Announce shared-file changes in Discord `#dev`

Before you push anything touching:
- `village_app/pubspec.yaml`
- `firebase.json`, `.firebaserc`, `firestore.indexes.json`
- `firestore.rules`
- `docs/*` (including this file)
- `SCHEMA.md`, `project.md`, `CLAUDE.md`, `README.md`

Post a quick message in Discord `#dev`: *"about to push update to pubspec.yaml — will add the http package"* or *"pushing firestore.rules privacy fix"*.

**Why:** If two people push different edits to `pubspec.yaml` in quick succession, the second person's rebase might have conflicts that aren't auto-resolvable. A heads-up means the second person knows to rebase carefully or wait 30 seconds.

## How to structure commits

Aim for **one logical change per commit**. Examples:

✅ Good:
```
Add UserPublic model with name, photo_url
Update matching_service.dart to call getProfile()
Fix language-priority test in TDD #1
```

❌ Bad:
```
Work in progress
stuff
fixed it
more fixes
```

You won't have time for lengthy commit messages, but a one-liner title helps whoever needs to `git blame` a line.

## Workflow in practice

```bash
# 1. Pull latest + your changes on top
git pull --rebase origin main

# 2. Work on your file(s) per OWNERSHIP.md
# (edit map_screen.dart, or matching_service.dart, etc.)

# 3. Run tests
flutter test

# 4. If shared files: announce in #dev
# "about to push: adding geopoint package to pubspec"

# 5. Stage & commit with a one-liner message
git add .
git commit -m "Add geopoint package for map markers"

# 6. Rebase on main one more time (in case someone pushed while you were testing)
git pull --rebase origin main

# 7. Push
git push origin main
```

Repeat 5–7 for each logical commit. Don't batch a bunch of changes and push once; that defeats the small-commit discipline.

## Handling merge conflicts during rebase

If you hit conflicts:

```bash
git status  # See which files conflict
# Fix the conflict markers in those files
git add .  # Stage your fixes
git rebase --continue
```

Usually conflicts will be in files you own (per `OWNERSHIP.md`), so you'll know the right resolution. If you hit a conflict in someone else's file, post in Discord voice: *"I'm rebasing and have a conflict in C's profile_screen.dart — what's the right merge?"*

## When to NOT use this workflow

If two of you need to edit the **exact same file** at the same time — e.g., both editing `models/HelpRequest.dart` — trunk-based dev becomes painful. The fix: **coordinate via Discord voice first**, agree on the structure, one person pushes, the other rebases and adjusts.

That's why `OWNERSHIP.md` says *"write the models FIRST, day-zero."* Lock down the shared contract before you branch off into disjoint files.

## Updated pre-flight checklist

Before the timer starts:

- [ ] All 3 names filled in `OWNERSHIP.md`
- [ ] **No merge captain needed** (everyone pushes)
- [ ] All 3 pass the §4 sanity check in `SETUP.md`
- [ ] Firebase project created and all 3 have Editor access
- [ ] Scaffold pushed to `main` and everyone has pulled it
- [ ] Models in `lib/models/` exist and match `SCHEMA.md`
- [ ] Discord voice channel open
- [ ] Everyone knows the three rules: rebase, test, announce

---

**Questions?** Ask in Discord voice. Three hours is short — don't google, don't read Hacker News. Just ask.
