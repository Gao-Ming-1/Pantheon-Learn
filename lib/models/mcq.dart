class Mcq {
  final String question;
  final List<String> options;
  final int correctIndex; // 0..3
  final String explanation;

  Mcq({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory Mcq.fromJson(Map<String, dynamic> json) {
    final List<dynamic> opts = json['options'] ?? [];
    return Mcq(
      question: (json['question'] ?? '').toString().trim(),
      options: opts.map((e) => e.toString()).toList(),
      correctIndex: _parseCorrectIndex(json['correct']),
      explanation: (json['explanation'] ?? '').toString().trim(),
    );
  }

  static int _parseCorrectIndex(dynamic correct) {
    if (correct == null) return 0;
    final String c = correct.toString().trim().toUpperCase();
    if (c == 'A') return 0;
    if (c == 'B') return 1;
    if (c == 'C') return 2;
    if (c == 'D') return 3;
    // If numeric index provided
    final int? idx = int.tryParse(c);
    if (idx != null && idx >= 0 && idx <= 3) return idx;
    return 0;
  }
}


