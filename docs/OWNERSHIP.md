# OWNERSHIP — who owns what during the build

Three-way split by **vertical feature slice** so nobody blocks anyone else after the initial scaffold lands. Each owner is the decision-maker on their files; anyone can submit PRs into another area but the owner approves.

> Edit the names below once the team confirms — placeholders use letters until you fill them in.

## Roles

| Owner | GitHub handle | Slice | Demo touchpoint (`project.md` §6) |
|-------|---------------|-------|-----------------------------------|
| **A** | `arnewiseman` | Map & visual shell, app scaffold, hardcoded demo data | Step 3 (the map visual) |
| **B** | `aerobu` | Request flow + Gale-Shapley matching + the fake-accept timer | Step 3 (the core match flow) |
| **C** | `bharathkb882` | Profiles, safety badges, Proof-of-Visit & social share  | Steps 2 & 4 (safety primer + the "wow" moment) |

**Branching strategy:** Choose one before the build starts:
- **PR + merge captain model** (below) — safer for async teams, lower merge risk.
- **Trunk-based direct-to-main** (`TRUNK_DEV.md`) — faster for 3-hour hackathons, requires discipline.

If you pick **PR + merge captain**: Pick a **merge captain** (recommend A) — they're the only one who merges PRs to `main` during the build, to avoid concurrent-merge surprises.

## File ownership

### A — Map & visual shell
- `frontend/lib/main.dart`
- `frontend/lib/screens/map_screen.dart`
- `frontend/lib/widgets/pulsing_marker.dart`
- `frontend/lib/data/demo_seed.dart` (hardcoded 5–6 volunteer pins + elder)
- `frontend/assets/` (map style JSON, stock photos)
- App-wide theming and navigation skeleton

### B — Request flow + matching engine
- `frontend/lib/screens/request_form.dart`
- `frontend/lib/services/matching_service.dart` (client-side fallback)
- `frontend/lib/services/firestore_service.dart`
- `frontend/lib/models/` (UserPublic, HelpRequest, MatchDoc — write these FIRST, day-zero)
- `functions/src/matching.ts` (Gale-Shapley Cloud Function)
- `frontend/test/matching_test.dart` — **TDD #1: language outranks distance**

### C — Profiles, safety, "wow" moments
- `frontend/lib/screens/profile_screen.dart`
- `frontend/lib/screens/proof_of_visit.dart`
- `frontend/lib/widgets/background_check_badge.dart`
- `frontend/lib/services/share_service.dart` (Facebook/Instagram share buttons)
- `firestore.rules` (privacy invariants)
- `frontend/test/privacy_test.dart` — **TDD #2: pre-match coords truncated to 2 dp**
- `frontend/test/request_write_test.dart` — **TDD #3: submit writes to `requests`**

## Shared / no-single-owner files

Touch with a quick heads-up in `#dev` on Discord:

- `frontend/pubspec.yaml`
- `firebase.json`, `.firebaserc`, `firestore.indexes.json`
- `docs/*`
- `README.md`, `CLAUDE.md`

## Branching (PR + merge captain model)

**Only if you're using the merge captain approach (not trunk-based):**

- `main` — always demo-ready. Only the merge captain pushes here.
- `feat/A-map`, `feat/B-matching`, `feat/C-safety` — long-lived per-person branches.
- Short feature sub-branches off your main branch are fine if you want them, but not required for a 3-hour build.
- Rebase your branch on `main` (`git pull --rebase origin main`) before opening a PR.

### PR etiquette for a 3-hour build

- **Title:** `[A|B|C] short description` — makes the queue scannable.
- **Description:** one sentence + a screenshot/GIF if it's a UI change.
- **Review:** 60-second eyes-on in Discord voice is enough. Don't gate on full async review.
- **Required check:** `flutter test` must pass locally before requesting merge.

**→ Using trunk-based workflow instead?** See `TRUNK_DEV.md` for the three rules (rebase, test, announce).

## Communication norms

- Discord voice is **always on** during the build — talk first, type second.
- `#dev` for "I'm about to push to X" / "anyone seen this error" / screenshots.
- `#general` for product decisions and the demo script.
- If you're stuck for >5 minutes, ask. Don't burn 20 minutes solo on a hackathon clock.

## Pre-flight checklist (before the timer starts)

- [ ] All 3 names filled in above
- [ ] **Branching strategy decided:** PR + merge captain (§ below), or trunk-based direct-to-main (`TRUNK_DEV.md`)?
- [ ] If PR model: merge captain picked; if trunk-based: everyone has read `TRUNK_DEV.md`
- [ ] All 3 pass the §4 sanity check in `SETUP.md`
- [ ] Firebase project created and all 3 have Editor access
- [ ] Scaffold pushed to `main` and everyone has pulled it
- [ ] Models in `lib/models/` exist and match `SCHEMA.md`
- [ ] Discord voice channel open
