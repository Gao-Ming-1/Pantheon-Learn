class WordEntry {
  final String word;
  final List<String> englishMeaning;
  final List<String> chineseMeaning;

  WordEntry({
    required this.word,
    required this.englishMeaning,
    required this.chineseMeaning,
  });

  // 简化构造函数，移除复杂的类型转换
  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word']?.toString() ?? '',
        englishMeaning: _convertToList(json['english_meaning']),
        chineseMeaning: _convertToList(json['chinese_meaning']),
      );

  static List<String> _convertToList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return [value.toString()];
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'english_meaning': englishMeaning,
        'chinese_meaning': chineseMeaning,
      };

  @override
  String toString() => '$word — ${chineseMeaning.join("; ")}';
}