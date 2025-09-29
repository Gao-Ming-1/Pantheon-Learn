import 'package:flutter/material.dart';
import '../services/history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = HistoryService.getItems();
    return Scaffold(
      appBar: AppBar(title: const Text('History (Last 10)')),
      body: items.isEmpty
          ? const Center(child: Text('No history yet.'))
          : ListView.builder(
              controller: _controller,
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final it = items[i];
                final mcq = it.mcq;
                final selected = it.selectedIndex;
                final correctIndex = mcq.correctIndex;
                final wasCorrect = it.wasCorrect;
                final subject = it.subject;
                final time = it.timestamp;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(mcq.question),
                        const SizedBox(height: 8),
                        for (int idx = 0; idx < mcq.options.length; idx++)
                          _HistoryOptionTile(
                            index: idx,
                            text: mcq.options[idx],
                            isSelected: selected == idx,
                            isCorrect: correctIndex == idx,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Explanation: ${mcq.explanation}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your answer: ${selected == null ? '-' : String.fromCharCode(65 + selected)}  •  Correct: ${String.fromCharCode(65 + correctIndex)}  •  Result: ${wasCorrect == null ? '-' : (wasCorrect ? 'Correct' : 'Wrong')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.vertical_align_top),
      ),
    );
  }
}

class _HistoryOptionTile extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;

  const _HistoryOptionTile({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    Color border = Colors.grey.shade300;
    Color? fill;
    IconData? icon;
    if (isCorrect) {
      border = Colors.green;
      fill = Colors.green.withOpacity(0.06);
      icon = Icons.check_circle;
    } else if (isSelected) {
      border = Colors.red;
      fill = Colors.red.withOpacity(0.06);
      icon = Icons.cancel;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text('$letter. $text'),
        trailing: icon == null ? null : Icon(icon, color: isCorrect ? Colors.green : Colors.red),
      ),
    );
  }
}


