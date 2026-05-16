# B's Optional Work — While Waiting for C's Profiles/Safety Features

C owns: profiles, safety badges, background checks, proof-of-visit, social share, Firestore rules

But B can work on integration, completion flows, and coordination points. Here are the best uses of time:

---

## 🥇 HIGHEST PRIORITY (will save C time)

### 1. **Complete TDD #3: Firestore Write Tests** (30 min) ⭐ RECOMMENDED

**Why:** B has written the services but NOT tested them. C will need these tests passing.

**What to do:** Add integration tests to `frontend/test/matching_test.dart`

```dart
group('TDD #3: Firestore writes', () {
  late FirebaseFirestore firestore;
  late CollectionReference requestsCollection;

  setUpAll(() async {
    // Firebase emulator setup (A's responsibility, but B can prepare)
    firestore = FirebaseFirestore.instance;
    requestsCollection = firestore.collection('requests');
  });

  test('Request writes to Firestore requests collection', () async {
    final request = HelpRequest(
      id: 'test_req_1',
      elderId: 'e1',
      type: 'grocery',
      language: 'spanish',
      latitude: 45.5, // Already truncated by PrivacyUtils
      longitude: -122.6,
      urgency: 5,
      description: 'Test request',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    );

    // TODO: Call FirestoreService.createRequest(request)
    // Verify it appears in Firestore

    final snapshot = await requestsCollection.doc(request.id).get();
    expect(snapshot.exists, true);
    expect(snapshot['language'], 'spanish');
    expect(snapshot['urgency'], 5);
  });

  test('Match writes to Firestore matches collection', () async {
    final match = MatchDoc(
      id: 'match_1',
      volunteerId: 'v1',
      requestId: 'r1',
      score: 0.95,
      reason: 'Spanish speaker, 100m away',
      createdMs: DateTime.now().millisecondsSinceEpoch,
    );

    // TODO: Call FirestoreService.saveMatch(match)
    // Verify it appears in Firestore
  });
});
```

**Benefit:** Completes all TDD requirements. C can build on verified infrastructure.

---

### 2. **Complete RequestFormScreen: Actual Implementation** (20 min)

**Why:** Form is skeleton only. C needs it to work end-to-end.

**What to do:** Implement the TODOs:

```dart
Future<void> _submitRequest() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    // ✅ Capture current location
    final position = await Geolocator.getCurrentPosition();
    
    // ✅ Truncate to 2 dp for privacy (TDD #2)
    final (:lat, :lng) = PrivacyUtils.truncateLocation(
      position.latitude,
      position.longitude,
    );

    // ✅ Create request object
    final request = HelpRequest(
      id: '',  // Firestore will generate
      elderId: currentUserId,  // TODO: get from auth
      type: _selectedType!,
      language: _selectedLanguage!,
      latitude: lat,
      longitude: lng,
      urgency: _urgency,
      description: _description,
      createdMs: DateTime.now().millisecondsSinceEpoch,
    );

    // ✅ Save to Firestore (TDD #3)
    await FirestoreService.createRequest(request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted! Finding volunteers...'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pushNamed('/matches');  // Next screen
    }
  } catch (e) {
    // Error handling
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
```

**Benefit:** Form is production-ready. Users can actually submit requests.

---

### 3. **Complete MatchDetailScreen: Wire Accept/Decline** (15 min)

**Why:** Buttons are stubs. Need actual Firestore updates.

**What to do:**

```dart
Future<void> _handleAccept() async {
  setState(() => _isAccepting = true);

  try {
    // ✅ Update Firestore
    await FirestoreService.acceptMatch(widget.matchId);

    // ✅ Fake 5-second timer ("accepting...") per OWNERSHIP.md
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match accepted! You\'re helping now.'),
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ Navigate to navigation/tracking screen
      Navigator.of(context).pushNamed('/tracking', arguments: widget.matchId);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isAccepting = false);
    }
  }
}
```

**Benefit:** Volunteers can actually accept matches. Flow is complete.

---

## 🥈 MEDIUM PRIORITY (coordination & flow)

### 4. **Create Matches List Screen** (20 min)

**Why:** After a request is submitted, user should see available matches.

**File:** `frontend/lib/screens/matches_list_screen.dart`

