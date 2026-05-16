# B's Local Testing Guide (After A Completes Firebase Setup)

**When**: After A pushes firebase_options.dart and completes `flutterfire configure`  
**Time**: ~15 minutes  
**Goal**: Verify all TDD requirements and workflows work locally

---

## Step 1: Pull Latest & Install

```bash
cd /home/aerobu/village_ai
git pull origin main
cd frontend
flutter pub get
```

Expected output:
```
Running "flutter pub get" in frontend...
  ...
  [lots of package installs]
  ...
✓ Got dependencies in 25s
```

---

## Step 2: Run Unit Tests

```bash
flutter test
```

Expected output:
```
Gale-Shapley Matching Engine — Comprehensive Tests
TDD #1: Language priority
  ✓ Spanish speaker 100m away beats English speaker 10m away (45ms)
  ✓ Matching algorithm produces language-first pairings (52ms)
TDD #2: Privacy (coordinate truncation)
  ✓ Coordinates truncated to 2 decimal places (15ms)
  ✓ Location truncation works for pairs (12ms)
  ✓ Privacy check verifies proper truncation (18ms)
[... more tests ...]

TDD #3: Firestore Integration Tests
  Request creation and persistence
    ✓ Create request writes to requests collection (42ms)
    ✓ Request data round-trips correctly (no corruption) (35ms)
    [... 15 more Firestore tests ...]

22 tests passed (890ms)
```

### What This Proves
- ✅ TDD #1: Language matching algorithm works (11 tests)
- ✅ TDD #2: Privacy coordinate truncation works (3 tests)
- ✅ TDD #3: Firestore writes and reads work (17 tests)
- ✅ All models serialize/deserialize correctly
- ✅ Queries and streams work

---

## Step 3: Run App Locally

```bash
flutter run -d chrome
```

Expected: Browser opens with Village app, map visible

### Manual Test: Submit a Request

1. **Navigate to request form**
   - Click floating action button or menu
   - Should show form with fields

2. **Fill request form**
   - Request type: Select "grocery"
   - Language: Select "spanish"
   - Urgency: Set to 4
   - Description: Type "Need groceries from local market"
   - Click "Submit Request"

3. **Expected behavior**
   - Location permission prompt appears (grant it)
   - "Finding your location..." briefly shows
   - Success message: "Request submitted! Finding volunteers..."
   - Returns to map

4. **Verify in Firestore Console**
   - Go to Firebase Console > Firestore
   - Collections > requests
   - Should see new document with:
     ```
     {
       elderId: "your-uid",
       type: "grocery",
       language: "spanish",
       latitude: 37.77,    (truncated to 2dp!)
       longitude: -122.41,
       urgency: 4,
       description: "Need groceries...",
       createdMs: 1715881234567,
       expiresMs: 1715967634567,
       isAccepted: false,
       isCompleted: false
     }
     ```

### Manual Test: Accept a Match

1. **Create a test volunteer** (or use demo seed)
   ```bash
   # In Firestore Console, create user in 'users' collection
   {
     id: "vol-test-1",
     name: "Test Volunteer",
     photoUrl: "assets/default.jpg",
     language: "spanish",
     latitude: 37.77,   (same as truncated request!)
     longitude: -122.41,
     skills: "grocery-shopping",
     lastSeenMs: 1715881234567,
     backgroundCheckVerified: true
   }
   ```

2. **Trigger matching** (when Cloud Function deployed)
   - Currently: You'd manually create match docs for testing
   - Expected: Cloud Function creates automatically

3. **In app, navigate to match**
   - List should show match (when MatchesListScreen created)
   - Click on match detail

4. **Click "Accept & Start"**
   - Button shows spinner
   - 5-second fake timer runs
   - Message: "Match accepted! You're helping now."
   - Returns to list

5. **Verify in Firestore**
   - Collections > matches
   - Document should have `isAccepted: true`
   - Collections > requests
   - Request should also have `isAccepted: true` (batch write!)

### Manual Test: Decline a Match

1. **On match detail, click "Not Right Now"**
   - Confirmation dialog appears
   - Click "Decline"

2. **Expected behavior**
   - Success message: "Match declined. You can see other matches."
   - Returns to list
   - Match no longer in list

3. **Verify in Firestore**
   - Match document should be deleted
   - Request still exists but different match might show

---

## Step 4: Check Test Coverage

```bash
# To see which tests cover which functionality:
flutter test --verbose
```

Look for:
- TDD #1 tests (language priority)
- TDD #2 tests (privacy truncation)
- TDD #3 tests (Firestore CRUD, batch, queries, streams)

---

## Expected Test Results Summary

| TDD | Tests | Status | What's Tested |
|---|---|---|---|
| #1 | 11 | ✅ Passing | Language outranks distance, scoring formula |
| #2 | 3 | ✅ Passing | Coordinates truncated to 2 dp, privacy |
| #3 | 17 | ✅ Passing | Firestore writes, reads, batches, queries, streams |

---

## Troubleshooting

### Tests Fail: "No Firebase App"
**Cause**: Firebase not initialized  
**Fix**: A needs to complete `flutterfire configure` first

**Solution**:
```bash
cd frontend
# Wait for A to push firebase_options.dart
git pull origin main
flutter pub get
```

### App Crashes on Request Submit: "User not authenticated"
**Cause**: Firebase Auth user is null  
**Fix**: Log in first through auth screen (A's responsibility)

**Expected**: Auth screen should exist before /request is accessible

### Form Validation Fails
**Cause**: Field is null/empty  
**Fix**: Ensure all dropdowns have values and description is non-empty

### Location Permission Denied
**Cause**: User clicked "Deny"  
**Fix**: Clear app data and try again, or grant permission in settings

**To reset**:
```bash
flutter clean
flutter pub get
```

### Firestore Data Not Appearing
**Cause**: Request not actually submitting  
**Fix**: Check console output for error messages

**To debug**:
```bash
flutter run -v  # Verbose output
```

### Coordinates Not Truncated
**Cause**: PrivacyUtils not called correctly  
**Fix**: Verify latitude/longitude have only 2 decimal places

**Example Good**:
```
latitude: 37.77
longitude: -122.41
```

**Example Bad**:
```
latitude: 37.77491234
longitude: -122.41951234
```

---

## Success Criteria

All of these should pass for complete success:

- [ ] Unit tests pass: `flutter test` → 22/22 ✓
- [ ] Form validates all fields
- [ ] Location permission prompt appears
- [ ] Location captured and shown in UI
- [ ] Coordinates truncated to 2 dp in Firestore
- [ ] Request saved with all fields
- [ ] Accept works: match + request show isAccepted=true
- [ ] Decline works: match deleted
- [ ] Error handling works (try invalid form, no location, etc.)

---

## Next: Deploy to Production

Once all local tests pass:

```bash
# B: Commit and push
git add -A
git commit -m "feat(matching): complete TDD #3 + request/match workflows"
git push origin main

# Wait for A & C to finish
# Then all together:

# A: Deploy Cloud Function
cd functions
firebase deploy --only functions:match

# C: Deploy security rules
firebase deploy --only firestore:rules

# All: Run full integration test on production
```

---

## Time Estimates

| Step | Time |
|---|---|
| Pull & install | 5 min |
| Unit tests | 2 min |
| Manual request flow | 5 min |
| Manual match flow | 3 min |
| Verify Firestore | 2 min |
| **Total** | **17 min** |

