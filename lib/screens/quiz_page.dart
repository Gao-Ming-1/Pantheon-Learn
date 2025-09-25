import 'package:flutter/material.dart';
import '../models/mcq.dart';
import '../services/ai_service.dart';

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
    'Pure Chemistry',
    'Pure Physics',
    'Combine Chemistry',
    'Combine Biology',
  ];

  Future<void> _loadNext() async {
    if (selectedSubject == null) return;
    setState(() {
      loading = true;
      error = null;
      selectedIndex = null;
    });
    try {
      final mcq = await AiService.generateSingleMcq(selectedSubject!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MCQ Practice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
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
            const SizedBox(height: 12),
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


