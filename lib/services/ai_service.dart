import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcq.dart';

class AiService {
  // 按用户提供
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _model = 'mistralai/mistral-7b-instruct:free';

  static const Map<String, String> subjectToExamples = {
    'Pure Chemistry': 'Pure Chemistry',
    'Pure Physics': 'Pure Physics',
    'Combine Chemistry': 'Combine Chemistry',
    'Combine Biology': 'Combine Biology',
  };

  /// 生成 1 道 MCQ（含答案和解释）。
  /// 返回结构化 Mcq。
  static Future<Mcq> generateSingleMcq(String subject) async {
    final prompt = _buildPrompt(subject);
    final completion = await _chatCompletion(prompt);
    final parsed = _tryParseToJson(completion);
    return Mcq.fromJson(parsed);
  }

  static String _buildPrompt(String subject) {
    final syllabus = subjectToExamples[subject] ?? 'Pure Chemistry';
    return '''You are an O-Level $syllabus MCQ generator.
Create ONE new multiple-choice question that mimics the style and syllabus coverage of the given subject's examples, but do not copy any exact content.

Constraints:
- Keep it general (use X/Y/Z instead of specific uncommon chemical/biological names when possible).
- Provide exactly 4 options labelled A, B, C, D.
- Provide the correct option letter and a 1-2 sentence explanation.
- Output MUST be valid strict JSON with keys: question (string), options (array of 4 strings), correct ("A"|"B"|"C"|"D"), explanation (string).
- Do not include any markdown, no backticks, no extra keys, no commentary.
''';
  }

  static Future<String> _chatCompletion(String prompt) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ]
    });

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI API error: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = map['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('AI API returned no choices');
    }
    final content = choices.first['message']?['content']?.toString() ?? '';
    if (content.isEmpty) {
      throw Exception('AI API empty content');
    }
    return content.trim();
  }

  static Map<String, dynamic> _tryParseToJson(String text) {
    // 尝试直接解析；若失败，做简单清洗
    String cleaned = text.trim();
    // 去掉可能的代码围栏
    if (cleaned.startsWith('```')) {
      final end = cleaned.lastIndexOf('```');
      if (end > 0) cleaned = cleaned.substring(3, end).trim();
    }
    // 去掉可能的 "json" 标记
    if (cleaned.toLowerCase().startsWith('json')) {
      cleaned = cleaned.substring(4).trim();
    }
    try {
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      return map;
    } catch (_) {
      // 退化解析：从 A-D 选项文本构造
      final fallback = _parseFromPlainText(text);
      return fallback;
    }
  }

  static Map<String, dynamic> _parseFromPlainText(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String question = '';
    final options = <String>[];
    String correct = 'A';
    String explanation = '';

    for (final line in lines) {
      if (question.isEmpty && !RegExp(r'^[ABCD][).]').hasMatch(line)) {
        question = line.replaceAll(RegExp(r'^\d+[).]\s*'), '').trim();
        continue;
      }
      if (RegExp(r'^A[).]').hasMatch(line)) options.add(line.substring(2).trim());
      if (RegExp(r'^B[).]').hasMatch(line)) options.add(line.substring(2).trim());
      if (RegExp(r'^C[).]').hasMatch(line)) options.add(line.substring(2).trim());
      if (RegExp(r'^D[).]').hasMatch(line)) options.add(line.substring(2).trim());
      final m = RegExp(r'Correct\s*[:\-]\s*([ABCD])', caseSensitive: false).firstMatch(line);
      if (m != null) correct = m.group(1)!.toUpperCase();
      final ex = RegExp(r'Explanation\s*[:\-]\s*(.*)', caseSensitive: false).firstMatch(line);
      if (ex != null) explanation = ex.group(1)!.trim();
    }

    while (options.length < 4) {
      options.add('Option ${String.fromCharCode(65 + options.length)}');
    }

    return {
      'question': question.isEmpty ? 'Generated question' : question,
      'options': options.take(4).toList(),
      'correct': correct,
      'explanation': explanation.isEmpty ? 'Refer to core concept of the syllabus.' : explanation,
    };
  }
}


