class WordEntry {
  final String word;                 // 英文单词或词组
  final List<String> englishMeaning; // 英语释义（可多条）
  final List<String> chineseMeaning; // 中文释义（可多条）

  WordEntry({
    required this.word,
    required dynamic englishMeaning,
    required dynamic chineseMeaning,
  })  : englishMeaning = _asStringList(englishMeaning),
        chineseMeaning = _asStringList(chineseMeaning);

  static List<String> _asStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[value.toString()];
  }

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        word: json['word'] as String,
        englishMeaning: json['english_meaning'] ?? [],
        chineseMeaning: json['chinese_meaning'] ?? [],
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'english_meaning': englishMeaning,
        'chinese_meaning': chineseMeaning,
      };

  @override
  String toString() => '$word — ${chineseMeaning.join("; ")}';
}


final List<WordEntry> kEnglishWordBank = [
  WordEntry(
    word: 'photosynthesis',
    englishMeaning: 'process in plants making food',
    chineseMeaning: '光合作用',
  ),
  WordEntry(
    word: 'evaporation',
    englishMeaning: 'liquid to gas at surface',
    chineseMeaning: '蒸发',
  ),
];

Future<List<WordEntry>> getEnglishWordList() async {
  return kEnglishWordBank;
}
