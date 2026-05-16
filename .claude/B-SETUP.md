# B's Setup Checklist

## ✅ Done

- [x] Created conda environment `village` with Python 3.11, Node.js 20.17.0, npm 10.8.2
- [x] Created branch `feat/B-matching` (currently checked out)
- [x] Latest docs pulled (TRUNK_DEV.md, updated OWNERSHIP.md)

## 🚀 Next steps (wait for A)

**A (arnewiseman) must scaffold the Flutter app first.** Your work depends on the models and directory structure they create.

Once A has merged the app scaffold to `main`:

1. **Rebase your branch:**
   ```bash
   git pull --rebase origin main
   ```

2. **Install Flutter dependencies:**
   ```bash
   cd village_app
   flutter pub get
   ```

3. **Install Firebase emulator (for local testing):**
   ```bash
   eval "$(conda shell.bash hook)" && conda activate village
   cd functions
   npm install
   npm run build
   firebase emulators:start --only functions,firestore
   ```
   (in a separate terminal)

4. **Run tests to verify setup:**
   ```bash
   cd village_app
   flutter test
   ```

## Your files to write

Per OWNERSHIP.md:
- `village_app/lib/screens/request_form.dart`
- `village_app/lib/services/matching_service.dart`
- `village_app/lib/services/firestore_service.dart`
- `village_app/lib/models/` (co-own with A initially, but you define the data structures)
- `functions/src/matching.ts` (Gale-Shapley implementation)
- `village_app/test/matching_test.dart` (TDD #1: language outranks distance)

## TDD rule for your slice

**TDD #1: Language outranks distance**

Before writing the matching engine, your test must verify:
- A request in Spanish, 100 meters away
- A request in English, 10 meters away
→ The Spanish match should win despite distance

Test file: `village_app/test/matching_test.dart`

## Branch strategy

You're on **trunk-based workflow** (read `TRUNK_DEV.md`):
- Rebase before every push
- `flutter test` must pass
- Announce in Discord `#dev` before touching shared files
- Push directly to `main` (no PR gate)

---

**When A posts "scaffold ready", rebase this branch and start coding!**
