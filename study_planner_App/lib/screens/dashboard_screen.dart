// lib/screens/dashboard_screen.dart
//
// ✅ DESIGN UNCHANGED — glassmorphism, gradients, animations, layouts identical.
// ✅ BACKEND WIRED   — Firestore real-time, CRUD, subject progress, calendar
//                      filtering, priorities, loading/error states, offline.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../theme/app_theme.dart';
import '../models/task_model.dart';
import '../models/models.dart' show SubjectModel, SampleData;
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../providers/timer_provider.dart';
import '../services/task_service.dart';
import 'ai_edge_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _selectedNav = 0;

  // ── Full-month calendar state ─────────────────────────────────────────────
  late DateTime _calendarMonth;   // year+month being displayed
  late DateTime _selectedDate;    // currently selected day
  bool _showFullCalendar = false; // expand to full monthly grid

  late AnimationController _fabController;
  late Animation<double>   _fabScale;

  static const List<String> _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Returns all days in the current month view (including leading/trailing blanks = null)
  List<DateTime?> get _monthDays {
    final first = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final last  = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    // Monday-based offset (weekday 1=Mon..7=Sun)
    final leading = (first.weekday - 1) % 7;
    final days = <DateTime?>[];
    for (int i = 0; i < leading; i++) days.add(null);
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_calendarMonth.year, _calendarMonth.month, d));
    }
    return days;
  }

  // 7-day window centred on selected date (for the compact strip)
  List<DateTime> get _weekDates {
    final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  void _prevMonth() => setState(() {
    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
  });

  void _selectDay(DateTime date, TaskProvider tp) {
    setState(() {
      _selectedDate    = date;
      _calendarMonth   = DateTime(date.year, date.month, 1);
      _showFullCalendar = false;
    });
    tp.selectDate(date);
  }

  @override
  void initState() {
    super.initState();

    final today     = DateTime.now();
    _selectedDate   = today;
    _calendarMonth  = DateTime(today.year, today.month, 1);

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TaskProvider>();
      if (tp.loadState == TaskLoadState.idle) tp.init();
      tp.selectDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkMainGradient : AppTheme.mainGradient),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedNav,
            children: [
              _buildHomeTab(),
              const FocusTimerWidget(),
              const AIEdgeScreen(),
              const ProfileScreen(),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedNav == 0
          ? ScaleTransition(
              scale: _fabScale,
              child: GestureDetector(
                onTap: () => _showAddTaskSheet(context),
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withValues(alpha: 0.5),
                        blurRadius: 15, offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Home tab ──────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return Consumer2<TaskProvider, UserProvider>(
      builder: (context, tp, up, _) {
        return RefreshIndicator(
          color: AppTheme.accentPurple,
          onRefresh: () async {
            tp.retry();
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${up.user?.name.split(' ').first ?? 'there'} 👋',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                        ),
                        Text(
                          up.user?.educationLevel != null && up.user!.educationLevel.isNotEmpty ? "${up.user!.educationLevel} · Let's study!" : "Let's plan your study!",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _selectedNav = 3),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.purpleGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPurple.withValues(alpha: 0.3),
                              blurRadius: 10, offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _buildCalendarSection(tp),
                const SizedBox(height: 16),

                // ── Personalized tip based on education + interests ───────────
                _buildPersonalizedTipCard(up),
                const SizedBox(height: 8),

                // ── Error banner ─────────────────────────────────────────────
                if (tp.hasError && tp.errorMessage != null)
                  _buildErrorBanner(tp.errorMessage!, tp),

                // ── Ongoing tasks header ──────────────────────────────────────
                Row(
                  children: [
                    Text('Ongoing',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => tp.clearDateFilter(),
                      child: Text('See all',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.accentPurple,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Task list ────────────────────────────────────────────────
                if (tp.isLoading)
                  _buildLoadingSkeleton()
                else if (tp.tasks.isEmpty)
                  _buildEmptyState()
                else
                  ...tp.tasks.map((task) => _buildTaskCard(task, tp)),

                const SizedBox(height: 16),

                // ── Study Progress ────────────────────────────────────────────
                Text('Study Progress',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                const SizedBox(height: 12),

                _buildSubjectGrid(tp),

                // ── Daily Stats ───────────────────────────────────────────────
                const SizedBox(height: 20),
                _buildDailyStatsCard(tp),

                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendarSection(TaskProvider tp) {
    final accent   = context.read<UserProvider>().accentColor;
    final today    = DateTime.now();
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final txtPri   = isDark ? AppTheme.darkTextPrimary   : AppTheme.textPrimary;
    final txtSec   = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_left_rounded, color: accent, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showFullCalendar = !_showFullCalendar),
                  child: Row(
                    children: [
                      Text(
                        '${_monthNames[_calendarMonth.month]} ${_calendarMonth.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700, color: txtPri),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _showFullCalendar ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded, color: txtSec, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  _selectDay(now, tp);
                  setState(() => _calendarMonth = DateTime(now.year, now.month, 1));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Today',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _nextMonth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.chevron_right_rounded, color: accent, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels.map((d) => SizedBox(
              width: 36,
              child: Text(d,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600, color: txtSec)),
            )).toList(),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _showFullCalendar
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDates.map((date) {
                final isSel    = _isSameDay(date, _selectedDate);
                final isToday  = _isSameDay(date, today);
                final hasTasks = tp.hasTasksOnDate(date);
                return GestureDetector(
                  onTap: () => _selectDay(date, tp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38, height: 58,
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? LinearGradient(
                              colors: [accent.withValues(alpha: 0.8), accent],
                              begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      color: isToday && !isSel ? accent.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSel
                          ? Border.all(color: accent.withValues(alpha: 0.4), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: isSel ? Colors.white : txtPri)),
                        const SizedBox(height: 3),
                        Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasTasks ? (isSel ? Colors.white : accent) : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            secondChild: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 2,
              children: _monthDays.map((date) {
                if (date == null) return const SizedBox();
                final isSel    = _isSameDay(date, _selectedDate);
                final isToday  = _isSameDay(date, today);
                final hasTasks = tp.hasTasksOnDate(date);
                return GestureDetector(
                  onTap: () => _selectDay(date, tp),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? LinearGradient(
                              colors: [accent.withValues(alpha: 0.8), accent],
                              begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      color: isToday && !isSel ? accent.withValues(alpha: 0.12) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isSel
                          ? Border.all(color: accent.withValues(alpha: 0.4), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
                                color: isSel ? Colors.white : txtPri)),
                        if (hasTasks)
                          Container(
                            width: 3, height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? Colors.white70 : accent,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Task card ─────────────────────────────────────────────────────────────

  Widget _buildTaskCard(TaskModel task, TaskProvider tp) {
    final priorityColor = task.priority == TaskPriority.high
        ? const Color(0xFFF48FB1)
        : task.priority == TaskPriority.medium
            ? const Color(0xFFCE93D8)
            : const Color(0xFFA5D6A7);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => tp.deleteTask(task.id),
      child: GestureDetector(
        onLongPress: () => _showTaskOptions(context, task, tp),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: task.color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: task.color.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subject icon
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: task.color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(task.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                  decoration: task.status == TaskStatus.completed
                                      ? TextDecoration.lineThrough
                                      : null),
                            ),
                          ),
                          // Priority badge
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        task.description,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: task.progressRatio,
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              task.color.withValues(alpha: 0.8)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status chip
                    GestureDetector(
                      onTap: task.status != TaskStatus.completed
                          ? () => tp.markCompleted(task.id)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.status == TaskStatus.completed
                              ? const Color(0xFFA5D6A7).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.status == TaskStatus.ongoing
                              ? 'Ongoing'
                              : task.status == TaskStatus.completed
                                  ? 'Done ✓'
                                  : 'Upcoming',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: task.status == TaskStatus.ongoing
                                ? AppTheme.accentPurple
                                : task.status == TaskStatus.completed
                                    ? const Color(0xFF388E3C)
                                    : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${task.completedMinutes}/${task.estimatedMinutes} min',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Subject progress grid ─────────────────────────────────────────────────

  Widget _buildSubjectGrid(TaskProvider tp) {
    // Build subject list from user's onboarding interests (falls back to defaults)
    final userInterests = context.read<UserProvider>().user?.interests ?? [];
    final baseSubjects  = SampleData.subjectsForInterests(userInterests);

    // Merge with live Firestore progress
    final subjects = baseSubjects.map((s) {
      final liveProgress = tp.progressForSubject(s.name);
      return SubjectModel(
        id:       s.id,
        name:     s.name,
        color:    s.color,
        icon:     s.icon,
        progress: liveProgress > 0 ? liveProgress : s.progress,
      );
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: subjects.length,
      itemBuilder: (_, i) => _buildSubjectCard(subjects[i]),
    );
  }

  Widget _buildSubjectCard(SubjectModel subject) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: subject.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(subject.icon, color: subject.color, size: 18),
              ),
              const Spacer(),
              Text(
                '${subject.progress}%',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subject.name,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: subject.progress / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Personalized tip card ─────────────────────────────────────────────────

  /// Returns a context-aware study tip based on the user's education level
  /// and their first selected interest.
  static Map<String, String> _getTipForUser({
    required String educationLevel,
    required List<String> interests,
  }) {
    final interest = interests.isNotEmpty ? interests.first : '';

    // Education-level specific tips
    final Map<String, Map<String, String>> eduTips = {
      'Year 2-9': {
        'icon': '🧩',
        'title': 'Learning Tip for You',
        'body': 'Try the "Read–Cover–Write–Check" method to memorise key facts. Short, fun sessions of 20 minutes work best at your level!',
      },
      'Year 10-11': {
        'icon': '📝',
        'title': 'GCSE Study Tip',
        'body': 'Past papers are your best friend. Aim for one timed paper per subject each week and review every mistake carefully.',
      },
      'Year 12-13': {
        'icon': '🎯',
        'title': 'A-Level Focus Tip',
        'body': 'Use spaced repetition for formulas and dates. Spread revision across multiple sessions rather than cramming the night before.',
      },
      'Bachelors': {
        'icon': '📚',
        'title': 'Undergraduate Strategy',
        'body': 'Link each lecture to one key concept and write a 3-sentence summary immediately after class. This boosts retention by over 50%.',
      },
      'Masters': {
        'icon': '🔬',
        'title': 'Postgraduate Tip',
        'body': 'Build a research question map for each module. Connecting ideas across topics strengthens critical thinking for essays and exams.',
      },
      'PhD': {
        'icon': '💡',
        'title': 'Research Productivity Tip',
        'body': 'Use daily writing sessions of 90 minutes (deep work blocks) and a reference manager like Zotero to stay on top of your literature.',
      },
    };

    // Interest-specific tips (override if interest is set)
    final Map<String, Map<String, String>> interestTips = {
      'Mathematics': {
        'icon': '➗',
        'title': 'Maths Tip',
        'body': 'Work problems without looking at the solution first. Struggle is where learning happens — then check your answer and understand any gaps.',
      },
      'Science': {
        'icon': '⚗️',
        'title': 'Science Tip',
        'body': 'Draw diagrams and label them from memory. Visual recall is one of the most effective ways to retain scientific concepts.',
      },
      'Literature': {
        'icon': '📖',
        'title': 'Literature Tip',
        'body': 'Annotate as you read — highlight themes, circle unusual word choices, and jot margin notes. Active reading beats passive reading every time.',
      },
      'History': {
        'icon': '🏛️',
        'title': 'History Tip',
        'body': 'Build a timeline for each topic. Seeing events in sequence helps you understand causation, which is key for essay analysis.',
      },
      'Languages': {
        'icon': '🗣️',
        'title': 'Language Learning Tip',
        'body': 'Speak out loud every day, even for just 5 minutes. Production (speaking/writing) builds fluency far faster than passive reading alone.',
      },
      'Technology': {
        'icon': '💻',
        'title': 'Tech Study Tip',
        'body': 'Build something small with every new concept you learn. Hands-on projects cement understanding far better than reading documentation alone.',
      },
      'Art & Design': {
        'icon': '🎨',
        'title': 'Art & Design Tip',
        'body': 'Keep a daily sketchbook — even 10 minutes of observation drawing sharpens your eye for composition, proportion, and detail.',
      },
      'Music': {
        'icon': '🎵',
        'title': 'Music Study Tip',
        'body': 'Isolate tricky passages and practise them at 60% speed before returning to full tempo. Slow practice builds muscle memory accurately.',
      },
      'Sports': {
        'icon': '🏅',
        'title': 'Sports Science Tip',
        'body': 'Study the theory behind your sport — biomechanics, nutrition, and psychology. Understanding the "why" takes performance to the next level.',
      },
    };

    // Prefer interest tip if available, otherwise use education tip
    if (interest.isNotEmpty && interestTips.containsKey(interest)) {
      return interestTips[interest]!;
    }
    if (educationLevel.isNotEmpty && eduTips.containsKey(educationLevel)) {
      return eduTips[educationLevel]!;
    }
    return {
      'icon': '✨',
      'title': 'Study Tip',
      'body': 'Break your study sessions into 25-minute focused blocks with 5-minute breaks. Use the Focus Timer tab to get started!',
    };
  }

  Widget _buildPersonalizedTipCard(UserProvider up) {
    final edu       = up.user?.educationLevel ?? '';
    final interests = up.user?.interests ?? [];
    final tip       = _getTipForUser(educationLevel: edu, interests: interests);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final accent    = up.accentColor;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title']!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip['body']!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Daily stats card ──────────────────────────────────────────────────────

  Widget _buildDailyStatsCard(TaskProvider tp) {
    final stats = tp.dailyStats;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Overview",
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statChip('${stats.todayTotal}',    'Tasks',     const Color(0xFFCE93D8)),
              _statChip('${stats.todayCompleted}','Done',      const Color(0xFFA5D6A7)),
              _statChip('${stats.todayMinutesDone}','Min done', const Color(0xFF81D4FA)),
            ],
          ),
          if (stats.todayTotal > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: stats.todayCompletionRate),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.accentPurple),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(stats.todayCompletionRate * 100).toStringAsFixed(0)}% complete',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) => Column(
    children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
        child: Center(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: GoogleFonts.poppins(
              fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
    ],
  );

  // ── Empty / loading / error states ───────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: AppTheme.accentPurple, size: 36),
            ),
            const SizedBox(height: 16),
            Text('No tasks for this day',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
            Text('Tap + to add a task',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const _ShimmerBox(),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String msg, TaskProvider tp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.red.shade700)),
          ),
          GestureDetector(
            onTap: tp.retry,
            child: Text('Retry',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav (unchanged) ────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,          'label': 'Home'},
      {'icon': Icons.timer_outlined,         'label': 'Focus'},
      {'icon': Icons.auto_awesome_rounded,   'label': 'AI Hub'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1A2535) : Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20, offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = _selectedNav == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedNav = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPurple.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i]['icon'] as IconData,
                          color: isSelected
                              ? AppTheme.accentPurple
                              : AppTheme.textHint,
                          size: 24),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.accentPurple
                              : AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Sheet & dialogs ───────────────────────────────────────────────────────

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialDate: _selectedDate,
      ),
    );
  }

  void _showTaskOptions(BuildContext context, TaskModel task, TaskProvider tp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskOptionsSheet(task: task, provider: tp),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete task?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: Text('This action cannot be undone.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;
  }
}

// ─── Shimmer loading box ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ─── Task Options Sheet (long-press) ─────────────────────────────────────────

class _TaskOptionsSheet extends StatelessWidget {
  final TaskModel task;
  final TaskProvider provider;
  const _TaskOptionsSheet({required this.task, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: null,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(task.title,
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(task.subject,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          const SizedBox(height: 20),
          if (task.status != TaskStatus.completed)
            _optionTile(
              context,
              icon: Icons.check_circle_outline_rounded,
              label: 'Mark as Completed',
              color: const Color(0xFFA5D6A7),
              onTap: () {
                provider.markCompleted(task.id);
                Navigator.pop(context);
              },
            ),
          _optionTile(
            context,
            icon: Icons.edit_outlined,
            label: 'Edit Task',
            color: AppTheme.accentPurple,
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    AddTaskSheet(existingTask: task),
              );
            },
          ),
          _optionTile(
            context,
            icon: Icons.delete_outline_rounded,
            label: 'Delete Task',
            color: Colors.red.shade300,
            onTap: () async {
              Navigator.pop(context);
              provider.deleteTask(task.id);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// ─── Focus Timer (unchanged) ──────────────────────────────────────────────────

class FocusTimerWidget extends StatefulWidget {
  const FocusTimerWidget({super.key});
  @override
  State<FocusTimerWidget> createState() => _FocusTimerWidgetState();
}

class _FocusTimerWidgetState extends State<FocusTimerWidget>
    with SingleTickerProviderStateMixin {

  // ── Mode labels matching TimerProvider.modeDurations keys ─────────────────
  static const List<String> _modeLabels = [
    'Pomodoro',
    'Short Break',
    'Long Break',
  ];

  // ── Pulse animation (design unchanged) ────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _selectedModeIndex(TimerProvider tp) =>
      _modeLabels.indexOf(tp.currentMode).clamp(0, 2);

  @override
  Widget build(BuildContext context) {
    // Consumer so UI re-renders on every timer tick
    return Consumer<TimerProvider>(
      builder: (context, tp, _) {
        final modeIdx   = _selectedModeIndex(tp);
        final isRunning = tp.isRunning;
        final breaks    = tp.todayShortBreaks + tp.todayLongBreaks;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Focus Timer',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text('Stay focused and productive',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // ── Mode selector (design unchanged) ───────────────────────────
              GlassCard(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: List.generate(_modeLabels.length, (i) {
                    final sel = modeIdx == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => tp.setMode(_modeLabels[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: sel ? AppTheme.purpleGradient : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _modeLabels[i],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 40),

              // ── Circular timer (design unchanged) ──────────────────────────
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                    scale: isRunning ? _pulseAnim.value : 1.0, child: child),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220, height: 220,
                      child: CircularProgressIndicator(
                        value: tp.progress,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentPurple),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 190, height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkCard.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.15),
                            blurRadius: 30, spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tp.formattedTime,
                              style: GoogleFonts.poppins(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                          Text(tp.currentMode,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ── Controls (design unchanged) ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timerBtn(Icons.refresh_rounded,   tp.reset),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: tp.toggleTimer,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.4),
                            blurRadius: 20, offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Icon(
                        isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white, size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _timerBtn(Icons.skip_next_rounded, tp.skip),
                ],
              ),
              const SizedBox(height: 36),

              // ── Stats (real data from Firestore) ───────────────────────────
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Sessions",
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat(tp.todayPomodoros.toString(),
                              'Sessions', const Color(0xFFCE93D8)),
                        _stat(tp.todayFocusMins.toString(),
                              'Minutes',  const Color(0xFF81D4FA)),
                        _stat(breaks.toString(),
                              'Breaks',   const Color(0xFFA5D6A7)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timerBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 4),
              )
            ],
          ),
          child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary, size: 24),
        ),
      );

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(
              child: Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
        ],
      );
}

// ─── Add / Edit Task Sheet ────────────────────────────────────────────────────

class AddTaskSheet extends StatefulWidget {
  final TaskModel?  existingTask;
  final DateTime?   initialDate;
  const AddTaskSheet({super.key, this.existingTask, this.initialDate});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();

  String       _subject  = 'Science';
  String       _priority = 'Medium';
  DateTime?    _dueDate;
  int          _estimatedMinutes = 60;
  bool         _isSaving = false;

  // Use user's interests if available, otherwise fall back to all subjects
  List<String> get _subjects {
    final interests = context.read<UserProvider>().user?.interests ?? [];
    return interests.isNotEmpty ? interests : SubjectMeta.all;
  }
  static const _priorities = ['Low', 'Medium', 'High'];

  bool get _isEdit => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    if (t != null) {
      _titleCtrl.text      = t.title;
      _descCtrl.text       = t.description;
      _subject             = t.subject;
      _priority            = _priorityLabel(t.priority);
      _dueDate             = t.dueDate;
      _estimatedMinutes    = t.estimatedMinutes;
    } else {
      _dueDate = widget.initialDate ?? DateTime.now();
      // Default to first interest if user has onboarding selections
      final interests = context.read<UserProvider>().user?.interests ?? [];
      if (interests.isNotEmpty) _subject = interests.first;
    }
  }

  String _priorityLabel(TaskPriority p) =>
      p == TaskPriority.high ? 'High' : p == TaskPriority.low ? 'Low' : 'Medium';

  TaskPriority get _priorityEnum =>
      _priority == 'High' ? TaskPriority.high :
      _priority == 'Low'  ? TaskPriority.low  : TaskPriority.medium;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    final tp = context.read<TaskProvider>();

    try {
      if (_isEdit) {
        final updated = widget.existingTask!.copyWith(
          title:            _titleCtrl.text.trim(),
          subject:          _subject,
          description:      _descCtrl.text.trim(),
          dueDate:          _dueDate,
          priority:         _priorityEnum,
          estimatedMinutes: _estimatedMinutes,
        );
        await tp.updateTask(updated);
      } else {
        await tp.addTask(
          title:            _titleCtrl.text.trim(),
          subject:          _subject,
          description:      _descCtrl.text.trim(),
          dueDate:          _dueDate ?? DateTime.now(),
          priority:         _priorityEnum,
          estimatedMinutes: _estimatedMinutes,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.accentPurple)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: null,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEdit ? 'Edit Task' : 'New Task',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
            const SizedBox(height: 16),

            _field(_titleCtrl, 'Task title', 1),
            const SizedBox(height: 12),
            _field(_descCtrl, 'Description', 3),
            const SizedBox(height: 12),

            // Subject dropdown
            _dropdown(),
            const SizedBox(height: 12),

            // Priority picker
            Row(
              children: _priorities.map((p) {
                final sel = _priority == p;
                final c = p == 'High'
                    ? const Color(0xFFF48FB1)
                    : p == 'Medium'
                        ? const Color(0xFFCE93D8)
                        : const Color(0xFFA5D6A7);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? c.withValues(alpha: 0.25)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? c : Colors.grey.shade200),
                      ),
                      child: Text(p,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: sel ? c : AppTheme.textSecondary)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Due date picker
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.accentPurple, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Select due date'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _dueDate == null
                              ? AppTheme.textHint
                              : Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Estimated minutes
            Row(
              children: [
                Text('Est. time:',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
                const Spacer(),
                ...[30, 60, 90, 120].map((m) {
                  final sel = _estimatedMinutes == m;
                  return GestureDetector(
                    onTap: () => setState(() => _estimatedMinutes = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.accentPurple.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel
                                ? AppTheme.accentPurple
                                : Colors.grey.shade200),
                      ),
                      child: Text('${m}m',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: sel
                                  ? AppTheme.accentPurple
                                  : AppTheme.textSecondary)),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Submit button
            GestureDetector(
              onTap: _isSaving ? null : _submit,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _isEdit ? 'Save Changes' : 'Add Task',
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, int lines) => TextField(
        controller: c,
        maxLines: lines,
        style: GoogleFonts.poppins(
            fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              color: AppTheme.textHint, fontSize: 14),
          filled: true, fillColor: null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppTheme.accentPurple)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _dropdown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _subject,
            isExpanded: true,
            style: GoogleFonts.poppins(
                fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
            items: _subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _subject = v!),
          ),
        ),
      );
}
