import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';


class AIEdgeScreen extends StatefulWidget {
  const AIEdgeScreen({super.key});

  @override
  State<AIEdgeScreen> createState() => _AIEdgeScreenState();
}

class _AIEdgeScreenState extends State<AIEdgeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && mounted) {
      // Personalize AI with user's education level and interests
      final up = context.read<UserProvider>();
      context.read<ChatProvider>().setUserProfile(
        educationLevel: up.user?.educationLevel ?? '',
        interests: up.user?.interests ?? [],
      );
      await context.read<ChatProvider>().initialize(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    setState(() => _showChat = true);
    await context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _onQuickAction(String actionKey) {
    setState(() => _showChat = true);
    final prompts = {
      'quiz': 'Generate a 5-question multiple choice quiz on a topic of your choice',
      'summarize': 'Summarize a difficult topic for me — pick something interesting',
      'tips': 'Give me 5 highly effective study tips with specific techniques',
      'plan': 'Create a balanced weekly study plan for me',
    };
    _messageController.text = prompts[actionKey] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          if (chat.isLoading && !_showChat) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppTheme.accentPurple),
                  const SizedBox(height: 16),
                  Text('Loading AI Tutor...',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return _showChat ? _buildChatView() : _buildHomeView();
        },
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Edge', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                  Text('Smart Resource Hub', style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildAIInputCard(),
          const SizedBox(height: 24),
          Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildQuickAction(icon: Icons.quiz_outlined, label: 'Generate Quiz', subtitle: 'Test your knowledge', gradient: AppTheme.purpleGradient, actionKey: 'quiz'),
              _buildQuickAction(icon: Icons.summarize_outlined, label: 'Summarize', subtitle: 'Summarize topics', gradient: AppTheme.blueGradient, actionKey: 'summarize'),
              _buildQuickAction(icon: Icons.lightbulb_outline_rounded, label: 'Study Tips', subtitle: 'AI powered tips', gradient: AppTheme.pinkGradient, actionKey: 'tips'),
              _buildQuickAction(icon: Icons.route_outlined, label: 'Study Plan', subtitle: 'Personalized plan', gradient: AppTheme.greenGradient, actionKey: 'plan'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Try Asking', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChatProvider.suggestedPrompts.map((prompt) {
              return GestureDetector(
                onTap: () {
                  setState(() => _showChat = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<ChatProvider>().sendMessage(prompt.replaceAll(RegExp(r'^[^\w]+'), ''));
                    _scrollToBottom();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text(prompt, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.accentPurple, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('AI Recommended', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(20)),
                child: Text('For You', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...SampleData.resourcesForInterests(
            context.read<UserProvider>().user?.interests ?? [],
          ).map((r) => _buildResourceCard(r)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAIInputCard() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF9C64A6), Color(0xFF7B5EA7), Color(0xFF5B8EBF)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_outlined, color: Colors.white70, size: 22),
                const SizedBox(width: 8),
                Text('Ask AI Tutor', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showChat = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('Open Chat', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask anything about your studies...',
                        hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(10)),
                        child: chat.isBusy
                            ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (chat.isBusy) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const _TypingIndicator(color: Colors.white70),
                  const SizedBox(width: 10),
                  Text('AI is thinking...', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showChat = false),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppTheme.accentPurple),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Tutor', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
                    Consumer<ChatProvider>(
                      builder: (_, chat, __) => Text(
                        chat.isStreaming ? 'typing...' : chat.isLoading ? 'loading...' : 'Online',
                        style: GoogleFonts.poppins(fontSize: 11, color: chat.isBusy ? AppTheme.accentPurple : Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<ChatProvider>(
                builder: (_, chat, __) => PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
                  onSelected: (val) async {
                    if (val == 'new') await chat.startNewChat();
                    if (val == 'clear') await chat.clearCurrentChat();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'new', child: Row(children: [const Icon(Icons.add_circle_outline, size: 18), const SizedBox(width: 8), Text('New Chat', style: GoogleFonts.poppins(fontSize: 13))])),
                    PopupMenuItem(value: 'clear', child: Row(children: [const Icon(Icons.delete_outline, size: 18), const SizedBox(width: 8), Text('Clear Chat', style: GoogleFonts.poppins(fontSize: 13))])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chat, _) {
              _scrollToBottom();
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: chat.displayMessages.length,
                itemBuilder: (context, index) {
                  final msg = chat.displayMessages[index];
                  return _buildMessageBubble(msg, chat);
                },
              );
            },
          ),
        ),
        Consumer<ChatProvider>(
          builder: (_, chat, __) {
            if (chat.suggestedResources.isEmpty) return const SizedBox();
            return _buildResourcesPanel(chat.suggestedResources);
          },
        ),
        Consumer<ChatProvider>(
          builder: (_, chat, __) {
            if (!chat.hasError) return const SizedBox();
            return _buildErrorBar(chat);
          },
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ChatProvider chat) {
    final isUser = msg.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(gradient: AppTheme.purpleGradient, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppTheme.purpleGradient : null,
                    color: isUser ? null : (isDark ? AppTheme.darkCard : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: !isUser && isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: msg.isStreaming && msg.content.isEmpty
                      ? const _TypingDotsIndicator()
                      : Text(
                          msg.content,
                          style: GoogleFonts.poppins(fontSize: 13, color: isUser ? Colors.white : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary), height: 1.5),
                        ),
                ),
                if (msg.hasError) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: chat.retryLastMessage,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('Tap to retry', style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(_formatTime(msg.timestamp), style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textHint)),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildResourcesPanel(List<AIStudyResource> resources) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded, size: 16, color: AppTheme.accentPurple),
            const SizedBox(width: 6),
            Text('Suggested Resources', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentPurple)),
          ]),
          const SizedBox(height: 8),
          ...resources.take(3).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Icon(_resourceIcon(r.type), size: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(r.title, style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(r.difficulty, style: GoogleFonts.poppins(fontSize: 10, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorBar(ChatProvider chat) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 16, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(chat.errorMessage, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red))),
        GestureDetector(
          onTap: chat.retryLastMessage,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
            child: Text('Retry', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _messageController,
              maxLines: 3, minLines: 1,
              style: GoogleFonts.poppins(fontSize: 14, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask your AI tutor...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Consumer<ChatProvider>(
          builder: (_, chat, __) => GestureDetector(
            onTap: chat.isBusy ? null : _sendMessage,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: chat.isBusy
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required String subtitle, required LinearGradient gradient, required String actionKey}) {
    return GestureDetector(
      onTap: () => _onQuickAction(actionKey),
      child: Container(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(ResourceModel resource) {
    final typeIcon = resource.type == 'video' ? Icons.play_circle_outline_rounded : resource.type == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.article_outlined;
    final typeColor = resource.type == 'video' ? const Color(0xFFF48FB1) : resource.type == 'pdf' ? const Color(0xFF81D4FA) : const Color(0xFFA5D6A7);
    return GlassCard(
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(resource.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.textPrimary))),
                  if (resource.isAIRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(6)),
                      child: Text('AI Pick', style: GoogleFonts.poppins(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text('${resource.subject} • ${resource.duration}', style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
          const SizedBox(width: 4),
          Text(resource.rating.toString(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(10)),
              child: Text('Start', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  IconData _resourceIcon(String type) {
    switch (type) {
      case 'video': return Icons.play_circle_outline;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'course': return Icons.school_outlined;
      default: return Icons.article_outlined;
    }
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color)));
  }
}

class _TypingDotsIndicator extends StatefulWidget {
  const _TypingDotsIndicator();
  @override
  State<_TypingDotsIndicator> createState() => _TypingDotsIndicatorState();
}

class _TypingDotsIndicatorState extends State<_TypingDotsIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _dotCount = IntTween(begin: 1, end: 3).animate(_controller);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (_, __) => Text('•' * _dotCount.value, style: GoogleFonts.poppins(fontSize: 20, color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextSecondary : AppTheme.textSecondary, letterSpacing: 4)),
    );
  }
}
