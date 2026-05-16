# backend/

Cloud Functions + Firebase config — owned by **B** (matching engine) and **C** (Firestore rules).

## Expected structure (scaffold by B)

```
backend/
├── functions/
│   ├── src/
│   │   └── matching.ts     # Gale-Shapley Cloud Function (B)
│   ├── package.json
│   └── tsconfig.json
├── firebase.json
├── .firebaserc
├── firestore.rules          # C owns
└── firestore.indexes.json
```

## Quick start (once B scaffolds)

```bash
cd backend/functions
npm install
npm run build
firebase emulators:start --only functions,firestore
```

See `docs/SETUP.md` for full Firebase setup instructions.
