import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable user model that maps to/from Firestore.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String educationLevel;
  final List<String> interests;
  final int studyStreak;
  final int totalHours;
  final double score;
  final DateTime? createdAt;

  // ── Settings persisted to Firestore ──────────────────────────────────────
  final int selectedThemeIndex;
  final bool notificationsEnabled;
  final bool studyRemindersEnabled;
  final bool darkModeEnabled;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.educationLevel = '',
    this.interests = const [],
    this.studyStreak = 0,
    this.totalHours = 0,
    this.score = 0.0,
    this.createdAt,
    this.selectedThemeIndex = 0,
    this.notificationsEnabled = true,
    this.studyRemindersEnabled = true,
    this.darkModeEnabled = false,
  });

  // ── Firestore serialisation ───────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'educationLevel': educationLevel,
        'interests': interests,
        'studyStreak': studyStreak,
        'totalHours': totalHours,
        'score': score,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'selectedThemeIndex': selectedThemeIndex,
        'notificationsEnabled': notificationsEnabled,
        'studyRemindersEnabled': studyRemindersEnabled,
        'darkModeEnabled': darkModeEnabled,
      };

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? 'Student',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      educationLevel: data['educationLevel'] as String? ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      studyStreak: (data['studyStreak'] as num?)?.toInt() ?? 0,
      totalHours: (data['totalHours'] as num?)?.toInt() ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      selectedThemeIndex: (data['selectedThemeIndex'] as num?)?.toInt() ?? 0,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      studyRemindersEnabled: data['studyRemindersEnabled'] as bool? ?? true,
      darkModeEnabled: data['darkModeEnabled'] as bool? ?? false,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    bool clearAvatar = false,
    String? educationLevel,
    List<String>? interests,
    int? studyStreak,
    int? totalHours,
    double? score,
    int? selectedThemeIndex,
    bool? notificationsEnabled,
    bool? studyRemindersEnabled,
    bool? darkModeEnabled,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
        educationLevel: educationLevel ?? this.educationLevel,
        interests: interests ?? this.interests,
        studyStreak: studyStreak ?? this.studyStreak,
        totalHours: totalHours ?? this.totalHours,
        score: score ?? this.score,
        createdAt: createdAt,
        selectedThemeIndex: selectedThemeIndex ?? this.selectedThemeIndex,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        studyRemindersEnabled:
            studyRemindersEnabled ?? this.studyRemindersEnabled,
        darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      );
}
