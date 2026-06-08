import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../utils/api_keys.dart'; // <-- set your Groq key here

/// ══════════════════════════════════════════════════════════════════════════
///  AI Service — powered by Groq API (OpenAI-compatible)
///
///  SETUP: Open lib/utils/api_keys.dart and replace:
///    const String kGeminiKey = 'YOUR_GROQ_API_KEY_HERE';
///  with your real key from https://console.groq.com/keys
/// ══════════════════════════════════════════════════════════════════════════

class AIService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'llama-3.3-70b-versatile'; // fast & free-tier friendly
  static const int _maxContextMessages = 20;
  static const int _maxTokens = 1024;

  // Build a personalized system prompt based on the user's profile
  static String buildSystemPrompt({
    String educationLevel = '',
    List<String> interests = const [],
  }) {
    final levelLine = educationLevel.isNotEmpty
        ? 'The student is currently studying at the $educationLevel level.'
        : '';
    final interestLine = interests.isNotEmpty
        ? 'Their main subjects of interest are: ${interests.join(', ')}.'
        : '';
    final personalisation = [levelLine, interestLine]
        .where((s) => s.isNotEmpty)
        .join(' ');

    return '''You are an expert AI Study Tutor integrated into a study planner app.
${personalisation.isNotEmpty ? 'Student context: $personalisation' : ''}
Your role is to:
1. Help students understand difficult concepts clearly and concisely
2. Provide step-by-step explanations when needed
3. Suggest relevant study resources, techniques, and strategies
4. Generate practice questions and quizzes on request
5. Create personalized study plans based on subjects and goals
6. Give motivating, encouraging responses while being academically rigorous
7. Adapt your explanation style to the student\'s education level and interests

When suggesting resources, format them as JSON at the end of your response like:
[RESOURCES]{"resources":[{"title":"...","description":"...","type":"video|article|pdf|course","subject":"...","difficulty":"beginner|intermediate|advanced"}]}[/RESOURCES]

Keep responses concise but thorough. Use bullet points and numbered lists for clarity.
Always be encouraging and supportive.''';
  }

  // Legacy constant kept for backward compat (used when no profile is available)
  static String get _systemPrompt => buildSystemPrompt();

  final String _apiKey;
  final http.Client _httpClient;

  AIService({String? apiKey, http.Client? httpClient})
      : _apiKey = apiKey ?? kGeminiKey,
        _httpClient = httpClient ?? http.Client();

  /// Check if API key has been configured
  bool get isKeyConfigured =>
      _apiKey.isNotEmpty &&
      _apiKey != 'YOUR_GROQ_API_KEY_HERE' &&
      _apiKey != 'YOUR_GEMINI_API_KEY_HERE';

  /// Send a chat message and return full response (non-streaming)
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String? context,
    String? customSystemPrompt,
  }) async {
    if (!isKeyConfigured) {
      throw const AIServiceException(
        'Groq API key not configured.\n\n'
        'Please open lib/utils/api_keys.dart and replace '
        'YOUR_GROQ_API_KEY_HERE with your real key.\n\n'
        'Get a free key at: https://console.groq.com/keys',
      );
    }

    try {
      final messages = _buildMessages(userMessage, history, context, customSystemPrompt);

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'max_tokens': _maxTokens,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String? ?? '';
        return text;
      } else {
        throw AIServiceException(_parseError(response));
      }
    } on TimeoutException {
      throw const AIServiceException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw AIServiceException('Network error: ${e.message}');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Unexpected error: $e');
    }
  }

  /// Stream a chat response token by token using SSE
  Stream<String> streamMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String? context,
    String? customSystemPrompt,
  }) async* {
    if (!isKeyConfigured) {
      throw const AIServiceException(
        'Groq API key not configured.\n\n'
        'Please open lib/utils/api_keys.dart and replace '
        'YOUR_GROQ_API_KEY_HERE with your real key.\n\n'
        'Get a free key at: https://console.groq.com/keys',
      );
    }

    final messages = _buildMessages(userMessage, history, context, customSystemPrompt);

    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.body = jsonEncode({
        'model': _model,
        'messages': messages,
        'max_tokens': _maxTokens,
        'temperature': 0.7,
        'stream': true,
      });

      final streamedResponse =
          await _httpClient.send(request).timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw AIServiceException(_parseErrorBody(body));
      }

      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.last;

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]' || data.isEmpty) continue;
            try {
              final json = jsonDecode(data);
              final text =
                  json['choices']?[0]?['delta']?['content'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            } catch (_) {
              // skip malformed SSE lines
            }
          }
        }
      }
    } on TimeoutException {
      throw const AIServiceException('Stream timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw AIServiceException('Network error: ${e.message}');
    } catch (e) {
      if (e is AIServiceException) rethrow;
      throw AIServiceException('Stream error: $e');
    }
  }

  /// Generate a quiz for a given subject/topic
  Future<String> generateQuiz({
    required String subject,
    required String topic,
    int questionCount = 5,
  }) async {
    final prompt =
        'Generate $questionCount multiple-choice quiz questions about "$topic" in $subject. '
        'Format each question with: Q) question, A) option1, B) option2, C) option3, D) option4, Answer: X';
    return sendMessage(userMessage: prompt, history: []);
  }

  /// Summarize a topic concisely
  Future<String> summarizeTopic({
    required String topic,
    required String subject,
  }) async {
    final prompt =
        'Create a concise but comprehensive summary of "$topic" in $subject. '
        'Include key concepts, important points, and any formulas or definitions.';
    return sendMessage(userMessage: prompt, history: []);
  }

  /// Generate a personalized study plan
  Future<String> generateStudyPlan({
    required List<String> subjects,
    required int availableHoursPerDay,
    required String goal,
  }) async {
    final prompt = 'Create a detailed study plan for: ${subjects.join(", ")}. '
        'Available time: $availableHoursPerDay hours/day. Goal: $goal. '
        'Include daily schedule, topic priorities, and revision strategy.';
    return sendMessage(userMessage: prompt, history: []);
  }

  /// Get study tips for a subject
  Future<String> getStudyTips({required String subject}) async {
    final prompt =
        'Give me 5 highly effective, specific study tips for $subject. '
        'Include memory techniques, practice strategies, and common pitfalls to avoid.';
    return sendMessage(userMessage: prompt, history: []);
  }

  /// Extract AI-suggested resources from a response
  List<AIStudyResource> extractResources(String response) {
    try {
      final match = RegExp(
        r'\[RESOURCES\](.*?)\[/RESOURCES\]',
        dotAll: true,
      ).firstMatch(response);
      if (match == null) return [];

      final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final resources =
          (json['resources'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return resources.map((r) => AIStudyResource.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Strip the resource JSON block from the display message
  String stripResourceBlock(String response) {
    return response
        .replaceAll(
            RegExp(r'\[RESOURCES\].*?\[/RESOURCES\]', dotAll: true), '')
        .trim();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Build OpenAI-compatible messages array from history + new message
  List<Map<String, dynamic>> _buildMessages(
    String userMessage,
    List<ChatMessage> history,
    String? context,
    String? customSystemPrompt,
  ) {
    final sysPrompt = customSystemPrompt ?? _systemPrompt;
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': sysPrompt},
    ];

    // Token optimisation: keep only recent messages
    final recentHistory = history.length > _maxContextMessages
        ? history.sublist(history.length - _maxContextMessages)
        : history;

    for (final msg in recentHistory) {
      if (msg.role == MessageRole.system) continue;
      final role = msg.role == MessageRole.assistant ? 'assistant' : 'user';
      messages.add({'role': role, 'content': msg.content});
    }

    // Add the new user message (with optional context prefix)
    final fullMessage =
        context != null ? 'Context: $context\n\n$userMessage' : userMessage;
    messages.add({'role': 'user', 'content': fullMessage});

    return messages;
  }

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      final msg = data['error']?['message'] as String? ?? '';
      return _groqErrorMessage(response.statusCode, msg);
    } catch (_) {
      return 'API error ${response.statusCode}';
    }
  }

  String _parseErrorBody(String body) {
    try {
      final data = jsonDecode(body);
      final msg = data['error']?['message'] as String? ?? '';
      return msg.isNotEmpty ? msg : 'API error';
    } catch (_) {
      return 'API error';
    }
  }

  String _groqErrorMessage(int statusCode, String rawMessage) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Check your API key format or request. ($rawMessage)';
      case 401:
      case 403:
        return 'Invalid or unauthorized Groq API key.\n'
            'Please update your key in lib/utils/api_keys.dart.\n'
            'Get a free key at: https://console.groq.com/keys';
      case 429:
        return 'Groq quota exceeded. Please wait a moment and try again.';
      case 500:
      case 503:
        return 'Groq service temporarily unavailable. Please try again.';
      default:
        return rawMessage.isNotEmpty ? rawMessage : 'API error $statusCode';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class AIServiceException implements Exception {
  final String message;
  const AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
