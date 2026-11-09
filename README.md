# ExpenseFlow

**ExpenseFlow** is a private, offline-first expense tracker built with Flutter. Track daily spending, manage budgets and ask an on-device AI assistant about your money: your data stays encrypted on your phone and the AI never sends it to a server.

## Features

- **Smart Expense Tracking** - Add expenses in seconds with categories, merchant, payment method (Cash, Card, UPI, Bank Transfer) and notes
- **Recurring Expenses** - Mark rent, EMIs or subscriptions as daily, weekly, monthly or yearly and they are logged automatically
- **Voice Entry** - Say "चहा 20 रुपये" or "petrol 500 cash" in English, Hindi or Marathi; recognised on-device and parsed into the form
- **Tax Tagging** - Tag 80C / 80D / HRA / 80G / 80E expenses and see a yearly deduction summary with statutory caps
- **Statements & Export** - Monthly PDF statement and Excel-ready CSV export, generated on the phone
- **Multi-currency** - Enter amounts in INR, USD, EUR or GBP; the original amount and exchange rate are kept with each expense
- **Budget Management** - Monthly, quarterly or yearly limits per category, pace alerts, and rollover (carry forward or move unspent money into a savings goal)
- **Receipt Scanning** - Photograph a bill; on-device OCR fills in the total, merchant, date, GST and line items
- **Events & Trips** - Temporary budgets for Diwali, weddings or trips, with trip mode in the trip's own currency
- **Envelope Budgeting** - Optional zero-based mode: give every rupee of income a job and move money between envelopes
- **Shared Budgets & Splits** - Household, roommate or trip groups with a shared budget, equal/custom splits and settle-up suggestions
- **Home Screen Widget** - "Safe to spend today" with one-tap quick add (Android and iOS)
- **Year in Review** - A shareable, on-device "Wrapped" of your spending year
- **On-device AI Assistant** - Chat about your spending with an LLM running locally, grounded in your own data via on-device embeddings (MiniLM + TensorFlow Lite) and a quantised vector index; answers include charts when useful
- **Encrypted at Rest** - All local data is AES-256 encrypted, with the key held in the Android Keystore / iOS Keychain
- **App Lock** - Optional fingerprint, face or device PIN lock
- **Offline First + Cloud Sync** - Works fully offline; syncs to Cloud Firestore when connected, with conflict handling
- **Notifications** - Budget alerts, AI-written weekly digest, bill/EMI reminders, logging reminders at your usual time, actionable "payment detected" notifications and push
- **Multi-language** - English, Hindi and Marathi
- **Neumorphic Design** - Custom soft-UI widgets with light and dark themes

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (stable channel)
- **Architecture:** Clean Architecture (data / domain / presentation per feature)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Dependency Injection:** [get_it](https://pub.dev/packages/get_it)
- **Routing:** [go_router](https://pub.dev/packages/go_router)
- **Local Storage:** [Hive](https://pub.dev/packages/hive) (AES-encrypted boxes) + [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) for the key
- **Security:** [local_auth](https://pub.dev/packages/local_auth) for app lock
- **Backend:** [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore, Cloud Messaging)
- **Networking:** [Dio](https://pub.dev/packages/dio) + [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- **AI/ML:** [flutter_gemma](https://pub.dev/packages/flutter_gemma) + [tflite_flutter](https://pub.dev/packages/tflite_flutter)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
- **Notifications:** [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) + [timezone](https://pub.dev/packages/timezone)
- **UI:** [flutter_animate](https://pub.dev/packages/flutter_animate), [google_fonts](https://pub.dev/packages/google_fonts), [flutter_svg](https://pub.dev/packages/flutter_svg), [flutter_screenutil](https://pub.dev/packages/flutter_screenutil)
- **Internationalization:** `flutter_localizations` + `intl` (gen-l10n)
- **Testing:** `flutter_test` + [mocktail](https://pub.dev/packages/mocktail)

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install), latest stable (Dart SDK `^3.12.2`, see `pubspec.yaml`)
- Android Studio or Xcode, plus an emulator or device
- A Firebase project

### Installation

1. **Clone the repository:**

```bash
git clone https://github.com/Amrut-03/expense_flow_app.git
cd expense_flow_app
```

2. **Install dependencies:**

```bash
flutter pub get
```

3. **Create a `.env` file** in the project root (it is git-ignored and bundled as an asset). Keys read by the app:

```env
API_BASE_URL=
GOOGLE_SERVER_CLIENT_ID=
FIREBASE_PROJECT_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_API_KEY_ANDROID=
FIREBASE_APP_ID_ANDROID=
FIREBASE_ANDROID_CLIENT_ID=
FIREBASE_API_KEY_IOS=
FIREBASE_APP_ID_IOS=
FIREBASE_IOS_CLIENT_ID=
FIREBASE_IOS_BUNDLE_ID=
```

4. **Set up Firebase:**
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`
   - Place `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
   - Deploy the security rules: `firebase deploy --only firestore:rules`

5. **Run code generation** (Hive adapters, JSON models):

```bash
dart run build_runner build --delete-conflicting-outputs
```

6. **Run the app:**

```bash
flutter run
```

## Project Structure

```
lib/
├── core/              # DI, router, theme, shared widgets, networking, errors,
│                      # notifications, push, logging, encrypted storage
├── features/
│   ├── ai/            # On-device AI assistant (Gemma, embeddings, retrieval, safety)
│   ├── app_lock/      # Biometric / device-PIN app lock
│   ├── auth/          # Email and Google sign-in
│   ├── budget/        # Budget limits and sync
│   ├── categories/    # Per-category transaction views
│   ├── currency/      # Currency selection and exchange rates
│   ├── dashboard/     # Spending overview and charts
│   ├── expense/       # Add / edit / view expenses
│   ├── notifications/ # Inbox, settings, FCM tokens
│   ├── onboarding/    # First-run walkthrough
│   ├── recurring/     # Recurring expense rules and generation
│   ├── settings/      # User settings, language, theme
│   ├── splash/        # Launch routing
│   └── sync/          # Local <-> Firestore sync
├── l10n/              # ARB files and generated localizations (en, hi, mr)
├── firebase_options.dart
└── main.dart          # App entry point
```

Each feature follows Clean Architecture: `data/` (models, datasources, repository implementations), `domain/` (entities, repository contracts, use cases) and `presentation/` (blocs/cubits, screens, widgets).

## Key Components

### Encrypted Local Storage
Every Hive box is opened with AES-256 encryption at startup by `SecureHive` (`lib/core/storage/`). The key is generated once and stored in the platform keystore. Existing plaintext data from older versions is migrated automatically on first launch.

### AI Assistant
The chat assistant runs Google Gemma on-device. Expenses, budgets and summaries are turned into text chunks, embedded with MiniLM (TensorFlow Lite) and retrieved by similarity to ground answers in your own data. A rule-based safety policy declines investment, tax, loan and medical advice. See [`docs/AI_ARCHITECTURE.md`](docs/AI_ARCHITECTURE.md).

### Recurring Expenses
Recurring rules are stored locally. On each launch, any occurrences that fell due are created as normal expenses (with deterministic ids so re-runs never duplicate) and then synced.

### Sync Engine
Local changes are marked pending and pushed to Cloud Firestore; remote changes are pulled and merged, with version-based conflict detection.

### Notifications
Local notifications handle budget alerts and scheduled summaries; Firebase Cloud Messaging delivers server-sent pushes.

## Testing

```bash
flutter test
```

Unit tests cover domain logic (validation, recurrence date math, recurring generation, budget alerts, AI safety and similarity), the app lock cubit, model serialization and the encrypted-storage migration.

## Roadmap

See [`docs/FEATURE_ROADMAP.md`](docs/FEATURE_ROADMAP.md).

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/new-feature`)
3. Commit your changes (`git commit -m "feat: add new feature"`)
4. Push to the branch (`git push origin feat/new-feature`)
5. Open a pull request

Please make sure tests pass: `flutter test`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/) - Build great layouts
- [Neumorphic Toolkit](https://pub.dev/packages/neumorphic) - Inspired the custom UI
- [FL Chart](https://pub.dev/packages/fl_chart) - For the charts
- [Google Gemma](https://ai.google.dev/gemma) - On-device AI model
- [Firebase](https://firebase.google.com/) - Backend services