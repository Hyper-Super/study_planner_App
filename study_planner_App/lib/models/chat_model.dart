import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageRole { user, assistant, system }
enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isStreaming;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isStreaming = false,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isStreaming,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isStreaming: isStreaming ?? this.isStreaming,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'metadata': metadata ?? {},
    };
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      content: data['content'] ?? '',
      role: MessageRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  /// Convert to OpenAI API message format
  Map<String, String> toOpenAIMessage() {
    return {
      'role': role == MessageRole.assistant ? 'assistant' : 'user',
      'content': content,
    };
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasError => status == MessageStatus.error;
}

/// Firestore structure:
/// users/{uid}/ai_chats/{sessionId}/messages/{messageId}
///
/// Session document:
/// users/{uid}/ai_chats/{sessionId}
///   - id: String
///   - title: String
///   - createdAt: Timestamp
///   - updatedAt: Timestamp
///   - messageCount: int
///   - lastMessage: String (preview)
///   - userId: String
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String lastMessage;
  final String userId;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.lastMessage,
    required this.userId,
  });

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
    String? lastMessage,
    String? userId,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messageCount': messageCount,
      'lastMessage': lastMessage,
      'userId': userId,
    };
  }

  factory ChatSession.fromFirestore(Map<String, dynamic> data) {
    return ChatSession(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Chat Session',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] ?? 0,
      lastMessage: data['lastMessage'] ?? '',
      userId: data['userId'] ?? '',
    );
  }
}

/// Suggested study resource from AI
class AIStudyResource {
  final String title;
  final String description;
  final String type; // 'video', 'article', 'pdf', 'course'
  final String? url;
  final String subject;
  final String difficulty; // 'beginner', 'intermediate', 'advanced'

  const AIStudyResource({
    required this.title,
    required this.description,
    required this.type,
    this.url,
    required this.subject,
    required this.difficulty,
  });

  factory AIStudyResource.fromJson(Map<String, dynamic> json) {
    return AIStudyResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'article',
      url: json['url'],
      subject: json['subject'] ?? '',
      difficulty: json['difficulty'] ?? 'intermediate',
    );
  }
}
