import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

/// Firestore structure:
///
/// users/
///   {uid}/
///     ai_chats/                    ← collection of sessions
///       {sessionId}/               ← session document
///         id: String
///         title: String
///         createdAt: Timestamp
///         updatedAt: Timestamp
///         messageCount: int
///         lastMessage: String
///         userId: String
///         messages/                ← sub-collection
///           {messageId}/
///             id: String
///             content: String
///             role: String ('user'|'assistant')
///             timestamp: Timestamp
///             status: String
///             metadata: Map
class FirestoreChatService {
  final FirebaseFirestore _db;

  FirestoreChatService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Collections ─────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _chatsRef(String uid) =>
      _db.collection('users').doc(uid).collection('ai_chats');

  CollectionReference<Map<String, dynamic>> _messagesRef(
          String uid, String sessionId) =>
      _chatsRef(uid).doc(sessionId).collection('messages');

  // ── Sessions ─────────────────────────────────────────────────────────────

  /// Create a new chat session
  Future<ChatSession> createSession({
    required String uid,
    String? title,
  }) async {
    final ref = _chatsRef(uid).doc();
    final session = ChatSession(
      id: ref.id,
      title: title ?? 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: 0,
      lastMessage: '',
      userId: uid,
    );
    await ref.set(session.toFirestore());
    return session;
  }

  /// Load all sessions for a user (most recent first)
  Future<List<ChatSession>> loadSessions(String uid) async {
    try {
      final snap = await _chatsRef(uid)
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => ChatSession.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get or create the default session for a user
  Future<ChatSession> getOrCreateDefaultSession(String uid) async {
    final sessions = await loadSessions(uid);
    if (sessions.isNotEmpty) return sessions.first;
    return createSession(uid: uid, title: 'AI Tutor Chat');
  }

  /// Update session metadata after a new message
  Future<void> _updateSession({
    required String uid,
    required String sessionId,
    required String lastMessage,
    required int messageCount,
    String? title,
  }) async {
    final data = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': lastMessage.length > 80
          ? '${lastMessage.substring(0, 80)}...'
          : lastMessage,
      'messageCount': messageCount,
    };
    if (title != null) data['title'] = title;
    await _chatsRef(uid).doc(sessionId).update(data);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Save a message to Firestore
  Future<void> saveMessage({
    required String uid,
    required String sessionId,
    required ChatMessage message,
    int currentCount = 0,
    bool updateSessionTitle = false,
    String? sessionTitle,
  }) async {
    final batch = _db.batch();

    // Save message document
    final msgRef = _messagesRef(uid, sessionId).doc(message.id);
    batch.set(msgRef, message.toFirestore());

    // Update session metadata
    final sessionRef = _chatsRef(uid).doc(sessionId);
    final sessionData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': message.content.length > 80
          ? '${message.content.substring(0, 80)}...'
          : message.content,
      'messageCount': currentCount + 1,
    };
    if (updateSessionTitle && sessionTitle != null) {
      sessionData['title'] = sessionTitle;
    }
    batch.update(sessionRef, sessionData);

    await batch.commit();
  }

  /// Load all messages for a session
  Future<List<ChatMessage>> loadMessages({
    required String uid,
    required String sessionId,
    int limit = 50,
  }) async {
    try {
      final snap = await _messagesRef(uid, sessionId)
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => ChatMessage.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Real-time stream of messages
  Stream<List<ChatMessage>> messagesStream({
    required String uid,
    required String sessionId,
  }) {
    return _messagesRef(uid, sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromFirestore(d.data())).toList());
  }

  /// Update a message (e.g., mark as error or update content after streaming)
  Future<void> updateMessage({
    required String uid,
    required String sessionId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    await _messagesRef(uid, sessionId).doc(messageId).update(data);
  }

  /// Delete a session and all its messages
  Future<void> deleteSession({
    required String uid,
    required String sessionId,
  }) async {
    // Delete all messages first
    final messages =
        await _messagesRef(uid, sessionId).limit(500).get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_chatsRef(uid).doc(sessionId));
    await batch.commit();
  }

  /// Clear all messages in a session (keep session)
  Future<void> clearMessages({
    required String uid,
    required String sessionId,
  }) async {
    final messages = await _messagesRef(uid, sessionId).get();
    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_chatsRef(uid).doc(sessionId), {
      'messageCount': 0,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
