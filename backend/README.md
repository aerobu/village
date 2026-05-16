# backend/

Cloud Functions code — owned by **B** (matching engine).

> **Note:** Firebase project config (`firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`) lives at the **repo root**, not here. That's the standard Firebase CLI layout — the CLI looks for `firebase.json` in the project root.

## Expected structure (scaffold by B)

```
backend/
└── functions/
    ├── src/
    │   └── matching.ts     # Gale-Shapley Cloud Function (B)
    ├── package.json
    └── tsconfig.json
```

The repo root also contains, after `firebase init`:
```
village/
├── firebase.json
├── .firebaserc            # default project: village-77ccb
├── firestore.rules        # C owns the security rules
└── firestore.indexes.json
```

## Quick start (once B scaffolds functions/)

```bash
cd backend/functions
npm install
npm run build
firebase emulators:start --only functions,firestore
```

See `docs/SETUP.md` for full Firebase setup instructions.
