/// App-wide constants — single source of truth for strings, sizes, durations.
library constants;

// ── App Info ──────────────────────────────────────────────────────────────
const String kAppName = 'Study Planner';
const String kAppVersion = '1.0.0';

// ── Spacing ───────────────────────────────────────────────────────────────
const double kPaddingSmall = 8.0;
const double kPaddingMedium = 16.0;
const double kPaddingLarge = 24.0;
const double kPaddingXL = 32.0;

// ── Border Radius ─────────────────────────────────────────────────────────
const double kRadiusSmall = 10.0;
const double kRadiusMedium = 16.0;
const double kRadiusLarge = 20.0;
const double kRadiusXL = 28.0;

// ── Animation Durations ───────────────────────────────────────────────────
const Duration kAnimFast = Duration(milliseconds: 200);
const Duration kAnimMedium = Duration(milliseconds: 400);
const Duration kAnimSlow = Duration(milliseconds: 700);

// ── Timer Defaults ────────────────────────────────────────────────────────
const int kPomodoroMinutes = 25;
const int kShortBreakMinutes = 5;
const int kLongBreakMinutes = 15;

// ── Onboarding ────────────────────────────────────────────────────────────
const List<String> kEducationLevels = [
  'Year 2-9', 'Year 10-11', 'Year 12-13', 'Bachelors', 'Masters', 'PhD',
];

const List<String> kInterests = [
  'Mathematics', 'Science', 'Literature', 'History',
  'Languages', 'Technology', 'Art & Design', 'Music', 'Sports',
];

// ── Subjects ──────────────────────────────────────────────────────────────
const List<String> kSubjects = [
  'Science', 'Mathematics', 'English', 'History', 'Technology',
];

// ── Priority Labels ───────────────────────────────────────────────────────
const List<String> kPriorityLevels = ['Low', 'Medium', 'High'];
