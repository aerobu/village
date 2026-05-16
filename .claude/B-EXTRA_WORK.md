# B's Extra Work — While Waiting for A's Scaffold

All of this is optional but will make you 2–3x faster when the scaffold lands.

---

## 🎯 High Priority (30 min each)

### 1. **Implement Full Cloud Function (TypeScript)**

Right now `functions/src/matching.ts` is a stub. You can flesh it out 100% without the Flutter app:

**What to add:**
- Full Gale-Shapley with proposal/rejection logic (not just greedy matching)
- Haversine distance implementation is already there, but verify it's correct
- Edge cases: no matches, all requests same language, volunteer double-booking

**How to test:**
```bash
cd functions
npm install
npm run build  # Compile TypeScript
# Create a test file: src/matching.test.ts
# Run: npm test
```

You can use Node.js's built-in test runner without any test framework dependency.

**Benefit when scaffold lands:** Cloud Function is already production-ready. B just deploys it.

---

### 2. **Write Comprehensive Unit Tests** (matching_test.dart + TypeScript)

TDD #1 is just one test. Add edge cases:

**Dart tests to add:**
```dart
test('No matching volunteers returns empty list', () { ... });
test('Multiple requests prefer higher urgency', () { ... });
test('Background check status affects scoring', () { ... });
test('Volunteer can only be matched once', () { ... });
test('Distance decay is linear from 500m to 5km', () { ... });
```

**TypeScript tests** (in `functions/src/matching.test.ts`):
```typescript
test('Gale-Shapley produces stable matching', () => { ... });
test('Rejections work correctly', () => { ... });
test('Score formula weights language at 70%', () => { ... });
```

**Benefit when scaffold lands:** High confidence the algorithm works before integration. Fast iteration when A's ready.

---

### 3. **Create Mock Data / Seed Generator**

Build a helper that generates realistic test data:

**New file: `lib/data/demo_seed.dart`**
```dart
class DemoSeed {
  static List<UserPublic> mockVolunteers() => [
    UserPublic(id: 'v1', name: 'Maria', language: 'spanish', ...),
    UserPublic(id: 'v2', name: 'Bob', language: 'english', ...),
    ...
  ];

  static List<HelpRequest> mockRequests() => [
    HelpRequest(id: 'r1', type: 'grocery', language: 'spanish', ...),
    ...
  ];
}
```

You can use this in tests and for manual testing once the app is up.

**Benefit when scaffold lands:** Tests run instantly with seed data. No waiting for Firestore.

---

## 📚 Medium Priority (optional, 15–30 min)

### 4. **Mirror TypeScript Types to Dart** (or vice versa)

Right now you have:
- Dart models in `lib/models/`
- TypeScript interfaces in `functions/src/matching.ts`

Create a **shared type definition document** that both sides can reference:

**New file: `docs/TYPES.md`**
```markdown
# Shared Type Definitions

## UserPublic
| Field | Type | Notes |
| --- | --- | --- |
| id | string | Unique volunteer ID |
| language | string | Must be one of: spanish, english, tagalog, mandarin |
| latitude | number | Truncated to 2 dp |
| longitude | number | Truncated to 2 dp |
...
```

This prevents drift between Dart and TypeScript definitions.

---

### 5. **Design Related Screens** (stubs)

Once a volunteer accepts a match, they need screens to:
- See the match details
- Navigate to the elder
- Mark as complete

**Create stubs:**
```
village_app/lib/screens/
├── match_detail_screen.dart    # Volunteer sees matched request
├── match_map_screen.dart       # Navigate to elder's location
└── completion_screen.dart      # Mark task as done
```

**Benefit:** When A says "ready", you can show something interactive. Also, you'll spot design issues early.

---

### 6. **Set Up Cloud Function Deployment Script**

Create a helper script in your `.claude/` folder:

**`.claude/deploy-function.sh`**
```bash
#!/bin/bash
eval "$(conda shell.bash hook)"
conda activate village
cd functions
npm install
npm run build
firebase deploy --only functions:match
echo "✓ Deployed matching Cloud Function"
```

Make it executable and documented.

---

## 🧠 Optional Deep Dives (educational)

### 7. **Study Gale-Shapley Stability Properties**

Write a document: `.claude/STABILITY_ANALYSIS.md`

Questions to answer:
- **Why is Gale-Shapley stable?** (prove it mathematically or with examples)
- **What happens if a volunteer becomes unavailable mid-match?**
- **Can we re-run matching and re-pair without breaking?**
- **How to prioritize urgency without breaking stability?**

This is NOT needed for the 3-hour build, but it shows deep thinking. Good for documentation later.

---

### 8. **Performance Analysis**

With 100 volunteers and 50 requests, how fast is matching?
- Gale-Shapley: O(n²) worst case, but typically O(n log n) in practice
- Your scoring: O(n²) to build preference lists

Write a document with complexity analysis and suggestions for optimization if data grows.

---

## 🛠️ What You Can Code Right Now

### Quick Wins (10 min each)

1. **Add distance_to() tests** — Haversine correctness
```dart
test('Distance between (0,0) and (0,1) is ~111km', () { ... });
```

2. **Add privacy truncation test** — Coordinates truncate to 2 dp
```dart
test('Coordinates truncated to 2 decimal places', () {
  final user = UserPublic(..., latitude: 37.77491234, ...);
  expect(user.latitude, 37.77);
});
```

3. **Add urgency scoring test**
```dart
test('Urgent requests (5/5) score higher than low urgency', () { ... });
```

---

## 📋 Recommended Order (if you have 1–2 hours)

1. **Implement full TypeScript matching.ts** (45 min) — highest ROI
2. **Write 5–10 unit tests** (30 min) — catch bugs early
3. **Create demo seed data** (15 min) — useful for testing
4. **Document shared types** (15 min) — prevent drift
5. **Create deployment script** (10 min) — automation

---

## 🎤 Pro Tip

**Coordinate with A in Discord:**
- *"I'm implementing full Gale-Shapley in TypeScript while you scaffold. I'll test it with mock data."*
- *"Once you have Firestore set up, I can wire the Cloud Function."*
- *"Want me to write seed data so we can demo matching once everything's integrated?"*

This way, when A finishes the scaffold, you're not starting from scratch — you've already validated the algorithm and have a deployment plan.

---

## 🚀 When A Posts "Scaffold Ready"

You'll be able to:
1. Rebase and merge your algorithm work
2. Deploy the Cloud Function immediately
3. Run TDD #1 and watch it pass
4. Start polishing the request form with real Firestore

**You'll be 2 hours ahead of the game.** 🎯
