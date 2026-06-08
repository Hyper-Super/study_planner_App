import 'package:flutter/material.dart';
import '../models/models.dart';

/// Utility helper functions used across multiple screens.

/// Format seconds into MM:SS string — used by Focus Timer.
/// Example: formatSeconds(90) → "01:30"
String formatSeconds(int totalSeconds) {
  final mins = totalSeconds ~/ 60;
  final secs = totalSeconds % 60;
  return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// Get a human-readable due date label.
/// Returns "Today", "Tomorrow", or formatted date string.
String formatDueDate(DateTime date) {
  final now = DateTime.now();
  final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff < 0) return 'Overdue';
  return '${date.day}/${date.month}/${date.year}';
}

/// Maps TaskPriority enum to a display Color.
Color priorityColor(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return const Color(0xFFF48FB1);
    case TaskPriority.medium:
      return const Color(0xFFCE93D8);
    case TaskPriority.low:
      return const Color(0xFFA5D6A7);
  }
}

/// Maps TaskStatus enum to a display label string.
String statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.ongoing:
      return 'Ongoing';
    case TaskStatus.completed:
      return 'Completed';
    case TaskStatus.upcoming:
      return 'Upcoming';
  }
}

/// Returns completion percentage string like "45%"
String completionPercent(int? completed, int? total) {
  if (completed == null || total == null || total == 0) return '0%';
  return '${((completed / total) * 100).round()}%';
}
