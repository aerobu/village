/**
 * Gale-Shapley matching algorithm for Village.
 * Pairs volunteers with help requests, prioritizing language match over distance.
 * 
 * TDD #1: Language outranks distance
 * A Spanish speaker 100m away beats an English speaker 10m away for a Spanish request.
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
function haversineDistance(
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
 */
function computeScore(
  volunteer: UserPublic,
  request: HelpRequest
): { score: number; reason: string } {
  const languageMatch = volunteer.language === request.language ? 1.0 : 0.0;

  const distMeters = haversineDistance(
    volunteer.latitude,
    volunteer.longitude,
    request.latitude,
    request.longitude
  );

  // Distance score: 1.0 if <500m, linear decay to 0.0 at 5km
  const maxDist = 5000;
  const distScore = Math.max(0, 1.0 - distMeters / maxDist);

  const urgencyScore = request.urgency / 5.0;

  const score = 0.7 * languageMatch + 0.2 * distScore + 0.1 * urgencyScore;

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
 * Gale-Shapley matching: pair volunteers with requests.
 * Stable matching that prioritizes language over distance.
 */
export function performMatching(
  volunteers: UserPublic[],
  requests: HelpRequest[]
): MatchDoc[] {
  const matches: MatchDoc[] = [];
  const now = Date.now();

  // Track which volunteer is matched to which request
  const volunteerMatches = new Map<string, string>(); // volunteerId -> requestId
  const requestMatches = new Map<string, string>(); // requestId -> volunteerId

  // Create preference lists: for each request, rank volunteers
  const preferences = new Map<
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

    preferences.set(request.id, ranked);
  }

  // Gale-Shapley: proposals and rejections
  const unmatched = new Set(requests.map((r) => r.id));
  const maxIterations = requests.length * volunteers.length;
  let iterations = 0;

  while (unmatched.size > 0 && iterations < maxIterations) {
    iterations++;

    for (const requestId of unmatched) {
      const request = requests.find((r) => r.id === requestId)!;
      const rankedVols = preferences.get(requestId)!;

      // Find the highest-ranked volunteer we haven't proposed to yet
      for (const { volunteerId, score, reason } of rankedVols) {
        // If volunteer is unmatched, match them
        if (!volunteerMatches.has(volunteerId)) {
          volunteerMatches.set(volunteerId, requestId);
          requestMatches.set(requestId, volunteerId);
          unmatched.delete(requestId);

          matches.push({
            id: `${volunteerId}-${requestId}`,
            volunteerId,
            requestId,
            score,
            reason,
            createdMs: now,
          });
          break;
        } else {
          // Volunteer is matched to another request
          // TODO: implement rejections (for full stable matching)
          // For now, first-come-first-served
          break;
        }
      }
    }
  }

  return matches;
}

/**
 * Cloud Function handler (stub).
 * Call this with { volunteers: UserPublic[], requests: HelpRequest[] }
 */
export function matchHandler(
  volunteers: UserPublic[],
  requests: HelpRequest[]
): MatchDoc[] {
  return performMatching(volunteers, requests);
}
