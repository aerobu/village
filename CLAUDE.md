# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository status

Pre-code: the repo currently contains only `project.md`, a hackathon blueprint. No project has been scaffolded, no dependencies installed, no build/lint/test commands exist yet. The first implementation session will need to scaffold the chosen stack before any of the architecture notes below apply.

## Project context

"village" — a hackathon app connecting older immigrants (initial focus: Indian demographic) with volunteers for errands and companionship. The full PRD, demo script, and TDD plan live in `project.md` — read it before making product decisions.

This is a **3-hour hackathon build**, not a production app. That constraint drives most architecture choices: optimize for visual polish and a working demo path, not generality.

## Intended architecture

- **Frontend:** Flutter (preferred for 60fps animations) or React Native
- **Mapping:** MapLibre GL JS / `flutter_map` — custom styling, pulsing markers, no paid API
- **Backend:** Firebase Cloud Functions (Python or Node) + Firestore for real-time sync + Firebase Auth
- **Matching:** Simplified Gale-Shapley algorithm weighing language, distance, rating — language match must outrank proximity

### Privacy invariants (enforce in code)
- Coordinates exposed to the frontend before a match is accepted are **truncated to 2 decimal places** (~1km radius). Precise coordinates are revealed only post-match.
- PII lives in isolated Firestore collections with strict rules; public profile docs hold only generalized/anonymized fields.

## Build-vs-hardcode policy

The blueprint deliberately hardcodes anything that doesn't demo well live. Respect these choices unless the user changes scope:

- **Build live:** map rendering, request form, UI transitions, Gale-Shapley array logic
- **Hardcode:** 5–6 dummy volunteer coordinates, a 3-second timer that fakes match acceptance, the "Background Check Passed" badge, the post-visit selfie photo

Do not invest time wiring a real second-device match flow, real background-check API, or real photo capture — the demo script in `project.md` §6 assumes the hardcoded versions.

## TDD targets

Three tests are specified in `project.md` §5 and should exist once the code is scaffolded:
1. Matching algorithm prioritizes language over distance
2. Pre-match coordinates are truncated to 2 decimal places
3. Submitting a request writes to the Firestore `Requests` collection (triggers the Cloud Function)
