import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../services/ai_service.dart';
import '../services/firestore_chat_service.dart';

enum ChatProviderState { idle, loading, streaming, error }

class ChatProvider extends ChangeNotifier {
  final AIService _aiService;
  final FirestoreChatService _firestoreService;
  static const _uuid = Uuid();

  ChatProvider({
    AIService? aiService,
    FirestoreChatService? firestoreService,
  })  : _aiService = aiService ?? AIService(),
        _firestoreService = firestoreService ?? FirestoreChatService();

  // ── State ────────────────────────────────────────────────────────────────

  List<ChatMessage> _messages = [];
  ChatProviderState _state = ChatProviderState.idle;
  String _errorMessage = '';
  String? _currentSessionId;
  String? _currentUserId;
  String _streamingContent = '';
  List<AIStudyResource> _suggestedResources = [];
  ChatMessage? _streamingMessage;

  // ── User profile for personalised AI prompt ───────────────────────────────
  String _educationLevel = '';
  List<String> _interests = [];

  /// Call this after onboarding / login to personalise the AI tutor.
  void setUserProfile({
    required String educationLevel,
    required List<String> interests,
  }) {
    _educationLevel = educationLevel;
    _interests = List<String>.from(interests);
  }

  String get _personalizedSystemPrompt => AIService.buildSystemPrompt(
        educationLevel: _educationLevel,
        interests: _interests,
      );

  // ── Getters ───────────────────────────────────────────────────────────────

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatProviderState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == ChatProviderState.loading;
  bool get isStreaming => _state == ChatProviderState.streaming;
  bool get hasError => _state == ChatProviderState.error;
  bool get isBusy => isLoading || isStreaming;
  List<AIStudyResource> get suggestedResources =>
      List.unmodifiable(_suggestedResources);
  String get streamingContent => _streamingContent;

  // Combined display list — real messages + live streaming message
  List<ChatMessage> get displayMessages {
    if (_streamingMessage != null) {
      return [..._messages, _streamingMessage!];
    }
    return _messages;
  }

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _setState(ChatProviderState.loading);

