import 'package:flutter/material.dart';
import 'dart:math';
import '../models/mcq.dart';
import '../services/ai_service.dart';
import '../models/word_entry.dart';
import 'word_list_page.dart';
import '../data/english_dict.dart';
import '../services/history_service.dart';
import '../services/tts_service.dart';
import 'settings_page.dart';
import 'assistant_chat_page.dart';
import '../widgets/combo.dart';

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
  final GlobalKey<ComboWidgetState> _comboKey = GlobalKey<ComboWidgetState>();

  final subjects = const [
    'Olevel English',
    'PSLE English',
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
      if (selectedSubject == 'Olevel English' ||
          selectedSubject == 'PSLE English') {
        // 英语科目：使用默认参数（较宽松）
        _comboKey.currentState?.setTuning(
          decayStep: 0.01,
          correctIncD: 0.58,
          correctIncOther: 0.25,
          wrongDec: 0.30,
        );
        mcq = await _generateEnglishMcq();
      } else {
        // 非英语科目：更慢衰减、更大奖励、更重惩罚
        _comboKey.currentState?.setTuning(
          decayStep: 0.006,     // 更慢衰减
          correctIncD: 0.70,    // 更大奖励
          correctIncOther: 0.35,
          wrongDec: 0.45,       // 惩罚更重
        );
        // 生成过程中暂停连击衰减
        _comboKey.currentState?.setPaused(true);
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
        // 恢复连击衰减
        _comboKey.currentState?.setPaused(false);
      });
    }
  }

  Future<Mcq> _generateEnglishMcq() async {
    final words =
        selectedSubject == 'PSLE English'
            ? englishWordDictPSLE
            : englishWordDictOlevel;
    if (words.isEmpty) {
      throw Exception('No words found in resources.');
    }
    final rnd = Random();
    final answer = words[rnd.nextInt(words.length)];

    // 生成干扰项
    final pool = List<WordEntry>.from(words)..removeWhere(
      (w) => w.word == answer.word && w.chineseMeaning == answer.chineseMeaning,
    );
    pool.shuffle(rnd);
    final distractors = pool.take(3).toList();

    late final String question;
    final options = <String>[];
    int correctIndex;

    switch (englishQuestionMode) {
      case kModeWordToCn:
        question = '$kModeWordToCn\n${answer.word}';
        options.add(
          answer.chineseMeaning.isEmpty ? '' : answer.chineseMeaning.first,
        );
        options.addAll(
          distractors.map(
            (e) => e.chineseMeaning.isEmpty ? '' : e.chineseMeaning.first,
          ),
        );
        break;
      case kModeWordToEn:
        question = '$kModeWordToEn\n${answer.word}';
        options.add(
          answer.englishMeaning.isEmpty ? '' : answer.englishMeaning.first,
        );
        options.addAll(
          distractors.map(
            (e) => e.englishMeaning.isEmpty ? '' : e.englishMeaning.first,
          ),
        );
        break;
      case kModeCnToWord:
        question = '$kModeCnToWord\n${answer.chineseMeaning}';
        options.add(answer.word);
        options.addAll(distractors.map((e) => e.word));
        break;
      case kModeEnToWord:
        question =
            '$kModeEnToWord\n${answer.englishMeaning.isEmpty ? '' : answer.englishMeaning.first}';
        options.add(answer.word);
        options.addAll(distractors.map((e) => e.word));
        break;
      default:
        question = '$kModeWordToCn: ${answer.word}';
        options.addAll(answer.chineseMeaning); // 展开所有中文释义
        for (var d in distractors) {
          options.addAll(d.chineseMeaning); // 展开每个干扰项
        }
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
    final isEnglish = selectedSubject == 'Olevel English' || selectedSubject == 'PSLE English';
    // 记录历史
    if (selectedSubject != null && current != null) {
      HistoryService.addEntry(
        subject: selectedSubject!,
        mcq: current!,
        selectedIndex: index,
        wasCorrect: isCorrect,
      );
    }
    // 所有科目均更新连击（英语使用默认参数，非英语已在载题时设置调优）
    if (isCorrect) {
      _comboKey.currentState?.onAnswerCorrect();
    } else {
      _comboKey.currentState?.onAnswerWrong();
    }
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
              Text(
                'Correct Answer：$correctLetter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWordList() async {
    final words =
        selectedSubject == 'PSLE English'
            ? englishWordDictPSLE
            : englishWordDictOlevel;
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WordListPage(words: words)));
  }

  Widget _englishToolbar() {
    const modes = [kModeWordToCn, kModeWordToEn, kModeCnToWord, kModeEnToWord];
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: englishQuestionMode,
            items:
                modes
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                englishQuestionMode = v;
                // 切换模式后清空当前题目，显示默认提示
                current = null;
                selectedIndex = null;
                error = null;
              });
            },
            decoration: const InputDecoration(
              labelText: 'English question mode',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print('home build start');
    final widgetTree = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Use LOGO as title at the left
            Image.asset('images/LOGO.png', height: 28),
            const Spacer(),
            // Smaller AI Assistant button aligned to the right
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AssistantChatPage()),
                );
              },
              icon: const Icon(Icons.smart_toy_outlined, size: 18),
              label: const Text('AI Assistant'),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 1),
                    ),
                    icon: Transform.translate(
                      offset: const Offset(0, -7),
                      child: const Icon(Icons.arrow_drop_down),
                    ),
                    value: selectedSubject,
                    items:
                        subjects
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSubject = v;
                        // 切换科目时重置连击
                        _comboKey.currentState?.reset();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed:
                      (current == null || loading)
                          ? null
                          : () {
                            _loadNext();
                          },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedSubject == 'Olevel English' ||
                selectedSubject == 'PSLE English')
              _englishToolbar(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed:
                      (selectedSubject == null || loading) ? null : _loadNext,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Generate Question'),
                ),
                const SizedBox(width: 8),
                // Combo 紧随按钮右侧，单行显示
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 56,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 200,
                          height: 60,
                          child: ComboWidget(key: _comboKey),
                        ),
                      ),
                    ),
                  ),
                ),
                // Word List 按钮移至 Settings 页面
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            current == null
                ? const Padding(
                  padding: EdgeInsets.only(top: 200),
                  child: Center(
                    child: Text(
                      'Please select a subject and generate a question.',
                    ),
                  ),
                )
                : _QuestionCard(
                  mcq: current!,
                  selectedIndex: selectedIndex,
                  onTap: _onSelect,
                  showTitleTts:
                      (selectedSubject == 'Olevel English' ||
                          selectedSubject == 'PSLE English') &&
                      (englishQuestionMode == kModeWordToCn ||
                          englishQuestionMode == kModeWordToEn),
                  showOptionTts:
                      (selectedSubject == 'Olevel English' ||
                          selectedSubject == 'PSLE English') &&
                      (englishQuestionMode == kModeCnToWord ||
                          englishQuestionMode == kModeEnToWord),
                ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Home：回到主界面（当前页），可选择滚动到顶部或刷新
            // 这里什么都不做即可保持当前主页
          } else if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
          }
        },
      ),
    );
    print('home build end');
    return widgetTree;
  }
}

