class WordEntry {
  final String word;            // 英文单词或词组
  final String englishMeaning;  // 英语释义（可选）
  final String chineseMeaning;  // 中文释义

  const WordEntry({
    required this.word,
    required this.englishMeaning,
    required this.chineseMeaning,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
    word: json['word'] as String,
    englishMeaning: json['english_meaning'] as String? ?? '',
    chineseMeaning: json['chinese_meaning'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'english_meaning': englishMeaning,
    'chinese_meaning': chineseMeaning,
  };

  @override
  String toString() => '$word — $chineseMeaning';
}

// 你可以把内置的词汇表填在这里：
// 例如：
// const kEnglishWordBank = <WordEntry>[
//   WordEntry(word: 'photosynthesis', englishMeaning: 'process in plants making food', chineseMeaning: '光合作用'),
//   WordEntry(word: 'evaporation', englishMeaning: 'liquid to gas at surface', chineseMeaning: '蒸发'),
// ];
const List<WordEntry> kEnglishWordBank = <WordEntry>[];

Future<List<WordEntry>> getEnglishWordList() async {
  return kEnglishWordBank;
}