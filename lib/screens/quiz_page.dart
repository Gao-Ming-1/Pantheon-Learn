import 'package:flutter/material.dart';
import 'dart:math';
import '../models/mcq.dart';
import '../services/ai_service.dart';
import '../models/word_entry.dart';
import 'word_list_page.dart';
import '../data/english_dict.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String? selectedSubject;
  Mcq? current;
  int? selectedIndex;
  bool loading = false;
  String? error;

  final subjects = const [
    'English',
    'Pure Chemistry',
    'Pure Physics',
    'Combine Chemistry',
    'Combine Biology',
  ];

  bool englishMode = true; // true: 题干英文→选中文；false: 题干中文→选英文
  // English 出题模式（四种文案）
  static const String kModeWordToCn = 'Pick Chinese meaning';
  static const String kModeWordToEn = 'Pick English meaning';
  static const String kModeCnToWord = 'Match Chinese meaning';
  static const String kModeEnToWord = 'Match English meaning';
  String englishQuestionMode = kModeWordToCn;

  Future<void> _loadNext() async {
    if (selectedSubject == null) return;
    setState(() {
      loading = true;
      error = null;
      selectedIndex = null;
    });
    try {
      Mcq mcq;
      if (selectedSubject == 'English') {
        mcq = await _generateEnglishMcq();
      } else {
        mcq = await AiService.generateSingleMcq(selectedSubject!);
      }
      setState(() {
        current = mcq;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<Mcq> _generateEnglishMcq() async {
    final words = englishWordDict;
    if (words.isEmpty) {
      throw Exception('No words found in resources.');
    }
    final rnd = Random();
    final answer = words[rnd.nextInt(words.length)];

    // 生成干扰项
    final pool = List<WordEntry>.from(words)..removeWhere((w) => w.word == answer.word && w.chineseMeaning == answer.chineseMeaning);
    pool.shuffle(rnd);
    final distractors = pool.take(3).toList();

    late final String question;
    final options = <String>[];
    int correctIndex;

    switch (englishQuestionMode) {
      case kModeWordToCn:
        question = '$kModeWordToCn: ${answer.word}';
        options.add(answer.chineseMeaning);
        options.addAll(distractors.map((e) => e.chineseMeaning));
        break;
      case kModeWordToEn:
        question = '$kModeWordToEn: ${answer.word}';
        options.add(answer.englishMeaning);
        options.addAll(distractors.map((e) => e.englishMeaning));
        break;
      case kModeCnToWord:
        question = '$kModeCnToWord\n${answer.chineseMeaning}';
        options.add(answer.word);
        options.addAll(distractors.map((e) => e.word));
        break;
      case kModeEnToWord:
        question = '$kModeEnToWord\n${answer.englishMeaning}';
        options.add(answer.word);
        options.addAll(distractors.map((e) => e.word));
        break;
      default:
        question = '$kModeWordToCn: ${answer.word}';
        options.add(answer.chineseMeaning);
        options.addAll(distractors.map((e) => e.chineseMeaning));
        break;
    }

    // 打乱选项并记录正确下标
    final indexed = options.asMap().entries.toList();
    indexed.shuffle(rnd);
    final shuffled = indexed.map((e) => e.value).toList();
    final originalCorrect = 0; // 我们把正确答案放在 options[0]
    correctIndex = shuffled.indexOf(options[originalCorrect]);

    return Mcq(
      question: question,
      options: shuffled,
      correctIndex: correctIndex,
      explanation: () {
        switch (englishQuestionMode) {
          case kModeWordToCn:
            return '词汇对应：${answer.word} → ${answer.chineseMeaning}';
          case kModeWordToEn:
            return '词汇对应：${answer.word} → ${answer.englishMeaning}';
          case kModeCnToWord:
            return '词汇对应：${answer.chineseMeaning} → ${answer.word}';
          case kModeEnToWord:
            return '词汇对应：${answer.englishMeaning} → ${answer.word}';
          default:
            return '词汇对应：${answer.word}';
        }
      }(),
    );
  }

  void _onSelect(int index) {
    if (current == null) return;
    setState(() {
      selectedIndex = index;
    });
    final isCorrect = index == current!.correctIndex;
    if (isCorrect) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correct! Generating next question…')),
      );
      _loadNext();
    } else {
      _showAnswerSheet();
    }
  }

  void _showAnswerSheet() {
    if (current == null) return;
    final correctLetter = String.fromCharCode(65 + current!.correctIndex);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correct Answer：$correctLetter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(current!.explanation),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _loadNext();
                      },
                      child: const Text('Next Question'),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWordList() async {
    final words = englishWordDict;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordListPage(words: words)),
    );
  }

  Widget _englishToolbar() {
    const modes = [
      kModeWordToCn,
      kModeWordToEn,
      kModeCnToWord,
      kModeEnToWord,
    ];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: englishQuestionMode,
            items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                englishQuestionMode = v;
              });
            },
            decoration: const InputDecoration(labelText: 'English question mode'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantheon Learn')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('images/LOGO.png', height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Subject'),
                    value: selectedSubject,
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSubject = v;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedSubject == 'English') _englishToolbar(),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: (selectedSubject == null || loading) ? null : _loadNext,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Generate Question'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: (current == null || loading) ? null : () {
                    _loadNext();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
                const SizedBox(width: 12),
                if (selectedSubject == 'English')
                  OutlinedButton.icon(
                    onPressed: loading ? null : _openWordList,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Word List'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: current == null
                  ? const Center(child: Text('Please select a subject and generate a question.'))
                  : _QuestionCard(
                      mcq: current!,
                      selectedIndex: selectedIndex,
                      onTap: _onSelect,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Mcq mcq;
  final int? selectedIndex;
  final void Function(int index) onTap;

  const _QuestionCard({
    required this.mcq,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mcq.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (int i = 0; i < mcq.options.length; i++)
              _OptionTile(
                index: i,
                text: mcq.options[i],
                selected: selectedIndex == i,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text('$letter. $text'),
      ),
    );
  }
}


