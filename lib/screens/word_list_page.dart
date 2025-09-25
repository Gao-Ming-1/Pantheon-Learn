import 'package:flutter/material.dart';
import '../models/word_entry.dart';

class WordListPage extends StatelessWidget {
  final List<WordEntry> words;
  const WordListPage({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word List')),
      body: ListView.separated(
        itemBuilder: (ctx, i) {
          final w = words[i];
          return ListTile(
            title: Text(w.word),
            subtitle: Text('${w.englishMeaning}\n${w.chineseMeaning}'),
            isThreeLine: true,
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: words.length,
      ),
    );
  }
}


