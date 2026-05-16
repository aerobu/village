/**
 * Comprehensive tests for the Gale-Shapley matching algorithm.
 *
 * Run with: npm test (requires Node.js 18+)
 */

import { strict as assert } from "assert";
import {
  performMatching,
  computeScore,
  haversineDistance,
  UserPublic,
  HelpRequest,
  MatchDoc,
} from "./matching";

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function createVolunteer(
  id: string,
  language: string,
  lat: number,
  lng: number,
  name: string = "Volunteer",
  skills: string = "grocery"
): UserPublic {
  return {
    id,
    name,
    language,
    latitude: lat,
    longitude: lng,
    skills,
    backgroundCheckVerified: true,
  };
}

function createRequest(
  id: string,
  language: string,
  lat: number,
  lng: number,
  type: string = "grocery",
  urgency: number = 3,
  elderId: string = "e1"
): HelpRequest {
  return {
    id,
    elderId,
    type,
    language,
    latitude: lat,
    longitude: lng,
    urgency,
    description: `Request ${id}`,
    createdMs: Date.now(),
  };
}

// ============================================================================
// TDD #1: Language Priority Tests
// ============================================================================

console.log("Running TDD #1: Language Priority Tests\n");

{
  // Test 1.1: Spanish speaker 100m away beats English speaker 10m away
  const spanish = createVolunteer("v_spanish", "spanish", 10.0, 20.0);
  const english = createVolunteer("v_english", "english", 10.0008, 20.0); // ~100m away

  const spanishReq = createRequest("r_spanish", "spanish", 10.0, 20.0);
  const englishReq = createRequest("r_english", "english", 10.0008, 20.0);

  const scoreSpanishToSpanish = computeScore(spanish, spanishReq).score;
  const scoreSpanishToEnglish = computeScore(spanish, englishReq).score;

  assert(
    scoreSpanishToSpanish > scoreSpanishToEnglish,
    `Spanish volunteer should prefer Spanish request: ${scoreSpanishToSpanish} > ${scoreSpanishToEnglish}`
  );
  assert(
    scoreSpanishToSpanish > 0.6,
    `Spanish match should score >0.6: got ${scoreSpanishToSpanish}`
  );
  assert(
    scoreSpanishToEnglish < 0.4,
    `Language mismatch should score <0.4: got ${scoreSpanishToEnglish}`
  );

  console.log("✓ Test 1.1: Language beats distance");
}

{
  // Test 1.2: Matching algorithm produces language-first pairings
  const spanish = createVolunteer("v_spanish", "spanish", 10.0, 20.0, "Maria");
  const english = createVolunteer("v_english", "english", 10.1, 20.1, "Bob");

  const spanishReq = createRequest("r_spanish", "spanish", 10.0, 20.0);
  const englishReq = createRequest("r_english", "english", 10.05, 20.05);

  const matches = performMatching([spanish, english], [spanishReq, englishReq]);

  const spanishMatch = matches.find(
    (m) => m.volunteerId === "v_spanish" && m.requestId === "r_spanish"
  );
  const englishMatch = matches.find(
    (m) => m.volunteerId === "v_english" && m.requestId === "r_english"
  );

  assert(
    spanishMatch !== undefined,
    "Expected Spanish volunteer matched to Spanish request"
  );
  assert(
    englishMatch !== undefined,
    "Expected English volunteer matched to English request"
  );
  assert(
    spanishMatch!.score > 0.6,
    `Spanish match score should be >0.6: got ${spanishMatch!.score}`
  );

  console.log("✓ Test 1.2: Algorithm produces language-first pairings");
}

// ============================================================================
// DISTANCE TESTS
// ============================================================================

console.log("\nRunning Distance Tests\n");

{
  // Test 2.1: Haversine distance calculation
  const dist = haversineDistance(0, 0, 0, 1);
  // At equator, 1 degree of longitude ≈ 111km
  const expectedDist = 111000;
  assert(
    Math.abs(dist - expectedDist) < 5000,
    `Distance should be ~111km: got ${dist}m`
  );

  console.log(
    `✓ Test 2.1: Haversine distance correct (expected ~111km, got ${Math.round(dist / 1000)}km)`
  );
}

{
  // Test 2.2: Distance decay (1.0 at <500m, 0.0 at 5km)
  const close = createVolunteer("v1", "english", 10.0, 20.0);
  const far = createVolunteer("v2", "english", 10.05, 20.0); // ~5.5km away
  const req = createRequest("r1", "english", 10.0, 20.0);

  const closeScore = computeScore(close, req).score;
  const farScore = computeScore(far, req).score;

  assert(closeScore > farScore, "Close volunteer should score higher");
  assert(
    Math.abs(closeScore - 0.8) < 0.1,
    `Close score should be ~0.8 (language 0.7 + distance 0.1): got ${closeScore}`
  ); // All same language

  console.log("✓ Test 2.2: Distance decay works correctly");
}

// ============================================================================
// URGENCY TESTS
// ============================================================================

console.log("\nRunning Urgency Tests\n");

{
  // Test 3.1: Urgent requests score higher
  const vol = createVolunteer("v1", "english", 10.0, 20.0);
  const lowUrgency = createRequest("r1", "english", 10.0, 20.0, "grocery", 1);
  const highUrgency = createRequest("r2", "english", 10.0, 20.0, "grocery", 5);

  const lowScore = computeScore(vol, lowUrgency).score;
  const highScore = computeScore(vol, highUrgency).score;

  assert(
    highScore > lowScore,
    `High urgency should score higher: ${highScore} > ${lowScore}`
  );
  assert(
    highScore - lowScore === 0.08,
    "Difference should be 0.08 (0.1 * (5-1)/5)"
  );

  console.log("✓ Test 3.1: Urgency scoring works");
}