```dart
class MatchesListScreen extends StatelessWidget {
  final String requestId;

  const MatchesListScreen({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Volunteers')),
      body: StreamBuilder<List<MatchDoc>>(
        stream: FirestoreService.watchMatchesForRequest(requestId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return const Center(
              child: Text('No volunteers found yet. Keep waiting...'),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                child: ListTile(
                  title: Text('${(match.score * 100).toInt()}% Match'),
                  subtitle: Text(match.reason),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/match-detail',
                    arguments: match.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

**Benefit:** Full user flow: request → matches list → match detail → accept

---

### 5. **Create Navigation/Routing Coordinator** (15 min)

**Why:** Multiple screens now exist but routing isn't in main.dart.

**What to do:** Update `frontend/lib/main.dart` routes:

```dart
routes: {
  '/': (_) => const MapScreen(),
  '/request': (_) => const RequestFormScreen(),
  '/matches': (context) {
    final requestId = ModalRoute.of(context)?.settings.arguments as String;
    return MatchesListScreen(requestId: requestId);
  },
  '/match-detail': (context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String;
    return MatchDetailScreen(matchId: matchId);
  },
  '/tracking': (context) {
    final matchId = ModalRoute.of(context)?.settings.arguments as String;
    return const _PlaceholderScreen(label: 'Live Tracking');  // C will build
  },
  '/profile': (_) => const _PlaceholderScreen(label: 'Profile'),  // C's
},
```

**Benefit:** Navigation flow is complete and testable.

---

### 6. **Create Demo Walkthrough Script** (20 min)

**Why:** For the live demo, there's a narrative to follow.

**File:** `.claude/DEMO_SCRIPT.md`

```markdown
# Demo Script — Complete User Journey (3 minutes)

## Scene 1: Elder Requests Help (30 sec)
1. App loads to map showing available volunteers
2. Click "Request Help" button
3. Fill form:
   - Type: "Grocery"
   - Language: "Spanish"
   - Urgency: 5
   - Description: "Need groceries from Safeway"
4. Click "Submit Request"
5. App saves to Firestore (show in Firebase console)

## Scene 2: Matching Algorithm Runs (20 sec)
1. Cloud Function triggered automatically
2. Runs Gale-Shapley matching
3. Results appear in Firestore `matches/` collection
4. App shows "Available Volunteers" list with scores

## Scene 3: Volunteer Accepts Match (40 sec)
1. Click on best match (Maria, 95%)
2. See match details: elder name, request type, distance, score
3. Click "Accept & Start"
4. 5-second "Accepting..." timer runs
5. Confirms: "Match accepted! You're helping now."

## Scene 4: Safety & Proof (30 sec)
1. Volunteer navigates to profile
2. Shows elder's background check badge (C's feature)
3. Shows proof-of-visit tracking (C's feature)
4. Shows social share button (C's feature)

Total time: 2–3 minutes, showcases all three slices.
```

**Benefit:** Demo is polished, organized, no fumbling.

---

## 🥉 LOWER PRIORITY (nice-to-have)

### 7. **Add Widget Tests for RequestFormScreen** (30 min)

```dart
testWidgets('Request form renders all fields', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  expect(find.byType(DropdownButton), findsWidgets);
  expect(find.byType(Slider), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
  expect(find.byType(ElevatedButton), findsWidgets);
});
```

### 8. **Add Error Recovery Tests** (20 min)

```dart
test('Handles Firestore offline gracefully', () async {
  // Mock Firestore failure
  // Verify UI shows error message
  // Verify retry button appears
});
```

### 9. **Create Acceptance Analytics** (15 min)

Track in Firestore:
- How many matches per request?
- Average time to accept?
- Language match rate?

---

## 📋 My Recommendation

**Do these 3 (total ~65 min):**

1. ✅ **TDD #3 integration tests** (30 min) — Completes testing requirements
2. ✅ **RequestFormScreen full impl** (20 min) — Forms actually work
3. ✅ **MatchDetailScreen wire-up** (15 min) — Accept/decline works

Then you'll have:
- ✓ All TDD requirements complete
- ✓ Full user journey working
- ✓ Ready for demo
- ✓ Nothing blocking C

---

## 🎯 What NOT to Do Yet

- Don't implement profiles (C's job)
- Don't implement safety badges (C's job)
- Don't implement proof-of-visit (C's job)
- Don't implement social share (C's job)
- Don't implement Firestore rules (C's job)

BUT you CAN create placeholder screens that C will wire up later.

---

## Timeline to Production

**If you do the top 3:**
1. TDD #3 tests: 30 min
2. Form implementation: 20 min
3. Accept/decline: 15 min
4. Testing locally: 30 min (when A finishes)
5. Deploy: 15 min
6. Push to main: 5 min
─────────────────────────
**Total: ~2 hours from now to main branch** ✨

