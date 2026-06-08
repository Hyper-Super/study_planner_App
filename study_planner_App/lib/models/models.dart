import 'package:flutter/material.dart';
import 'task_model.dart' show SubjectMeta;

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String educationLevel;
  final List<String> interests;
  final int studyStreak;
  final int totalHours;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.educationLevel = '',
    this.interests = const [],
    this.studyStreak = 0,
    this.totalHours = 0,
  });
}

class TaskModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final Color color;
  final int? estimatedMinutes;
  final int? completedMinutes;

  const TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.color,
    this.estimatedMinutes,
    this.completedMinutes,
  });
}

enum TaskStatus { ongoing, completed, upcoming }
enum TaskPriority { low, medium, high }

class SubjectModel {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final int progress;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.progress,
  });
}

class ResourceModel {
  final String id;
  final String title;
  final String type;
  final String subject;
  final String duration;
  final double rating;
  final bool isAIRecommended;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.type,
    required this.subject,
    required this.duration,
    required this.rating,
    this.isAIRecommended = false,
  });
}

class SampleData {
  // ── Subjects — dynamic based on onboarding interests ─────────────────────

  /// Returns SubjectModel list driven by the user's selected interests.
  /// Falls back to the 4 default subjects when interests list is empty.
  static List<SubjectModel> subjectsForInterests(List<String> interests) {
    if (interests.isEmpty) return subjects;
    return interests.asMap().entries.map((entry) {
      final i    = entry.key;
      final name = entry.value;
      return SubjectModel(
        id:       '${i + 1}',
        name:     name,
        color:    SubjectMeta.colorFor(name),
        icon:     SubjectMeta.iconFor(name),
        progress: 0,
      );
    }).toList();
  }

  /// Returns ResourceModel list filtered to the user's interests.
  /// Falls back to all resources when interests list is empty.
  static List<ResourceModel> resourcesForInterests(List<String> interests) {
    if (interests.isEmpty) return resources;
    final matched = resources.where((r) => interests.contains(r.subject)).toList();
    return matched.isEmpty ? resources : matched;
  }


  static final List<TaskModel> tasks = [
    TaskModel(
      id: '1',
      title: 'Science',
      subject: 'Physics',
      description: 'Lorem ipsum is simply dummy text',
      dueDate: DateTime.now().add(const Duration(hours: 2)),
      status: TaskStatus.ongoing,
      priority: TaskPriority.high,
      color: const Color(0xFF81D4FA),
      estimatedMinutes: 90,
      completedMinutes: 45,
    ),
    TaskModel(
      id: '2',
      title: 'Maths',
      subject: 'Algebra',
      description: 'Chapter 5 - Quadratic equations',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      status: TaskStatus.upcoming,
      priority: TaskPriority.medium,
      color: const Color(0xFFCE93D8),
      estimatedMinutes: 60,
      completedMinutes: 0,
    ),
    TaskModel(
      id: '3',
      title: 'English',
      subject: 'Literature',
      description: 'Essay writing practice',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      status: TaskStatus.upcoming,
      priority: TaskPriority.low,
      color: const Color(0xFFA5D6A7),
      estimatedMinutes: 45,
      completedMinutes: 0,
    ),
  ];

  static final List<SubjectModel> subjects = [
    SubjectModel(
      id: '1',
      name: 'Science',
      color: const Color(0xFF81D4FA),
      icon: Icons.science_outlined,
      progress: 72,
    ),
    SubjectModel(
      id: '2',
      name: 'Mathematics',
      color: const Color(0xFFCE93D8),
      icon: Icons.calculate_outlined,
      progress: 55,
    ),
    SubjectModel(
      id: '3',
      name: 'English',
      color: const Color(0xFFA5D6A7),
      icon: Icons.menu_book_outlined,
      progress: 88,
    ),
    SubjectModel(
      id: '4',
      name: 'History',
      color: const Color(0xFFFFCC80),
      icon: Icons.history_edu_outlined,
      progress: 40,
    ),
  ];

  static final List<ResourceModel> resources = [
    ResourceModel(
      id: '1',
      title: 'Quantum Physics Fundamentals',
      type: 'video',
      subject: 'Science',
      duration: '45 min',
      rating: 4.8,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '2',
      title: 'Algebra Mastery Guide',
      type: 'pdf',
      subject: 'Mathematics',
      duration: '30 min read',
      rating: 4.6,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '3',
      title: 'Essay Writing Techniques',
      type: 'article',
      subject: 'Literature',
      duration: '15 min read',
      rating: 4.3,
      isAIRecommended: false,
    ),
    ResourceModel(
      id: '4',
      title: 'World History: Key Events',
      type: 'video',
      subject: 'History',
      duration: '60 min',
      rating: 4.5,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '5',
      title: 'Learn Python in 30 Days',
      type: 'course',
      subject: 'Technology',
      duration: '5 hr course',
      rating: 4.9,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '6',
      title: 'English Grammar Essentials',
      type: 'pdf',
      subject: 'English',
      duration: '20 min read',
      rating: 4.4,
      isAIRecommended: false,
    ),
    ResourceModel(
      id: '7',
      title: 'Spanish for Beginners',
      type: 'video',
      subject: 'Languages',
      duration: '40 min',
      rating: 4.7,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '8',
      title: 'Color Theory & Design Basics',
      type: 'article',
      subject: 'Art & Design',
      duration: '25 min read',
      rating: 4.5,
      isAIRecommended: true,
    ),
    ResourceModel(
      id: '9',
      title: 'Music Theory Fundamentals',
      type: 'video',
      subject: 'Music',
      duration: '35 min',
      rating: 4.6,
      isAIRecommended: false,
    ),
    ResourceModel(
      id: '10',
      title: 'Sports Science & Performance',
      type: 'article',
      subject: 'Sports',
      duration: '18 min read',
      rating: 4.2,
      isAIRecommended: false,
    ),
  ];
}
