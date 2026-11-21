# Veqzi — Personal Expense Tracker

**Veqzi** is a fast, privacy-first personal expense tracker built with Flutter. It combines offline-first local storage with optional Google Drive cloud backup, interactive financial charts, smart app security, and multi-language/multi-currency support to help you stay on top of your daily finances.

---

## Key Features

- **Offline Expense & Income Tracking (`sqflite`)**: Log, edit, and categorize transactions completely offline with a fast local SQLite database.
- **Interactive Pie & Bar Charts**: Visualize spending breakdowns by category and track financial trends over time using `fl_chart`.
- **PDF Report Export**: Export and share clean transaction reports directly from your device.
- **Google Sign-In**: Seamlessly authenticate with your Google account to unlock cloud features.
- **Google Drive Backup & Restore**: Safely back up your local transaction database to Google Drive and restore it anytime on any device.
- **Smart App Lock**: Protect your financial data with biometric authentication (fingerprint/face) and PIN lock support.
- **Light & Dark Theme**: Full Material 3 theming with smooth Light, Dark, and System theme modes using Google Fonts (`Poppins`).
- **Custom Animated Splash Screen**: Branded native and animated launch experience powered by `flutter_native_splash` and `flutter_animate`.
- **Multi-Currency & Multi-Language**: Switch effortlessly between currencies (default `৳`) and languages (Bangla & English).
- **Daily Reminders**: Stay consistent with configurable daily local notifications.

---

## Tech Stack & Packages

- **Framework**: Flutter (Dart SDK `^3.10.7`, Material 3)
- **Local Storage & Preferences**: `sqflite`, `path`, `path_provider`, `shared_preferences`
- **Charts & UI**: `fl_chart`, `google_fonts`, `flutter_animate`, `cupertino_icons`
- **Authentication & Cloud Backup**: `google_sign_in`, `googleapis`, `googleapis_auth`, `http`
- **Security**: `local_auth`
- **Notifications & Scheduling**: `flutter_local_notifications`, `timezone`, `flutter_timezone`
- **Export, Sharing & Utilities**: `csv`, `share_plus`, `intl`, `image_picker`, `google_generative_ai`
- **App Icons & Splash**: `flutter_launcher_icons`, `flutter_native_splash`

---

## Project Structure

```text
lib/
├── main.dart                    # App entry point, theming, dashboard & charts
├── splash_screen.dart           # Custom animated splash screen
├── add_transaction.dart         # Add/edit transactions & receipt scanning
├── database_helper.dart         # SQLite (sqflite) database layer
├── drive_helper.dart            # Google Drive backup & restore
├── auth_helper.dart             # Biometric & PIN authentication logic
├── pin_screen.dart              # PIN entry & verification screen
├── app_lock_settings_screen.dart# Smart App Lock configuration
├── app_settings_screen.dart     # Theme, currency, language & reminder settings
├── profile_screen.dart          # User profile & Google Sign-In management
├── currency_helper.dart         # Multi-currency preferences
├── language_helper.dart         # Multi-language (Bangla/English) helper
└── notification_helper.dart     # Daily reminder scheduling
```

---

## Download

Get the latest Android APK directly from the GitHub Releases page:

**[Download Veqzi APK (GitHub Releases)](https://github.com/eyasinalways/veqzi-expense-tracker/releases)**

---

## Getting Started (Local Development)

1. **Clone the repository**:
   ```bash
   git clone https://github.com/eyasinalways/veqzi-expense-tracker.git
   cd veqzi-expense-tracker
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase / Google Sign-In (Required for Cloud Backup)**:
   Sensitive configuration files are intentionally excluded from version control. Place your own configuration files locally before building:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Android Release Signing (optional): `android/key.properties` and your `.jks`/`.keystore` file

4. **Run the app**:
   ```bash
   flutter run
   ```
