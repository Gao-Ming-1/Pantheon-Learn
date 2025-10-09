import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssistantMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  AssistantMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
  factory AssistantMessage.fromJson(Map<String, dynamic> m) =>
      AssistantMessage(role: (m['role'] ?? '').toString(), content: (m['content'] ?? '').toString());
}

class AssistantSession {
  final String id;
  final DateTime createdAt;
  String title;
  final List<AssistantMessage> messages;

  AssistantSession({required this.id, required this.createdAt, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'messages': messages.map((e) => e.toJson()).toList(),
      };
  factory AssistantSession.fromJson(Map<String, dynamic> m) => AssistantSession(
        id: (m['id'] ?? '').toString(),
        createdAt: DateTime.tryParse((m['createdAt'] ?? '').toString()) ?? DateTime.now(),
        title: (m['title'] ?? 'New Chat').toString(),
        messages: ((m['messages'] as List<dynamic>? ?? [])).map((e) => AssistantMessage.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class AssistantService {
  AssistantService._internal();
  static final AssistantService instance = AssistantService._internal();

  static const String _prefsKey = 'assistant_sessions_v1';
  static const String _endpoint = 'https://pantheon-learn.vercel.app/api/chat';

  final List<AssistantSession> _sessions = <AssistantSession>[];
  String? _activeSessionId;

  List<AssistantSession> get sessions => List.unmodifiable(_sessions);
  AssistantSession? get activeSession => _sessions.firstWhere((s) => s.id == _activeSessionId, orElse: () => _sessions.isEmpty ? null as AssistantSession : _sessions.first);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List list = jsonDecode(raw) as List;
        _sessions
          ..clear()
          ..addAll(list.map((e) => AssistantSession.fromJson(e as Map<String, dynamic>)));
        if (_sessions.isNotEmpty) {
          _activeSessionId = _sessions.first.id;
        }
      } catch (_) {}
    }
    if (_sessions.isEmpty) newChat();
  }

  void newChat() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final s = AssistantSession(id: id, createdAt: DateTime.now(), title: 'New Chat', messages: []);
    _sessions.insert(0, s);
    _activeSessionId = id;
    _persist();
  }

  void selectChat(String id) {
    _activeSessionId = id;
    _persist();
  }

  Future<void> deleteChat(String id) async {
    _sessions.removeWhere((e) => e.id == id);
    if (_sessions.isNotEmpty) {
      _activeSessionId = _sessions.first.id;
    } else {
      newChat();
    }
    _persist();
  }

  Future<void> sendMessage(String content) async {
    final session = activeSession;
    if (session == null) return;
    session.messages.add(AssistantMessage(role: 'user', content: content));
    if (session.title == 'New Chat' && content.trim().isNotEmpty) {
      session.title = content.trim().substring(0, content.trim().length > 30 ? 30 : content.trim().length);
    }
    _persist();

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a friendly AI tutor embedded in a quiz learning site. Only answer learning-related questions and politely refuse unrelated topics.'
        },
        ...session.messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      ]
    });

    try {
      final res = await http.post(Uri.parse(_endpoint), headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
        // Expecting OpenRouter-like response: {choices:[{message:{role:'assistant',content:'...'}}]}
        final choices = data['choices'] as List<dynamic>?;
        String reply = 'Sorry, I could not generate a response.';
        if (choices != null && choices.isNotEmpty) {
          reply = (choices.first['message']?['content'] ?? reply).toString();
        }
        session.messages.add(AssistantMessage(role: 'assistant', content: reply));
        _persist();
      } else {
        session.messages.add(AssistantMessage(role: 'assistant', content: 'Request failed: ${res.statusCode}'));
        _persist();
      }
    } catch (e) {
      session.messages.add(AssistantMessage(role: 'assistant', content: 'Network error: $e'));
      _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_sessions.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, data);
  }
}


