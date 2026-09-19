# Khetha Go

**GovTech 2026 DHET Hackathon** a Flutter app that helps South African learners work out what to do after school: which careers suit them, which qualifications they can get into, how to fund them, and how to apply.

It runs on **iOS and Android** from one codebase, with a Cupertino-first design and frosted-glass UI.

## What it does

| Area | What the learner can do |
|---|---|
| **Home** | See a personal dashboard and the next best step, based on what they have completed so far. |
| **Explore** | Browse careers, qualifications, universities and TVET colleges, with search and field filters. |
| **Career guidance** | Take the Job Fit and Career Choice quizzes (RIASEC / Holland Codes). Each recommendation explains *why* it was made. |
| **Results and APS** | Enter matric results by hand, or scan a results statement (iOS). The app calculates the Admission Point Score and shows which qualifications are open. |
| **Grade 9 support** | Choose subjects by seeing which careers each combination opens up. |
| **Apply** | Track applications and prepare the documents each one needs. |
| **Support** | NSFAS information, bursaries, tutors, and a searchable Help and FAQ. |
| **Accounts** | Sign up and sign in with Supabase Auth, with an optional PIN and biometric unlock. |
| **Read aloud** | A Listen button on careers, quiz questions, results and help answers, using the phone's own voice. It works offline and can be switched off in Settings. |
| **Languages** | English, isiZulu, isiXhosa, Sesotho and Afrikaans for the interface. Career and qualification records stay in English. |
| **Accessibility** | WCAG AA contrast, Dynamic Type, an in-app text-size slider, support for the phone's Increase Contrast setting, screen-reader labels, and a low-bandwidth mode that turns off blur. |
| **Reminders** | Optional daily reminders scheduled on the device. |

## Tech stack

- **Framework:** Flutter 3.41 / Dart 3.11
- **Platforms:** iOS 15+ and Android
- **UI:** Cupertino widgets plus [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) for the glass effect, with section-aware colour theming and light and dark modes
- **State:** `ChangeNotifier` (`AppState`) shared with an `InheritedNotifier`
- **Backend:** [Supabase](https://supabase.com) (Postgres and Auth) through `supabase_flutter`
- **On-device storage:** `shared_preferences`
- **Device features:** `image_picker`, `file_picker`, `flutter_local_notifications`, `local_auth` (biometrics), `flutter_tts` (read aloud), `url_launcher`
- **Text recognition:** Apple Vision on iOS, through a method channel to Swift. Android currently offers manual results entry.

## Backend and data

The app uses Supabase for two things:

1. **Reference data.** Universities, TVET colleges, programmes, careers, bursaries, subjects, provinces, support resources, tutors and interest questions are read from Postgres tables. The app ships with bundled seed data and falls back to it automatically if the network or database is unavailable, so it keeps working offline.
2. **Accounts.** Sign-up and sign-in use Supabase Auth. A `profiles` row holds the learner's name, email and SA ID number.

The reference-data schema is in [`supabase/schema.sql`](supabase/schema.sql) and [`supabase/migrations/`](supabase/migrations). Row-level security is enabled with public read policies on the reference tables.

> **Note:** the `profiles` table used by sign-up is not yet in the SQL files in this repository. Anyone setting up their own Supabase project needs to create it (with row-level security limited to each user's own row) before sign-up will work.

## Privacy

- Results, applications, documents, quiz answers and app preferences are stored on the device only.
- Scanned results are read on the device and the image is discarded, never uploaded.
- Read aloud uses the phone's speech engine, with no network calls.
- The learner controls what is remembered: consent switches in Settings, a view of everything stored, and a delete-all option.
- Account details (name, email, SA ID number) are stored in Supabase so the learner can sign in.

## Getting started

**Prerequisites:** Flutter 3.41 or newer. For Android, the Android SDK with a device or emulator. For iOS, Xcode on a Mac.

```bash
flutter pub get
flutter run
```

Use `flutter run -d <device-id>` if more than one device is connected (`flutter devices` lists them). For a fair performance check of the glass effects, use `flutter run --profile`.

**Android notes.** The Gradle config enables core library desugaring (needed by `flutter_local_notifications`), and `MainActivity` extends `FlutterFragmentActivity` (needed by `local_auth`). The manifest declares the internet, camera, biometric and notification permissions.

**Supabase.** The project URL and publishable key are set in [`lib/services/supabase_service.dart`](lib/services/supabase_service.dart). To use your own project, replace them and run the SQL in `supabase/`.

## Project structure

```
lib/
  main.dart              App entry, glass initialisation, theming
  screens/               Home, Explore, Apply, Support, Settings, quizzes,
                         results, auth, FAQ, onboarding, detail pages
  data/                  Seed data, RIASEC scoring, career matching,
                         APS and admissions, subject advisor, results parser
  models/                Career, results, funding and application models
  services/              Supabase, notifications, speech, text scanning,
                         ID validation, document verification, applications
  state/                 AppState (preferences, consent, auth, PIN)
  theme/                 Palette, section colours, glass adapters
  widgets/               Page shell, charts, Listen button
  l10n/                  Interface strings in five languages
supabase/                Schema and migrations
android/ ios/            Platform projects (plus web, macOS, Windows, Linux scaffolding)
test/ integration_test/  Unit, widget and integration tests
```

## Testing

```bash
flutter test
```

Tests cover the RIASEC scoring, admissions and APS logic, ID validation, results parsing, the subject advisor, career matching, application flow, section theming and colour contrast, and app navigation. `integration_test/` holds the on-device text scanner test.

## Roadmap

- Android text recognition (Google ML Kit, on-device)
- Move interface strings to `gen_l10n` and extend Read aloud to more screens
- Complete the psychometric assessment: more items and richer career justification text
- Rebuild the Explore filters with a fully reactive filter state
- Add the `profiles` table and its access policies to the repository's SQL