// ============================================================================
// GALE-SHAPLEY STABILITY TESTS
// ============================================================================

console.log("\nRunning Gale-Shapley Stability Tests\n");

{
  // Test 4.1: No unmatched volunteer-request pair would prefer each other
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0, "Maria");
  const v2 = createVolunteer("v2", "english", 10.1, 20.1, "Bob");
  const r1 = createRequest("r1", "spanish", 10.0, 20.0);
  const r2 = createRequest("r2", "english", 10.05, 20.05);

  const matches = performMatching([v1, v2], [r1, r2]);

  // Verify no blocking pairs
  for (const match of matches) {
    const volunteer = [v1, v2].find((v) => v.id === match.volunteerId)!;
    const request = [r1, r2].find((r) => r.id === match.requestId)!;

    // For each other request, volunteer should prefer their current match
    const otherRequests = [r1, r2].filter((r) => r.id !== request.id);
    for (const other of otherRequests) {
      const currentScore = computeScore(volunteer, request).score;
      const alternativeScore = computeScore(volunteer, other).score;
      assert(
        currentScore >= alternativeScore,
        `Volunteer should prefer current match`
      );
    }
  }

  console.log("✓ Test 4.1: Matching is stable (no blocking pairs)");
}

{
  // Test 4.2: Rejections work correctly
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const v2 = createVolunteer("v2", "english", 10.0, 20.0);

  const r1 = createRequest("r1", "spanish", 10.0, 20.0, "grocery", 5); // High urgency Spanish
  const r2 = createRequest("r2", "spanish", 10.0, 20.0, "grocery", 1); // Low urgency Spanish

  const matches = performMatching([v1, v2], [r1, r2]);

  // v1 (Spanish) should prefer r1 (high urgency Spanish) over r2 (low urgency Spanish)
  const v1Match = matches.find((m) => m.volunteerId === "v1")!;
  assert(
    v1Match.requestId === "r1",
    "Spanish volunteer should match high urgency Spanish request"
  );

  console.log("✓ Test 4.2: Rejections prioritize higher quality matches");
}

// ============================================================================
// EDGE CASE TESTS
// ============================================================================

console.log("\nRunning Edge Case Tests\n");

{
  // Test 5.1: No volunteers returns empty matches
  const req = createRequest("r1", "spanish", 10.0, 20.0);
  const matches = performMatching([], [req]);
  assert(matches.length === 0, "Should return empty matches");
  console.log("✓ Test 5.1: No volunteers → empty matches");
}

{
  // Test 5.2: No requests returns empty matches
  const vol = createVolunteer("v1", "spanish", 10.0, 20.0);
  const matches = performMatching([vol], []);
  assert(matches.length === 0, "Should return empty matches");
  console.log("✓ Test 5.2: No requests → empty matches");
}

{
  // Test 5.3: More volunteers than requests
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const v2 = createVolunteer("v2", "english", 10.0, 20.0);
  const v3 = createVolunteer("v3", "tagalog", 10.0, 20.0);
  const r1 = createRequest("r1", "spanish", 10.0, 20.0);

  const matches = performMatching([v1, v2, v3], [r1]);
  assert(matches.length === 1, "Should have 1 match");
  assert(matches[0].volunteerId === "v1", "Spanish volunteer should match");
  console.log("✓ Test 5.3: More volunteers than requests");
}

{
  // Test 5.4: More requests than volunteers
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const r1 = createRequest("r1", "spanish", 10.0, 20.0);
  const r2 = createRequest("r2", "english", 10.0, 20.0);

  const matches = performMatching([v1], [r1, r2]);
  assert(matches.length === 1, "Should have 1 match");
  console.log("✓ Test 5.4: More requests than volunteers");
}

{
  // Test 5.5: All requests same language
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const v2 = createVolunteer("v2", "spanish", 10.1, 20.1);
  const r1 = createRequest("r1", "spanish", 10.0, 20.0, "grocery", 5);
  const r2 = createRequest("r2", "spanish", 10.05, 20.05, "grocery", 1);

  const matches = performMatching([v1, v2], [r1, r2]);
  assert(matches.length === 2, "Should match both");

  // Higher urgency should get matched to closer/more preferred volunteer
  const r1Match = matches.find((m) => m.requestId === "r1")!;
  const r2Match = matches.find((m) => m.requestId === "r2")!;
  assert(r1Match.score > r2Match.score, "High urgency should have better score");
  console.log("✓ Test 5.5: All same language → priority by urgency/distance");
}

{
  // Test 5.6: Language mismatch for all
  const v1 = createVolunteer("v1", "spanish", 10.0, 20.0);
  const r1 = createRequest("r1", "english", 10.0, 20.0);

  const match = computeScore(v1, r1);
  assert(match.score > 0, "Should still have a score (0.2 distance + 0.1 urgency)");
  assert(match.score < 0.4, "Should be low (no language match)");
  console.log(
    "✓ Test 5.6: Language mismatch still produces matches at lower score"
  );
}

// ============================================================================
// SUMMARY
// ============================================================================

console.log("\n" + "=".repeat(70));
console.log("✅ ALL TESTS PASSED");
console.log("=".repeat(70));
console.log("\nTests run:");
console.log("  - TDD #1: Language priority (2 tests)");
console.log("  - Distance calculations (2 tests)");
console.log("  - Urgency weighting (1 test)");
console.log("  - Gale-Shapley stability (2 tests)");
console.log("  - Edge cases (5 tests)");
console.log("\nTotal: 12 tests");
