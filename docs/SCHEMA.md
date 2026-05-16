# SCHEMA — Firestore collections for village

Source of truth for the data model. Agree on this **before** parallelizing feature work — every screen and the matching function depend on it.

## Collections

### `users/{id}`
Public volunteer and elder profiles. Readable by any authenticated user. Safe to display on the map / in match cards.

| Field            | Type      | Notes                                                                |
|------------------|-----------|----------------------------------------------------------------------|
| `id`             | string    | document id (typically Firebase Auth UID)                            |
| `name`           | string    | First name + last initial only ("Priya S.")                          |
| `photoUrl`       | string    | Generic avatar URL or empty string                                   |
| `language`       | string    | Single language tag: `"tamil"`, `"spanish"`, `"english"`, etc.        |
| `latitude`       | number    | **Truncated to 2 decimal places.** ~1.1 km precision (privacy).      |
| `longitude`      | number    | **Truncated to 2 decimal places.**                                   |
| `skills`         | string    | Comma-separated for volunteers: `"groceries,companionship,transport"` |
| `lastSeenMs`     | number    | Unix ms; used to filter active volunteers (last 24 hours)            |
| `backgroundCheckVerified` | boolean | `true` = verified badge shown for volunteers                  |

**Note on role:** The demo doesn't have a `role` field — elder vs. volunteer distinction is contextual (seeded separately in `demo_seed.dart`, or inferred from who created the request).

### `requests/{id}`
Created when an elder hits "Find Match". Writing here can trigger the Cloud Function. **TDD #3: submitting a request writes to this collection.**

| Field           | Type      | Notes                                           |
|-----------------|-----------|-------------------------------------------------|
| `id`            | string    | document id                                     |
| `elderId`       | string    | Firebase Auth UID of the elder requesting help |
| `type`          | string    | `"grocery"`, `"transportation"`, `"tech-help"`, `"companionship"`, etc. |
| `language`      | string    | Preferred language: `"tamil"`, `"spanish"`, `"english"`, etc.       |
| `latitude`      | number    | **Truncated to 2 decimals** (privacy invariant)                      |
| `longitude`     | number    | **Truncated to 2 decimals**                                         |
| `urgency`       | number    | Integer 1–5 (5 = ASAP). Used in matching score.                     |
| `description`   | string    | Free-text task description from the elder                           |
| `createdMs`     | number    | Unix ms when request was submitted                                  |
| `expiresMs`     | number?   | Unix ms when request expires if not matched (optional)              |
| `isAccepted`    | boolean   | `true` once a volunteer accepts the match                           |
| `isCompleted`   | boolean   | `true` once the task is marked complete                             |

### `matches/{id}`
Output of the Gale-Shapley matching algorithm. Represents a proposed pairing of a volunteer with a request.

| Field          | Type      | Notes                                           |
|----------------|-----------|-------------------------------------------------|
| `id`           | string    | document id: `"{volunteerId}-{requestId}"`     |
| `volunteerId`  | string    | Firebase Auth UID of the volunteer             |
| `requestId`    | string    | references `requests/{id}`                      |
| `score`        | number    | 0.0–1.0 match quality. Formula: `0.7*language + 0.2*distance + 0.1*urgency` |
| `reason`       | string    | Human-readable: `"Tamil speaker, 300m away"`   |
| `createdMs`    | number    | Unix ms when the matching algorithm ran        |
| `isAccepted`   | boolean   | `true` once volunteer taps Accept              |

## Privacy invariants

**TDD #2: Coordinate truncation.** All lat/lng exposed to the frontend before match acceptance are truncated to 2 decimal places (~1.1 km precision). See `frontend/lib/utils/privacy_utils.dart`.

**Demo simplification:** The original design included a `users_pii` collection for exact locations (revealed only post-match). For this demo, we use the simplified single-collection approach with truncated coordinates exposed throughout.

## Dart models

These live in `frontend/lib/models/`. **Person B owns these** (see `OWNERSHIP.md`).

```dart
// models/user_public.dart
class UserPublic {
  final String id;
  final String name;
  final String photoUrl;
  final String language;         // single tag, not array
  final double latitude;          // truncated to 2 dp
  final double longitude;         // truncated to 2 dp
  final String skills;            // comma-separated string
  final int lastSeenMs;
  final bool backgroundCheckVerified;
  
  double distanceTo(double lat, double lng) { /* Haversine formula */ }
  Map<String, dynamic> toJson() { /* … */ }
  factory UserPublic.fromJson(Map<String, dynamic> json) { /* … */ }
}

// models/help_request.dart
class HelpRequest {
  final String id;
  final String elderId;
  final String type;              // "grocery", "transport", etc.
  final String language;          // single tag
  final double latitude;          // truncated to 2 dp
  final double longitude;
  final int urgency;              // 1–5
  final String description;
  final int createdMs;
  final int? expiresMs;
  final bool isAccepted;
  final bool isCompleted;
  
  Map<String, dynamic> toJson() { /* … */ }
  factory HelpRequest.fromJson(Map<String, dynamic> json) { /* … */ }
}

// models/match_doc.dart
class MatchDoc {
  final String id;
  final String volunteerId;
  final String requestId;
  final double score;             // 0.0–1.0
  final String reason;
  final int createdMs;
  final bool isAccepted;
  
  Map<String, dynamic> toJson() { /* … */ }
  factory MatchDoc.fromJson(Map<String, dynamic> json) { /* … */ }
}
```

## Hardcoded demo data

Lives in `frontend/lib/data/demo_seed.dart` (Person A owns this file):

- **5 volunteer `users` docs** with varied languages (Tamil, Hindi, Bengali, English) and approx locations around downtown Portland, OR.
- **1 elder `users` doc** for the demo user.
- **1 stock "proof of visit" photo** (`assets/images/proof_stub.jpg`) for the post-match screen.

Seeding runs on app startup when `DEMO_MODE=true` (default). With `DEMO_MODE=false`, the app reads live from Firestore.
