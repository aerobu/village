# SCHEMA — Firestore collections for village

Source of truth for the data model. Agree on this **before** parallelizing feature work — every screen and the matching function depend on it.

The privacy invariants from `CLAUDE.md` are encoded directly into the collection split: PII lives in a restricted collection, public profiles only carry generalized fields, and pre-match coordinates are truncated to 2 decimal places (~1 km).

## Collections

### `users_public/{uid}`
Readable by any authenticated user. Safe to display on the map / in match cards.

| Field            | Type      | Notes                                                                |
|------------------|-----------|----------------------------------------------------------------------|
| `uid`            | string    | Firebase Auth UID                                                    |
| `role`           | string    | `"elder"` \| `"volunteer"`                                            |
| `displayName`    | string    | First name + last initial only ("Priya S.")                          |
| `photoUrl`       | string?   | Generic avatar URL OR null                                           |
| `languages`      | string[]  | ISO-ish tags: `["ta","en"]` (Tamil, English)                          |
| `approxLocation` | geopoint  | **Coordinates truncated to 2 decimal places.** ~1km granularity.     |
| `rating`         | number    | 0.0 – 5.0, hardcoded for demo                                        |
| `backgroundCheck`| boolean   | `true` for demo volunteers (the "badge"). Always `false` for elders. |
| `skills`         | string[]  | Volunteer-only: `["groceries","companionship","transport"]`           |
| `needs`          | string[]  | Elder-only: same vocabulary as `skills`                              |

### `users_pii/{uid}`
**Locked down by security rules.** Only the user themselves can read; only the matching Cloud Function can read across users (via Admin SDK). Never queried from the client for other users.

| Field         | Type     | Notes                                  |
|---------------|----------|----------------------------------------|
| `uid`         | string   | mirrors `users_public.uid`             |
| `fullName`    | string   |                                        |
| `phone`       | string   |                                        |
| `exactLocation`| geopoint| Full precision. Revealed to a matched counterparty only after acceptance. |
| `email`       | string   |                                        |
| `address`     | string?  |                                        |

### `requests/{requestId}`
Created when an elder hits "Find Match". Writing here is what triggers the Cloud Function (TDD test #3).

| Field           | Type      | Notes                                           |
|-----------------|-----------|-------------------------------------------------|
| `requestId`     | string    | document id                                     |
| `elderUid`      | string    | references `users_public/{uid}`                 |
| `needType`      | string    | `"groceries"`, `"companionship"`, etc.          |
| `requiredLanguage` | string | ISO-ish tag, e.g. `"ta"`                         |
| `approxLocation`| geopoint  | truncated to 2 decimals (privacy invariant)     |
| `status`        | string    | `"pending"` → `"matched"` → `"completed"`        |
| `createdAt`     | timestamp | `serverTimestamp()`                              |
| `matchId`       | string?   | filled in when matched                           |

### `matches/{matchId}`
Result of the Gale-Shapley pass. Only the two participants can read the corresponding match doc.

| Field          | Type      | Notes                                           |
|----------------|-----------|-------------------------------------------------|
| `matchId`      | string    |                                                 |
| `requestId`    | string    |                                                 |
| `elderUid`     | string    |                                                 |
| `volunteerUid` | string    |                                                 |
| `acceptedAt`   | timestamp | for the hardcoded 3-second fake-accept timer    |
| `completedAt`  | timestamp?| set when "Complete Visit" is tapped             |
| `proofPhotoUrl`| string?   | hardcoded stock photo URL for the demo          |

## Dart model stubs

These should land in `frontend/lib/models/` as soon as the scaffold is in. **Person B owns these** (see `OWNERSHIP.md`) and they block the other two — write them first.

```dart
// models/user_public.dart
class UserPublic {
  final String uid;
  final String role;              // "elder" | "volunteer"
  final String displayName;
  final List<String> languages;
  final GeoPoint approxLocation;  // truncated
  final double rating;
  final bool backgroundCheck;
  final List<String> skills;
  final List<String> needs;
  // fromMap / toMap …
}

// models/request.dart
class HelpRequest {
  final String requestId;
  final String elderUid;
  final String needType;
  final String requiredLanguage;
  final GeoPoint approxLocation;
  final String status;            // "pending" | "matched" | "completed"
  // …
}

// models/match.dart
class MatchDoc {
  final String matchId;
  final String requestId;
  final String elderUid;
  final String volunteerUid;
  final DateTime? acceptedAt;
  final String? proofPhotoUrl;
  // …
}
```

## Security rules sketch

Real rules go in `firestore.rules`. Minimum for the demo:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    // Anyone signed in can read public profiles.
    match /users_public/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    // PII: only the user themselves. Cloud Functions use Admin SDK and bypass rules.
    match /users_pii/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // Requests: elder writes their own; everyone reads pending requests (for the map).
    match /requests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.elderUid
                    && request.resource.data.approxLocation == roundTo2Dp(request.resource.data.approxLocation);
      allow update: if request.auth != null; // tighten later
    }

    // Matches: only the two participants.
    match /matches/{matchId} {
      allow read: if request.auth.uid == resource.data.elderUid
                  || request.auth.uid == resource.data.volunteerUid;
      allow write: if false; // Cloud Function only
    }
  }
}
```

`roundTo2Dp` isn't a real rules built-in — we enforce truncation in the client write path and assert it in TDD test #2 instead.

## Hardcoded demo data

Lives in `frontend/lib/data/demo_seed.dart` (Person A owns this file):

- **5–6 volunteer `users_public` docs** with varied languages (Tamil, Hindi, Bengali, English) and approx locations spread around a small radius.
- **1 elder `users_public` doc** for the demo user.
- **1 stock "proof of visit" photo URL** in `assets/` for the post-match screen.

Seeding runs on app startup if a `--dart-define=DEMO_SEED=true` flag is passed.
