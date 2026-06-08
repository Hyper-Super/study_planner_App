// lib/models/task_model.dart
//
// Production-ready TaskModel with full Firestore serialization.
// Replaces the TaskModel in models.dart — keep SubjectModel, ResourceModel,
// SampleData, etc. untouched in models.dart.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum TaskStatus { ongoing, completed, upcoming }
enum TaskPriority { low, medium, high }

extension TaskStatusX on TaskStatus {
  String get value => name; // 'ongoing' | 'completed' | 'upcoming'
  static TaskStatus fromString(String v) =>
      TaskStatus.values.firstWhere((e) => e.name == v,
          orElse: () => TaskStatus.upcoming);
}

extension TaskPriorityX on TaskPriority {
  String get value => name;
  static TaskPriority fromString(String v) =>
      TaskPriority.values.firstWhere((e) => e.name == v,
          orElse: () => TaskPriority.medium);
  int get sortOrder => index; // low=0 medium=1 high=2
}

// ─── Subject colour / icon mapping (keeps Color out of Firestore) ─────────────

class SubjectMeta {
  static const Map<String, Color> colors = {
    'Science':     Color(0xFF81D4FA),
    'Mathematics': Color(0xFFCE93D8),
    'English':     Color(0xFFA5D6A7),
    'History':     Color(0xFFFFCC80),
    'Technology':  Color(0xFFF48FB1),
    // Added to cover all onboarding interests
    'Literature':  Color(0xFFA5D6A7),
    'Languages':   Color(0xFFF48FB1),
    'Art & Design':Color(0xFFFFAB91),
    'Music':       Color(0xFFB39DDB),
    'Sports':      Color(0xFF80CBC4),
  };

  static const Map<String, IconData> icons = {
    'Science':     Icons.science_outlined,
    'Mathematics': Icons.calculate_outlined,
    'English':     Icons.menu_book_outlined,
    'History':     Icons.history_edu_outlined,
    'Technology':  Icons.computer_outlined,
    // Added to cover all onboarding interests
    'Literature':  Icons.auto_stories_outlined,
    'Languages':   Icons.translate_outlined,
    'Art & Design':Icons.palette_outlined,
    'Music':       Icons.music_note_outlined,
    'Sports':      Icons.sports_soccer_outlined,
  };

  static Color colorFor(String subject) =>
      colors[subject] ?? const Color(0xFF9B8EC4);

  static IconData iconFor(String subject) =>
      icons[subject] ?? Icons.book_outlined;

  static const List<String> all = [
    'Science', 'Mathematics', 'English', 'History', 'Technology',
    'Literature', 'Languages', 'Art & Design', 'Music', 'Sports',
  ];
}

// ─── TaskModel ────────────────────────────────────────────────────────────────

class TaskModel {
  final String id;
  final String userId;          // Firestore owner — required for security rules
  final String title;
  final String subject;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final int estimatedMinutes;
  final int completedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Derived / transient — computed, never stored
  Color get color => SubjectMeta.colorFor(subject);
  IconData get icon => SubjectMeta.iconFor(subject);
  double get progressRatio =>
      estimatedMinutes == 0 ? 0 : completedMinutes / estimatedMinutes;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    this.estimatedMinutes = 60,
    this.completedMinutes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Factory: new task (before it has a Firestore ID) ──────────────────────

  factory TaskModel.create({
    required String userId,
    required String title,
    required String subject,
    required String description,
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    int estimatedMinutes = 60,
  }) {
    final now = DateTime.now();
    return TaskModel(
      id: '',           // Firestore will assign
      userId: userId,
      title: title,
      subject: subject,
      description: description,
      dueDate: dueDate,
      status: dueDate.isAfter(now) ? TaskStatus.upcoming : TaskStatus.ongoing,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      completedMinutes: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ── Firestore → Dart ──────────────────────────────────────────────────────

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id:                 doc.id,
      userId:             d['userId']            as String? ?? '',
      title:              d['title']             as String? ?? '',
      subject:            d['subject']           as String? ?? 'Science',
      description:        d['description']       as String? ?? '',
      dueDate:            (d['dueDate']          as Timestamp).toDate(),
      status:             TaskStatusX.fromString(d['status'] as String? ?? 'upcoming'),
      priority:           TaskPriorityX.fromString(d['priority'] as String? ?? 'medium'),
      estimatedMinutes:   (d['estimatedMinutes'] as num?)?.toInt() ?? 60,
      completedMinutes:   (d['completedMinutes'] as num?)?.toInt() ?? 0,
      createdAt:          (d['createdAt']        as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:          (d['updatedAt']        as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Dart → Firestore ──────────────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
    'userId':           userId,
    'title':            title,
    'subject':          subject,
    'description':      description,
    'dueDate':          Timestamp.fromDate(dueDate),
    'status':           status.value,
    'priority':         priority.value,
    'estimatedMinutes': estimatedMinutes,
    'completedMinutes': completedMinutes,
    'createdAt':        Timestamp.fromDate(createdAt),
    'updatedAt':        FieldValue.serverTimestamp(),
  };

  // ── copyWith ──────────────────────────────────────────────────────────────

  TaskModel copyWith({
    String?        id,
    String?        userId,
    String?        title,
    String?        subject,
    String?        description,
    DateTime?      dueDate,
    TaskStatus?    status,
    TaskPriority?  priority,
    int?           estimatedMinutes,
    int?           completedMinutes,
    DateTime?      createdAt,
    DateTime?      updatedAt,
  }) {
    return TaskModel(
      id:                 id                ?? this.id,
      userId:             userId            ?? this.userId,
      title:              title             ?? this.title,
      subject:            subject           ?? this.subject,
      description:        description       ?? this.description,
      dueDate:            dueDate           ?? this.dueDate,
      status:             status            ?? this.status,
      priority:           priority          ?? this.priority,
      estimatedMinutes:   estimatedMinutes  ?? this.estimatedMinutes,
      completedMinutes:   completedMinutes  ?? this.completedMinutes,
      createdAt:          createdAt         ?? this.createdAt,
      updatedAt:          updatedAt         ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