    try {
      final session =
          await _firestoreService.getOrCreateDefaultSession(userId);
      _currentSessionId = session.id;
      _messages = await _firestoreService.loadMessages(
        uid: userId,
        sessionId: session.id,
      );

      // Add welcome message if first time
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _setState(ChatProviderState.idle);
    } catch (e) {
      _setError('Failed to load chat history. $e');
    }
  }

  void _addWelcomeMessage() {
    final levelGreet = _educationLevel.isNotEmpty
        ? ' I can see you\'re studying at the $_educationLevel level'
        : '';
    final interestGreet = _interests.isNotEmpty
        ? ', with a focus on ${_interests.take(2).join(' and ')}'
        : '';
    final personalLine = (levelGreet.isNotEmpty || interestGreet.isNotEmpty)
        ? '$levelGreet$interestGreet — I\'ll tailor my explanations to suit you!'
        : '';

    final welcome = ChatMessage(
      id: _uuid.v4(),
      content:
          '👋 Hi! I\'m your AI Study Tutor. I\'m here to help you understand concepts, '
          'practice problems, create study plans, and more.'
          '${personalLine.isNotEmpty ? '\n\n$personalLine' : ''}\n\n'
          'What would you like to study today?',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(welcome);
  }

  // ── Sending Messages ──────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || isBusy) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    _messages.add(userMsg);
    _streamingContent = '';
    _streamingMessage = null;
    notifyListeners();

    // Save user message to Firestore
    if (_currentUserId != null && _currentSessionId != null) {
      await _firestoreService.saveMessage(
        uid: _currentUserId!,
        sessionId: _currentSessionId!,
        message: userMsg.copyWith(status: MessageStatus.sent),
        currentCount: _messages.length - 1,
        updateSessionTitle: _messages.length == 1,
        sessionTitle: _generateSessionTitle(content),
      );
    }

    // Mark user message as sent
    final idx = _messages.indexWhere((m) => m.id == userMsg.id);
    if (idx != -1) {
      _messages[idx] = userMsg.copyWith(status: MessageStatus.sent);
    }

    // Stream AI response
    await _streamAIResponse(content);
  }

  Future<void> _streamAIResponse(String userContent) async {
    _setState(ChatProviderState.streaming);

    final assistantMsgId = _uuid.v4();
    _streamingMessage = ChatMessage(
      id: assistantMsgId,
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isStreaming: true,
    );

    try {
      final buffer = StringBuffer();

      await for (final token in _aiService.streamMessage(
        userMessage: userContent,
        history: _messages
            .where((m) => m.role != MessageRole.system)
            .toList(),
        customSystemPrompt: _personalizedSystemPrompt,
      )) {
        buffer.write(token);
        _streamingContent = buffer.toString();
        _streamingMessage = _streamingMessage!.copyWith(
          content: _streamingContent,
        );
        notifyListeners();
      }

      // Finalize streamed message
      final fullContent = buffer.toString();
      final resources = _aiService.extractResources(fullContent);
      final cleanContent = _aiService.stripResourceBlock(fullContent);

      final finalMsg = ChatMessage(
        id: assistantMsgId,
        content: cleanContent,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        isStreaming: false,
        metadata: resources.isNotEmpty
            ? {'hasResources': true, 'resourceCount': resources.length}
            : null,
      );

      _messages.add(finalMsg);
      _streamingMessage = null;
      _streamingContent = '';
      _suggestedResources = resources;
      _setState(ChatProviderState.idle);

      // Save AI response to Firestore
      if (_currentUserId != null && _currentSessionId != null) {
        await _firestoreService.saveMessage(
          uid: _currentUserId!,
          sessionId: _currentSessionId!,
          message: finalMsg,
          currentCount: _messages.length - 1,
        );
      }
    } catch (e) {
      _streamingMessage = null;
      _streamingContent = '';

      final errorMsg = ChatMessage(
        id: assistantMsgId,
        content: _friendlyError(e),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
        isStreaming: false,
      );
      _messages.add(errorMsg);
      _setError(_friendlyError(e));
    }
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────

  Future<void> generateQuiz({
    required String subject,
    required String topic,
  }) async {
    await sendMessage(
        'Generate a 5-question quiz about "$topic" in $subject with multiple choice answers.');
  }

  Future<void> summarizeTopic({
    required String subject,
    required String topic,
  }) async {
    await sendMessage('Give me a concise summary of "$topic" in $subject.');
  }

  Future<void> getStudyTips(String subject) async {
    await sendMessage(
        'Give me 5 highly effective study tips for $subject with specific techniques.');
  }

  Future<void> generateStudyPlan({
    required List<String> subjects,
    required int hoursPerDay,
    required String goal,
  }) async {
    await sendMessage(
        'Create a detailed study plan for ${subjects.join(", ")}. '
        'I have $hoursPerDay hours/day. My goal: $goal.');
  }

  // ── Retry ────────────────────────────────────────────────────────────────

  Future<void> retryLastMessage() async {
    if (isBusy) return;

    // Find last user message
    final lastUser = _messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => _messages.first,
    );

    // Remove all messages after the last user message
    final idx = _messages.indexOf(lastUser);
    if (idx != -1) {
      _messages = _messages.sublist(0, idx + 1);
      _errorMessage = '';
      notifyListeners();
      await _streamAIResponse(lastUser.content);
    }
  }

  // ── Clear / New Chat ──────────────────────────────────────────────────────

  Future<void> startNewChat() async {
    if (_currentUserId == null) return;

    _messages = [];
    _streamingMessage = null;
    _streamingContent = '';
    _suggestedResources = [];
    _errorMessage = '';
    notifyListeners();

    final session = await _firestoreService.createSession(
      uid: _currentUserId!,
      title: 'New Chat',
    );
    _currentSessionId = session.id;
    _addWelcomeMessage();
    notifyListeners();
  }

  Future<void> clearCurrentChat() async {
    if (_currentUserId == null || _currentSessionId == null) return;

    await _firestoreService.clearMessages(
      uid: _currentUserId!,
      sessionId: _currentSessionId!,
    );

    _messages = [];
    _suggestedResources = [];
    _streamingMessage = null;
    _streamingContent = '';
    _addWelcomeMessage();
    notifyListeners();
  }

  // ── Suggested prompts ──────────────────────────────────────────────────────

  static const List<String> suggestedPrompts = [
    '📚 Help me understand quantum physics',
    '🧮 Explain quadratic equations step by step',
    '✍️ Give me essay writing tips',
    '📅 Create a weekly study schedule',
    '🧠 How to memorize history dates effectively?',
    '⚗️ Quiz me on chemical reactions',
  ];

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setState(ChatProviderState state) {
    _state = state;
    if (state != ChatProviderState.error) _errorMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    _state = ChatProviderState.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _friendlyError(dynamic e) {
    if (e is AIServiceException) {
      if (e.message.contains('401') ||
          e.message.contains('403') ||
          e.message.contains('API key not configured') ||
          e.message.contains('unauthorized')) {
        return 'Invalid or missing Groq API key.\n'
            'Please add your key in lib/utils/api_keys.dart.\n'
            'Get a free key at: https://console.groq.com/keys';
      } else if (e.message.contains('429') || e.message.contains('quota')) {
        return 'Groq quota exceeded. Please wait a moment and try again.';
      } else if (e.message.contains('timeout')) {
        return 'Request timed out. Please check your connection and retry.';
      }
      return e.message;
    }
    return 'Something went wrong. Please try again.';
  }

  String _generateSessionTitle(String firstMessage) {
    if (firstMessage.length <= 40) return firstMessage;
    return '${firstMessage.substring(0, 37)}...';
  }

  void clearError() {
    if (_state == ChatProviderState.error) {
      _setState(ChatProviderState.idle);
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}
