# Matching Algorithm — Gale-Shapley for Village

## Overview

The matching engine pairs **volunteers** with **help requests** using a stable matching algorithm optimized for:
1. **Language match** (highest priority)
2. **Distance** (secondary)
3. **Urgency** (tertiary)
4. **Volunteer availability** (skills match)

**Key invariant (TDD #1):** Language outranks distance. A Spanish speaker 100m away beats an English speaker 10m away for a Spanish request.

---

## Algorithm: Modified Gale-Shapley

Classic stable marriage problem adapted for multi-volunteer / multi-request matching:

### Inputs
- `volunteers: UserPublic[]` — available volunteers with language, location, skills
- `requests: HelpRequest[]` — incoming help requests needing matches

### Process

1. **Rank preferences for each request** (from request's perspective):
   - Sort volunteers by: language match (binary), then distance, then urgency, then background-check status
   - Example: Request in Spanish → Spanish speakers first, sorted by distance

2. **Propose and reject** (standard Gale-Shapley):
   - Each unmatched request proposes to its top-ranked remaining volunteer
   - Volunteer accepts if they prefer this request to any current proposal
   - Volunteer rejects if busy or prefer another request
   - Repeat until stable (everyone matched or no more proposals possible)

3. **Generate match documents** with scores:
   - Score = `0.7 * language_match + 0.2 * distance_score + 0.1 * urgency_score`
   - `language_match`: 1.0 if same language, 0.0 otherwise
   - `distance_score`: 1.0 if <500m, linear decay to 0.0 at 5km
   - `urgency_score`: (request.urgency / 5.0)

### Output
- `matches: MatchDoc[]` — stable pairings with scores

---

## Why Gale-Shapley?

- **Stable:** No unmatched pair would prefer each other over current assignments
- **Efficient:** O(n²) in worst case; O(n) typical
- **Fair:** Avoids "greedy" mismatches (e.g., first volunteer doesn't hog all requests)

---

## Language Rule (TDD #1)

**Test case:** Spanish speaker S, English speaker E, and two requests:
- Request R1: Spanish, 100m from S
- Request R2: English, 10m from E

Expected result:
- S → R1 (same language wins despite distance)
- E → R2

**Scoring:**
- S vs R1: 0.7 * 1.0 + 0.2 * 1.0 + 0.1 * 0.5 = 0.95
- S vs R2: 0.7 * 0.0 + 0.2 * 0.99 + 0.1 * 0.5 = 0.298
- E vs R1: 0.7 * 0.0 + 0.2 * 0.98 + 0.1 * 0.5 = 0.246
- E vs R2: 0.7 * 1.0 + 0.2 * 1.0 + 0.1 * 0.5 = 0.95

Result: S prefers R1, E prefers R2 → stable.

---

## Privacy Considerations (TDD #2, owned by C)

- **Coordinates truncated to 2 decimal places** (~1.1 km precision) before matching
- Firestore rules prevent leaking exact locations to non-matched parties
- Matched pairs see exact location only after acceptance

---

## Implementation Files

- **TypeScript:** `functions/src/matching.ts` — Cloud Function
- **Dart wrapper:** `village_app/lib/services/matching_service.dart` — client fallback + result caching
- **Tests:** `village_app/test/matching_test.dart` — TDD #1 verification

---

## Deployment

The algorithm runs in a **Cloud Function** triggered when:
1. A new request is submitted by an elder, OR
2. A volunteer comes online (backend decides when to rerun)

Function returns matches to Firestore; the app reads and displays them.

---

## Future improvements (if time)

- Soft-match on skills (e.g., "tech-help" volunteer with some tech background)
- Time-window matching (only volunteers active in next 2 hours)
- Repeat matching every N minutes if some requests still unmatched
