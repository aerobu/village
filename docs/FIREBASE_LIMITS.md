# FIREBASE_LIMITS — staying on the free Spark plan

The `village-77ccb` project runs on **Firebase Spark** (no billing enabled).
Spark refuses requests when quotas are exhausted — it does **not** auto-upgrade
or bill you. The risk isn't a surprise invoice, it's that the demo breaks
mid-pitch if a quota runs out.

## Hard limits (daily, reset at midnight Pacific)

| Resource              | Spark limit     | Realistic demo budget       |
|-----------------------|-----------------|-----------------------------|
| Firestore reads       | **50,000/day**  | Aim for <2,000/day combined |
| Firestore writes      | **20,000/day**  | Aim for <500/day combined   |
| Firestore deletes     | **20,000/day**  | Should be ~0                |
| Firestore storage     | 1 GiB total     | We'll use kilobytes         |
| Network egress        | 10 GiB/month    | Effectively unlimited       |
| Auth (anon + email)   | Unlimited       | —                           |
| **Cloud Functions**   | **Not deployable on Spark** | use the emulator    |

## Rules of the road for this project

### 1. Use `DemoSeed` for everything visual

The 5 volunteers + 1 elder on the map come from `lib/data/demo_seed.dart` —
**not** Firestore. Don't replace this with a live query "to make it more real."
That single change would push us toward the read budget every page load.

### 2. `--dart-define=DEMO_MODE=true` skips Firestore entirely

The demo path (open app → see map → submit request → see match) runs end-to-end
against in-memory state. Firestore is touched only when `DEMO_MODE=false`.
Default the demo to `true`:
```bash
flutter run -d chrome --dart-define=DEMO_MODE=true
```

### 3. Always `.limit()` your queries

Every Firestore query in this codebase must call `.limit(N)`:
```dart
// ❌ Don't
FirebaseFirestore.instance.collection('users_public').get();

// ✅ Do
FirebaseFirestore.instance
    .collection('users_public')
    .limit(20)
    .get();
```

### 4. Prefer `.get()` over `.snapshots()` for the hackathon

Real-time listeners (`.snapshots()`) keep a connection open and re-read on any
change. For a 3-hour demo that's overkill and bills reads every update.
- ✅ One-shot fetch: `await ref.get()`
- ⚠️ Listener: only for the match-acceptance step, and **dispose it immediately**
  in `dispose()`.

### 5. Cache aggressively

In `main.dart` we configure Firestore with offline persistence and a small cache.
Once a doc is read it stays in the cache and subsequent reads cost zero quota.
Don't override this with `Source.server`.

### 6. No write-loops in tests

`flutter test` against the real Firestore would burn writes. Tests must either:
- Mock Firestore with `fake_cloud_firestore`, OR
- Run against the local Firebase emulator (`firebase emulators:start`)

### 7. Tighten security rules before exposing the URL anywhere

The current `firestore.rules` allow any authenticated user to update any
request doc (`update: if request.auth != null` on `/requests/{requestId}`).
That's fine for a private demo. Before you share the deployed URL publicly,
either tighten the rule or take the site down.

## How to check current usage

```bash
# Open the Firebase Console usage tab:
open https://console.firebase.google.com/project/village-77ccb/usage
```

The "Cloud Firestore" card shows reads/writes/deletes for today. If you ever
see it climb above 5K, something is looping.

## What NOT to do

- ❌ Click "Upgrade to Blaze" in the console (defeats the purpose of this doc).
- ❌ Add a `.snapshots()` listener on `users_public` without `.limit()`.
- ❌ Run a load test against the deployed Firestore.
- ❌ Seed Firestore with demo data — keep it in `demo_seed.dart`.
