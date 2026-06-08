# 📚 Study Planner App

> A beautiful, AI-powered study planner built with Flutter & Firebase — featuring a soft glassmorphism UI, Pomodoro focus timer, real-time task management, and an AI tutor chat.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots & Screens](#-screenshots--screens)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Firebase Setup](#-firebase-setup)
- [Installation](#-installation)
- [Running the App](#-running-the-app)
- [Building for Release](#-building-for-release)
- [Dependencies](#-dependencies)
- [Permissions](#-permissions)
- [Design System](#-design-system)
- [Configuration](#-configuration)
- [Contributing](#-contributing)

---

## 🌟 Overview

**Study Planner** is a full-stack Flutter mobile app that helps students organise their academic life. It combines real-time Firestore task management with a built-in Pomodoro timer, AI tutor chat powered by an external AI API, and a polished glassmorphism design system supporting both light and dark modes with multiple accent colours.

| | |
|---|---|
| **Platform** | Android & iOS |
| **Flutter** | ≥ 3.0.0 |
| **Dart** | ≥ 3.0.0 |
| **Backend** | Firebase (Auth · Firestore · Storage) |
| **Version** | 1.0.0+1 |

---

## ✨ Features

### Core
- **Task Management** — Create, edit, delete, and complete tasks with subject, priority (Low / Medium / High), and due date
- **Focus Timer (Pomodoro)** — 25 min work / 5 min short break / 15 min long break cycles with animated circular progress and session history saved to Firestore
- **Subject Progress** — Visual progress bars per subject (Science, Mathematics, English, History, Technology)
- **Interactive Calendar** — Filter tasks by date with a horizontal date-picker strip

### AI & Chat
- **AI Tutor Chat** — Send questions to an AI service and get study guidance in a real-time chat UI backed by Firestore
- **AI Edge Screen** — Quick-action prompts, smart resource recommendations with AI badges, and resource hub

### Auth & Profile
- **Firebase Auth** — Email/password login and registration; Google Sign-In; Apple Sign-In (iOS)
- **Onboarding Flow** — Education level selector + subject interest grid stored to Firestore on first launch
- **Profile Screen** — Avatar (camera / gallery), display name, stats, 5 accent colour themes, dark mode toggle, notification settings, sign-out

### Notifications & Audio
- **Local Notifications** — Scheduled task reminders via `flutter_local_notifications`; exact alarm support on Android 12+
- **Timer Audio** — Sound cues at the end of focus and break sessions via `audioplayers`

### UI / UX
- **Glassmorphism design system** — Frosted-glass cards, pastel gradients (purple → pink → blue), soft shadows
- **Dark mode** — Full dark theme (`#1A1A2E` background) driven by `UserProvider`
- **5 accent colour themes** — Purple, Pink, Blue, Green, Orange; persisted with `shared_preferences`
- **Animated splash** — Logo scale + fade with gradient background
- **Portrait-only** — Orientation locked for consistent layout
- **No text scaling** — `TextScaler.noScaling` applied globally

---

## 📱 Screenshots & Screens

| Screen | File | Description |
|--------|------|-------------|
| Splash | `splash_screen.dart` | Animated logo, gradient background, Firebase auth-state routing |
| Login | `login_screen.dart` | Email/password, Google Sign-In, Apple Sign-In (iOS only), sign-up toggle |
| Onboarding | `onboarding_screen.dart` | 2-page flow: education level selector → interests grid |
| Dashboard | `dashboard_screen.dart` | Calendar strip, task list (Firestore real-time), subject progress, Focus Timer tab |
| AI Edge | `ai_edge_screen.dart` | AI tutor chat, quick-action prompts, recommended resources |
| Profile | `profile_screen.dart` | Avatar picker, theme selector, dark mode, notifications, account |
| About | `about_app_screen.dart` | App version, developer info |
| Help & Support | `help_support_screen.dart` | FAQ accordion, contact options |
| Privacy Policy | `privacy_policy_screen.dart` | In-app privacy policy text |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3 + Material 3 |
| Language | Dart 3 |
| State Management | Provider (`task_provider`, `timer_provider`, `user_provider`, `chat_provider`) |
| Backend / Database | Firebase Firestore (real-time) |
| Authentication | Firebase Auth + Google Sign-In + Sign in with Apple |
| File Storage | Firebase Storage (profile images) |
| AI Chat | HTTP REST calls via `ai_service.dart` |
| Local Storage | `shared_preferences` (theme, onboarding flag) |
| Notifications | `flutter_local_notifications` + `timezone` |
| Audio | `audioplayers` |
| Font | Poppins via `google_fonts` |

---

## 🗂 Project Structure

```
study_planner_App/
├── android/                        # Android platform code
│   └── app/
│       ├── google-services.json    # Firebase config (Android)
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── res/                # Icons, launch images, styles
├── ios/                            # iOS platform code
│   └── Runner/
│       ├── Info.plist
│       ├── AppDelegate.swift
│       └── Assets.xcassets/        # App icons, launch images
├── assets/
│   ├── images/                     # App images (add your own)
│   └── icons/                      # App icons (add your own)
├── lib/
│   ├── main.dart                   # Entry point — Firebase init, providers, MaterialApp
│   ├── theme/
│   │   └── app_theme.dart          # Colors, gradients, typography, GlassCard widget, buildLightTheme / buildDarkTheme
│   ├── models/
│   │   ├── models.dart             # Barrel + shared sample data
│   │   ├── task_model.dart         # Task (id, title, subject, priority, dueDate, isCompleted)
│   │   ├── session_model.dart      # PomodoroSession (duration, type, completedAt)
│   │   ├── chat_model.dart         # ChatMessage (senderId, text, timestamp, isAI)
│   │   └── user_model.dart         # UserModel (uid, name, email, educationLevel, interests, accentColor, isDarkMode)
│   ├── providers/
│   │   ├── task_provider.dart      # Task CRUD, Firestore stream, filter by date/subject
│   │   ├── timer_provider.dart     # Pomodoro state machine, session persistence, audio cues
│   │   ├── user_provider.dart      # Auth state, theme preferences, onboarding, profile updates
│   │   └── chat_provider.dart      # AI chat messages, Firestore sync, send/receive
│   ├── screens/
│   │   ├── splash_screen.dart      # Animated splash + auth routing
│   │   ├── login_screen.dart       # Firebase Auth UI (email, Google, Apple)
│   │   ├── onboarding_screen.dart  # Education level + interests selection
│   │   ├── dashboard_screen.dart   # Main home — tasks, calendar, focus timer
│   │   ├── ai_edge_screen.dart     # AI tutor chat + resource hub
│   │   ├── profile_screen.dart     # Profile, themes, settings, sign-out
│   │   ├── about_app_screen.dart   # About screen
│   │   ├── help_support_screen.dart # FAQ + support
│   │   └── privacy_policy_screen.dart # Privacy policy
│   ├── services/
│   │   ├── auth_service.dart       # Firebase Auth helpers (sign-in, sign-up, Google, Apple, sign-out)
│   │   ├── task_service.dart       # Firestore CRUD for tasks
│   │   ├── session_service.dart    # Firestore CRUD for Pomodoro sessions
│   │   ├── firestore_chat_service.dart # Firestore read/write for AI chat messages
│   │   ├── ai_service.dart         # HTTP calls to AI API
│   │   ├── profile_service.dart    # Firebase Storage upload, Firestore user doc update
│   │   ├── audio_service.dart      # audioplayers wrapper — play focus/break end sounds
│   │   ├── notification_service.dart # flutter_local_notifications init, schedule, cancel
│   │   └── onboarding_service.dart # shared_preferences onboarding-complete flag
│   └── utils/
│       ├── api_keys.dart           # API key constants (AI service key)
│       ├── constants.dart          # App-wide constants (timer defaults, subject list, priorities)
│       └── helpers.dart            # Date formatting, colour helpers, misc utilities
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── analysis_options.yaml
```

---

## ✅ Prerequisites

- **Flutter SDK** ≥ 3.0.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** ≥ 3.0.0 (bundled with Flutter)
- **Android Studio** or **VS Code** with the Flutter & Dart plugins
- **Firebase project** with Android and iOS apps registered
- **Xcode** ≥ 14 (for iOS builds, macOS only)

---

## 🔥 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project.

2. **Add Android app**
   - Package name: `com.example.study_planner`
   - Download `google-services.json` → place at `android/app/google-services.json`

3. **Add iOS app**
   - Bundle ID: `com.example.studyPlanner`
   - Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`

4. **Enable Firebase services**

   | Service | Purpose |
   |---------|---------|
   | Authentication | Email/password, Google, Apple sign-in |
   | Firestore Database | Tasks, sessions, chat messages, user profiles |
   | Firebase Storage | Profile image uploads |

5. **Firestore Security Rules** — start with development rules then tighten:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

6. **Google Sign-In** — Enable in Firebase Console → Authentication → Sign-in methods.

7. **Apple Sign-In** (iOS only) — Enable in Firebase Console, add the `Sign In with Apple` capability in Xcode, and configure your Apple Developer account.

---

## 🚀 Installation

```bash
# 1. Clone or unzip the project
cd study_planner_App

# 2. Place your Firebase config files
#    android/app/google-services.json   ← Android
#    ios/Runner/GoogleService-Info.plist ← iOS

# 3. Add your AI API key
#    Open lib/utils/api_keys.dart and set:
#    const String kAiApiKey = 'YOUR_API_KEY_HERE';

# 4. Install Flutter dependencies
flutter pub get

# 5. Ensure asset folders exist (they may be empty)
mkdir -p assets/images assets/icons
```

---

## ▶️ Running the App

```bash
# Check connected devices
flutter devices

# Run in debug mode
flutter run

# Run on a specific device
flutter run -d <device-id>

# Hot reload while running
r

# Hot restart while running
R
```

---

## 📦 Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode to archive and distribute
```

---

## 📦 Dependencies

```yaml
# UI
google_fonts: ^6.1.0              # Poppins font
smooth_page_indicator: ^1.1.0     # Onboarding page dots
percent_indicator: ^4.2.3         # Circular & linear progress rings
fl_chart: ^0.68.0                 # Charts (subject progress)
animated_text_kit: ^4.2.2         # Text animations
flutter_animate: ^4.5.0           # Declarative animations
cupertino_icons: ^1.0.2           # iOS-style icons

# State & Storage
provider: ^6.1.1                  # State management (ChangeNotifier)
shared_preferences: ^2.2.2        # Persist theme + onboarding flag
intl: ^0.18.1                     # Date/time formatting

# AI / Networking
http: ^1.2.1                      # REST API calls to AI service
uuid: ^4.3.3                      # Unique IDs for tasks/messages

# Firebase
firebase_core: ^3.6.0             # Firebase initialisation
firebase_auth: ^5.3.1             # Authentication
cloud_firestore: ^5.4.0           # Real-time database
firebase_storage: ^12.3.0         # Profile image storage

# Social Auth
google_sign_in: ^6.2.1            # Google OAuth
sign_in_with_apple: ^6.1.0        # Apple OAuth (iOS)
crypto: ^3.0.3                    # Nonce hashing for Apple Sign-In

# Media
image_picker: ^1.1.2              # Camera & gallery for profile photo

# Notifications
flutter_local_notifications: ^17.2.3  # Scheduled task reminders
timezone: ^0.9.4                      # Timezone-aware scheduling

# Audio
audioplayers: ^6.1.0              # Timer end sounds
```

---

## 🔐 Permissions

### Android (`AndroidManifest.xml`)

| Permission | Reason |
|-----------|--------|
| `INTERNET` | Firebase, AI API, Google Sign-In |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule notifications after reboot |
| `VIBRATE` | Notification vibration |
| `USE_EXACT_ALARM` | Precise task reminders (Android 12+) |
| `SCHEDULE_EXACT_ALARM` | Precise task reminders (Android 13+) |
| `POST_NOTIFICATIONS` | Show notifications (Android 13+) |
| `WAKE_LOCK` | Keep timer alive in background |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent timer being killed |
| `CAMERA` | Profile photo capture |
| `READ_MEDIA_IMAGES` | Profile photo from gallery |

### iOS (`Info.plist`)
- `NSCameraUsageDescription` — Profile photo capture
- `NSPhotoLibraryUsageDescription` — Profile photo from gallery

---

## 🎨 Design System

**Theme:** Soft Glassmorphism — frosted glass cards, pastel gradients, smooth animations

| Token | Value |
|-------|-------|
| Font | Poppins (`google_fonts`) |
| Primary Purple | `#B39DDB` |
| Primary Pink | `#F8BBD0` |
| Primary Blue | `#B3E5FC` |
| Accent Purple | `#9B8EC4` |
| Background (light) | `#F0F4FF` |
| Background (dark) | `#1A1A2E` |
| Card (dark) | `#16213E` |

**Accent colour themes** (user-selectable in Profile):
Purple · Pink · Blue · Green · Orange

**GlassCard widget** is defined in `lib/theme/app_theme.dart` and used throughout for the frosted-glass card effect.

---

## ⚙️ Configuration

### Change default Pomodoro timer lengths
In `lib/utils/constants.dart`:
```dart
const int kPomodoroMinutes   = 25;   // Focus session
const int kShortBreakMinutes = 5;    // Short break
const int kLongBreakMinutes  = 15;   // Long break
```

### Add or change subjects
```dart
const List<String> kSubjects = [
  'Science', 'Mathematics', 'English', 'History', 'Technology',
];
```

### Change default accent colour
In `lib/theme/app_theme.dart`:
```dart
static const Color accentPurple = Color(0xFF9B8EC4); // ← Change this
```

### Add a new screen
1. Create `lib/screens/my_new_screen.dart`
2. Import it in `dashboard_screen.dart` (or wherever you navigate from)
3. Push with `Navigator.push(context, MaterialPageRoute(builder: (_) => MyNewScreen()))`

### Swap the AI backend
Open `lib/services/ai_service.dart` and replace the HTTP endpoint and headers with your preferred AI provider (OpenAI, Gemini, etc.).

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "feat: add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please follow the existing code style and run `flutter analyze` before submitting.

---

## 📄 License

This project is for educational and personal use. See individual package licenses in `pubspec.yaml` for third-party terms.

---

*Built with 💜 using Flutter & Firebase — soft glassmorphism aesthetic, AI-powered study tools*
