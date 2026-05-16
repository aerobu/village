/**
 * Gale-Shapley matching algorithm for Village.
 * Pairs volunteers with help requests, prioritizing language match over distance.
 *
 * TDD #1: Language outranks distance
 * A Spanish speaker 100m away beats an English speaker 10m away for a Spanish request.
 *
 * Algorithm: Classic Gale-Shapley stable matching with requests proposing to volunteers.
 * - Stable: No unmatched pair would prefer each other over current assignments
 * - O(n²) proposals worst case, typically O(n log n)
 */

export interface UserPublic {
  id: string;
  name: string;
  language: string; // 'spanish', 'english', 'tagalog', etc.
  latitude: number;
  longitude: number;
  skills: string; // comma-separated
  backgroundCheckVerified: boolean;
}

export interface HelpRequest {
  id: string;
  elderId: string;
  type: string; // 'grocery', 'transportation', 'tech-help', etc.
  language: string;
  latitude: number;
  longitude: number;
  urgency: number; // 1–5
  description: string;
  createdMs: number;
  expiresMs?: number;
}

export interface MatchDoc {
  id: string;
  volunteerId: string;
  requestId: string;
  score: number; // 0.0–1.0
  reason: string;
  createdMs: number;
}

/**
 * Haversine distance in meters between two lat/lng points.
 */
export function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000; // Earth radius in meters
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

/**
 * Compute match score between a volunteer and a request.
 * Formula: 0.7 * language + 0.2 * distance + 0.1 * urgency
 *
 * TDD #1: Language is 70% of the weight. This ensures language match
 * always beats distance. A Spanish speaker 100km away scores ~0.7,
 * while an English speaker 10m away with matching request language ~0.2.
 */
export function computeScore(
  volunteer: UserPublic,
  request: HelpRequest
): { score: number; reason: string } {
  // Language match: 1.0 if same, 0.0 otherwise (binary)
  const languageMatch = volunteer.language === request.language ? 1.0 : 0.0;

  // Distance score: 1.0 if <500m, linear decay to 0.0 at 5km
  const distMeters = haversineDistance(
    volunteer.latitude,
    volunteer.longitude,
    request.latitude,
    request.longitude
  );
  const maxDist = 5000; // 5km
  const distScore = Math.max(0, 1.0 - distMeters / maxDist);

  // Urgency score: 0.0–1.0 based on request urgency (1–5 scale)
  const urgencyScore = request.urgency / 5.0;

  // Weighted formula: language is 70% (critical), distance 20%, urgency 10%
  const score = 0.7 * languageMatch + 0.2 * distScore + 0.1 * urgencyScore;

  // Human-readable explanation
  let reason = "";
  if (languageMatch > 0.5) {
    reason = `${volunteer.language} speaker`;
  } else {
    reason = `language mismatch`;
  }
  reason += `, ${Math.round(distMeters)}m away`;
  reason += `, urgency ${request.urgency}/5`;

  return { score, reason };
}

/**
 * Full Gale-Shapley matching algorithm with rejections.
 *
 * Requests "propose" to volunteers in order of preference.
 * Volunteers accept or reject based on score comparison.
 *
 * Returns a stable matching where no unmatched pair would prefer
 * each other over their current assignments.
 *
 * Process:
 * 1. Build preference lists: for each request, rank all volunteers
 * 2. Requests propose to volunteers in preference order
 * 3. Volunteers accept if free, or reject current match if new is better
 * 4. Repeat until all requests matched or no better matches possible
 */
export function performMatching(
  volunteers: UserPublic[],
  requests: HelpRequest[]
): MatchDoc[] {
  // Edge cases
  if (volunteers.length === 0 || requests.length === 0) {
    return [];
  }

  const now = Date.now();
  const matches = new Map<string, MatchDoc>(); // volunteerId -> MatchDoc

  // Build preference lists: for each request, rank all volunteers by score
  const requestPrefs = new Map<
    string,
    Array<{ volunteerId: string; score: number; reason: string }>
  >();

  for (const request of requests) {
    const ranked = volunteers
      .map((vol) => {
        const { score, reason } = computeScore(vol, request);
        return { volunteerId: vol.id, score, reason };
      })
      .sort((a, b) => b.score - a.score); // highest score first

    requestPrefs.set(request.id, ranked);
  }

  // Track which volunteer is currently matched (volunteerId -> requestId)
  const volunteerMatches = new Map<string, string>();

  // Track proposal index for each request (how far they've proposed)
  const proposalIndices = new Map<string, number>();
  for (const requestId of requests.map((r) => r.id)) {
    proposalIndices.set(requestId, 0);
  }

  // Gale-Shapley: proposals and rejections
  const unmatchedRequests = new Set(requests.map((r) => r.id));
  const maxIterations = requests.length * volunteers.length + 100;
  let iterations = 0;

  while (unmatchedRequests.size > 0 && iterations < maxIterations) {
    iterations++;

    // For each unmatched request, propose to next volunteer on their list
    const requestsToProcess = Array.from(unmatchedRequests);

    for (const requestId of requestsToProcess) {
      const request = requests.find((r) => r.id === requestId)!;
      const prefs = requestPrefs.get(requestId)!;
      const index = proposalIndices.get(requestId) || 0;

      // If no more volunteers to propose to, request stays unmatched
      if (index >= prefs.length) {
        continue;
      }

      const { volunteerId, score, reason } = prefs[index];
      proposalIndices.set(requestId, index + 1);

      // Check if volunteer is free or can be persuaded to switch
      const volunteersCurrentMatch = volunteerMatches.get(volunteerId);

      if (volunteersCurrentMatch === undefined) {
        // Volunteer is free: accept immediately
        volunteerMatches.set(volunteerId, requestId);
        unmatchedRequests.delete(requestId);

        matches.set(volunteerId, {
          id: `${volunteerId}-${requestId}`,
          volunteerId,
          requestId,
          score,
          reason,
          createdMs: now,
        });
      } else {
        // Volunteer is matched to another request.
        // Compute their current match score for comparison.
        const volunteersCurrentRequest = requests.find(
          (r) => r.id === volunteersCurrentMatch
        )!;
        const volunteer = volunteers.find((v) => v.id === volunteerId)!;
        const currentScore = computeScore(volunteer, volunteersCurrentRequest)
          .score;

        if (score > currentScore) {
          // New request is better: reject current match, accept new one
          unmatchedRequests.add(volunteersCurrentMatch); // Current match becomes unmatched
          volunteerMatches.set(volunteerId, requestId);
          unmatchedRequests.delete(requestId);

          matches.set(volunteerId, {
            id: `${volunteerId}-${requestId}`,
            volunteerId,
            requestId,
            score,
            reason,
            createdMs: now,
          });
        }
        // Else: volunteer prefers current match, request must propose to next volunteer
      }
    }
  }

  return Array.from(matches.values());
}

/**
 * Cloud Function HTTP handler.
 *
 * POST /match with body:
 * {
 *   "volunteers": UserPublic[],
 *   "requests": HelpRequest[]
 * }
 *
 * Returns:
 * {
 *   "matches": MatchDoc[]
 * }
 */
export function matchHandler(
  volunteers: UserPublic[],
  requests: HelpRequest[]
): MatchDoc[] {
  return performMatching(volunteers, requests);
}
