# B's Coding Roadmap — Ready to Start

All stub files created and ready for you to develop on your `feat/B-matching` branch.

## 📁 Files Created (yours to implement)

### Data Models (foundation — already created ✓)
```
village_app/lib/models/
├── user_public.dart       # Volunteer/elder profile
├── help_request.dart      # What's being requested
└── match_doc.dart         # Matching algorithm output
```

### Matching Engine (core work)
```
functions/src/
└── matching.ts            # Gale-Shapley algorithm (TypeScript)
                           # Status: Stub with computeScore() + performMatching()

village_app/lib/services/
├── matching_service.dart  # Client-side wrapper + local fallback
│                          # Status: Stub with computeScore() + performMatching()
└── firestore_service.dart # Firestore CRUD for requests/matches
                           # Status: Complete with all helper methods
```

### Request Form (UI)
```
village_app/lib/screens/
└── request_form.dart      # Elder submits help request
                           # Status: Stub with form structure + TODOs
```

### Tests (TDD #1)
```
village_app/test/
└── matching_test.dart     # Language priority test
                           # Status: Ready to run once scaffold lands
```

### Documentation
```
docs/
└── MATCHING_ALGORITHM.md  # Full algorithm explanation + scoring formula
                           # Status: Complete reference
```

---

## 🎯 Next Steps (When A's Scaffold Lands)

### 1. **Rebase Your Branch**
```bash
git pull --rebase origin main
```

### 2. **Install Flutter Dependencies**
```bash
cd village_app
flutter pub get
```

### 3. **Run TDD #1 (Language Priority Test)**
```bash
flutter test test/matching_test.dart
```
Should fail at first (no implementation). Make it pass by implementing `computeScore()` with the 0.7 * language weight.

### 4. **Expand the Matching Algorithm**
In `functions/src/matching.ts` and `village_app/lib/services/matching_service.dart`:
- Implement full Gale-Shapley with proposal/rejection logic
- Handle multi-volunteer / multi-request stable matching
- Make TDD #1 pass

### 5. **Implement Request Form**
In `village_app/lib/screens/request_form.dart`:
- Uncomment the `geolocator` import once it's in pubspec.yaml
- Implement location capture
- Truncate to 2 dp for privacy (TDD #2, but verify with C)
- Submit to Firestore (TDD #3)

### 6. **Wire Firestore Service**
- Use `FirestoreService.createRequest()` to save requests
- Use `FirestoreService.saveBatchMatches()` to store algorithm output
- Stream matches with `watchMatchesForRequest()` for real-time UI updates

### 7. **Deploy Cloud Function**
Once A has Firebase set up:
```bash
eval "$(conda shell.bash hook)" && conda activate village
cd functions
npm install
npm run build
firebase deploy --only functions:match
```

---

## 📋 Checklist for Implementation

- [ ] TDD #1 test passes (language > distance scoring)
- [ ] `computeScore()` weighted correctly (0.7 lang, 0.2 dist, 0.1 urgency)
- [ ] `performMatching()` returns stable pairings
- [ ] Request form submits to Firestore `requests` collection
- [ ] Coordinates truncated to 2 dp (TDD #2 — verify with C)
- [ ] Firestore service methods all work
- [ ] Cloud Function deploys and receives request/volunteer data
- [ ] `flutter test` passes all tests
- [ ] No warnings in `flutter analyze`

---

## 🚀 What You Can Do Right Now (while waiting for A)

1. **Study the algorithm:** Read `MATCHING_ALGORITHM.md` carefully
2. **Understand the data model:** Review the three model classes
3. **Understand the scoring:** See `docs/MATCHING_ALGORITHM.md` §Language Rule
4. **Understand the test:** Know exactly what TDD #1 expects
5. **Familiarize yourself with the stubs:** Each file has TODO comments marking what needs implementation

Once A pushes "scaffold ready" to Discord, you'll be able to rebase and start coding immediately.

---

## 🎤 Questions?

Drop a message in Discord `#dev`. The whole point of trunk-based dev is **talk first, code second** — don't burn 20 minutes stuck on something.

---

**Branch:** `feat/B-matching`  
**Status:** Ready to develop once A lands scaffold  
**Waiting for:** A's Flutter app scaffold (`main` branch)
