# 📚 Study Planner App — Flutter/Dart

A beautiful, feature-rich study planner app with a soft glassmorphism UI matching your reference design. Built with Flutter/Dart.

---

## 🎨 Design System

**Theme:** Soft Glassmorphism — pastel gradients, frosted glass cards, smooth animations  
**Font:** Poppins (via google_fonts)  
**Colors:** Purple (#9B8EC4), Pink (#F48FB1), Blue (#81D4FA), Green (#A5D6A7)

---

## 📱 Screens

| Screen | File | Description |
|--------|------|-------------|
| Splash | `splash_screen.dart` | Animated logo + gradient background |
| Login | `login_screen.dart` | Email, Google/Apple sign-in, toggle signup |
| Onboarding | `onboarding_screen.dart` | Select education level + interests |
| Dashboard | `dashboard_screen.dart` | Task list, calendar, subject progress |
| Focus Timer | (inside dashboard) | Pomodoro/break timer with circular progress |
| AI Edge | `ai_edge_screen.dart` | AI tutor chat + smart resource hub |
| Profile | `profile_screen.dart` | User info, theme picker, settings, account |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin

### Installation

```bash
# 1. Clone / unzip the project
cd study_planner

# 2. Install dependencies
flutter pub get

# 3. Create required asset folders
mkdir -p assets/images assets/icons

# 4. Run on device/emulator
flutter run
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

---

## 📦 Dependencies

```yaml
google_fonts: ^6.1.0          # Poppins font
smooth_page_indicator: ^1.1.0  # Onboarding dots
percent_indicator: ^4.2.3      # Progress rings
fl_chart: ^0.68.0              # Charts
lottie: ^3.0.0                 # Animations
animated_text_kit: ^4.2.2      # Text animations
shared_preferences: ^2.2.2     # Local storage
intl: ^0.18.1                  # Date formatting
provider: ^6.1.1               # State management
glassmorphism: ^3.0.0          # Glass effects
flutter_animate: ^4.5.0        # Animations
```

---

## 🗂️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart           # Colors, typography, GlassCard widget
├── models/
│   └── models.dart              # Data models + sample data
└── screens/
    ├── splash_screen.dart        # Animated splash
    ├── login_screen.dart         # Auth screen
    ├── onboarding_screen.dart    # Onboarding flow
    ├── dashboard_screen.dart     # Main dashboard + Focus Timer
    ├── ai_edge_screen.dart       # AI Resource Hub
    └── profile_screen.dart       # Profile + Settings
```

---

## ✨ Key Features

- **Animated Splash** — elastic logo scale + fade with gradient background
- **Auth Screen** — Google/Apple social login buttons, login/signup toggle
- **Onboarding** — 2-page flow: education level selector + interests grid
- **Dashboard** — Interactive calendar, task cards with progress bars, subject grid
- **Focus Timer** — Pomodoro/Short Break/Long Break modes, animated circular timer, session stats
- **Add Task** — Bottom sheet with subject, priority selector
- **AI Edge** — Ask AI Tutor, 4 quick actions, recommended resources with AI badges
- **Profile** — Avatar, stats, 5 color themes, notification toggles, account options

---

## 🎨 Customization

### Change accent color
In `lib/theme/app_theme.dart`:
```dart
static const Color accentPurple = Color(0xFF9B8EC4); // ← Change this
```

### Add new screens
Create file in `lib/screens/`, import in `dashboard_screen.dart`, add to `IndexedStack`.

### Add real backend
Replace `SampleData` in `models.dart` with API calls using `http` or `dio` package.

---

## 📋 Notes

- Text scaling is disabled for consistent UI across all devices
- Portrait orientation only (locked)
- All animations use Flutter's built-in `AnimationController` — no extra libs needed for core animations
- Assets folders (`assets/images/`, `assets/icons/`) must exist even if empty

---

*Built with 💜 using Flutter — matching the soft glassmorphism aesthetic from the reference design*
