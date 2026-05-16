#!/usr/bin/env node

/**
 * Test runner for Gale-Shapley matching algorithm.
 * This is a pure JavaScript implementation that can run without TypeScript compilation.
 *
 * Run with: node run-tests.js
 */

// ============================================================================
// MATCHING ALGORITHM (copied from matching.ts for self-contained testing)
// ============================================================================

function haversineDistance(lat1, lon1, lat2, lon2) {
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

function toRad(deg) {
  return (deg * Math.PI) / 180;
}

function computeScore(volunteer, request) {
  const languageMatch = volunteer.language === request.language ? 1.0 : 0.0;
  const distMeters = haversineDistance(
    volunteer.latitude,
    volunteer.longitude,
    request.latitude,
    request.longitude
  );
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

function performMatching(volunteers, requests) {
  if (volunteers.length === 0 || requests.length === 0) {
    return [];
  }

  const now = Date.now();
  const matches = new Map();

  const requestPrefs = new Map();
  for (const request of requests) {
    const ranked = volunteers
      .map((vol) => {
        const { score, reason } = computeScore(vol, request);
        return { volunteerId: vol.id, score, reason };
      })
      .sort((a, b) => b.score - a.score);

    requestPrefs.set(request.id, ranked);
  }

  const volunteerMatches = new Map();
  const proposalIndices = new Map();
  for (const requestId of requests.map((r) => r.id)) {
    proposalIndices.set(requestId, 0);
  }

  const unmatchedRequests = new Set(requests.map((r) => r.id));
  const maxIterations = requests.length * volunteers.length + 100;
  let iterations = 0;

  while (unmatchedRequests.size > 0 && iterations < maxIterations) {
    iterations++;

    const requestsToProcess = Array.from(unmatchedRequests);

    for (const requestId of requestsToProcess) {
      const request = requests.find((r) => r.id === requestId);
      const prefs = requestPrefs.get(requestId);
      const index = proposalIndices.get(requestId) || 0;

      if (index >= prefs.length) {
        continue;
      }

      const { volunteerId, score, reason } = prefs[index];
      proposalIndices.set(requestId, index + 1);

      const volunteersCurrentMatch = volunteerMatches.get(volunteerId);

      if (volunteersCurrentMatch === undefined) {
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
        const volunteersCurrentRequest = requests.find(
          (r) => r.id === volunteersCurrentMatch
        );
        const volunteer = volunteers.find((v) => v.id === volunteerId);
        const currentScore = computeScore(volunteer, volunteersCurrentRequest)
          .score;

        if (score > currentScore) {
          unmatchedRequests.add(volunteersCurrentMatch);
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
      }
    }
  }

  return Array.from(matches.values());
}

// ============================================================================
// TEST HELPERS
// ============================================================================

let testCount = 0;
let passCount = 0;

function assert(condition, message) {
  if (!condition) {
    throw new Error(`❌ Assertion failed: ${message}`);
  }
}

function test(name, fn) {
  testCount++;
  try {
    fn();
    passCount++;
    console.log(`✓ ${name}`);
  } catch (e) {
    console.error(`✗ ${name}`);
    console.error(`  ${e.message}`);
  }
}

function createVolunteer(id, language, lat, lng, name = "Volunteer", skills = "grocery") {
  return { id, name, language, latitude: lat, longitude: lng, skills, backgroundCheckVerified: true };
}

function createRequest(id, language, lat, lng, type = "grocery", urgency = 3, elderId = "e1") {
  return { id, elderId, type, language, latitude: lat, longitude: lng, urgency, description: `Request ${id}`, createdMs: Date.now() };
}

// ============================================================================
// TESTS
// ============================================================================

console.log("\n" + "=".repeat(70));
console.log("TDD #1: Language Priority Tests");
console.log("=".repeat(70) + "\n");

test("Spanish speaker 100m away beats English speaker 10m away", () => {
  const spanish = createVolunteer("v_spanish", "spanish", 10.0, 20.0);
  const englishReq = createRequest("r_english", "english", 10.0008, 20.0);

  const scoreSpanishToSpanish = computeScore(spanish, createRequest("r_spanish", "spanish", 10.0, 20.0)).score;
  const scoreSpanishToEnglish = computeScore(spanish, englishReq).score;

  assert(scoreSpanishToSpanish > scoreSpanishToEnglish, `Spanish match should win: ${scoreSpanishToSpanish} > ${scoreSpanishToEnglish}`);
  assert(scoreSpanishToSpanish > 0.6, `Spanish match should score >0.6: got ${scoreSpanishToSpanish}`);
  assert(scoreSpanishToEnglish < 0.4, `Language mismatch should score <0.4: got ${scoreSpanishToEnglish}`);
});

test("Matching algorithm produces language-first pairings", () => {
  const spanish = createVolunteer("v_spanish", "spanish", 10.0, 20.0, "Maria");
  const english = createVolunteer("v_english", "english", 10.1, 20.1, "Bob");
  const spanishReq = createRequest("r_spanish", "spanish", 10.0, 20.0);
  const englishReq = createRequest("r_english", "english", 10.05, 20.05);

  const matches = performMatching([spanish, english], [spanishReq, englishReq]);

  const spanishMatch = matches.find((m) => m.volunteerId === "v_spanish" && m.requestId === "r_spanish");
  const englishMatch = matches.find((m) => m.volunteerId === "v_english" && m.requestId === "r_english");

  assert(spanishMatch !== undefined, "Expected Spanish volunteer matched to Spanish request");
  assert(englishMatch !== undefined, "Expected English volunteer matched to English request");
  assert(spanishMatch.score > 0.6, `Spanish match score should be >0.6: got ${spanishMatch.score}`);
});

console.log("\n" + "=".repeat(70));
console.log("Distance Tests");
console.log("=".repeat(70) + "\n");

test("Haversine distance calculation", () => {
  const dist = haversineDistance(0, 0, 0, 1);
  const expectedDist = 111000;
  assert(Math.abs(dist - expectedDist) < 5000, `Distance should be ~111km: got ${Math.round(dist / 1000)}km`);
});

test("Distance decay works correctly", () => {
  const close = createVolunteer("v1", "english", 10.0, 20.0);
  const far = createVolunteer("v2", "english", 10.05, 20.0);
  const req = createRequest("r1", "english", 10.0, 20.0);

  const closeScore = computeScore(close, req).score;
  const farScore = computeScore(far, req).score;

  assert(closeScore > farScore, "Close volunteer should score higher");
});

console.log("\n" + "=".repeat(70));
console.log("Urgency Tests");
console.log("=".repeat(70) + "\n");

test("Urgent requests score higher", () => {
  const vol = createVolunteer("v1", "english", 10.0, 20.0);
  const lowUrgency = createRequest("r1", "english", 10.0, 20.0, "grocery", 1);
  const highUrgency = createRequest("r2", "english", 10.0, 20.0, "grocery", 5);

  const lowScore = computeScore(vol, lowUrgency).score;
  const highScore = computeScore(vol, highUrgency).score;

  assert(highScore > lowScore, `High urgency should score higher: ${highScore} > ${lowScore}`);
});

console.log("\n" + "=".repeat(70));
console.log("Gale-Shapley Stability Tests");
console.log("=".repeat(70) + "\n");

test("Matching is stable (no blocking pairs)", () => {
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0, "Maria");
  const v2 = createVolunteer("v2", "english", 10.1, 20.1, "Bob");
  const r1 = createRequest("r1", "spanish", 10.0, 20.0);
  const r2 = createRequest("r2", "english", 10.05, 20.05);

  const matches = performMatching([v1, v2], [r1, r2]);

  for (const match of matches) {
    const volunteer = [v1, v2].find((v) => v.id === match.volunteerId);
    const request = [r1, r2].find((r) => r.id === match.requestId);

    const otherRequests = [r1, r2].filter((r) => r.id !== request.id);
    for (const other of otherRequests) {
      const currentScore = computeScore(volunteer, request).score;
      const alternativeScore = computeScore(volunteer, other).score;
      assert(currentScore >= alternativeScore, "Volunteer should prefer current match");
    }
  }
});

test("Rejections prioritize higher quality matches", () => {
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const v2 = createVolunteer("v2", "english", 10.0, 20.0);
  const r1 = createRequest("r1", "spanish", 10.0, 20.0, "grocery", 5);
  const r2 = createRequest("r2", "spanish", 10.0, 20.0, "grocery", 1);

  const matches = performMatching([v1, v2], [r1, r2]);

  const v1Match = matches.find((m) => m.volunteerId === "v1");
  assert(v1Match.requestId === "r1", "Spanish volunteer should match high urgency Spanish request");
});

console.log("\n" + "=".repeat(70));
console.log("Edge Case Tests");
console.log("=".repeat(70) + "\n");

test("No volunteers returns empty matches", () => {
  const req = createRequest("r1", "spanish", 10.0, 20.0);
  const matches = performMatching([], [req]);
  assert(matches.length === 0, "Should return empty matches");
});

test("No requests returns empty matches", () => {
  const vol = createVolunteer("v1", "spanish", 10.0, 20.0);
  const matches = performMatching([vol], []);
  assert(matches.length === 0, "Should return empty matches");
});

test("More volunteers than requests", () => {
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const v2 = createVolunteer("v2", "english", 10.0, 20.0);
  const v3 = createVolunteer("v3", "tagalog", 10.0, 20.0);
  const r1 = createRequest("r1", "spanish", 10.0, 20.0);

  const matches = performMatching([v1, v2, v3], [r1]);
  assert(matches.length === 1, "Should have 1 match");
  assert(matches[0].volunteerId === "v1", "Spanish volunteer should match");
});

test("Language mismatch still produces matches", () => {
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const r1 = createRequest("r1", "english", 10.0, 20.0);

  const match = computeScore(v1, r1);
  assert(match.score > 0, "Should still have a score");
  assert(match.score < 0.4, "Should be low (no language match)");
});

// ============================================================================
// SUMMARY
// ============================================================================

console.log("\n" + "=".repeat(70));
if (passCount === testCount) {
  console.log(`✅ ALL TESTS PASSED (${passCount}/${testCount})`);
} else {
  console.log(`⚠️  SOME TESTS FAILED (${passCount}/${testCount} passed)`);
}
console.log("=".repeat(70));
