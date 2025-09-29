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
  }

  static List<HistoryEntry> getItems() => List.unmodifiable(_items);
}


