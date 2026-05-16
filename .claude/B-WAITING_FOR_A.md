# B's Optional Work While Waiting for A's Firebase Setup

Estimated time: A takes 15–30 min, so you have time for quick wins. Pick 1–2 from this list.

---

## 🥇 HIGH VALUE (15–20 min each)

### 1. **Create Demo Seed Data** ⭐ (RECOMMENDED)

Why: Super useful for testing without real Firestore. Create hardcoded test volunteers/requests.

**File to create:** `frontend/lib/data/test_seed.dart`

```dart
class TestSeed {
  static List<UserPublic> volunteers() => [
    UserPublic(
      id: 'vol_maria',
      name: 'Maria',
      language: 'spanish',
      latitude: 45.5152,
      longitude: -122.6784,
      skills: 'grocery-shopping,transportation',
      lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      backgroundCheckVerified: true,
    ),
    // ... more volunteers
  ];

  static List<HelpRequest> requests() => [
    HelpRequest(
      id: 'req_1',
      elderId: 'elder_john',
      type: 'grocery',
      language: 'english',
      latitude: 45.5165,
      longitude: -122.6760,
      urgency: 4,
      description: 'Need groceries from Safeway',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    ),
    // ... more requests
  ];
}
```

Then in request_form.dart, you can test with:
```dart
final matches = MatchingService.performMatching(
  TestSeed.volunteers(),
  TestSeed.requests(),
);
```

**Benefit:** Fast testing of matching logic without Firestore. See results instantly.

---

### 2. **Implement TDD #2: Privacy Truncation Helper** (10 min)

Why: Coordinates must be truncated to 2 dp before matching. Good to verify this works.

**File to create:** `frontend/lib/utils/privacy_utils.dart`

```dart
class PrivacyUtils {
  /// Truncate coordinate to 2 decimal places for privacy (~1.1km precision).
  /// TDD #2: Pre-match coords truncated to 2 dp
  static double truncateCoordinate(double value) {
    return (value * 100).round() / 100;
  }

  /// Truncate a full lat/lng pair
  static ({double lat, double lng}) truncateLocation(double lat, double lng) {
    return (lat: truncateCoordinate(lat), lng: truncateCoordinate(lng));
  }
}
```

**Add test in matching_test.dart:**
```dart
test('Coordinates truncated to 2 decimal places', () {
  final truncated = PrivacyUtils.truncateCoordinate(37.77491234);
  expect(truncated, 37.77);
});
```

**Benefit:** Ensures privacy invariant is checked before matching.

---

### 3. **Design Match Detail Screen** (20 min)

Why: Once a match is made, volunteers need to see the request details.

**File to create:** `frontend/lib/screens/match_detail_screen.dart`

```dart
class MatchDetailScreen extends StatelessWidget {
  final MatchDoc match;
  final HelpRequest request;
  final UserPublic elder;

  const MatchDetailScreen({
    required this.match,
    required this.request,
    required this.elder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Type: ${request.type}'),
            Text('Elder: ${elder.name}'),
            Text('Language: ${request.language}'),
            Text('Distance: ${(match.reason)}'),
            Text('Urgency: ${request.urgency}/5'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Call FirestoreService.acceptMatch(match.id)
              },
              child: const Text('Accept & Start'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Add to routes in main.dart:**
```dart
'/match/:id': (context) => const MatchDetailScreen(),
```

**Benefit:** Next screen in the flow. Ready for C to polish later.

---

## 🥈 MEDIUM VALUE (10–15 min each)

### 4. **Write More Comprehensive Dart Tests**

Expand `frontend/test/matching_test.dart` with:
```dart
test('Volunteers can only match once', () { ... });
test('Higher urgency requests get better volunteers', () { ... });
test('Distance decay is linear (500m→5km)', () { ... });
test('Language mismatch still produces matches', () { ... });
```

**Benefit:** Catch bugs early, document expected behavior.

---

### 5. **Create Firebase Emulator Setup Script**

Create `.claude/setup-emulator.sh`:
```bash
#!/bin/bash
cd functions
firebase emulators:start --only functions,firestore
```

**Benefit:** If A's Firebase Blaze plan costs money, emulator is free fallback.

---

### 6. **Document Shared Types**

Create `docs/TYPES.md` showing all data structures:
```markdown
# Shared Type Definitions

## UserPublic
- id: string (unique volunteer ID)
- language: string (must match HelpRequest.language for TDD #1)
- latitude/longitude: numbers (truncated to 2 dp)
- ...

## HelpRequest
- language: string (critical: TDD #1)
- urgency: 1–5 (affects scoring)
- ...

## MatchDoc
- score: 0.0–1.0 (0.7*language + 0.2*distance + 0.1*urgency)
- ...
```

**Benefit:** Prevents Dart/TypeScript type drift, reference for C later.

---

## 🥉 LOW VALUE (but interesting)

### 7. **Study Algorithm Stability**

Write `.claude/STABILITY_PROOF.md` explaining why Gale-Shapley is stable:
- Why volunteers only switch for better matches
- Why no "blocking pairs" exist
- Why it terminates

**Benefit:** Deep understanding, good documentation.

---

## 🎯 MY RECOMMENDATION

**Do these 3 (total ~40 min):**

1. **Create demo seed data** (15 min) ← USE THIS FOR LOCAL TESTING
2. **Implement privacy truncation** (10 min) ← VERIFY TDD #2
3. **Design match detail screen** (20 min) ← NEXT SCREEN IN FLOW

Then you'll have:
- ✓ Test data ready
- ✓ Privacy check verified
- ✓ Next UI screen drafted
- ✓ 40 min used productively
- ✓ Everything ready for when A finishes

**When A says "Firebase ready", you'll:**
1. `git pull`
2. `flutter pub get`
3. Use TestSeed to manually test matching
4. Verify privacy truncation works
5. Push to main with confidence

---

## 📋 Checklist (Pick One)

- [ ] Demo seed data + test with it
- [ ] Privacy truncation helper + test
- [ ] Match detail screen + routing
- [ ] More comprehensive Dart tests
- [ ] Emulator setup script
- [ ] Shared types documentation
- [ ] Stability proof/documentation

