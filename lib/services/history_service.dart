import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mcq.dart';

class HistoryEntry {
  final String subject;
  final Mcq mcq;
  final int? selectedIndex; // null if not answered
  final bool? wasCorrect;   // null if not answered
  final DateTime timestamp;

  HistoryEntry({
    required this.subject,
    required this.mcq,
    required this.selectedIndex,
    required this.wasCorrect,
    required this.timestamp,
  });
}

class HistoryService {
  static final List<HistoryEntry> _items = <HistoryEntry>[];
  static const int _maxEntries = 10;
  static const String _prefsKey = 'app_history_v1';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      _items
        ..clear()
        ..addAll(list.map((e) => _fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      // ignore corrupt data
    }
  }

  static void addEntry({
    required String subject,
    required Mcq mcq,
    required int? selectedIndex,
    required bool? wasCorrect,
  }) {
    _items.insert(0, HistoryEntry(
      subject: subject,
      mcq: mcq,
      selectedIndex: selectedIndex,
      wasCorrect: wasCorrect,
      timestamp: DateTime.now(),
    ));
    if (_items.length > _maxEntries) {
      _items.removeRange(_maxEntries, _items.length);
    }
    _persist();
  }

  static List<HistoryEntry> getItems() => List.unmodifiable(_items);

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_items.map(_toJson).toList());
    await prefs.setString(_prefsKey, data);
  }

  static Map<String, dynamic> _toJson(HistoryEntry e) => {
        'subject': e.subject,
        'mcq': {
          'question': e.mcq.question,
          'options': e.mcq.options,
          'correctIndex': e.mcq.correctIndex,
          'explanation': e.mcq.explanation,
        },
        'selectedIndex': e.selectedIndex,
        'wasCorrect': e.wasCorrect,
        'timestamp': e.timestamp.toIso8601String(),
      };

  static HistoryEntry _fromJson(Map<String, dynamic> m) => HistoryEntry(
        subject: (m['subject'] ?? '').toString(),
        mcq: Mcq(
          question: (m['mcq']?['question'] ?? '').toString(),
          options: (m['mcq']?['options'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          correctIndex: (m['mcq']?['correctIndex'] as num?)?.toInt() ?? 0,
          explanation: (m['mcq']?['explanation'] ?? '').toString(),
        ),
        selectedIndex: (m['selectedIndex'] as num?)?.toInt(),
        wasCorrect: m['wasCorrect'] as bool?,
        timestamp: DateTime.tryParse((m['timestamp'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}