class _QuestionCard extends StatelessWidget {
  final Mcq mcq;
  final int? selectedIndex;
  final void Function(int index) onTap;
  final bool showTitleTts;
  final bool showOptionTts;

  const _QuestionCard({
    required this.mcq,
    required this.selectedIndex,
    required this.onTap,
    this.showTitleTts = false,
    this.showOptionTts = false,
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
            _QuestionTitle(text: mcq.question, englishMode: showTitleTts),
            const SizedBox(height: 16),
            for (int i = 0; i < mcq.options.length; i++)
              _OptionTile(
                index: i,
                text: mcq.options[i],
                selected: selectedIndex == i,
                onTap: () => onTap(i),
                showTtsIcon: showOptionTts,
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
  final bool showTtsIcon; // 仅 English 匹配题型显示单词发音图标

  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.onTap,
    this.showTtsIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '$letter. $text',
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        trailing:
            showTtsIcon
                ? IconButton(
                  icon: const Icon(Icons.volume_up, size: 20),
                  onPressed: () {
                    TtsService.instance.speak(text);
                  },
                )
                : null,
      ),
    );
  }
}

class _QuestionTitle extends StatelessWidget {
  final String text;
  final bool englishMode; // 仅在 English 的“Pick ... meaning”场景下显示发音按钮
  const _QuestionTitle({required this.text, required this.englishMode});

  @override
  Widget build(BuildContext context) {
    if (!englishMode) {
      return Text(text, style: Theme.of(context).textTheme.titleMedium);
    }
    final parts = text.split('\n');
    final title = parts.isNotEmpty ? parts.first : text;
    final word = parts.length > 1 ? parts[1].trim() : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        if (word.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  word,
                  style: Theme.of(context).textTheme.titleLarge,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20),
                onPressed: () {
                  TtsService.instance.speak(word);
                },
              ),
            ],
          ),
      ],
    );
  }
}
