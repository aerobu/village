# Hackathon Project Blueprint: Elder Community Connection App

## Document 1: Product Requirements Document (PRD)

### 1. Objective
To build a scalable, visually impressive application that connects older immigrants (initially focusing on the Indian demographic) with trusted volunteers for assistance with daily tasks, companionship, and errands.

### 2. Core Features
* **User Profiles:** Dual-sided profiles for "Elders" and "Volunteers" emphasizing language fluency, location, and specific needs/skills.
* **Real-Time Request System:** "Uber-style" request ping indicating need type (e.g., Groceries), preferred language (e.g., Tamil), and general location.
* **Visual Map Interface:** High-fidelity, smooth mapping interface showing nearby volunteers or request hotspots.
* **Proof of Visit / Social Credit:** Post-meeting photo capture and social sharing integration to build community trust and gamify volunteer motivation.
* **Safety & Privacy:**
    * Simulated Volunteer Background Checks.
    * Prominent "Report User" functionality.
    * Location masking (showing general vicinity rather than precise address until a match is confirmed).

---

## Document 2: System Architecture

### 1. High-Level Architecture
An event-driven, serverless architecture optimized for real-time state synchronization and rapid prototyping.

* **Frontend Client:** Flutter or React Native for high-performance cross-platform rendering and fluid map animations.
* **Backend / Database:** Firebase (Cloud Firestore & Firebase Auth) for real-time document synchronization and user state management.
* **Matching Engine:** Cloud Functions for Firebase running a customized Gale-Shapley stable matching algorithm.

### 2. Privacy & Security Protocols
* **Data Segregation:** Personally Identifiable Information (PII) stored in isolated, highly restricted Firestore collections. Public profiles contain only anonymized or generalized data.
* **End-to-End Encryption:** Applied to in-transit messaging between matched users.
* **Audit Trails:** Administrative logging tied to the "Report User" mechanism.

---

## Document 3: Build Stages (The 3-Hour Hackathon Plan)

* **Sprint 1: Scaffolding & Setup (Minutes 0 - 30)**
    * Initialize Flutter/React Native project.
    * Configure Firebase/Firestore backend connections.
    * Set up MapLibre/Leaflet map rendering foundation.
* **Sprint 2: The Core Visuals (Minutes 30 - 90)**
    * Implement map visualizations (custom markers, pulsing animations for volunteers).
    * Build out the Request Form UI and Profile screens.
* **Sprint 3: The Matching Logic (Minutes 90 - 130)**
    * Write the simplified Gale-Shapley matching function (taking language, distance, and rating into account).
    * Connect the "Submit Request" button to the simulated match response.
* **Sprint 4: Safety & Social "Wow" Factors (Minutes 130 - 160)**
    * Build the fake "Background Check Approved" UI element.
    * Build the "Proof of Visit" post-match screen with a hardcoded sample selfie and social share buttons.
* **Sprint 5: Demo Polish (Minutes 160 - 180)**
    * Finalize hardcoded coordinates and timing.
    * Rehearse the exact click-path. Remove any buggy edge cases from the UI.

---

## Document 4: Tech Stack & Implementation Guide

### Recommended Stack
* **UI/Frontend:** Flutter (Dart). Best for rapid UI layout and smooth, 60fps animations which judges love.
* **Mapping:** MapLibre GL JS or flutter_map. Allows custom styling (dark mode, custom pulsing markers) without heavy API costs.
* **Backend Logic:** Python (for the matching script) or Node.js running on Firebase Cloud Functions.
* **Database:** Firebase Firestore.

### What to Build vs. What to Hardcode
* **Build Live:** The map rendering, the request form, the UI transitions, and the basic Gale-Shapley matching array logic.
* **Hardcode for the Demo:**
    * *Volunteer Locations:* Pre-populate 5-6 dummy volunteer coordinates on the map.
    * *The Match Acceptance:* Don't try to build a 2-device demo. Hardcode a 3-second delay after submitting a request that automatically triggers a pop-up: "Volunteer [Name] has accepted! They speak Tamil and are 5 mins away."
    * *Background Check:* A simple UI badge that says "Check Passed" rather than a real API call.
    * *Social Credit Photo:* Hardcode a wholesome stock photo of an elder and volunteer smiling together that appears when you click "Complete Visit."

---

## Document 5: Test-Driven Development (TDD) Plan

* **Test 1: Algorithm Integrity:** Given a mock array of 3 volunteers and 1 elder with strict language requirements (Tamil), assert that the algorithm prioritizes the language match over the closest geographic match.
* **Test 2: Privacy Masking:** Assert that the coordinate data exposed to the frontend prior to a match being accepted is truncated to 2 decimal places (approx. 1km radius) rather than exact coordinates.
* **Test 3: Event Firing:** Assert that submitting a request successfully writes to the Firestore "Requests" collection, triggering the Cloud Function.

---

## Document 6: End-to-End Demo Workflow (Pitch Script)

1.  **The Hook (1 Min):** Explain the problem—isolation among aging immigrant populations. Introduce the app as a safe, culturally aware community bridge.
2.  **The Safety Primer (30 Secs):** Show the volunteer profile screen. Point out the "Background Check Validated" badge and explain the location masking.
3.  **The Core Workflow (1.5 Mins):**
    * *Action:* Open the app from the Elder's perspective.
    * *Visual:* The screen shows a beautiful map with glowing, generalized dots representing nearby help.
    * *Action:* Fill out the request: "Need groceries. Must speak Tamil." Click Find Match.
    * *Action:* Explain the Gale-Shapley matching happening in the background.
    * *Visual:* A customized alert pops up with a volunteer's profile: "Matched! They are on their way."
4.  **The Social Credit "Wow" Moment (1 Min):**
    * *Action:* Fast forward to the end of the meeting. Click "Complete Task."
    * *Visual:* The screen shows the "Proof of Visit" page with a photo of the two individuals.
    * *Action:* Explain how this builds community trust and gamifies the experience, showing the button to share to Facebook/Instagram.
5.  **Closing:** Summarize the tech stack and open for Q&A.
